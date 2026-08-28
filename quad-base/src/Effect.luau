--[[
	Effect — a leaf consumer with several dependencies (`State`/`Source`/`Ref`)
	and a cleanup contract. `Effect(fn, ...deps)`; `fn(self) -> ...cleanup`.
	`.claude/base/effect-plan.md`, transcribed as-is:
	  - "확정 구조": the strong owner is ALWAYS the Effect (`_deps` map);
	    registrations at the deps are weak (`ref:WeakCallback`, internal
	    `observer:WeakSubscribe()`); the single fire gate is `canExecute`.
	  - "의사코드 — 생성자": deps validated once (`select("#")`, nil → error,
	    non State/Source/Ref → error, duplicates ignored — `H-70`); one
	    closure PER DEP KIND (`onRefFire(_, ref)` / `onStateFire(_, _, from)`,
	    `H-107`); `fire`: `from == nil` (the internal Observer's install fire)
	    is dropped, else `_epochs:Update(from)` → `Rerun` (`H-151`: the only
	    place `_epochs` is written; no `_blocker`, `H-150`); `_epochs` seeded
	    `Sync`/`TrackFrom` by `isEpoch`; install = `_rerunRequired = true` +
	    `rawRerun(self, true)`.
	  - `_bindDestroying(inst)` (guard `isRunning`; `_unbindDestroying` first;
	    injected `onDestroying(inst, fn)`; replay once if `_rerunRequired`),
	    `_unbindDestroying()` (idempotent), `_consumeCleanup()` (read → clear →
	    `_rerunRequired = true` → run under `_cleanupRunning`, `H-160`).
	  - `rawRerun(self, force)` + public `Rerun()`: re-entrancy is deferred
	    (`_pending`), an unexecutable state HOLDS the request (`H-159`), the
	    loop has no death judgement (`H-147`); errors leave `_running` /
	    `_cleanupRunning` set — that Effect is dead, by contract.
	  - "`EffectHandle:Subscribe()`": four entry points of its OWN (not
	    Observer's bodies, `H-144`), first line `isRunning` guard (`H-147`),
	    `resubscribeTail` replays a held change after registration,
	    `Unsubscribe` consumes the cleanup.

	Assembly (`H-174`): `Effect.Init(module)` — gates (`module.canExecute` /
	`module.canBound`) and the injected `module.onDestroying` are read at call
	time; the registries come from `Observer.luau` (`H-99`), pulled in with
	`module:RunInit(Observer.Init)` (idempotent).
]]

local Brand = require("./Brand")
local EpochMap = require("./EpochMap")
local Observer = require("./Observer")

local EffectBrand = Brand.EffectBrand
local isState = Brand.isState
local isSource = Brand.isSource
local isRef = Brand.isRef
local isEpoch = Brand.isEpoch

-- Per-instance impls live ON the module instance (`module._impl`, private — the
-- `H-174` (a) form: "RunInit 뒤의 비공개 필드로 형제 Init에 넘김"). A weak-key map
-- keyed by `module` would never collect: the impl's closures capture `module`, and
-- Luau has no ephemerons (`relate-plan.md`), so every `Quad.New()` would be pinned.
local function implsOf(module: any): { [string]: any }
	local impls = rawget(module, "_impl")
	if impls == nil then
		impls = {}
		rawset(module, "_impl", impls)
	end
	return impls
end

local function createImpl(module: any)
	module:RunInit(Observer.Init) -- registries live there (`H-99`)
	local ObserverImpl = Observer.implFor(module)
	local Subscribed = ObserverImpl._Subscribed
	local WeakSubscribed = ObserverImpl._WeakSubscribed

	local Impl = {}
	Impl.__index = Impl

	-- ── local helpers, declared before their callers ─────────────────
	local function isRunning(self: any): boolean -- predicate only; `error` stays in each body (level 2)
		return self._running == true or self._cleanupRunning == true
	end

	-- The body. `force` means exactly one thing: "may be called ignoring
	-- canExecute" — the install from the constructor, not yet bound.
	local function rawRerun(self: any, force: boolean)
		if self._running then
			self._pending = true -- re-entered while running → deferred re-run
			return
		end
		if self._cleanupRunning or (not force and not module.canExecute(self)) then
			self._rerunRequired = true -- `H-159`/`H-160`: unexecutable (cleanup running / unbound / dead)
			return --   → HOLD, replayed once on the next bind/subscribe
		end
		self._running = true
		repeat
			self._pending = false
			self:_consumeCleanup() -- sets `_rerunRequired = true`
			self._rerunRequired = false -- the ONLY place the flag goes down: fn really runs
			-- TODO(H-185): `EffectFn` is typed `-> ...(() -> ())` (H-95 pack) but only the first
			--   return is kept; extra cleanups are silently dropped.
			self._cleanup = self.fn(self)
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
	function Impl._bindDestroying(self: any, inst: any)
		if isRunning(self) then
			error("Effect: cannot bind an Effect from inside its own fn or cleanup", 2) -- `H-147` (A)
		end
		self:_unbindDestroying() -- rebind (portal remount): drop the old connection first — idempotent
		-- (1) leaf dies → cleanup exactly once. The one hook point (`LP-2`).
		-- TODO(H-182): after this callback, `canExecute` stays true for the rest of the Destroy
		--   wave (gcconn is cut last), so a dep change later in the wave re-runs fn on the
		--   dying leaf and stores a cleanup nothing consumes.
		self._destroyConn = module.onDestroying(inst, function() -- injected op, read at call time
			self:_unbindDestroying()
			self:_consumeCleanup()
		end)
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
		-- Ref callbacks and the internal Observers stay (weakly registered; the gate
		-- silences them). `_cleanup` is NOT run here.
	end

	-- read → clear → run. `_cleanup`'s presence is not "installed" — the flag is.
	function Impl._consumeCleanup(self: any)
		local c: any = self._cleanup
		self._cleanup = nil
		self._rerunRequired = true -- consumed = must install again at the next chance
		if c ~= nil then
			self._cleanupRunning = true -- `H-160`: cleanup runs outside `_running` in two of its three sites
			(c :: () -> ())()
			self._cleanupRunning = false
		end
	end

	function Impl.Rerun(self: any): any -- public, no args — always gated
		rawRerun(self, false)
		return self
	end

	-- ── four entry points — EffectHandle's OWN bodies (`H-144` (b)) ────
	function Impl.WeakSubscribe(self: any): any
		if isRunning(self) then
			error("Effect: cannot change subscription from inside fn or cleanup", 2) -- `H-147`
		end
		if not module.canBound(self) then
			error(if self.Subscribed then "Effect: already subscribed" else "Effect: already bound to an Instance", 2)
		end
		self.Subscribed = true
		WeakSubscribed[self] = true
		resubscribeTail(self)
		return self
	end

	function Impl.Subscribe(self: any): any
		if isRunning(self) then
			error("Effect: cannot change subscription from inside fn or cleanup", 2) -- `H-147`
		end
		if not module.canBound(self) then
			error(if self.Subscribed then "Effect: already subscribed" else "Effect: already bound to an Instance", 2)
		end
		self.Subscribed = true
		WeakSubscribed[self] = true
		Subscribed[self] = true -- the strong keep is up BEFORE the tail runs
		resubscribeTail(self)
		return self
	end

	function Impl.WeakUnsubscribe(self: any): any -- lenient (`H-133`) — does not touch the cleanup
		if isRunning(self) then
			error("Effect: cannot change subscription from inside fn or cleanup", 2) -- `H-147`
		end
		if Subscribed[self] ~= nil then
			error("Effect: subscribed strongly; use :Unsubscribe()", 2)
		end
		WeakSubscribed[self] = nil
		self.Subscribed = false
		return self
	end

	function Impl.Unsubscribe(self: any): any
		if isRunning(self) then
			error("Effect: cannot change subscription from inside fn or cleanup", 2) -- `H-147`
		end
		if Subscribed[self] == nil then -- gate FIRST: never strongly subscribed → error, cleanup untouched
			error("Effect: not subscribed strongly; use :WeakUnsubscribe()", 2)
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
			error("Effect: fn must be a function", 2)
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
			_destroyConn = nil,
			Subscribed = false,
		}, Impl)
		EffectBrand:register(self)

		-- (0) deps validation — once, in the constructor. `select("#")` so a nil hole
		--     does not silently truncate the list.
		-- TODO(H-186): no check that a dep belongs to THIS quad instance — a cross-instance dep
		--   is gated by the dep's backend (`d:Observer` resolves through its own impl).
		local seen = {}
		for i = 1, select("#", ...) do
			local d = (select(i, ...))
			if d == nil then
				error(`Effect: dep #{i} is nil`, 2)
			end
			if not (isState(d) or isSource(d) or isRef(d)) then
				error(`Effect: dep #{i} is not a State/Source/Ref`, 2)
			end
			seen[d] = true -- duplicates are silently ignored (dedup lives in `_deps`/`_epochs`)
		end

		-- (1) register deps — HERE, ONCE. One closure per dep kind (`H-107`).
		local function fire(from: any)
			if from == nil then
				return -- the internal Observer's install fire (no source) cannot `Update(nil)`
			end
			if self._epochs:Update(from) then -- `H-151`: the only place `_epochs` is written
				self:Rerun() -- unexecutable → rawRerun holds it (`H-159`)
			end
		end
		local function onRefFire(_value: any, ref: any)
			fire(ref) -- Ref: the 2nd arg is the source
		end
		local function onStateFire(_targetState: any, _observer: any, from: any)
			fire(from) -- Observer: the 3rd arg is the source
		end
		for d in pairs(seen) do
			if isRef(d) then
				self._deps[d] = onRefFire -- strong owner = Effect
				d:WeakCallback(onRefFire) -- the Ref side is weak
			else
				local o = d:Observer(onStateFire)
				self._deps[d] = o -- strong owner = Effect
				o:WeakSubscribe() -- the global registry side is weak
			end
			-- seeding by "is it an Epoch" — Source/Ref are (`Sync`), a State hands over
			-- what it tracks (`_track` → `TrackFrom`, same polymorphic hook `_recompute` uses)
			if isEpoch(d) then
				self._epochs:Sync(d)
			else
				d:_track(self._epochs)
			end
		end

		-- (2) install — once, immediately; cannot be deferred to bind.
		self._rerunRequired = true
		rawRerun(self, true)
		return self
	end

	module.Effect = Effect
	return Impl
end

local function Init(module: any)
	implsOf(module).Effect = createImpl(module)
end

local function implFor(module: any)
	local impl = implsOf(module).Effect
	if impl == nil then
		error("Effect: Effect.Init(module) has not run for this quad instance", 1)
	end
	return impl
end

return {
	Init = Init,
	implFor = implFor,
}
