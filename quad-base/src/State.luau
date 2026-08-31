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
local ImplRegistry = require("./ImplRegistry")
local Observer = require("./Observer")
local Void = require("./Void")
local QuadTypes = require("../luau_packages/quad_types")
local Err = require("./ErrorNamespace")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

export type StateData<T> = QuadTypes.StateData<T>
export type State<T> = QuadTypes.State<T>
type EpochMap = EpochMap.EpochMap

local StateBrand = Brand.StateBrand
local isEpoch = Brand.isEpoch
local isState = Brand.isState
local isModifier = Brand.isModifier

local WEAK_KEY_MT = { __mode = "k" }

-- One implementation per quad instance (`H-174`); storage scheme in `ImplRegistry.luau`.
local implsOf = ImplRegistry.implsOf

local function createImpl(module: any)
	module:RunInit(Observer.Init) -- `:Observer` needs the per-instance Observer impl (idempotent pull, `H-177`)
	local ObserverImpl = Observer.implFor(module)

	local Impl = {}
	Impl.__index = Impl

	-- ── propagation loop ──────────────────────────────────────────────
	-- Shared by every node type that has `_subs` (Source nodes too).
	local function emitDown(self: any, from: any)
		-- H-23: adding a key during iteration is undefined, so snapshot first.
		-- "이번 파동 중에 붙은 구독자는 다음 파동부터"가 계약.
		local snap = {}
		for sub in self._subs do
			snap[#snap + 1] = sub
		end
		for _, sub in snap do
			(sub :: any):_receive(from) -- every subscriber is an `EmitReceive` (`H-163`)
		end
	end
	Impl._emitDown = emitDown

	-- ── node creation ─────────────────────────────────────────────────
	local function newNode(deps: { any }, fn: any, mt: any?): any
		for i, dep in deps do
			if not isState(dep) then
				Err.errorBeforeNearest(`State: dep #{i} is not a State/Source`, SURFACE) -- 3: past Compute/With/Gate to the user's call
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
		for _, dep in deps do
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
		-- `H-198` (user-confirmed 2026-08-31): stamp upstream revisions BEFORE fn —
		-- anything that moves DURING fn (a reentrant Set, or one withheld by a
		-- closed gate, which never reaches our `_receive`) then shows up afterwards
		-- as `Refresh` drift and `Get`'s loop recomputes. Stamping after fn marked
		-- those moves as already seen (permanent stale cache).
		for _, dep in hold do
			dep:_track(self._valueEpochMap)
		end
		-- `fn(self, previous?, ...deps)` — `self` is the RECEIVER's lazy handle
		-- (`hold[1]`), never this result node.
		local result = self._fn(hold[1], self._cache, table.unpack(hold, 2))
		if isModifier(result) then
			-- `H-205`: level 3 — `_recompute`'s only callers are Get's own lines, so 2
			-- always blamed quad internals; 3 reaches the user on a direct `Get` and is
			-- never worse through a pass-through chain (no fixed level reaches user code there).
			Err.errorBeforeNearest("State: a Compute function returned a Modifier — State/Source cannot hold Modifiers", SURFACE)
		end
		self._cache = result
		self._cacheCurrCount = gen -- only on success: a thrown fn never marks the cache valid
	end

	function Impl.Get(self: any): any
		-- `H-198` (user-confirmed): a LOOP, not a single pass — restart until one
		-- recompute completes with nothing moving under it, so every Get returns a
		-- value computed from the latest reads ("항상 최신 값만 읽게되어"). Counter
		-- mismatch catches Sets our `_receive` saw (`H-85`); `Refresh` drift catches
		-- the ones it never did (behind a closed gate). Values only — notification
		-- still waits for the real emit. An fn that re-Sets its own (transitive)
		-- dep on every pass never converges: UB (user-confirmed).
		while true do
			if self._cacheCurrCount ~= self._cacheTargetCount then
				self:_recompute()
			elseif self._valueEpochMap:Refresh() then
				self:_invalidate()
				self:_recompute()
			else
				return self._cache
			end
		end
	end

	-- ── derived-node methods (shared by Source through `__index`) ─────
	local function passThrough(s: any)
		return s:Get()
	end

	-- `H-199`: a nil dep must error, not vanish — `deps[#deps + 1]` would drop it
	-- silently AND shift later deps left, so `fn`'s positional lazy-dep args land
	-- in the wrong slots. Index numbering matches `newNode`'s (self is dep #1).
	local function collectDeps(self: any, ...: any): { any }
		local deps = { self }
		for i = 1, select("#", ...) do
			local dep = (select(i, ...))
			if dep == nil then
				Err.errorBeforeNearest(`State: dep #{i + 1} is nil`, SURFACE) -- 3: past With/Compute to the user's call
			end
			deps[i + 1] = dep
		end
		return deps
	end

	function Impl.With(self: any, ...: any): any
		return newNode(collectDeps(self, ...), passThrough) -- value is `self`'s, subscriptions are wider
	end

	function Impl.Compute(self: any, fn: any, ...: any): any
		if type(fn) ~= "function" then
			-- `H-202`: without this the crash lands at the first `Get` deep inside
			-- `_recompute` — sibling surfaces (Gate/Observer/Apply) all validate here.
			Err.errorBeforeNearest("State: Compute fn must be a function", SURFACE)
		end
		return newNode(collectDeps(self, ...), fn) -- one node: edges only, no combining node
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
			for epoch in from do
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
			Err.errorBeforeNearest("State: Gate setup must be a function (emit) -> onUpstreamEmit", SURFACE)
		end
		local node = newNode({ self }, passThrough, GateImpl) -- StateBrand + seeding + `_hold` like any node
		node._withheld = newWithheld()
		node._onUpstreamEmit = Void -- until setup returns: a throwing setup must not leave a nil callee
		-- `H-200` (b): detach while user code (`setup`) runs — whether it THROWS or
		-- returns garbage, no zombie subscriber is left behind (no pcall needed). The
		-- window is unobservable: the withheld set stays empty while detached.
		self._subs[node] = nil
		local onUpstreamEmit = (setup :: any)(function(commit: boolean?): boolean
			return node:_flush(commit)
		end)
		if type(onUpstreamEmit) ~= "function" then
			Err.errorBeforeNearest("State: Gate setup must return the onUpstreamEmit function", SURFACE)
		end
		node._onUpstreamEmit = onUpstreamEmit -- strong: the policy closure (and, through it, the Blocker handle)
		self._subs[node] = true -- re-attach: the gate starts hearing emits only now
		return node
	end

	-- `state:Observer(fn?)` — leaf subscriber, fires once at registration
	-- (`source-state-plan.md` "`state:Observer(fn)`"). Body lives in `Observer.luau`.
	function Impl.Observer(self: any, fn: any?): any
		if fn ~= nil and type(fn) ~= "function" then
			Err.errorBeforeNearest("State: Observer fn must be a function (or nil for the always-observe utility)", SURFACE)
		end
		return ObserverImpl.new(self, fn)
	end

	function Impl.Apply(self: any, factory: any): any
		if type(factory) == "function" then
			return (factory :: any)(self)
		end
		if type(factory) ~= "table" or type(factory.__apply) ~= "function" then
			Err.errorBeforeNearest("State: Apply factory must be a function or an object with an __apply method", SURFACE)
		end
		return (factory :: any):__apply(self) -- method form: `self` there is the factory object (`H-158`)
	end

	-- `H-231`: public surface joins the shared error-namespace tag layer
	for _, fn in { Impl.Get, Impl.With, Impl.Compute, Impl.Gate, Impl.Observer, Impl.Apply } do
		Err.setFuncLevel(fn, SURFACE)
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
