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
	    else hold `_rerunRequired = true`, `H-159` — the install window too),
	    `Observer:_catchUp()` (the ONLY place a held change is replayed — with
	    `from = nil`), `State:Observer(fn)` constructor ORDER (join `_subs` →
	    one install run — round13 3′ reversed the old "fn once → join" order,
	    Q73; 2026-10-01 dropped the install re-run loop), `observer._state`
	    strong ref (`_hold` equivalent, `H-110`); "`state:Observer(fn)`" section: fires once on
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
	compared only for a Source (a derived target is outside it — see `run`).
	`Effect` does NOT reuse these bodies (heterogeneous types; `conventions.md`
	설계 원칙) — the two follow one protocol with their own bodies.
]]

local Brand = require("./Brand")
local DebugKeyFilter = require("./DebugKeyFilter")
local ImplRegistry = require("./ImplRegistry")
local Err = require("./ErrorNamespace")
local Relate = require("./Relate")
local Void = require("./Void")
local InitDispatch = require("./Dispatch")
local ModuleIdentity = require("./ModuleIdentity")
local QuadTypes = require("../luau_packages/quad_types")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

local ObserverBrand = Brand.ObserverBrand
local BindableBrand = Brand.BindableBrand

local WEAK_KEY_MT = { __mode = "k" }

-- ── debug-only checks (`architecture.md` "debug 층"; kept out of the logic below) ──
-- 2026-10-01 (user decision): an Observer is a final consumer — setting OTHER targets is normal, but
-- feeding its own upstream (the State it watches, or anything upstream of it) directly or indirectly is
-- undefined (`source-state-plan.md` "Compute 순수성" 2026-10-01 paragraph); only an Effect's own-dep Set
-- is defined (its deferred re-run untangles the wave). The visible symptom: a delivery this handle can
-- run arrives while its own fn is still running — the run would nest. With `q.debug` on, that prints
-- one line per Observer (weak) and the run goes on unchanged. `_running` alone is not the signal: an fn
-- that THREW leaves it up for good (no pcall — architecture "예외 안전성 계약"), so the probe also asks
-- whether `fn` really has a frame on the call stack (the stack unwinds by itself). Handles quad creates
-- for its own bookkeeping (Slot position math, `:List`'s data Observer, the per-position length
-- Observers) are born with `_internal = true` through `State:_internalObserver` — set BEFORE the install
-- run, so the install window is skipped too — and are not user code. [2026-10-06 user decision, round14
-- Q174] StateHandler's Observer (a State placed in props) is NOT internal: its fn is quad's dispatch of the
-- State's value, but under it run Ref/Tween callbacks, hooks and the engine's synchronous signals — a
-- write back to that State from there is the same feedback, so the message names that case too.
-- A nested delivery that came THROUGH the Slot bookkeeping is skipped too (user decision 2026-10-01:
-- a callback watching a Slot's `Offset`/`Length` that CRUDs a Slot so the value moves again is not State
-- feedback — the loop goes through the position math, which re-runs until it settles; the user cannot see
-- it as feedback without knowing Slot internals). Walking out from the innermost frame, meeting the
-- bookkeeping's `recompute` or `setOffsetSource` (the mount/re-seat write — round14 `H-886`: an Extract +
-- Add of the watched Slot reaches the Offset Source there, not through `recompute`) before this handle's
-- `fn` means the change was routed by the bookkeeping.
local function fedBackDirectly(fn: any, recompute: any, setOffsetSource: any): boolean
	local level = 1
	while true do
		local f = debug.info(level, "f")
		if f == nil or f == recompute or f == setOffsetSource then
			return false
		end
		if f == fn then
			return true
		end
		level += 1
	end
end

-- Asked on BOTH delivery branches (round14 — user decision 2026-10-06, debug detector 1): the run branch
-- (the delivery would nest) and the held branch (the handle cannot execute yet — the install window: an
-- install fn that writes its own upstream once and stops was 0 lines before).
local function checkUpstreamFeedback(observer: any, warned: { [any]: true }, bookkeeping: any)
	if observer._running and not observer._internal and warned[observer] == nil
		and fedBackDirectly(observer.fn, bookkeeping._recompute, bookkeeping.setOffsetSource) then
		warned[observer] = true
		print("Observer: a change reached this Observer while its own fn was running - the fn (for a State placed in props: quad's dispatch of its value, with the callbacks and engine signals it set off) fed its own upstream, directly or through other handles (undefined; set other targets, or use an Effect for a self-correcting write)")
	end
end

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
	-- 2026-10-01 (user decision — the round13 3′ install re-run loop is gone): a delivery runs fn in place
	-- when the handle can execute, and is HELD otherwise (`_rerunRequired`, `H-159` — replayed once on the
	-- next bind/subscribe). The install window is such a state (a new handle is neither bound nor
	-- subscribed): a change arriving while the install fn runs is held, not re-run there (user: "설치 발화
	-- 중에 변경을 계속 받을 필요 없고 … pending 으로 끝날 수 있음"). Only the fn itself (or what it sets off)
	-- can cause such a change — feeding its own upstream, undefined for an Observer.
	--
	-- `_seenRevision` (Q109, user decision 2026-09-30): the Source revision this handle last ran on —
	-- the SAME record Effect keeps per dep in its `_epochs` map (`Sync` before fn, `Update` on delivery),
	-- specialised to one number because an Observer watches exactly one node. Stamped at every fn start
	-- (`rawget` — nil for a derived State). A derived target is outside this record: a handle revived
	-- mid-wave (Q109 shape) or a nested wave (C6 shape) can run twice with the same value — its emit map
	-- filters at the node's entry, not the outer snapshot walk (2026-09-30 mock measurement; Effect's map
	-- keys the source and so filters the nested case, both double on revive).
	local function run(self: any, from: any)
		-- `H-183`: fn may not change its own lifecycle (`H-147` symmetric). An fn that throws leaves the
		-- flag set — NOT "dead": `_receive` does not read it, so the Observer keeps firing (self-healing,
		-- `H-445`/`H-545`); what the stuck flag blocks is (re)subscribing and (re)binding
		-- (`_assertBindable`) — round11 Q63 corrected the old "dead by contract" wording.
		-- Save/restore, not true/false (`H-332`): only a NESTED run (the fn fed its own upstream —
		-- undefined) can tell the two apart; kept because it costs nothing, it does not defend that UB
		-- input and is no contract.
		local outer = self._running
		self._running = true
		self._seenRevision = rawget(self._state, "Revision") -- nil for a derived State
		self.fn(self._state, self, from)
		self._running = outer
	end

	local debugWarned: { [any]: true } = setmetatable({}, WEAK_KEY_MT) :: any
	function Impl._receive(self: any, from: any)
		-- Q109: a direct Source delivery whose revision this handle already ran on (a catch-up or a nested
		-- run in the same wave read it) is not a new change — skip (Effect: `_epochs:Update` false). Only
		-- `from == _state` (a Source) — see the derived-target limit at `run`; a gate batch (an
		-- EpochSet) is never skipped.
		if from == self._state and self._seenRevision == from.Revision then -- only a Source emits itself as `from`
			return
		end
		if module.Backend.canExecute(self) then -- read at fire time (`H-174`)
			if module.debug then
				checkUpstreamFeedback(self, debugWarned, module.Bookkeeping)
			end
			run(self, from)
		else
			if module.debug then
				checkUpstreamFeedback(self, debugWarned, module.Bookkeeping)
			end
			self._rerunRequired = true -- `H-159`: change before binding (or in the install window) is held — replayed once when bound
		end
	end

	-- Catch-up: bind/subscribe replays a held change once, with no source.
	-- The only caller set: `bindLifetime` (through `_afterBind`), `Subscribe`, `WeakSubscribe`.
	function Impl._catchUp(self: any)
		if self._rerunRequired then
			self._rerunRequired = false
			run(self, nil)
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

	-- ── lifetime hooks (`BindableBrand`, 2026-10-01 — `research/bindable-hooks-plan.md`) ──
	-- `bindLifetime` knows no Observer: it calls `_assertBindable` (above, before the commit) and this
	-- one (after the commit) on any `BindableBrand` member. Observer's own body — Effect has its own
	-- (conventions: heterogeneous types share no body, `H-144`). No `_beforeUnbind`: unbinding an
	-- Observer has nothing of its own to tear down, so `unbindLifetime` skips it.
	function Impl._afterBind(self: any, _inst: any)
		self:_catchUp() -- `H-159`: one catch-up for emits held before binding
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

	-- `internal` (private — only `State:_internalObserver`): quad's own bookkeeping handle, marked before
	-- the install run so the upstream-feedback debug check skips its install window too (round14).
	function Impl.new(state: any, fn: any, internal: true?): any
		local o: any = setmetatable({
			fn = fn or alwaysObserve,
			_internal = internal, -- nil for every user handle (no slot)
			_state = state, -- strong: the handle holds its upstream (`_hold` equivalent, `H-110`)
			_rerunRequired = false, -- one meaning: "a change arrived while unexecutable" (held; 3′ — was seeded `true`)
			_seenRevision = false, -- the Source revision at this handle's last fn start (Q109 — Effect's `_epochs` entry)
			_running = false, -- `H-183`: raised around every fn run; the subscribe entries + `_assertBindable` refuse while up (Q63 (b): releasing passes)
			Subscribed = false, -- the shared flag both handle types carry (`H-111`)
		}, Impl)
		ObserverBrand:Register(o)
		BindableBrand:Register(o) -- lifetime hooks + `Subscribed` (`LifetimeHandle.luau`)
		-- round13 3′ (Q73 (a), user decision 2026-09-30): join FIRST, then the install run — an emit inside
		-- the install window (fn's own Set, or anyone else's) lands in `_receive` and is held
		-- (`_rerunRequired`) for the first bind/subscribe; the old order (fire → join) lost it (user: "첫
		-- 발화든 어느 발화든 자기 state 가 set 된다면 다시 실행되어도 됨"). 2026-10-01: no re-run inside the
		-- install itself (user: "설치 중 즉시 도는거 아님"). An install fn that throws leaves the handle in
		-- `_subs` (weak-keyed — it goes with the handle) with `_running` up, so (re)subscribe/bind are
		-- refused and later deliveries are only held: it never runs.
		state._subs[o] = true
		run(o, nil)
		return o
	end

	-- `H-231`: public surface joins the shared error-namespace tag layer
	Err.setFuncLevel(SURFACE, Impl.WeakSubscribe, Impl.WeakUnsubscribe, Impl.Subscribe, Impl.Unsubscribe)

	return Impl
end

-- Dispatch-side registrations for the Observer VALUE (`H-278`, user-directed:
-- "각 객체를 아는 곳은 각 객체가 선언된 곳" — moved out of the dissolved
-- Dispatch/Leaf.luau; [2026-10-01] NoneHandler/StateHandler followed — None.luau/State.luau register
-- them, Dispatch keeps only NilHandler and the Processed* terminals). Two handlers:
--   - ObserverLeafHandler (HIGH — dispatch skeleton band): children-array
--     leaf binding. Body 1:1 with `source-state-plan.md` "Observer/Effect
--     Leaf dedup" (H-39 registration, `old ~= v` dedup via a weak Relate
--     (`H-71`, load-bearing per `H-266`)). The combined handler split into
--     one per owning module — the two value spaces are disjoint, so the
--     per-module dedup relate is equivalent.
--   - ObserverStringKeyDebugFilter (`debugOnly`, NORMAL + 2 — `DebugKeyFilter.luau`): with `q.debug`
--     on, warns when an Observer sits at a string key naming a property (the Property handler takes
--     it before the FALLBACK guard below can); answers false, so dispatch is unchanged.
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
	DebugKeyFilter.register(dispatch, "ObserverStringKeyDebugFilter", function(v: any): string?
		return if Brand.isObserver(v) then "Observer" else nil
	end)
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
