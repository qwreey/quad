--[[
	Observer — the leaf subscriber a `State` fires, and the owner of the two
	global subscription registries (`Subscribed` strong / `WeakSubscribed`
	weak-key) that `Effect.luau` shares (`H-99`).

	Assembly (`H-174`): `Observer.Init(module)` builds one implementation (and
	one registry pair) per quad instance; the lifetime gates are read as
	`module.canExecute(self)` / `module.canBound(self)` AT CALL TIME — never
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

	An Observer is NOT an `Epoch` and carries no epoch bookkeeping — it only
	forwards the source it received. `EffectHandle` does NOT reuse these
	bodies (heterogeneous types; `conventions.md` 설계 원칙).
]]

local Brand = require("./Brand")
local ImplRegistry = require("./ImplRegistry")
local Err = require("./ErrorNamespace")
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

	-- Registries — owned here, shared with `Effect.luau` (`H-99`). Per quad
	-- instance because the gates that read `.Subscribed` are per instance.
	local Subscribed = {} :: { [any]: true } -- strong: keeps the handle alive
	local WeakSubscribed = setmetatable({}, WEAK_KEY_MT) :: { [any]: true } -- membership only
	Impl._Subscribed = Subscribed
	Impl._WeakSubscribed = WeakSubscribed

	-- ── EmitReceive ──────────────────────────────────────────────────
	function Impl._receive(self: any, from: any)
		if module.canExecute(self) then -- read at fire time (`H-174`)
			self._running = true -- `H-183`: fn may not change its own lifecycle (`H-147` symmetric);
			self.fn(self._state, self, from) --   an fn that throws leaves it set — dead by contract
			self._running = false
		else
			self._rerunRequired = true -- `H-159`: change before binding is held — replayed once when bound
		end
	end

	-- Catch-up: bind/subscribe replays a held change once, with no source.
	-- The only caller set: `bindLifetime`, `Subscribe`, `WeakSubscribe`.
	function Impl._catchUp(self: any)
		if self._rerunRequired then
			self._rerunRequired = false
			self._running = true -- `H-183`
			self.fn(self._state, self, nil)
			self._running = false
		end
	end

	-- `H-184`: `bindLifetime` asks this BEFORE committing the binding — a refusal
	-- must not leave a half-bound handle. Blame: nearest SURFACE frame past this
	-- and `bindLifetime` (`H-231` walker — the old hand-counted 3 is gone).
	function Impl._assertBindable(self: any)
		if self._running then
			Err.errorBeforeNearest("Observer: cannot bind an Observer from inside its own fn", SURFACE) -- `H-183`
		end
	end

	-- ── four entry points (`lifecycle-pattern.md` (2)) ───────────────
	function Impl.WeakSubscribe(self: any): any
		if self._running then
			Err.errorBeforeNearest("Observer: cannot change subscription from inside its own fn", SURFACE) -- `H-183` (`H-147` symmetric)
		end
		if not module.canBound(self) then -- same gate as bindLifetime (shared isBoundAlive)
			Err.errorBeforeNearest(
				if self.Subscribed then "Observer: already subscribed" else "Observer: already bound to an Instance",
				SURFACE
			)
		end
		self.Subscribed = true -- `H-111`: the weak path raises the flag too
		WeakSubscribed[self] = true
		self:_catchUp() -- `H-159`: held change once, symmetric with bind
		return self
	end

	function Impl.WeakUnsubscribe(self: any): any
		if self._running then
			Err.errorBeforeNearest("Observer: cannot change subscription from inside its own fn", SURFACE) -- `H-183`
		end
		-- A strong keep left behind would make a half-released, never-GC'd handle: fail fast.
		if Subscribed[self] ~= nil then
			Err.errorBeforeNearest("Observer: subscribed strongly; use :Unsubscribe()", SURFACE)
		end
		-- `H-133`: that is the whole guard — never subscribed / already weakly released pass silently.
		WeakSubscribed[self] = nil
		self.Subscribed = false
		return self
	end

	function Impl.Subscribe(self: any): any
		if self._running then
			Err.errorBeforeNearest("Observer: cannot change subscription from inside its own fn", SURFACE) -- `H-183`
		end
		-- `H-149`: NOT delegated to WeakSubscribe — level 2 must point at the user's call,
		-- and colon delegation would resolve to a subtype's override.
		if not module.canBound(self) then
			Err.errorBeforeNearest(
				if self.Subscribed then "Observer: already subscribed" else "Observer: already bound to an Instance",
				SURFACE
			)
		end
		self.Subscribed = true
		WeakSubscribed[self] = true
		Subscribed[self] = true -- just one more layer: the strong keep
		self:_catchUp()
		return self
	end

	function Impl.Unsubscribe(self: any): any
		if self._running then
			Err.errorBeforeNearest("Observer: cannot change subscription from inside its own fn", SURFACE) -- `H-183`
		end
		-- Symmetric with WeakUnsubscribe's guard: release through the path you subscribed by.
		if Subscribed[self] == nil then
			Err.errorBeforeNearest("Observer: not subscribed strongly; use :WeakUnsubscribe()", SURFACE)
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
			_rerunRequired = true,
			_running = false, -- `H-183`: raised around every fn run; entry points refuse while up
			Subscribed = false, -- the shared flag both handle types carry (`H-111`)
		}, Impl)
		ObserverBrand:register(o)
		o._running = true -- `H-183`: the install fire is an fn run like any other
		o.fn(state, o, nil) -- (1) fire once at registration — no source (`nil`)
		o._running = false
		o._rerunRequired = false -- (2) the install fire lowers the flag
		state._subs[o] = true -- (3) only THEN join the subscriber set — reversed, (1) Setting its own
		return o --     State would land in this Observer's `_receive` and raise the flag
	end

	-- `H-231`: public surface joins the shared error-namespace tag layer
	for _, fn in { Impl.WeakSubscribe, Impl.WeakUnsubscribe, Impl.Subscribe, Impl.Unsubscribe } do
		Err.setFuncLevel(fn, SURFACE)
	end

	return Impl
end

local function Init(module: any)
	implsOf(module).Observer = createImpl(module)
end

local function implFor(module: any)
	local impl = implsOf(module).Observer
	if impl == nil then
		error("Observer: Observer.Init(module) has not run for this quad instance", 1) -- invariant; callers pull it in first
	end
	return impl
end

return {
	Init = Init,
	implFor = implFor,
}
