--[[
	State — derived reactive node (`:Compute` / `:With` / `:Apply`), the
	propagation loop, and the epoch-based recompute judgement.

	Assembly (`H-174`, user-confirmed 2026-08-28): `InitState(module)` builds
	one implementation table per `quad` instance and keeps `module` in its
	closure, so later units (`Observer`, `Gate`) can read lifetime gates as
	`module.canExecute(...)` AT FIRE TIME (never captured at init — the
	backend overwrites those fields after `New()`). `implFor(module)` hands
	the same table to `Source.luau`'s init (its only caller — `Store.luau`
	never touches it; it reaches State only through the `Source` values it
	creates).

	There is no runtime `State` constructor — nodes exist only as results of
	`:Compute`/`:With` (and `:Gate`, unit 4). `State` is NOT an `Epoch`
	(`state-epoch-plan.md` §4): its counters are private recompute
	bookkeeping, and upstream tracking goes through `valueEpochMap`.

	Sources, transcribed as-is:
	  - `.claude/base/source-state-plan.md` "전파 루프 — 확정 의사코드"
	    (`_emitDown`: snapshot, then `sub:_receive(from)` — every subscriber
	    is an `EmitReceive`, `H-163`), "`:With`도 새 State 노드로 확정"
	    (pass-through node, wider subscription list), "self 인자도 lazy
	    핸들로 통일", "`:Compute(fn, ...)`" (trailing deps: one node),
	    "trailing deps를 `fn`에 lazy positional 인자로도 노출"
	    (`fn(self, previous?, ...deps)`), "`state:Apply(factory)`"
	    (`__apply` method form, `H-158`), "`_hold`로 살아남는다"
	    (downstream → upstream strong, upstream → downstream weak).
	  - `.claude/base/state-epoch-plan.md` §4: seeding (`emitEpochMap`
	    empty, `valueEpochMap` filled from every dep — `:Sync(dep)` if the
	    dep is an `Epoch`, `:TrackFrom(dep.valueEpochMap)` otherwise),
	    receive rules 1~3, the `cacheTargetCount`/`cacheCurrCount` pair
	    (`H-85`, `curr = nil` initially), recompute (`d:_track`, then
	    `cacheCurrCount = gen` only on success), `Get` (`Refresh` walk
	    advances the value only — never notifies).
	  - `.claude/base/modifier-plan.md` 7번: a `:Compute` result that is a
	    Modifier errors before it is cached.
]]

local Brand = require("./Brand")
local EpochMap = require("./EpochMap")
local QuadTypes = require("../roblox_packages/quad_types")

export type StateData<T> = QuadTypes.StateData<T>
export type State<T> = QuadTypes.State<T>
type EpochMap = EpochMap.EpochMap

local StateBrand = Brand.StateBrand
local isEpoch = Brand.isEpoch
local isState = Brand.isState
local isModifier = Brand.isModifier

local WEAK_KEY_MT = { __mode = "k" }

-- One implementation per quad instance (`H-174`).
local implByModule = setmetatable({}, WEAK_KEY_MT) :: { [any]: any }

local function createImpl(module: any)
	local Impl = {}
	Impl.__index = Impl
	Impl._module = module -- read lazily by later units, never captured

	-- ── propagation loop ──────────────────────────────────────────────
	-- Shared by every node type that has `_subs` (Source nodes too).
	local function emitDown(self: any, from: any)
		-- H-23: adding a key during `pairs` is undefined, so snapshot first.
		-- "이번 파동 중에 붙은 구독자는 다음 파동부터"가 계약.
		local snap = {}
		for sub in pairs(self._subs) do
			snap[#snap + 1] = sub
		end
		for _, sub in ipairs(snap) do
			(sub :: any):_receive(from) -- every subscriber is an `EmitReceive` (`H-163`)
		end
	end
	Impl._emitDown = emitDown

	-- ── node creation ─────────────────────────────────────────────────
	local function newNode(deps: { any }, fn: any): any
		for i, dep in ipairs(deps) do
			if not isState(dep) then
				error(`State: dep #{i} is not a State/Source`, 3) -- 3: past Compute/With to the user's call
			end
		end
		local self = setmetatable({
			_fn = fn,
			_hold = deps, -- strong: downstream → upstream (`_hold` invariant)
			_subs = setmetatable({}, WEAK_KEY_MT), -- weak-key: upstream → downstream
			_valueEpochMap = EpochMap(),
			_emitEpochMap = EpochMap(), -- starts EMPTY on purpose (§4 seeding)
			_cacheTargetCount = 0,
			_cacheCurrCount = nil, -- never computed yet → always differs
			_cache = nil,
		}, Impl)
		StateBrand:register(self)
		-- §4 seeding: valueEpochMap takes every upstream epoch, live.
		for _, dep in ipairs(deps) do
			dep._subs[self] = true
			if isEpoch(dep) then
				self._valueEpochMap:Sync(dep)
			else
				self._valueEpochMap:TrackFrom(dep._valueEpochMap)
			end
		end
		return self
	end
	Impl._newNode = newNode

	-- ── EmitReceive + epoch bookkeeping ──────────────────────────────
	function Impl._track(self: any, map: EpochMap)
		map:TrackFrom(self._valueEpochMap) -- a State is not an Epoch: hand over what it tracks
	end

	function Impl._invalidate(self: any)
		self._cacheTargetCount = bit32.bnot(-self._cacheTargetCount)
	end

	-- §4 "emit을 받았을 때": two maps, two booleans, three cases.
	function Impl._receive(self: any, from: any)
		local valueChanged = self._valueEpochMap:Update(from)
		local emitChanged = self._emitEpochMap:Update(from)
		if valueChanged then
			self:_invalidate() -- rule 1: value is stale
		end
		if valueChanged or emitChanged then
			emitDown(self, from) -- rules 1/2: forward the SAME source; rule 3: swallow
		end
	end

	function Impl._recompute(self: any)
		local gen = self._cacheTargetCount -- snapshot right before fn (`H-85`)
		local hold = self._hold
		-- `fn(self, previous?, ...deps)` — `self` is the RECEIVER's lazy handle
		-- (`hold[1]`), never this result node.
		local result = self._fn(hold[1], self._cache, table.unpack(hold, 2))
		if isModifier(result) then
			error("State: a Compute function returned a Modifier — State/Source cannot hold Modifiers", 2)
		end
		self._cache = result
		for _, dep in ipairs(hold) do
			dep:_track(self._valueEpochMap) -- fresh value is current w.r.t. EVERY upstream
		end
		self._cacheCurrCount = gen -- only on success: a thrown fn never marks the cache valid
	end

	function Impl.Get(self: any): any
		if self._cacheCurrCount ~= self._cacheTargetCount then
			self:_recompute()
		elseif self._valueEpochMap:Refresh() then
			-- 순회: catch an emit that never reached us (gate, wave not arrived) —
			-- advance the VALUE only; notification waits for the real emit.
			self:_invalidate()
			self:_recompute()
		end
		return self._cache
	end

	-- ── derived-node methods (shared by Source through `__index`) ─────
	local function passThrough(s: any)
		return s:Get()
	end

	function Impl.With(self: any, ...: any): any
		local deps = { self }
		for i = 1, select("#", ...) do
			deps[#deps + 1] = (select(i, ...))
		end
		return newNode(deps, passThrough) -- value is `self`'s, subscriptions are wider
	end

	function Impl.Compute(self: any, fn: any, ...: any): any
		local deps = { self }
		for i = 1, select("#", ...) do
			deps[#deps + 1] = (select(i, ...))
		end
		return newNode(deps, fn) -- one node: edges only, no combining node
	end

	function Impl.Apply(self: any, factory: any): any
		if type(factory) == "function" then
			return (factory :: any)(self)
		end
		return (factory :: any):__apply(self) -- method form: `self` there is the factory object (`H-158`)
	end

	return Impl
end

local function Init(module: any)
	implByModule[module] = createImpl(module)
end

local function implFor(module: any)
	local impl = implByModule[module]
	if impl == nil then
		error("State: InitState(module) has not run for this quad instance", 1) -- invariant check; every caller pulls it in first (`H-177`)
	end
	return impl
end

return {
	Init = Init,
	implFor = implFor,
}
