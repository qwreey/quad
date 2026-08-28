--[[
	State — derived reactive node (`:Compute` / `:With` / `:Apply`), the
	propagation loop, and the epoch-based recompute judgement.

	Assembly (`H-174`, user-confirmed 2026-08-28): `State.Init(module)` builds
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
	  - `.claude/base/gate-plan.md` "`GateNode` 조립" (unit 4): `state:Gate(setup)`
	    makes a `GateNode` — a pass-through State node whose `_receive` judges
	    with `Peek` on the emit map, merges the source into a weak-key
	    `_withheld` set, and hands control to the policy; `_flush(commit)` is
	    the `emit` the policy holds (empty → false; swap → `Sync(batch)` →
	    `_emitDown(batch)`; `emit(false)` discards). Value is never gated (3번).
]]

local Brand = require("./Brand")
local EpochMap = require("./EpochMap")
local Observer = require("./Observer")
local Void = require("./Void")
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
	module:RunInit(Observer.Init) -- `:Observer` needs the per-instance Observer impl (idempotent pull, `H-177`)
	local ObserverImpl = Observer.implFor(module)

	local Impl = {}
	Impl.__index = Impl

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
	local function newNode(deps: { any }, fn: any, mt: any?): any
		for i, dep in ipairs(deps) do
			if not isState(dep) then
				error(`State: dep #{i} is not a State/Source`, 3) -- 3: past Compute/With/Gate to the user's call
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
		}, mt or Impl)
		StateBrand:register(self) -- `H-152`: a GateNode is a State too — first line of its assembly
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

	-- ── GateNode (`gate-plan.md` "`GateNode` 조립") — same layer as a ComputeNode ──
	local GateImpl = setmetatable({}, { __index = Impl })
	GateImpl.__index = GateImpl

	local function newWithheld()
		return setmetatable({}, WEAK_KEY_MT) -- `H-9`: every withheld table is weak-keyed, the swapped-in one too
	end

	-- The ONLY exception to §4: the emit map is Peeked at receive time and
	-- written at flush (`Sync(batch)`), so "what I have sent downstream" stays true.
	function GateImpl._receive(self: any, from: any)
		local valueChanged = self._valueEpochMap:Update(from)
		local emitChanged = self._emitEpochMap:Peek(from) -- Peek, not Update (`H-72`)
		if valueChanged then
			self:_invalidate()
		end
		if not (valueChanged or emitChanged) then
			return -- rule 3: swallowed — no policy, not added to the set
		end
		-- Merge the source(s) into the withheld set. A batch is UNFOLDED (never held
		-- by reference — an upstream gate's batch is a one-shot snapshot).
		local withheld = self._withheld
		if isEpoch(from) then
			withheld[from] = true
		else
			for epoch in pairs(from) do
				withheld[epoch] = true
			end
		end
		self._onUpstreamEmit() -- the policy decides: emit() / emit(false) / nothing
	end

	-- This IS the `emit(commit) -> boolean` the policy holds.
	function GateImpl._flush(self: any, commit: boolean?): boolean
		local batch = self._withheld
		if next(batch) == nil then
			return false -- (1) empty batch: nothing at all (8번)
		end
		self._withheld = newWithheld() -- (2) swap, never clear — nested waves get a fresh table
		if commit == false then
			return true -- discard (`H-55`): no Sync, no propagation
		end
		self._emitEpochMap:Sync(batch) -- (3) BEFORE propagating, all at once
		emitDown(self, batch) -- (4) the detached batch is the payload — the gate itself never is
		return true
	end

	-- `state:Gate(setup)`; `setup(emit) -> onUpstreamEmit`. Returns a State<T> (same T).
	function Impl.Gate(self: any, setup: any): any
		if type(setup) ~= "function" then
			error("State: Gate setup must be a function (emit) -> onUpstreamEmit", 2)
		end
		local node = newNode({ self }, passThrough, GateImpl) -- StateBrand + seeding + `_hold` like any node
		node._withheld = newWithheld()
		node._onUpstreamEmit = Void -- until setup returns: a throwing setup must not leave a nil callee
		local onUpstreamEmit = (setup :: any)(function(commit: boolean?): boolean
			return node:_flush(commit)
		end)
		if type(onUpstreamEmit) ~= "function" then
			self._subs[node] = nil -- detach the half-built node before reporting (no orphan in `_subs`)
			error("State: Gate setup must return the onUpstreamEmit function", 2)
		end
		node._onUpstreamEmit = onUpstreamEmit -- strong: the policy closure (and, through it, the Blocker handle)
		return node
	end

	-- `state:Observer(fn?)` — leaf subscriber, fires once at registration
	-- (`source-state-plan.md` "`state:Observer(fn)`"). Body lives in `Observer.luau`.
	function Impl.Observer(self: any, fn: any?): any
		if fn ~= nil and type(fn) ~= "function" then
			error("State: Observer fn must be a function (or nil for the always-observe utility)", 2)
		end
		return ObserverImpl.new(self, fn)
	end

	function Impl.Apply(self: any, factory: any): any
		if type(factory) == "function" then
			return (factory :: any)(self)
		end
		if type(factory) ~= "table" or type(factory.__apply) ~= "function" then
			error("State: Apply factory must be a function or an object with an __apply method", 2)
		end
		return (factory :: any):__apply(self) -- method form: `self` there is the factory object (`H-158`)
	end

	return Impl
end

local function Init(module: any)
	implsOf(module).State = createImpl(module)
end

local function implFor(module: any)
	local impl = implsOf(module).State
	if impl == nil then
		error("State: State.Init(module) has not run for this quad instance", 1) -- invariant check; every caller pulls it in first (`H-177`)
	end
	return impl
end

return {
	Init = Init,
	implFor = implFor,
}
