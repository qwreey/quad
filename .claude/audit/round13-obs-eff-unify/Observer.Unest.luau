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
	    else hold `_rerunRequired = true`, `H-159`), `Observer:_catchUp()`
	    (the ONLY place a held change is replayed — with `from = nil`),
	    `State:Observer(fn)` constructor ORDER (fn once → flag down → join
	    `_subs`; `H-159`/`H-164`), `observer._state` strong ref (`_hold`
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

	PROTOTYPE obs-eff-unify U′ (2026-09-30): the Observer follows Effect's rerun
	PROTOCOL — the same field vocabulary with the same meanings, its OWN bodies:
	  `_epochs`        what fn has seen (EpochMap; written by `Update` on delivery and
	                   `Sync` of a direct Epoch dep right before fn — see `rawRerun`)
	  `_rerunRequired` a change arrived while not executable — held, replayed on bind/subscribe
	  `_pending`       a change arrived while fn was running UNEXECUTABLY (install window,
	                   released inside fn) — the loop runs fn again or holds (U′: an executable
	                   change during a run still nests — see `rawRerun`)
	  `_running`       fn is on the stack (H-183 gate; a throw leaves it up — not dead, U′)
	  `force`          the install run — may run while unexecutable (and keeps looping)
	An Observer is still NOT an `Epoch` (it has no Revision of its own) — it only
	RECORDS the epochs delivered to it (user 2026-08-26: "observer 에는 epoch 란게
	존재하지 않음. emit 으로 온 epoch 를 넘겨줄 뿐" — identity, not bookkeeping).
	`Effect` does NOT reuse these bodies (heterogeneous types; `conventions.md` 설계 원칙) —
	what the two share is data (EpochMap, the registries) and this written protocol.
]]

local Brand = require("./Brand")
local EpochMap = require("./EpochMap")
local ImplRegistry = require("./ImplRegistry")
local Err = require("./ErrorNamespace")
local Relate = require("./Relate")
local Void = require("./Void")
local InitDispatch = require("./Dispatch")
local ModuleIdentity = require("./ModuleIdentity")
local QuadTypes = require("../luau_packages/quad_types")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

local ObserverBrand = Brand.ObserverBrand
local isEpoch = Brand.isEpoch

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

	-- ── the rerun body (Observer's own — Effect has its own `rawRerun`) ──
	-- PROTOTYPE U. `force` means exactly one thing, as in Effect: "may run ignoring canExecute" —
	-- the install from the constructor. `from` is the delivery's source for the FIRST run only;
	-- a re-run for a change that arrived while fn ran passes `nil` ("read the value", `H-164` —
	-- the source is not stored: several changes may have arrived).
	local function rawRerun(self: any, force: boolean, from: any)
		-- PROTOTYPE U′ (Unest): Effect's protocol with ONE deliberate difference — an EXECUTABLE
		-- change that arrives while fn runs runs fn again right there (nested, as HEAD), instead of
		-- `_pending`. Reason: without pcall a deferred re-run cannot tell "fn is on the stack" from
		-- "fn threw earlier", so deferral makes a thrown Observer dead; nesting keeps HEAD's
		-- self-heal (the next change still runs fn — spec.observer 9, H-445, H-569, H-571 …).
		-- `_pending` therefore only carries changes that arrive while fn runs UNEXECUTABLY: the
		-- install window (Q73) and an fn that has just released itself (Q63 (b)).
		-- (`force` first: the install never asks the gate — a bare quad has no backend yet)
		if not force and not module.Backend.canExecute(self) then -- read at fire time (`H-174`)
			if self._running then
				self._pending = true -- install window / released inside fn: the loop decides (run or hold)
			else
				self._rerunRequired = true -- `H-159`: unexecutable → HOLD, replayed once on bind/subscribe
			end
			return
		end
		-- `H-183`: fn may not change its own lifecycle. Save/restore, not true/false (`H-332`): a
		-- nested run must not lower the guard for the outer fn's tail. A throw leaves the flag up —
		-- NOT dead: the next executable change still runs fn (round11 Q63 wording).
		local outer = self._running
		self._running = true
		local state = self._state
		repeat
			self._pending = false
			self._rerunRequired = false -- the only place the hold goes down: fn really runs
			-- fn reads its State live; a direct Source's live revision is exactly what its next
			-- delivery would carry — mark it seen, so a same-wave delivery that reaches us after this
			-- run (a nested wave already ran us; catch-up mid-wave, Q109) is not a new change.
			-- A derived State is not touched: a Gate below it may be withholding (`H-151`).
			if isEpoch(state) then
				self._epochs:Sync(state)
			end
			self.fn(state, self, from)
			from = nil
			if not force and not module.Backend.canExecute(self) then
				-- lost executability inside fn (it released itself — Q63 (b)): a change that
				-- arrived meanwhile is held, not run on the released handle
				if self._pending then
					self._pending = false
					self._rerunRequired = true
				end
				break
			end
		until not self._pending
		self._running = outer
	end

	-- ── EmitReceive ──────────────────────────────────────────────────
	-- `Update` first, always (bound or not — Effect's `fire`): a revision already seen is
	-- not a change (a stale outer-wave delivery after a nested wave, a diamond).
	function Impl._receive(self: any, from: any)
		if self._epochs:Update(from) then
			rawRerun(self, false, from)
		end
	end

	-- Catch-up: bind/subscribe replays a held change once, with no source.
	-- The only caller set: `bindLifetime`, `Subscribe`, `WeakSubscribe`.
	function Impl._catchUp(self: any)
		if self._rerunRequired then
			rawRerun(self, false, nil)
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
			_epochs = EpochMap(), -- PROTOTYPE U: what fn has seen (Effect's field, same meaning)
			_rerunRequired = false,
			_pending = false, -- PROTOTYPE U: a change arrived while fn ran (Effect's field, same meaning)
			_running = false, -- `H-183`: raised around every fn run; the subscribe entries + `_assertBindable` refuse while up (Q63 (b): releasing passes)
			Subscribed = false, -- the shared flag both handle types carry (`H-111`)
		}, Impl)
		ObserverBrand:Register(o)
		-- PROTOTYPE U — Effect's constructor order: seed, register, install.
		state:_track(o._epochs) -- seed (Source: `Sync`; State: `TrackFrom` its value map — Effect's rule)
		state._subs[o] = true -- join BEFORE the install run (Q73): a change inside the install window —
		o._rerunRequired = true --   fn's own Set or anyone else's — reaches `_receive` → `_pending` → fn again
		rawRerun(o, true, nil) -- install: fire once at registration — no source (`nil`)
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
