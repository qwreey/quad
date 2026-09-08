--!strict
--[[
	Debounce / Throttle — time-based emit gates, as POLICIES on top of
	`state:Gate`, driven by the injected `setTimeout`/`clearTimeout` ops.
	`.claude/base/debounce-throttle-plan.md` (1-1 the one-bit model, 5 API shape,
	5-4 control handles, 6 injected ops, 7 window/timer policy) and
	`.claude/base/gate-plan.md` 5번 (`b:Policy(emit)` delegation, two paths).

	  Debounce{ Time, Leading?, Trailing?, MaxTime?, Handle? } -> factory
	  Throttle{ Time, Leading?, Trailing?, Handle? }           -> factory
	  state:Apply(factory)   -- one GateNode per Apply (own Blocker, own timers)
	  factory:Flush() / factory:Cancel()   -- broadcast to every gate it made
	  opts.Handle (Ref<GateHandle?>) is Set with { Flush, Cancel } at Apply time

	One implementation, one bit (`reset`): Debounce = the signal restarts the
	window; Throttle = the window length is fixed. Leading/trailing/reopen-after-
	pass are identical (plan 1-1). Semantics are (A) emit-gate: the gate only
	DEFERS downstream notification — `:Get()` inside a window is the latest value
	(plan 4).

	Wiring (gate-plan 5번, `H-118` table): the upstream-emit path goes through
	`pass()` = `blocker:Policy(emit)` — while a window is open the Blocker is On
	(the converse does not hold during a timer-path commit: window closed, Blocker
	still On until the flush returns), so `pass()` withholds or passes; the timer/handle path calls the
	gate's `emit()` / `emit(false)` directly and uses its return value ("was
	anything withheld") — the ONLY channel to the withheld set (`H-86`), which
	is why there is no `pending` flag here (`H-32` cannot recur). Every commit
	flushes through the direct `emit()` FIRST and settles the window after —
	`Blocker:Off()`/`OffWithoutEmit()` are never used as the flush (they run the
	handle blind: no return value, and `OffWithoutEmit` would discard a live
	batch); the Blocker is flipped Off only on an empty set. A re-entrant
	upstream emit during a flush lands in the fresh set: withheld if the window
	was still counted open (Blocker On), and if it opened the next window itself
	that window is kept (never two windows). `Flush` with nothing withheld is a
	true no-op (the running window is untouched).

	MaxTime uses a second timer (plan 7 form (b)), not `min(Time, deadline -
	os.clock())` (6-1): base stays clock-free so a virtual-time backend (the
	test mock) is fully deterministic — plan 11절 "가상 시계로 결정론적 테스트".
	The min-form is a later optimization behind the same surface.

	GC (plan 8): a pending timer holds its gate through the callback upvalues
	for at most 2 × Time after the last signal (the window that a pass reopens
	must see an empty set before the gate goes idle) — bounded, self-healing. The
	factory tracks its gates weak-key (5-4) so it never pins them; the strong
	owner of a gate's handle table is the `onUpstreamEmit` closure (same idiom
	as `Blocker`'s handle ownership, `H-63`). An `opts.Handle` Ref the USER holds
	does pin the gate (Ref → h → emit → GateNode → upstream chain) — that is the
	user's keep, same as holding the gated State itself.
]]

local Brand = require("./Brand")
local Blocker = require("./Blocker")
local QuadTypes = require("../luau_packages/quad_types")
local Err = require("./ErrorNamespace")

local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE
local isState = Brand.isState
local isRef = Brand.isRef

type Timeout = QuadTypes.Timeout

local WEAK_KEY_MT = { __mode = "k" }

-- `Time`/`MaxTime` are read at each schedule point only (plan 5-2: polling,
-- no subscription — an already scheduled timer keeps its delay).
local function readTime(name: string, field: string, t: any): number
	local v = if isState(t) then t:Get() else t
	if type(v) ~= "number" or v ~= v or v < 0 then
		-- reached from emit depth (upstream signal) and from timer callbacks — outermost
		Err.errorBefore(`{name}: {field} must be a non-negative number (got {typeof(v)})`, SURFACE)
	end
	return v
end

local function checkTime(name: string, field: string, t: any, optional: boolean)
	if t == nil then
		if optional then
			return
		end
		Err.errorBeforeNearest(`{name}: {field} is required (a number of seconds or a State<number>)`, SURFACE)
	end
	if isState(t) then
		return
	end
	if type(t) ~= "number" or t ~= t or t < 0 then
		Err.errorBeforeNearest(`{name}: {field} must be a non-negative number or a State<number> (got {typeof(t)})`, SURFACE)
	end
end

local function checkFlag(name: string, field: string, v: any)
	if v ~= nil and type(v) ~= "boolean" then
		Err.errorBeforeNearest(`{name}: {field} must be a boolean (got {typeof(v)})`, SURFACE)
	end
end

local FactoryImpl = {}
FactoryImpl.__index = FactoryImpl
function FactoryImpl.__tostring(self: any): string
	return `{self._name}(Time={tostring(self._opts.Time)})`
end

-- Broadcast (plan 5-4): snapshot before walking — a flush can propagate into
-- user code that applies this factory again (new gate mid-walk).
local function eachHandle(self: any, method: string)
	local snapshot = {}
	for handle in self._instances do
		snapshot[#snapshot + 1] = handle
	end
	for _, handle in snapshot do
		handle[method](handle)
	end
end

function FactoryImpl.Flush(self: any)
	eachHandle(self, "Flush")
end

function FactoryImpl.Cancel(self: any)
	eachHandle(self, "Cancel")
end

-- Applicative factory, method form (`H-158`): `state:Apply(Debounce{...})`.
function FactoryImpl.__apply(self: any, state: any): any
	if not isState(state) then
		Err.errorBeforeNearest(`{self._name}: Apply target must be a State (got {typeof(state)})`, SURFACE)
	end
	local module, opts, name = self._module, self._opts, self._name
	local reset, leading, trailing = self._reset, self._leading, self._trailing
	local maxTime = opts.MaxTime

	-- the per-gate handle: Flush/Cancel + the timer state (fields, not
	-- upvalues, so the ONE table is what every closure — and the registry — sees)
	local h: any = { _window = nil :: Timeout?, _cap = nil :: Timeout? }

	-- `emit` annotated: `state` is `any` here, so an unannotated parameter is inferred from
	-- its first use (`emit()` → `() -> boolean`) and `emit(false)` becomes an arity error
	-- under the new solver (user, 2026-09-08 — LSP `Luau1008`).
	local gated = state:Gate(function(emit: QuadTypes.GateEmit)
		local b = Blocker()
		local pass = b:Policy(emit)
		local onWindowEnd, onCap

		local function closeWindow()
			if h._window ~= nil then
				module.clearTimeout(h._window)
				h._window = nil
			end
		end
		local function clearCap()
			if h._cap ~= nil then
				module.clearTimeout(h._cap)
				h._cap = nil
			end
		end
		local function openWindow()
			-- read + schedule BEFORE any state change (`H-509`, the `H-392`/`H-445`
			-- precedent): a throwing Time read or a missing backend must not leave
			-- the Blocker On with no window (withheld signals with no timer to free them)
			local t = module.setTimeout(onWindowEnd, readTime(name, "Time", opts.Time))
			b:On() -- inside a window: upstream emits are withheld by `pass()`
			h._window = t
		end
		-- idle = no timers + Blocker Off. ONLY on an empty withheld set: `Blocker:
		-- OffWithoutEmit()` is not a flag flip — it runs the registered handle with
		-- `emit(false)`, which would DISCARD a non-empty batch (spec 2 caught this).
		local function goIdle()
			closeWindow()
			clearCap()
			b:OffWithoutEmit()
		end
		-- Timer-path commit: the window is over (expired or cut by the cap). Flush
		-- FIRST through the direct `emit()` (gate-plan 5번 two paths — the Blocker is
		-- still On, which is fine: the handle is not involved), THEN settle the
		-- state: if a re-entrant upstream emit already opened the next window, keep
		-- it (its signal sits in the fresh set — it was withheld, not passed); else
		-- reopen if anything went through (minimum Time until the next pass), or go
		-- idle. Shared by window end (trailing) and the MaxTime cap.
		local function commitIdle()
			closeWindow()
			clearCap()
			local had = emit()
			if h._window ~= nil then
				return
			end
			if had then
				openWindow()
			else
				goIdle() -- empty set: OffWithoutEmit is a no-op flush = flag only
			end
		end

		function onWindowEnd()
			h._window = nil -- expired, not cancelled
			if trailing then
				commitIdle()
			else
				emit(false) -- Trailing = false: the batch is DISCARDED (`H-55` — OffWithoutEmit alone would not empty it)
				goIdle()
			end
		end

		function onCap()
			h._cap = nil
			commitIdle() -- the running window is cancelled inside (goIdle) and reopened if anything passed
		end

		-- Handle-path commit (5-4): flush now; only if something went through does
		-- the window restart from now. With nothing withheld this is a true no-op —
		-- the running window (if any) is untouched (idempotent Flush).
		function h.Flush(_self: any)
			if emit() then
				closeWindow()
				clearCap()
				openWindow()
			end
		end
		function h.Cancel(_self: any)
			emit(false) -- drop, no propagation (set now empty → goIdle is safe)
			goIdle()
		end

		return function() -- onUpstreamEmit (synchronous; the gate already merged the source into its set)
			-- `held` = "this signal is withheld, not passed" — read the Blocker BEFORE
			-- anything below flips it (`H-510`): a re-entrant emit during a timer-path
			-- commit sees no window but a still-On Blocker, so `pass()` withholds
			local held = b:IsOn() or not leading
			if h._window == nil then
				-- idle: a leading gate passes now (Blocker is Off → `pass()` flushes),
				-- otherwise withhold first
				if not leading then
					b:On()
				end
				pass()
				if h._window == nil then -- guard: a re-entrant emit during the pass may have opened it
					openWindow()
				end
			else
				pass() -- Blocker is On → withheld
				if reset then -- the one bit: Debounce restarts the window, Throttle keeps it
					closeWindow()
					openWindow()
				end
			end
			-- MaxTime (Debounce only): a second timer the signal never resets — armed
			-- when something is withheld and only if trailing can pass it.
			if held and maxTime ~= nil and trailing and h._cap == nil then
				h._cap = module.setTimeout(onCap, readTime(name, "MaxTime", maxTime))
			end
		end
	end)

	self._instances[h] = true -- weak-key (plan 5-4): the gate's closure owns `h`, not the factory
	if opts.Handle ~= nil then
		opts.Handle:Set(h)
	end
	return gated
end

local function make(module: any, name: string, reset: boolean, opts: any): any
	if type(opts) ~= "table" then
		Err.errorBeforeNearest(`{name}: options table expected (got {typeof(opts)})`, SURFACE)
	end
	checkTime(name, "Time", opts.Time, false)
	checkFlag(name, "Leading", opts.Leading)
	checkFlag(name, "Trailing", opts.Trailing)
	if reset then
		checkTime(name, "MaxTime", opts.MaxTime, true)
	elseif opts.MaxTime ~= nil then
		Err.errorBeforeNearest("Throttle: MaxTime is Debounce-only (a throttle already passes every Time)", SURFACE)
	end
	if opts.Handle ~= nil and not isRef(opts.Handle) then
		Err.errorBeforeNearest(`{name}: Handle must be a Ref (got {typeof(opts.Handle)})`, SURFACE)
	end
	-- defaults differ per name (plan 5-3 table); both false passes nothing → error
	local leading = if reset then opts.Leading == true else opts.Leading ~= false
	local trailing = opts.Trailing ~= false
	if not leading and not trailing then
		Err.errorBeforeNearest(`{name}: Leading and Trailing both false would pass nothing through`, SURFACE)
	end
	return setmetatable({
		_module = module,
		_name = name,
		_opts = opts,
		_reset = reset,
		_leading = leading,
		_trailing = trailing,
		_instances = setmetatable({}, WEAK_KEY_MT),
	}, FactoryImpl)
end

-- Per-instance (`H-174` idiom): the factories read the module's injected
-- `setTimeout`/`clearTimeout` at schedule time (a provider may install them
-- after the factory was made).
local function Init(module: any)
	local function Debounce(opts: any): any
		return make(module, "Debounce", true, opts)
	end
	local function Throttle(opts: any): any
		return make(module, "Throttle", false, opts)
	end
	module.Debounce = Debounce
	module.Throttle = Throttle
	Err.setFuncLevel(SURFACE, Debounce, Throttle) -- `H-231`
end

Err.setFuncLevel(SURFACE, FactoryImpl.Flush, FactoryImpl.Cancel, FactoryImpl.__apply)

return { Init = Init }
