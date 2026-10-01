--!strict
--[[
	Effect — a leaf consumer with several dependencies (`State`/`Source`/`Ref`)
	and a cleanup contract. `Effect(fn, ...deps)`; `fn(self) -> ...cleanup`.
	`.claude/base/effect-plan.md`, transcribed as-is:
	  - "확정 구조": the strong owner is ALWAYS the Effect (`_deps` map);
	    registrations at the deps are weak (`ref:WeakCallback`, the dep's
	    weak-keyed `_subs`); the single fire gate is `canExecute`.
	  - "의사코드 — 생성자": deps validated once (`select("#")`, nil → error,
	    non State/Source/Ref → error, duplicates ignored — `H-70`); round13
	    3′ (user decision 2026-09-30): a State/Source dep's `_subs` holds the
	    Effect itself (`_receive` — no internal Observer), a Ref dep keeps
	    `onRefFire(_, ref)` (`H-107`); `_receive`: `_epochs:Update(from)` →
	    `Rerun` (`H-151`; the one other writer is the pre-fn `Sync` of direct
	    Epoch deps in `rawRerun`, Q109; no `_blocker`, `H-150`); `_epochs`
	    NOT seeded (see the constructor); install = `_rerunRequired = true` +
	    `rawRerun(self, true)`.
	  - `_bindDestroying(inst)` (guard `isRunning`; `_unbindDestroying` first;
	    injected `onDestroying(inst, fn)`; replay once if `_rerunRequired`),
	    `_unbindDestroying()` (idempotent), `_consumeCleanup()` (read → clear →
	    `_rerunRequired = true` → run under `_cleanupRunning`, `H-160`).
	    `bindLifetime`/`unbindLifetime` reach the first two through the
	    `BindableBrand` hooks `_afterBind(inst)`/`_beforeUnbind()` (2026-10-01).
	  - `rawRerun(self, force)` + public `Rerun()`: re-entrancy is deferred
	    (`_pending`), an unexecutable state HOLDS the request (`H-159`), the
	    loop has no death judgement (`H-147`); errors leave `_running` /
	    `_cleanupRunning` set — that Effect is dead, by contract.
	  - "`Effect:Subscribe()`": four entry points of its OWN (not
	    Observer's bodies, `H-144`), first line `isRunning` guard (`H-147`),
	    `resubscribeTail` replays a held change after registration,
	    `Unsubscribe` consumes the cleanup.

	Assembly (`H-174`): `Effect.Init(module)` — gates (`module.Backend.canExecute` /
	`module.Backend.canBound`) and the injected `module.Backend.onDestroying` are read at call
	time; the registries come from `Observer.luau` (`H-99`), pulled in with
	`module:RunInit(Observer.Init)` (idempotent).
]]

local Brand = require("./Brand")
local EpochMap = require("./EpochMap")
local Err = require("./ErrorNamespace")
local QuadTypes = require("../luau_packages/quad_types")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE
local ImplRegistry = require("./ImplRegistry")
local Observer = require("./Observer")
local Relate = require("./Relate")
local Void = require("./Void")
local InitDispatch = require("./Dispatch")
local ModuleIdentity = require("./ModuleIdentity")

local EffectBrand = Brand.EffectBrand
local BindableBrand = Brand.BindableBrand
local isState = Brand.isState
local isSource = Brand.isSource
local isRef = Brand.isRef
local isEpoch = Brand.isEpoch

-- One implementation per quad instance (`H-174`); storage scheme in `ImplRegistry.luau`.
local implsOf = ImplRegistry.implsOf

-- ── debug-only checks (`architecture.md` "debug 층"; kept out of the logic below) ──
-- 2026-10-01 (user decision): `rawRerun`'s deferred re-run loop has no cap by contract — an fn that
-- keeps setting one of its own deps never settles, and since a Source propagates even an equal value
-- (`H-68`) an unconditional `Set` is enough (install or not — the re-run is deferred, never nested).
-- With `q.debug` on, the loop counts and raises past this limit.
local DEBUG_RERUN_LIMIT = 10000
local function checkReruns(count: number)
	if count > DEBUG_RERUN_LIMIT then
		Err.errorBefore(
			`Quad0263 Effect: fn re-ran {DEBUG_RERUN_LIMIT} times in one loop - the fn keeps setting one of its own deps (a Source propagates even an equal value; set only when the value differs)`,
			SURFACE
		)
	end
end

local function createImpl(module: any)
	module:RunInit(Observer.Init) -- registries live there (`H-99`)
	local ObserverImpl = Observer.implFor(module)
	local Subscribed = ObserverImpl._Subscribed
	local WeakSubscribed = ObserverImpl._WeakSubscribed

	local Impl = {}
	Impl.__index = Impl
	-- `EffectMarker` (quad-types) — the type promises the marker, so the value carries it
	-- (`H-300`); read through `__index`, zero per-instance slots. Identity stays the brand —
	-- the field is the input-position type's evidence (user decision 2026-09-07: Tag/
	-- Attr/Observer/Effect go marker like State/Slot, typing-limits 8.11).
	Impl.__quadEffect = true
	Impl._moduleIdentity = module.moduleIdentity -- cross-instance guard token (`ModuleIdentity.luau`)
	-- `__tostring` (2026-09-08, advisory 권고 1)
	function Impl.__tostring(self: any): string
		return `Effect({ObserverImpl._subscriptionOf(self)})`
	end

	-- ── local helpers, declared before their callers ─────────────────
	local function isRunning(self: any): boolean -- predicate only; the raise stays in each body (nearest-SURFACE walker)
		return self._running == true or self._cleanupRunning == true
	end

	-- The body. `force` means exactly one thing: "may be called ignoring
	-- canExecute" — the install from the constructor, not yet bound.
	-- Observer.luau follows this same protocol (`_pending` / `_rerunRequired` / `force`) with its own
	-- body (round13 3′) — except that an executable Observer delivery nests instead of deferring.
	local function rawRerun(self: any, force: boolean)
		if self._running then
			self._pending = true -- re-entered while running → deferred re-run
			return
		end
		if self._cleanupRunning or self._dying or (not force and not module.Backend.canExecute(self)) then
			self._rerunRequired = true -- `H-159`/`H-160`/`H-182`: unexecutable (cleanup running / dying / unbound / dead)
			return --   → HOLD, replayed once on the next bind/subscribe
		end
		self._running = true
		local count = if module.debug then 0 else nil -- debug only: this loop's fn-run count
		repeat
			self:_consumeCleanup() -- sets `_rerunRequired = true`
			-- round11 code-review (2026-09-18, after Q63 (b)): the cleanup just run may have UNSUBSCRIBED
			-- this handle (the gate is gone) — then fn must not run on a dead handle. Hold instead
			-- (`_rerunRequired` is already up); the forced install never gets here with a cleanup.
			if not force and (self._dying or not module.Backend.canExecute(self)) then
				self._pending = false
				break
			end
			-- round10 Q51 (a) (user decision 2026-09-17): `_pending` goes down AFTER the cleanup,
			-- right before fn — a `Set` made inside the cleanup is consumed by the fn that follows
			-- (it reads the new value), so it must not queue one more (cleanup, fn) cycle with the
			-- same input. It used to be lowered before the cleanup ("cl fn cl fn" for one Set).
			-- Requests that arrive DURING fn still re-run (`_pending` = a request while running).
			self._pending = false
			self._rerunRequired = false -- the ONLY place the flag goes down: fn really runs
			if count then
				count += 1
				checkReruns(count)
			end
			-- round13 3′ (Q109, user decision 2026-09-30 — every run): fn is about to read every dep
			-- live; a direct Epoch dep's (Source/Ref) live revision is exactly what its next delivery
			-- would carry — mark it seen, so a same-wave delivery that reaches us after this run is not
			-- a new change. State deps are not touched: a Gate below them may be withholding (`H-151`).
			for d in self._deps do
				if isEpoch(d) then
					self._epochs:Sync(d)
				end
			end
			-- `H-185` (user, 2026-08-31): the cleanup is ONE function — wrap several
			-- teardowns in one closure (`function() a() b() end`); extra returns are
			-- deliberately not collected (a list would widen the re-entry surface).
			local cleanup = self.fn(self)
			if cleanup ~= nil and type(cleanup) ~= "function" then
				-- 2026-09-15 (user decision, public surface (18)): a non-function return (a number, a
				-- connection object out of React/Fusion habit) used to be stored and blow up later inside
				-- `_consumeCleanup` blaming this file, leaving the Effect silently dead. Raise HERE — the
				-- Effect dies exactly as when fn throws (`_running` stays), but at the cause with a clear
				-- message. Outermost blame: the user's `q.Effect` line at install, the `:Set` line at emit depth.
				Err.errorBefore(`Quad0086 Effect: fn must return a cleanup function or nothing (got {typeof(cleanup)})`, SURFACE)
			end
			self._cleanup = cleanup
			-- round11 Q63/Q68 (b) (user decision 2026-09-18): the handle may have lost its executability
			-- WHILE fn ran — it unsubscribed itself (Q63 (b) opened that door), or it yielded and the
			-- leaf died / the position was retracted meanwhile (Q68: `_dying` + `_consumeCleanup` ran on
			-- an empty slot before fn returned). A cleanup stored now would sit on a handle nothing will
			-- ever consume — so consume it at once (`dying` = whether the leaf's death is the cause) and
			-- hold. Not on the forced install: the constructor runs fn before any bind on purpose.
			-- Checked REGARDLESS of whether a cleanup came back (code-review): with `_pending` up
			-- (fn Set a dep, then unsubscribed itself) the loop would otherwise run fn again on the
			-- dead handle and die in its second Unsubscribe with `_running` stuck.
			if not force and (self._dying or not module.Backend.canExecute(self)) then
				self:_consumeCleanup() -- nil-safe; sets `_rerunRequired` — replayed if the handle is re-armed
				self._pending = false
				break
			end
		until not self._pending
		self._running = false
	end

	-- After registration: replay a held change once (`H-144`; `Refresh` gone, `H-151`).
	local function resubscribeTail(self: any)
		if self._rerunRequired then
			self:Rerun() -- registered now, so the public gate passes
		end
	end

	-- ── hooks called by `bindLifetime` / `unbindLifetime` ─────────────

	-- `H-184`: `bindLifetime` asks this BEFORE committing the binding, so a refusal
	-- cannot leave a half-bound handle (bound, `canExecute` true, no Destroying
	-- connection). Blame: OUTERMOST (4순회 `H-384`, same as Observer) — the in-tree
	-- chain `process` → `bindLifetime` (both tagged) → here made "nearest" stop
	-- at `bindLifetime` and blame `Effect.luau`.
	function Impl._assertBindable(self: any)
		if isRunning(self) then
			Err.errorBefore("Quad0087 Effect: cannot bind an Effect from inside its own fn or cleanup", SURFACE) -- `H-147` (A)
		end
	end

	-- ── lifetime hooks (`BindableBrand`, 2026-10-01 — `research/bindable-hooks-plan.md`) ──
	-- `bindLifetime`/`unbindLifetime` know no Effect: they call these on any `BindableBrand` member
	-- (`_assertBindable` above runs before the commit). Effect's own bodies — not Observer's
	-- (conventions: heterogeneous types share no body, `H-144`); thin, so the named bodies below
	-- keep their other callers (`WeakSubscribe`/`Subscribe` drop the connection through
	-- `_unbindDestroying` directly).
	function Impl._afterBind(self: any, inst: any)
		self:_bindDestroying(inst) -- Destroying hookup + held-change catch-up
	end

	function Impl._beforeUnbind(self: any)
		self:_unbindDestroying() -- the Destroying connection only — never the cleanup (lifecycle-pattern (1))
	end

	function Impl._bindDestroying(self: any, inst: any)
		-- `H-147`'s guard moved to `_assertBindable` (`H-184`) — `bindLifetime` (through `_afterBind`)
		-- is the only caller and has already asked it before committing the binding.
		self:_unbindDestroying() -- rebind (portal remount): drop the old connection first — idempotent
		self._dying = false -- `H-182`: rebinding a survivor of a Destroy wave re-arms it
		-- (1) leaf dies → cleanup exactly once. The one hook point (`LP-2`).
		local conn
		conn = module.Backend.onDestroying(inst, function() -- injected op, read at call time
			-- round11 `H-574` (탐사 H′ 1, Deferred 실측): Roblox's default SignalBehavior queues
			-- `Destroying` while Destroy cuts gcconn synchronously — a handle rebound to a NEW
			-- instance inside that same chunk got this OLD callback at the resume point, which
			-- disconnected the new binding, raised `_dying` and consumed the cleanup on a living
			-- host (fn never ran again; the new host's death ran no cleanup). `H-182`'s "either
			-- order is the same" argument assumed no rebind in the window. A callback that no
			-- longer owns the binding is stale — ignore it.
			if self._destroyConn ~= conn then
				return
			end
			-- `H-182`: `canExecute` stays true for the rest of the Destroy wave (gcconn
			-- is cut last) — the flag closes that window so a dep change later in the
			-- wave HOLDS instead of re-running fn on the dying leaf. NOT `_destroyed`
			-- (Slot's word): a Slot never rebinds, this handle may — the bind above re-arms.
			self._dying = true
			self:_unbindDestroying()
			self:_consumeCleanup()
		end)
		self._destroyConn = conn
		-- (2) catch-up: a change held while unexecutable is replayed once. gcconn is
		--     connected by now, so the public Rerun's gate passes.
		if self._rerunRequired then
			self:Rerun()
		end
	end

	function Impl._unbindDestroying(self: any)
		if self._destroyConn then
			self._destroyConn:Disconnect()
			self._destroyConn = nil
		end
		-- Ref callbacks and the `_subs` memberships stay (weakly registered; the gate
		-- silences them). `_cleanup` is NOT run here.
	end

	-- read → clear → run. `_cleanup`'s presence is not "installed" — the flag is.
	-- round10 Q57 (user proposal 2026-09-17): the cleanup receives `dying` — true only when the
	-- consumption is the leaf's death (`_bindDestroying`'s Destroying callback sets `_dying`
	-- one line before calling here); false at the other three sites (rerun before fn,
	-- `Unsubscribe`, the numeric-key value-swap retract). Pure addition — a `() -> ()`
	-- cleanup ignores it (arity subtyping, typing-limits 8.23). `OnDestroyed` keys on it.
	-- User: "_dying 이 true 로 새워지는건 오직 onDestroying 콜백 뿐이고, 내부적으로 있는 값을
	-- 외부에 노출해주는것일 뿐" — chosen over a public `Dying` field ("값이 설정되는 순간
	-- 순간에 진실성이고, 생명주기 계약 자체는 외부에서 접근하는데 있어 도움이 안 되는것").
	function Impl._consumeCleanup(self: any)
		local c: any = self._cleanup
		self._cleanup = nil
		self._rerunRequired = true -- consumed = must install again at the next chance
		if c ~= nil then
			-- save/restore, not true/false (`H-332` shape): a cleanup may call `Unsubscribe` (Q63 (b)),
			-- which re-enters here with an empty slot — it must not lower the flag for the outer cleanup's tail
			local outer = self._cleanupRunning
			self._cleanupRunning = true -- `H-160`: cleanup runs outside `_running` in two of its three sites
			(c :: (boolean) -> ())(self._dying == true)
			self._cleanupRunning = outer
		end
	end

	-- The EmitReceive every dep delivers to (State/Source through `_subs`, Ref through its callback —
	-- round13 3′). `Update` first, always — `H-151`: written here (and by the pre-fn `Sync`, Q109).
	-- Observer keeps the same record as one number (`_seenRevision`); the two must mean the same.
	function Impl._receive(self: any, from: any)
		if self._epochs:Update(from) then
			self:Rerun() -- unexecutable → rawRerun holds it (`H-159`)
		end
	end

	function Impl.Rerun(self: any): any -- public, no args — always gated
		rawRerun(self, false)
		return self
	end

	-- ── four entry points — Effect's OWN bodies (`H-144` (b)) ────
	function Impl.WeakSubscribe(self: any): any
		if isRunning(self) then
			Err.errorBeforeNearest("Quad0088 Effect: cannot change subscription from inside fn or cleanup, or after this Effect's fn or cleanup has thrown - a thrown Effect stays dead; create a new one", SURFACE) -- `H-147`
		end
		if not module.Backend.canBound(self) then
			Err.errorBeforeNearest(if self.Subscribed then "Quad0089 Effect: already subscribed" else "Quad0230 Effect: already bound to an Instance", SURFACE) -- error-code: inline if
		end
		self.Subscribed = true
		self._dying = false -- `H-182`: every path that re-arms executability lowers it
		-- round13 E20 (`H-707`): the host died (gcconn cut) but its Deferred `Destroying` callback may
		-- still be queued — drop that connection so the late callback sees `_destroyConn ~= conn`
		-- (the `H-574` staleness guard) instead of raising `_dying` on this revived handle.
		self:_unbindDestroying()
		WeakSubscribed[self] = true
		resubscribeTail(self)
		return self
	end

	function Impl.Subscribe(self: any): any
		if isRunning(self) then
			Err.errorBeforeNearest("Quad0090 Effect: cannot change subscription from inside fn or cleanup, or after this Effect's fn or cleanup has thrown - a thrown Effect stays dead; create a new one", SURFACE) -- `H-147`
		end
		if not module.Backend.canBound(self) then
			Err.errorBeforeNearest(if self.Subscribed then "Quad0091 Effect: already subscribed" else "Quad0231 Effect: already bound to an Instance", SURFACE) -- error-code: inline if
		end
		self.Subscribed = true
		self._dying = false -- `H-182`
		self:_unbindDestroying() -- `H-707`, same as WeakSubscribe
		WeakSubscribed[self] = true
		Subscribed[self] = true -- the strong keep is up BEFORE the tail runs
		resubscribeTail(self)
		return self
	end

	-- round11 Q63 (b) (user decision 2026-09-18): the two UNsubscribe entries are NOT gated on
	-- `isRunning`. An fn that threw leaves `_running` up forever (dead by contract, no pcall), and
	-- with the gate the handle could never be released — the strong `Subscribed` keep held it and
	-- its upstream for the module's lifetime. Releasing is the safe direction: it never calls fn
	-- (a dead handle's `_cleanup` is already nil — rawRerun consumed it before fn ran), so the
	-- `H-147` reentrancy the gate guards (subscribing yourself from inside fn) stays closed.
	-- Side effect: fn may now unsubscribe itself; a cleanup it then returns is consumed at once
	-- by rawRerun's tail (Q68 (b) — the handle is no longer executable).
	function Impl.WeakUnsubscribe(self: any): any -- lenient (`H-133`) — does not touch the cleanup
		if Subscribed[self] ~= nil then
			Err.errorBeforeNearest("Quad0092 Effect: subscribed strongly; use :Unsubscribe()", SURFACE)
		end
		WeakSubscribed[self] = nil
		self.Subscribed = false
		return self
	end

	function Impl.Unsubscribe(self: any): any -- no `isRunning` gate — see WeakUnsubscribe (Q63 (b))
		if Subscribed[self] == nil then -- gate FIRST: never strongly subscribed → error, cleanup untouched
			Err.errorBeforeNearest("Quad0093 Effect: only a strongly subscribed Effect can be released with :Unsubscribe() - a weakly subscribed one must be released with :WeakUnsubscribe(), and one held only by a seat must be released by clearing that seat", SURFACE)
		end
		Subscribed[self] = nil
		WeakSubscribed[self] = nil
		self.Subscribed = false -- blocks future re-runs
		self:_consumeCleanup() -- only when the gate passed: the last cleanup exactly once
		return self
	end

	-- ── constructor ──────────────────────────────────────────────────
	local function Effect(fn: any, ...: any): any
		if type(fn) ~= "function" then
			Err.errorBeforeNearest(`Quad0094 Effect: fn must be a function (got {typeof(fn)})`, SURFACE)
		end
		local self = setmetatable({
			fn = fn,
			_deps = {}, -- strong owner of every registration
			_epochs = EpochMap(),
			_cleanup = nil,
			_rerunRequired = false,
			_running = false,
			_pending = false,
			_cleanupRunning = false,
			_dying = false, -- `H-182`: inside a Destroy wave, after our Destroying ran
			_destroyConn = nil,
			Subscribed = false,
		}, Impl)
		EffectBrand:Register(self)
		BindableBrand:Register(self) -- lifetime hooks + `Subscribed` (`LifetimeHandle.luau`)

		-- (0) deps validation — once, in the constructor. `select("#")` so a nil hole
		--     does not silently truncate the list.
		-- `H-186` (user-confirmed 2026-08-31): a dep from ANOTHER quad instance is UB —
		--   not checked here. (The old "a guard here closes only half the hole" reasoning was
		--   withdrawn on 2026-09-15 — architecture "교차 인스턴스": the guard belongs at the
		--   seat/StoreBind entry, where `q.moduleIdentity` is compared; a dependency edge across
		--   instances simply fires.)
		local seen = {}
		for i = 1, select("#", ...) do
			local d = (select(i, ...))
			if d == nil then
				Err.errorBeforeNearest(`Quad0095 Effect: dep #{i} is nil`, SURFACE)
			end
			if not (isState(d) or isSource(d) or isRef(d)) then
				Err.errorBeforeNearest(`Quad0096 Effect: dep #{i} is not a State/Source/Ref`, SURFACE)
			end
			seen[d] = true -- duplicates are silently ignored (dedup lives in `_deps`/`_epochs`)
		end

		-- (1) register deps — HERE, ONCE. round13 3′: a State/Source dep's `_subs` holds the
		-- Effect ITSELF (an `EmitReceive`, `Impl._receive` below) — no internal Observer; a Ref dep
		-- keeps its callback (`H-107`: the Ref's 2nd arg is the source).
		local function onRefFire(_value: any, ref: any)
			self:_receive(ref)
		end
		for d in seen do
			if isRef(d) then
				self._deps[d] = onRefFire -- strong owner = Effect
				d:WeakCallback(onRefFire) -- the Ref side is weak
			else
				(self._deps :: any)[d] = true -- strong owner = Effect
				d._subs[self] = true -- the dep side is weak (`_subs` is weak-keyed)
			end
			-- round13 3′: no seeding. It fed the old `_epochs:Refresh()` catch-up (gone since
			-- `H-151`); what it still did was mark a Gate dep's WITHHELD revision as seen (a State
			-- dep handed over its VALUE map), so an Effect created while the gate withheld swallowed
			-- the later flush — against the gate contract. A direct Epoch dep is marked by the pre-fn
			-- `Sync` in `rawRerun` (the install included); a Ref's registration call `Update`s it.
		end

		-- (2) install — once, immediately; cannot be deferred to bind.
		self._rerunRequired = true
		rawRerun(self, true)
		return self
	end

	module.Effect = Effect
	-- `H-231`: public surface joins the shared error-namespace tag layer
	Err.setFuncLevel(SURFACE, Impl.Rerun, Impl.WeakSubscribe, Impl.Subscribe, Impl.WeakUnsubscribe, Impl.Unsubscribe, Effect)

	return Impl
end

-- Dispatch-side registrations for the Effect VALUE (`H-278` — mirror of
-- Observer.luau's `registerDispatchHandlers`, see the rationale there; the
-- only body difference is the `H-57` cleanup consumption on swap/teardown).
local function registerDispatchHandlers(module: any)
	module:RunInit(InitDispatch)
	local dispatch: QuadTypes.Dispatch = module.Dispatch
	local relate = Relate() -- (inst, k) -> last bound handle; weak value (`H-71`)

	dispatch.addHandler({
		name = "EffectLeafHandler",
		keyType = "number", -- `H-484`: only number keys can match (isHandlable checks it too)
		isHandlable = function(_inst: any, k: any, v: any): boolean
			return type(k) == "number" and Brand.isEffect(v)
		end,
		priority = dispatch.HANDLER_PRIORITY_HIGH,
		process = function(inst: any, k: any, v: any, _index: number): (any?, boolean) -> ()
			module.Bookkeeping.setEmpty(inst, k) -- `H-39` (한 본문 — Bookkeeping `setEmpty`)

			ModuleIdentity.assertOwnAtDispatch(module, v, "Effect")
			local old = relate:GetWeak(inst, k) -- `H-71`; load-bearing dedup (`H-266`)
			if old ~= v then
				module.Backend.bindLifetime(inst, v)
			end
			relate:SetWeak(inst, k, v)
			return function(nextValue: any?, _retracting: boolean)
				if nextValue ~= v then
					module.Backend.unbindLifetime(v)
					-- `H-57`: the value leaving its seat consumes its cleanup (`dying` = false —
					-- the inst is alive). The old premise "destruction-equivalent, it never comes
					-- back" was wrong (round10 Q57): re-seating it re-installs fn through
					-- `_rerunRequired` and it lives on — that is why `dying` exists.
					v:_consumeCleanup()
					if relate:GetWeak(inst, k) == v then
						relate:SetWeak(inst, k, nil)
					end
				end
			end
		end,
	})
	dispatch.addHandler({
		name = "EffectDynamicPathGuard",
		isHandlable = function(_inst: any, _k: any, v: any): boolean
			return Brand.isEffect(v)
		end,
		priority = dispatch.HANDLER_PRIORITY_FALLBACK,
		process = function(_inst: any, k: any, _v: any, _index: number): (any?, boolean) -> ()
			Err.errorBefore(`Quad0097 Effect: must be an array item, not the value of a {typeof(k)} key`, SURFACE)
			return Void -- unreachable; keeps the contract type
		end,
	})
end

local function Init(module: any)
	implsOf(module).Effect = createImpl(module)
	registerDispatchHandlers(module)
end

local function implFor(module: any)
	local impl = implsOf(module).Effect
	if impl == nil then
		error("Quad0098 Effect: Effect.Init(module) has not run for this quad instance", 1)
	end
	return impl
end

return {
	Init = Init,
	implFor = implFor,
}
