--!strict
--[[
	Observer — the leaf subscriber a `State` fires, and the owner of the two
	global subscription registries (`Subscribed` strong / `WeakSubscribed`
	weak-key) that `Effect.luau` shares (`H-99`).

	Assembly (`H-174`): `Observer.Init(module)` builds one implementation (and
	one registry pair) per quad instance; the lifetime gates are read as
	`module.Backend.canExecute(self)` / `module.Backend.canBound(self)` AT CALL TIME — never
	captured at init, the backend overwrites those fields after `New()`.
	`State.luau` reaches the constructor through `implFor(module)`.

	Sources, transcribed as-is:
	  - `.claude/base/source-state-plan.md` "전파 루프 — 확정 의사코드":
	    `Observer:_receive(from)` (`canExecute` → `fn(self._state, self, from)`,
	    else hold `_rerunRequired = true`, `H-159`; inside the install run →
	    `_pending`, run again in place), `Observer:_catchUp()`
	    (the ONLY place a held change is replayed — with `from = nil`),
	    `State:Observer(fn)` constructor ORDER (join `_subs` → forced install
	    run that repeats while `_pending` — round13 3′ reversed the old
	    "fn once → join" order, Q73), `observer._state` strong ref (`_hold`
	    equivalent, `H-110`); "`state:Observer(fn)`" section: fires once on
	    registration, `fn(targetState, self, emitFrom?)` — `nil` means
	    "no source: install or catch-up, read the value" (`H-164`); no-arg
	    `state:Observer()` = always-observe utility.
	  - `.claude/base/lifecycle-pattern.md` "(2) 전역 경로": the four entry
	    points — `WeakSubscribe` is the primitive (sets `.Subscribed = true`
	    too, `H-111`), `Subscribe` is INLINED (no delegation, `H-149`),
	    `WeakUnsubscribe` is lenient (`H-133`) except when a strong keep
	    exists, `Unsubscribe` is strict and clears both tables. Each entry
	    point runs its own `canBound` gate exactly once and throws with
	    `level 2` from its own body (`H-104`).

	An Observer is NOT an `Epoch`; it forwards the source it received. Its one
	piece of bookkeeping is `_seenRevision` (round13 3′, Q109) — the same
	"revision this handle last ran on" record Effect keeps per dep in its
	`_epochs` map, as one number because an Observer watches one node, and
	compared only for a Source (a derived target is outside it — see `runLoop`).
	`Effect` does NOT reuse these bodies (heterogeneous types; `conventions.md`
	설계 원칙) — the two follow one protocol with their own bodies.
]]

local Brand = require("./Brand")
local ImplRegistry = require("./ImplRegistry")
local Err = require("./ErrorNamespace")
local Relate = require("./Relate")
local Void = require("./Void")
local InitDispatch = require("./Dispatch")
local ModuleIdentity = require("./ModuleIdentity")
local QuadTypes = require("../luau_packages/quad_types")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

local ObserverBrand = Brand.ObserverBrand

local WEAK_KEY_MT = { __mode = "k" }

-- One implementation (and registry pair) per quad instance (`H-174`);
-- storage scheme in `ImplRegistry.luau`.
local implsOf = ImplRegistry.implsOf

local function createImpl(module: any)
	local Impl = {}
	Impl.__index = Impl
	-- `ObserverMarker` (quad-types) — the type promises the marker, so the value carries it
	-- (`H-300`); read through `__index`, zero per-instance slots. Identity stays the brand —
	-- the field is the input-position type's evidence (user decision 2026-09-07: Tag/
	-- Attr/Observer/Effect go marker like State/Slot, typing-limits 8.11).
	Impl.__quadObserver = true
	Impl._moduleIdentity = module.moduleIdentity -- cross-instance guard token (`ModuleIdentity.luau`), read via `__index`

	-- Registries — owned here, shared with `Effect.luau` (`H-99`). Per quad
	-- instance because the gates that read `.Subscribed` are per instance.
	local Subscribed = {} :: { [any]: true } -- strong: keeps the handle alive
	local WeakSubscribed = setmetatable({}, WEAK_KEY_MT) :: { [any]: true } -- membership only
	Impl._Subscribed = Subscribed
	Impl._WeakSubscribed = WeakSubscribed
	-- `__tostring` (2026-09-08, advisory 권고 1): strong / weak / none, from the registries
	local function subscriptionOf(self: any): string
		return if Subscribed[self] then "subscribed" elseif WeakSubscribed[self] then "weak" else "unsubscribed"
	end
	Impl._subscriptionOf = subscriptionOf
	function Impl.__tostring(self: any): string
		return `Observer({subscriptionOf(self)})`
	end

	-- ── EmitReceive ──────────────────────────────────────────────────
	-- round13 bundle 3′ (user decision 2026-09-30, Q73 (a) + Q110 (b)) — Effect's vocabulary, no new name:
	--   `_pending`       = "a delivery arrived while fn was running and could not run in place" (Effect's
	--                      field, same meaning); only possible while the handle is NOT executable — the
	--                      install window, or an fn that has just unsubscribed itself;
	--   `_rerunRequired` = "a change arrived while not executable" (held; replayed once on bind/subscribe);
	--   `force`          = the install run, which may run while unexecutable (Effect's parameter, same meaning).
	-- A forced run re-runs fn while `_pending` (the install window takes changes in place — an emit inside
	-- the install fire used to be lost, Q73; Effect's install already re-ran); an unforced run turns a
	-- leftover `_pending` into a hold. No oscillation cap (user: a non-converging install fn is UB, same as
	-- Effect's install). Executable deliveries still NEST — deliberately unlike Effect's deferred re-run:
	-- an Observer that threw keeps firing on the next change (self-healing, `H-445`/`H-545`), which a
	-- deferred loop without pcall would lose. Re-runs pass `from = nil` ("read the value", `H-164`).
	--
	-- `_seenRevision` (Q109, user decision 2026-09-30): the Source revision this handle last ran on —
	-- the SAME record Effect keeps per dep in its `_epochs` map (`Sync` before fn, `Update` on delivery),
	-- specialised to one number because an Observer watches exactly one node. Stamped at every fn start
	-- (`rawget` — nil for a derived State). A derived target is outside this record: a handle revived
	-- mid-wave (Q109 shape) or a nested wave (C6 shape) can run twice with the same value — its emit map
	-- filters at the node's entry, not the outer snapshot walk (2026-09-30 mock measurement; Effect's map
	-- keys the source and so filters the nested case, both double on revive).
	local function runLoop(self: any, from: any, force: boolean)
		local outer = self._running -- `H-183` (save/restore — `H-332`)
		self._running = true
		repeat
			self._pending = false
			self._seenRevision = rawget(self._state, "Revision") -- nil for a derived State
			self.fn(self._state, self, from)
			from = nil
		until not (self._pending and (force or module.Backend.canExecute(self)))
		if self._pending then
			self._pending = false
			self._rerunRequired = true -- lost executability inside fn: hold, replay on the next bind/subscribe
		end
		self._running = outer
	end

	function Impl._receive(self: any, from: any)
		-- Q109: a direct Source delivery whose revision this handle already ran on (a catch-up or a nested
		-- run in the same wave read it) is not a new change — skip (Effect: `_epochs:Update` false). Only
		-- `from == _state` (a Source) — see the derived-target limit at `runLoop`; a gate batch (an
		-- EpochSet) is never skipped.
		local rev = nil
		if from == self._state then -- only a Source emits itself as `from`
			rev = from.Revision
			if self._seenRevision == rev then
				return
			end
		end
		if module.Backend.canExecute(self) then -- read at fire time (`H-174`)
			-- Deliberately inline, not `runLoop(self, from, false)` (same result — code-review 2026-09-30
			-- suggested merging): every nesting level of a self-Setting fn passes through here, and a
			-- call adds a stack frame per level, lowering the recursion depth before overflow.
			-- `H-183`: fn may not change its own lifecycle (`H-147` symmetric). An fn
			-- that throws leaves the flag set — NOT "dead": this gate does not read it, so
			-- the Observer keeps firing; what the stuck flag blocks is (re)subscribing and
			-- (re)binding (`_assertBindable`) — round11 Q63 corrected the old "dead by
			-- contract" wording. Save/restore, not true/false: a reentrant wave (fn sets
			-- its own State) must not lower the guard for the outer fn's tail (`H-332`)
			local outer = self._running
			self._running = true
			if rev ~= nil then
				self._seenRevision = rev
			end
			self.fn(self._state, self, from)
			self._running = outer
			if self._pending and not outer then -- fn unsubscribed itself, then changed its State: hold
				self._pending = false
				self._rerunRequired = true
			end
		elseif self._running then
			self._pending = true -- inside a run that cannot take it in place (the install window): runLoop re-runs
		else
			self._rerunRequired = true -- `H-159`: change before binding is held — replayed once when bound
		end
	end

	-- Catch-up: bind/subscribe replays a held change once, with no source.
	-- The only caller set: `bindLifetime`, `Subscribe`, `WeakSubscribe`.
	function Impl._catchUp(self: any)
		if self._rerunRequired then
			self._rerunRequired = false
			runLoop(self, nil, false)
		end
	end

	-- `H-184`: `bindLifetime` asks this BEFORE committing the binding — a refusal
	-- must not leave a half-bound handle. Blame: OUTERMOST (4순회 `H-384`) — the
	-- only in-tree chain is leaf `process` (tagged) → `bindLifetime` (tagged by the
	-- backend) → here, so "nearest" stopped at `bindLifetime` and blamed
	-- `Observer.luau`; outermost reaches the user's entry (`effect-plan.md` 의사코드:
	-- "사용자 호출부"), the `H-378` lesson for a tagged intermediate frame.
	function Impl._assertBindable(self: any)
		if self._running then
			Err.errorBefore("Quad0109 Observer: cannot bind an Observer from inside its own fn", SURFACE) -- `H-183`
		end
	end

	-- ── four entry points (`lifecycle-pattern.md` (2)) ───────────────
	function Impl.WeakSubscribe(self: any): any
		if self._running then
			Err.errorBeforeNearest("Quad0110 Observer: cannot change subscription from inside its own fn", SURFACE) -- `H-183` (`H-147` symmetric)
		end
		if not module.Backend.canBound(self) then -- same gate as bindLifetime (shared isBoundAlive)
			Err.errorBeforeNearest( -- error-code: inline if
				if self.Subscribed then "Quad0111 Observer: already subscribed" else "Quad0234 Observer: already bound to an Instance",
				SURFACE
			)
		end
		self.Subscribed = true -- `H-111`: the weak path raises the flag too
		WeakSubscribed[self] = true
		self:_catchUp() -- `H-159`: held change once, symmetric with bind
		return self
	end

	-- round11 Q63 (b) (user decision 2026-09-18): the two UNsubscribe entries are not gated on
	-- `_running` — an fn that threw leaves the flag up forever, and a strongly subscribed handle
	-- could then never be released (module-lifetime keep of the handle and its `_state`).
	-- Releasing runs no fn, so the `H-183` reentrancy the gate exists for stays closed.
	function Impl.WeakUnsubscribe(self: any): any
		-- A strong keep left behind would make a half-released, never-GC'd handle: fail fast.
		if Subscribed[self] ~= nil then
			Err.errorBeforeNearest("Quad0112 Observer: subscribed strongly; use :Unsubscribe()", SURFACE)
		end
		-- `H-133`: that is the whole guard — never subscribed / already weakly released pass silently.
		WeakSubscribed[self] = nil
		self.Subscribed = false
		return self
	end

	function Impl.Subscribe(self: any): any
		if self._running then
			Err.errorBeforeNearest("Quad0113 Observer: cannot change subscription from inside its own fn", SURFACE) -- `H-183`
		end
		-- `H-149`: NOT delegated to WeakSubscribe — level 2 must point at the user's call,
		-- and colon delegation would resolve to a subtype's override.
		if not module.Backend.canBound(self) then
			Err.errorBeforeNearest( -- error-code: inline if
				if self.Subscribed then "Quad0114 Observer: already subscribed" else "Quad0235 Observer: already bound to an Instance",
				SURFACE
			)
		end
		self.Subscribed = true
		WeakSubscribed[self] = true
		Subscribed[self] = true -- just one more layer: the strong keep
		self:_catchUp()
		return self
	end

	function Impl.Unsubscribe(self: any): any -- no `_running` gate — see WeakUnsubscribe (Q63 (b))
		-- Symmetric with WeakUnsubscribe's guard: release through the path you subscribed by.
		if Subscribed[self] == nil then
			Err.errorBeforeNearest("Quad0115 Observer: only a strongly subscribed Observer can be released with :Unsubscribe() - a weakly subscribed one must be released with :WeakUnsubscribe(), and one held only by a seat must be released by clearing that seat", SURFACE)
		end
		Subscribed[self] = nil
		WeakSubscribed[self] = nil -- both tables, directly (`H-149`: no delegation)
		self.Subscribed = false
		return self
	end

	-- ── constructor — called by `State:Observer(fn)`; ORDER IS THE CONTRACT ──
	local function alwaysObserve(targetState: any)
		targetState:Get() -- no-arg `state:Observer()` = "always observe" utility
	end

	function Impl.new(state: any, fn: any): any
		local o: any = setmetatable({
			fn = fn or alwaysObserve,
			_state = state, -- strong: the handle holds its upstream (`_hold` equivalent, `H-110`)
			_rerunRequired = false, -- one meaning: "a change arrived while unexecutable" (held; 3′ — was seeded `true`)
			_seenRevision = false, -- the Source revision at this handle's last fn start (Q109 — Effect's `_epochs` entry)
			_pending = false, -- "a delivery arrived during this run" (Effect's field, same meaning)
			_running = false, -- `H-183`: raised around every fn run; the subscribe entries + `_assertBindable` refuse while up (Q63 (b): releasing passes)
			Subscribed = false, -- the shared flag both handle types carry (`H-111`)
		}, Impl)
		ObserverBrand:Register(o)
		-- round13 3′ (Q73 (a), user decision 2026-09-30): join FIRST, then the forced install run — an
		-- emit inside the install window (fn's own Set, or anyone else's) lands in `_receive` →
		-- `_pending` → the loop runs fn again. The old order (fire → join) was incidental, not intended
		-- (user: "첫 발화든 어느 발화든 자기 state 가 set 된다면 다시 실행되어도 됨"). An install fn that
		-- throws now leaves the handle in `_subs` (weak-keyed — it goes with the handle). `_running` stays
		-- up, so later deliveries only raise `_pending` and (re)subscribe/bind are refused: it never runs.
		state._subs[o] = true
		runLoop(o, nil, true)
		return o
	end

	-- `H-231`: public surface joins the shared error-namespace tag layer
	Err.setFuncLevel(SURFACE, Impl.WeakSubscribe, Impl.WeakUnsubscribe, Impl.Subscribe, Impl.Unsubscribe)

	return Impl
end

-- Dispatch-side registrations for the Observer VALUE (`H-278`, user-directed:
-- "각 객체를 아는 곳은 각 객체가 선언된 곳" — moved out of the dissolved
-- Dispatch/Leaf.luau; the None pair stays in Dispatch because None is
-- Dispatch's own concept). Two handlers:
--   - ObserverLeafHandler (HIGH — dispatch skeleton band): children-array
--     leaf binding. Body 1:1 with `source-state-plan.md` "Observer/Effect
--     Leaf dedup" (H-39 registration, `old ~= v` dedup via a weak Relate
--     (`H-71`, load-bearing per `H-266`)). The combined handler split into
--     one per owning module — the two value spaces are disjoint, so the
--     per-module dedup relate is equivalent.
--   - ObserverDynamicPathGuard (FALLBACK — override-able): a named-slot
--     Observer is a type-bypass mistake; message text is the 2026-08-18
--     user-confirmed wording, raised via the outermost scan (`errorBefore` —
--     same reasoning as match failure, `H-219`).
local function registerDispatchHandlers(module: any)
	module:RunInit(InitDispatch) -- idempotent pull (the `H-174` idiom)
	local dispatch: QuadTypes.Dispatch = module.Dispatch
	-- (inst, k) -> last bound observer. Weak value (`H-71`): the observer's fn
	-- may capture inst; v is strongly held by gchold while bound, so the entry
	-- cannot fall out early during the window dedup matters in.
	local relate = Relate()

	dispatch.addHandler({
		name = "ObserverLeafHandler",
		keyType = "number", -- `H-484`: only number keys can match (isHandlable checks it too)
		isHandlable = function(_inst: any, k: any, v: any): boolean
			-- k type check is mandatory — without it this handler outmatches
			-- the named-slot guard below and it becomes dead code
			return type(k) == "number" and Brand.isObserver(v)
		end,
		priority = dispatch.HANDLER_PRIORITY_HIGH,
		process = function(inst: any, k: any, v: any, _index: number): (any?, boolean) -> ()
			-- `H-39`: terminal handlers register their array position — this
			-- leaf contributes no physical element, so the pair is None/0.
			module.Bookkeeping.setEmpty(inst, k) -- `H-39` (한 본문 — Bookkeeping `setEmpty`)

			ModuleIdentity.assertOwnAtDispatch(module, v, "Observer") -- another instance's handle would never run here
			local old = relate:GetWeak(inst, k) -- read Weak to match the SetWeak write (`H-71`)
			if old ~= v then
				module.Backend.bindLifetime(inst, v)
			end
			relate:SetWeak(inst, k, v)
			return function(nextValue: any?, _retracting: boolean)
				if nextValue ~= v then
					module.Backend.unbindLifetime(v)
					-- Clear only when we actually stand down — unconditional
					-- clearing would kill the dedup on spurious re-emits
					-- (nextValue == v), the exact RefLeafHandler bug.
					if relate:GetWeak(inst, k) == v then
						relate:SetWeak(inst, k, nil)
					end
				end
			end
		end,
	})
	dispatch.addHandler({
		name = "ObserverDynamicPathGuard",
		isHandlable = function(_inst: any, _k: any, v: any): boolean
			return Brand.isObserver(v)
		end,
		priority = dispatch.HANDLER_PRIORITY_FALLBACK,
		process = function(_inst: any, k: any, _v: any, _index: number): (any?, boolean) -> ()
			Err.errorBefore(`Quad0116 Observer: must be an array item, not the value of a {typeof(k)} key`, SURFACE)
			return Void -- unreachable; keeps the contract type
		end,
	})
end

local function Init(module: any)
	implsOf(module).Observer = createImpl(module)
	registerDispatchHandlers(module)
end

local function implFor(module: any)
	local impl = implsOf(module).Observer
	if impl == nil then
		error("Quad0117 Observer: Observer.Init(module) has not run for this quad instance", 1) -- invariant; callers pull it in first
	end
	return impl
end

return {
	Init = Init,
	implFor = implFor,
}
