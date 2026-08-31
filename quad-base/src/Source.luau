--[[
	Source — the writable root value. Structurally satisfies `State` (all
	derived methods come from `State.luau`'s impl through `__index`) and is
	itself an `Epoch` (`Revision`), so it is registered in BOTH
	`SourceBrand` and `EpochBrand` (multi-tagging, `brand-plan.md`) — never in
	`StateBrand`: `isState = isSource or StateBrand` is composed in the
	predicate, not by double registration.

	Sources, as-is:
	  - `.claude/base/source-state-plan.md` "State는 쓰기 대상이 아님 —
	    확정, Source는 독립 공개 프리미티브로 격상" (`Source(default)`),
	    "`Source:Set(v)`는 동일값이어도 항상 갱신하고 emit한다" (`H-68`),
	    "Source 값을 직접 mutate한 뒤 전파 — `:Emit()`" (root only),
	    "따름정리 — `Store<T>`/`Source<T>`의 `T`는 Modifier가 될 수 없음".
	  - `.claude/base/modifier-plan.md` 7번: `isModifier` guard at the
	    constructor and at `:Set` (the constructor also covers `store:Of`).
	  - `.claude/base/state-epoch-plan.md` §2: `Revision` bump is
	    `bit32.bnot(-rev)`; `Set`/`Emit` push the Source itself as the emit
	    payload ("출처" only — no value, no revision).

	Assembly (`H-174`): `InitSource(module)` — needs the per-instance State
	impl for its `__index` chain, and pulls it in itself via
	`module:RunInit(State.Init)` (idempotent), so `New()` order is irrelevant.
]]

local Brand = require("./Brand")
local State = require("./State")
local QuadTypes = require("../luau_packages/quad_types")
local Err = require("./ErrorNamespace")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

export type Source<T> = QuadTypes.Source<T>

local SourceBrand = Brand.SourceBrand
local EpochBrand = Brand.EpochBrand
local isModifier = Brand.isModifier

local WEAK_KEY_MT = { __mode = "k" }

local function Init(module: any)
	-- Pull our dependency ourselves, `require`-style (`module-lifecycle-plan.md`
	-- "순서 의존성은 각 `InitXxx`를 `require`처럼 멱등하게 만들어서 해소한다") —
	-- `RunInit` is idempotent, so `New()` need not order us after `State.Init`.
	module:RunInit(State.Init)
	local StateImpl = State.implFor(module)
	local emitDown = StateImpl._emitDown

	local Impl = setmetatable({}, { __index = StateImpl })
	Impl.__index = Impl

	function Impl.Get(self: any): any
		return self._value
	end

	-- In-place mutation was done by the caller; only the signal is sent.
	-- Root Sources only — derived States have no such concept ("하드 경계").
	function Impl.Emit(self: any): any
		self.Revision = bit32.bnot(-self.Revision)
		emitDown(self, self) -- payload = the source epoch itself
		return self
	end

	-- `H-68`: same value still bumps the revision and emits — dedup is the
	-- downstream's job (EpochMap judgement, gates), and `==` would silently
	-- drop in-place table mutations.
	function Impl.Set(self: any, value: any): any
		if isModifier(value) then
			Err.errorBeforeNearest("Source: cannot Set a Modifier as a Source value", SURFACE)
		end
		self._value = value
		-- `H-207`: one copy of the bump-and-emit tail. Direct call, not colon
		-- delegation — same type, same impl table, no subtype override to hit.
		return Impl.Emit(self)
	end

	function Impl._track(self: any, map: any)
		map:Sync(self) -- a Source IS an Epoch: it goes into the map directly
	end

	local function Source(default: any): any
		if isModifier(default) then
			Err.errorBeforeNearest("Source: cannot hold a Modifier as a Source value", SURFACE)
		end
		local self = setmetatable({
			_value = default,
			Revision = 0,
			_subs = setmetatable({}, WEAK_KEY_MT), -- weak-key subscribers (downstream)
		}, Impl)
		SourceBrand:register(self)
		EpochBrand:register(self)
		return self
	end

	-- `H-231`: public surface joins the shared error-namespace tag layer
	for _, fn in { Impl.Get, Impl.Emit, Impl.Set, Source } do
		Err.setFuncLevel(fn, SURFACE)
	end

	module.Source = Source
end

return Init
