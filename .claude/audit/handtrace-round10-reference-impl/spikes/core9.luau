--!nocheck
-- 9라운드 참조 구현 — 2026-08-26 `9dd8213` 이후 계약을 base/에서 옮긴 전사물.
-- 옮긴 원문: source-state-plan.md(전파 루프 `_emitDown`, Observer 3-인자, `_state`),
-- lifecycle-pattern.md((1) isBoundAlive/bindLifetime/unbindLifetime, (2) Weak/Subscribe 4진입점),
-- ref-plan.md(`:Set` 순서 값→리비전→콜백, Callbacks/WeakCallbacks 스냅샷·dedup, Uncallback),
-- effect-plan.md(생성자 fire/onRefFire/onStateFire, _bindDestroying, Rerun, Subscribe/Unsubscribe),
-- state-epoch-plan.md(EpochMap, 캐시 카운터 쌍), blocker-plan.md(On/Off/OffWithoutEmit/IsOn).
-- 엔진 부재: bindLifetime은 mock inst `{conn = {Connected = bool}}`의 gcconn을 복사한다(H-97 mock 4종).
local M = {}
local function weakK() return setmetatable({}, {__mode = "k"}) end

-- ── EpochMap ───────────────────────────────────────────────────────────
local EpochMap = {}; EpochMap.__index = EpochMap
function M.EpochMap() return setmetatable({map = weakK()}, EpochMap) end
local function unfold(from)
    if from.Revision ~= nil then return {from} end
    local t = {}; for e in pairs(from) do t[#t+1] = e end; return t
end
function EpochMap:Update(from)
    local changed = false
    for _, e in ipairs(unfold(from)) do
        if self.map[e] ~= e.Revision then changed = true; self.map[e] = e.Revision end
    end
    return changed
end
function EpochMap:Peek(from)
    for _, e in ipairs(unfold(from)) do if self.map[e] ~= e.Revision then return true end end
    return false
end
function EpochMap:Sync(from) for _, e in ipairs(unfold(from)) do self.map[e] = e.Revision end end
function EpochMap:Refresh()
    local changed = false
    for e, rev in pairs(self.map) do
        if e.Revision ~= rev then changed = true; self.map[e] = e.Revision end
    end
    return changed
end
function EpochMap:TrackFrom(other) for e in pairs(other.map) do self.map[e] = e.Revision end end

-- ── 판별자 ─────────────────────────────────────────────────────────────
local Source, State, Observer, Ref, EffectHandle = {}, {}, {}, {}, {}
Source.__index, State.__index, Observer.__index, Ref.__index, EffectHandle.__index =
    Source, State, Observer, Ref, EffectHandle
local function isSource(x)   return getmetatable(x) == Source end
local function isState(x)    return getmetatable(x) == Source or getmetatable(x) == State end
local function isObserver(x) return getmetatable(x) == Observer end
local function isRef(x)      return getmetatable(x) == Ref end
local function isEffect(x)   return getmetatable(x) == EffectHandle end
local function isEpoch(x)    return isSource(x) or isRef(x) end
M.isSource, M.isState, M.isObserver, M.isRef, M.isEffect, M.isEpoch =
    isSource, isState, isObserver, isRef, isEffect, isEpoch

-- ── 생명주기 (lifecycle-pattern.md (1)) — mock inst = {conn = {Connected = true}} ──
local BindData = weakK()   -- value -> {gchold=, gcconn=}
local function isBoundAlive(value)
    local bd = BindData[value]
    if bd and bd.gcconn ~= nil and bd.gcconn.Connected then return true end
    if isObserver(value) or isEffect(value) then return value.Subscribed == true end
    return false
end
local function canBound(value) return not isBoundAlive(value) end
local function canExecute(value) return isBoundAlive(value) end
M.canBound, M.canExecute = canBound, canExecute
function M.bindLifetime(inst, value)
    if not canBound(value) then
        local isGlobal = (isObserver(value) or isEffect(value)) and value.Subscribed == true
        error(if isGlobal then "already subscribed" else "already bound to another instance", 2)
    end
    inst.gchold = inst.gchold or {}
    inst.gchold[value] = true
    BindData[value] = {gchold = inst.gchold, gcconn = inst.conn}
    if isEffect(value) then value:_bindDestroying(inst) end
end
function M.unbindLifetime(value)
    if isEffect(value) then value:_unbindDestroying() end
    local bd = BindData[value]
    if bd and bd.gchold then bd.gchold[value] = nil end
    BindData[value] = nil
end
function M.newInst(name) return {name = name, conn = {Connected = true}, destroying = {}} end
function M.destroyInst(inst)
    inst.conn.Connected = false
    for _, fn in ipairs(inst.destroying) do fn() end
end

-- ── 전파 루프 (source-state-plan.md "전파 루프 — 확정 의사코드") ──────
local function emitDown(self, from)
    local snap = {}
    for sub in pairs(self._subs) do snap[#snap+1] = sub end     -- H-23 스냅샷
    for _, sub in ipairs(snap) do
        if isState(sub) then
            sub:_receive(from)
        elseif canExecute(sub) then
            sub.fn(sub._state, sub, from)   -- ⭐ (리시버 State, Observer 자신, 출처) H-109
        end
    end
end

-- ── Source ─────────────────────────────────────────────────────────────
function M.Source(v)
    return setmetatable({_value = v, Revision = 0, _subs = weakK()}, Source)
end
function Source:Get() return self._value end
function Source:Set(v)
    self._value = v
    self.Revision = bit32.bnot(-self.Revision)
    emitDown(self, self)
    return self
end
function Source:_track(map) map:Sync(self) end
function Source:_addSub(s) self._subs[s] = true end

-- ── State (Compute) — 캐시 카운터 쌍 (state-epoch-plan.md §4, H-85) ────
function M.Compute(deps, fn)
    local self = setmetatable({
        fn = fn, _hold = deps, _subs = weakK(),
        valueEpochMap = M.EpochMap(), emitEpochMap = M.EpochMap(),
        cacheTargetCount = 0, cacheCurrCount = nil, cache = nil,
    }, State)
    for _, d in ipairs(deps) do d:_addSub(self); d:_track(self.valueEpochMap) end
    return self
end
function State:_track(map) map:TrackFrom(self.valueEpochMap) end
function State:_addSub(s) self._subs[s] = true end
function State:_receive(from)
    local valueChanged = self.valueEpochMap:Update(from)
    local emitChanged  = self.emitEpochMap:Update(from)
    if valueChanged then self.cacheTargetCount = bit32.bnot(-self.cacheTargetCount) end
    if valueChanged or emitChanged then emitDown(self, from) end
end
function State:Get()
    if self.cacheCurrCount ~= self.cacheTargetCount or self.valueEpochMap:Refresh() then
        if self.cacheCurrCount == self.cacheTargetCount then
            self.cacheTargetCount = bit32.bnot(-self.cacheTargetCount)
        end
        local target = self.cacheTargetCount
        self.cache = self.fn(self, self.cache)
        self.cacheCurrCount = target
        for _, d in ipairs(self._hold) do d:_track(self.valueEpochMap) end
    end
    return self.cache
end
Source.Compute = function(self, fn) return M.Compute({self}, fn) end
State.Compute  = Source.Compute

-- ── Observer + 4진입점 레지스트리 (lifecycle-pattern.md (2)) ───────────
local Subscribed     = {}
local WeakSubscribed = weakK()
local function newObserver(state, fn)
    fn = fn or function(targetState) targetState:Get() end   -- H-61
    local self = setmetatable({fn = fn, _state = state}, Observer)   -- H-110 강참조
    state:_addSub(self)
    fn(state, self, nil)          -- 등록 즉시 1회(설치 발화, emitFrom = nil)
    return self
end
Source.Observer, State.Observer = newObserver, newObserver
function Observer:WeakSubscribe()
    if not canBound(self) then
        error(if self.Subscribed then "already subscribed" else "already bound to an instance", 2)
    end
    self.Subscribed = true          -- H-111
    WeakSubscribed[self] = true
    return self
end
function Observer:WeakUnsubscribe()
    if Subscribed[self] ~= nil then error("subscribed strongly; use :Unsubscribe()", 2) end
    WeakSubscribed[self] = nil
    self.Subscribed = false
    return self
end
function Observer:Subscribe()
    self:WeakSubscribe()
    Subscribed[self] = true
    return self
end
function Observer:Unsubscribe()
    if Subscribed[self] == nil then error("not subscribed strongly; use :WeakUnsubscribe()", 2) end
    Subscribed[self] = nil
    return self:WeakUnsubscribe()
end

-- ── Ref (ref-plan.md `:Set` 순서 절 + WeakCallback 항목) ──────────────
function M.Ref(default)
    return setmetatable({Value = default, Revision = 0, Callbacks = {}, WeakCallbacks = weakK()}, Ref)
end
function Ref:WeakCallback(fn)
    self.WeakCallbacks[fn] = true
    fn(self.Value, self)            -- 등록 즉시 1회, nil이어도 그대로(H-120)
    return self
end
function Ref:Callback(fn)
    self:WeakCallback(fn)
    self.Callbacks[fn] = true       -- GC 킵 한 겹
    return self
end
function Ref:Uncallback(fn)
    self.Callbacks[fn] = nil; self.WeakCallbacks[fn] = nil
    return self
end
function Ref:Set(value)
    self.Value = value                                   -- (1)
    self.Revision = bit32.bnot(-self.Revision)           -- (2) 콜백보다 앞
    local snapshot = {}                                  -- (3)
    for k in pairs(self.Callbacks) do table.insert(snapshot, k) end
    for k in pairs(self.WeakCallbacks) do
        if self.Callbacks[k] == nil then table.insert(snapshot, k) end
    end
    for _, k in ipairs(snapshot) do
        if self.Callbacks[k] == nil and self.WeakCallbacks[k] == nil then continue end
        if type(k) == "thread" then
            self.Callbacks[k] = nil
            coroutine.resume(k, self)
        else
            k(value, self)                               -- ⭐ 값 + Ref 자신(= Epoch)
        end
    end
    return self
end

-- ── Effect (effect-plan.md 생성자/훅/Rerun/Subscribe) ─────────────────
function M.Effect(fn, ...)
    local self = setmetatable({fn = fn, _deps = {}, _epochs = M.EpochMap()}, EffectHandle)
    self._blocker = M.Blocker()
    local seen = {}
    for i = 1, select("#", ...) do
        local d = select(i, ...)
        if d == nil then error("Effect: dep #" .. i .. " is nil", 2) end
        if not (isState(d) or isSource(d) or isRef(d)) then
            error("Effect: dep #" .. i .. " is not a State/Source/Ref", 2)
        end
        if not seen[d] then seen[d] = true end
    end
    self._blocker:On()
    local function fire(from)
        if not canExecute(self) then return end
        if self._blocker:IsOn() then return end
        if self._epochs:Update(from) then self:Rerun() end
    end
    local function onRefFire(_, ref) fire(ref) end
    local function onStateFire(_, _, from) fire(from) end
    for d in pairs(seen) do
        if isRef(d) then
            self._deps[d] = onRefFire
            d:WeakCallback(onRefFire)
        else
            local o = d:Observer(onStateFire)
            self._deps[d] = o
            o:WeakSubscribe()
        end
        if isEpoch(d) then self._epochs:Sync(d) else self._epochs:TrackFrom(d.valueEpochMap) end
    end
    self._blocker:OffWithoutEmit()
    self:Rerun()
    return self
end
function EffectHandle:_bindDestroying(inst)
    self:_unbindDestroying()
    local conn = {Connected = true}
    table.insert(inst.destroying, function()
        if not conn.Connected then return end
        self:_unbindDestroying(); self:_consumeCleanup()
    end)
    self._destroyConn = conn
    local depsChanged = self._epochs:Refresh()
    if not self._installed or depsChanged then self:Rerun() end
end
function EffectHandle:_unbindDestroying()
    if self._destroyConn then self._destroyConn.Connected = false; self._destroyConn = nil end
end
function EffectHandle:_consumeCleanup()
    local c = self._cleanup; self._cleanup = nil; self._installed = false
    if c then c() end
end
function EffectHandle:Rerun()
    if self._running then self._pending = true; return end
    self._running = true
    repeat
        self._pending = false
        self:_consumeCleanup()
        self._cleanup = self.fn(self)
        self._installed = true
    until not self._pending
    self._running = false
end
-- Effect의 Subscribe/Unsubscribe — lifecycle-pattern의 Observer 4진입점을 그대로 재사용
--   (핸들 자신만 등록, 내부 Observer는 건드리지 않는다 — H-59)
EffectHandle.WeakSubscribe, EffectHandle.WeakUnsubscribe = Observer.WeakSubscribe, Observer.WeakUnsubscribe
EffectHandle.Subscribe = Observer.Subscribe
function EffectHandle:Unsubscribe()
    Observer.Unsubscribe(self)      -- 게이트 + 레지스트리 + .Subscribed = false
    self:_consumeCleanup()          -- 마지막 cleanup 정확히 1회
    return self
end

-- ── Blocker ─────────────────────────────────────────────────────────────
local Blocker = {}; Blocker.__index = Blocker
function M.Blocker() return setmetatable({IsBlocked = false, handles = weakK()}, Blocker) end
function Blocker:IsOn() return self.IsBlocked end
function Blocker:On() self.IsBlocked = true; return self end
function Blocker:_run(emit)
    local snap = {}; for h in pairs(self.handles) do snap[#snap+1] = h end
    for _, h in ipairs(snap) do h(emit) end
end
function Blocker:Off() self.IsBlocked = false; self:_run(true); return self end
function Blocker:OffWithoutEmit() self.IsBlocked = false; self:_run(false); return self end

return M
