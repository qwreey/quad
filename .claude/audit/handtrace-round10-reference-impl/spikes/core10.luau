--!nocheck
-- 10라운드 참조 구현 — HEAD `0ec22fb`(2026-08-28) 시점 `base/`를 옮긴 전사물.
-- 출발점은 9라운드 전사물 `core9.luau`(같은 폴더에 원본 보존)이고, 거기에
-- `H-143`~`H-149` 시점 계약을 얹었다:
--   · effect-plan.md  — `Rerun` 꼬리 `wasAlive and not canExecute` + `_pending` 버림(H-143),
--                       네 진입점 `EffectHandle` 자기 것 + `resubscribeTail`(H-144 (b)),
--                       생성자 `_blocker`, `fire` 가드 순서, `_bindDestroying` 캐치업(Refresh 먼저)
--   · lifecycle-pattern.md (2) — Observer 네 진입점(`Subscribe`→`WeakSubscribe` 콜론 위임 **그대로**,
--                       H-149가 판단 대기라 원문대로 둔다), `WeakUnsubscribe` 관대(H-133)
--   · gate-plan.md 4번/GateNode 조립 — `_receive`(valueEpochMap:Update + emitEpochMap:**Peek**),
--                       `_flush(commit)` 네 단계 + 반환값, `newWeakK` 스왑(H-9), unfold 합류
--   · blocker-plan.md/H-63 — onunblock 핸들 weak-키 셋, 강한 주인은 `onUpstreamEmit` 클로저,
--                       `Off`/`OffWithoutEmit` 스냅샷 순회, `Policy(emit)`
--   · state-epoch-plan.md §3/§4 — EpochMap(`Update`/`Peek`/`Refresh`/`Sync`/`TrackFrom`),
--                       캐시 카운터 쌍, `_hold`(하류→상류 강함), 구독자 weak-키
--   · source-state-plan.md — `_emitDown` 스냅샷, Observer 3-인자 + `_state`, `:With` pass-through,
--                       `Source:Set` 동일값도 emit(H-68)
--   · ref-plan.md — `:Set` 값→리비전→콜백, 두 테이블 스냅샷·dedup, `WeakCallback`/`Callback`/`Uncallback`
-- 엔진 부재: mock inst = `{conn = {Connected = bool}, destroying = {}}` (H-97 mock 4종),
-- `onDestroying`은 `inst.destroying` 배열에 콜백을 넣는 것으로 흉내낸다.
-- ⚠️ 이 파일은 문서가 아니라 전사물이다 — 여기서 나온 결과는 원문과 줄 단위 대조 뒤에만 발견이다.
local M = {}
local function weakK() return setmetatable({}, {__mode = "k"}) end
M.weakK = weakK

-- ── EpochMap (state-epoch-plan.md §3) ───────────────────────────────────
local EpochMap = {}; EpochMap.__index = EpochMap
function M.EpochMap() return setmetatable({map = weakK()}, EpochMap) end
local function isEpochLike(x) return type(x) == "table" and x.Revision ~= nil end
local function unfold(from)
    if isEpochLike(from) then return {from} end
    local t = {}; for e in pairs(from) do t[#t+1] = e end; return t
end
M.unfold = unfold
function EpochMap:Update(from)
    local changed = false
    for _, e in ipairs(unfold(from)) do
        if self.map[e] ~= e.Revision then changed = true; self.map[e] = e.Revision end
    end
    return changed
end
function EpochMap:Peek(from)                       -- H-72: 비교만, 덮지 않음
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
function EpochMap:_keys() local t = {}; for e in pairs(self.map) do t[#t+1] = e end; return t end

-- ── 판별자 (brand-plan.md의 isX — 여기선 메타테이블 항등으로 흉내) ──────
local Source, State, GateNode, Observer, Ref, EffectHandle = {}, {}, {}, {}, {}, {}
Source.__index, State.__index, GateNode.__index, Observer.__index, Ref.__index, EffectHandle.__index =
    Source, State, GateNode, Observer, Ref, EffectHandle
local function isSource(x)   return getmetatable(x) == Source end
local function isState(x)    local mt = getmetatable(x); return mt == Source or mt == State or mt == GateNode end
local function isObserver(x) return getmetatable(x) == Observer end
local function isRef(x)      return getmetatable(x) == Ref end
local function isEffect(x)   return getmetatable(x) == EffectHandle end
local function isEpoch(x)    return isSource(x) or isRef(x) end
M.isSource, M.isState, M.isObserver, M.isRef, M.isEffect, M.isEpoch =
    isSource, isState, isObserver, isRef, isEffect, isEpoch

-- ── 생명주기 (lifecycle-pattern.md (1)) — mock inst ────────────────────
local BindData = weakK()   -- value -> {gchold=, gcconn=}
M.BindData = BindData
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
-- mock 엔진: Instance + Destroying 훅(주입 op `onDestroying`)
function M.newInst(name) return {name = name, conn = {Connected = true}, destroying = {}} end
function M.onDestroying(inst, fn)
    local conn = {Connected = true}
    conn.Disconnect = function(self) self.Connected = false end
    inst.destroying[#inst.destroying + 1] = {conn = conn, fn = fn}
    return conn
end
-- Immediate 모드 흉내: Destroying 콜백을 동기로 돌린 뒤 커넥션을 끊는다(Roblox 순서).
function M.destroyInst(inst)
    local snap = {}
    for _, e in ipairs(inst.destroying) do snap[#snap+1] = e end
    for _, e in ipairs(snap) do if e.conn.Connected then e.fn() end end
    inst.conn.Connected = false
    for _, e in ipairs(inst.destroying) do e.conn.Connected = false end
    inst.destroying = {}
end

-- ── 전파 루프 (source-state-plan.md "전파 루프 — 확정 의사코드") ──────
local function emitDown(self, from)
    local snap = {}
    for sub in pairs(self._subs) do snap[#snap+1] = sub end     -- H-23 스냅샷
    for _, sub in ipairs(snap) do
        if isState(sub) then
            sub:_receive(from)
        elseif canExecute(sub) then
            sub.fn(sub._state, sub, from)   -- (리시버 State, Observer 자신, 출처) H-109
        end
    end
end
M.emitDown = emitDown

-- ── Source ─────────────────────────────────────────────────────────────
function M.Source(v)
    return setmetatable({_value = v, Revision = 0, _subs = weakK()}, Source)
end
function Source:Get() return self._value end
function Source:Set(v)                    -- H-68: 동일값도 항상 리비전 갱신 + emit
    self._value = v
    self.Revision = bit32.bnot(-self.Revision)
    emitDown(self, self)
    return self
end
function Source:Emit()
    self.Revision = bit32.bnot(-self.Revision)
    emitDown(self, self)
    return self
end
function Source:_track(map) map:Sync(self) end
function Source:_addSub(s) self._subs[s] = true end

-- ── State (Compute / With) — 캐시 카운터 쌍 (state-epoch-plan.md §4) ──
local function seedValueMap(self, deps)
    for _, d in ipairs(deps) do d:_addSub(self); d:_track(self.valueEpochMap) end
end
local function newNode(deps, fn)
    local self = setmetatable({
        fn = fn, _hold = deps, _subs = weakK(),
        valueEpochMap = M.EpochMap(), emitEpochMap = M.EpochMap(),
        cacheTargetCount = 0, cacheCurrCount = nil, cache = nil, recomputes = 0,
    }, State)
    seedValueMap(self, deps)
    return self
end
function M.Compute(deps, fn) return newNode(deps, fn) end
function State:_track(map) map:TrackFrom(self.valueEpochMap) end
function State:_addSub(s) self._subs[s] = true end
function State:_invalidate() self.cacheTargetCount = bit32.bnot(-self.cacheTargetCount) end
function State:_receive(from)
    local valueChanged = self.valueEpochMap:Update(from)
    local emitChanged  = self.emitEpochMap:Update(from)
    if valueChanged then self:_invalidate() end
    if valueChanged or emitChanged then emitDown(self, from) end
end
function State:_recompute()
    local target = self.cacheTargetCount
    self.recomputes += 1
    -- ⚠️ [전사 정정] `fn(self, previous?, ...deps)`의 `self`는 **리시버 State의 lazy 핸들**이지 결과 노드가
    --   아니다(source-state-plan.md "self 인자도 lazy 핸들로 통일"). 7·9라운드 전사물은 결과 노드를 넘겨
    --   `s:Get()`이 자기 자신을 재귀하게 돼 있었다(그쪽 테스트는 첫 인자를 안 써서 안 드러났다).
    self.cache = self.fn(self._hold[1], self.cache, table.unpack(self._hold, 2))
    self.cacheCurrCount = target
    for _, d in ipairs(self._hold) do d:_track(self.valueEpochMap) end
end
function State:Get()
    if self.cacheCurrCount ~= self.cacheTargetCount then
        self:_recompute()
    elseif self.valueEpochMap:Refresh() then   -- 순회: 값만 앞당기고 통지는 안 한다
        self:_invalidate()
        self:_recompute()
    end
    return self.cache
end
-- 파생 메소드(콜론) — Source/State/GateNode 공용
local function Compute(self, fn, ...)
    local deps = {self}
    for i = 1, select("#", ...) do deps[#deps+1] = (select(i, ...)) end
    return newNode(deps, fn)
end
local function With(self, ...)
    local deps = {self}
    for i = 1, select("#", ...) do deps[#deps+1] = (select(i, ...)) end
    return newNode(deps, function(s) return s:Get() end)   -- pass-through(값은 self 그대로)
end

-- ── Observer + 네 진입점 레지스트리 (lifecycle-pattern.md (2)) ──────────
local Subscribed     = {}
local WeakSubscribed = weakK()
M.Subscribed, M.WeakSubscribed = Subscribed, WeakSubscribed
local function newObserver(state, fn)
    fn = fn or function(targetState) targetState:Get() end   -- H-61
    local self = setmetatable({fn = fn, _state = state}, Observer)   -- H-110 강참조
    state:_addSub(self)
    fn(state, self, nil)          -- 등록 즉시 1회(설치 발화, emitFrom = nil)
    return self
end
function Observer:WeakSubscribe()
    if not canBound(self) then
        error(if self.Subscribed then "already subscribed" else "already bound to an Instance", 2)
    end
    self.Subscribed = true          -- H-111
    WeakSubscribed[self] = true
    return self
end
function Observer:WeakUnsubscribe()
    if Subscribed[self] ~= nil then error("subscribed strongly; use :Unsubscribe()", 2) end
    WeakSubscribed[self] = nil      -- 관대(H-133): 없어도 그냥 지나간다
    self.Subscribed = false
    return self
end
function Observer:Subscribe()
    self:WeakSubscribe()            -- ⚠️ 콜론 위임 그대로(H-149 판단 대기) — level 2가 이 줄을 가리킨다
    Subscribed[self] = true
    return self
end
function Observer:Unsubscribe()
    if Subscribed[self] == nil then error("not subscribed strongly; use :WeakUnsubscribe()", 2) end
    Subscribed[self] = nil
    return self:WeakUnsubscribe()
end

-- ── GateNode (gate-plan.md "GateNode 조립") ─────────────────────────────
function GateNode:_track(map) map:TrackFrom(self.valueEpochMap) end
function GateNode:_addSub(s) self._subs[s] = true end
function GateNode:_invalidate() self.cacheTargetCount = bit32.bnot(-self.cacheTargetCount) end
function GateNode:_flush(commit)
    if next(self._withheld) == nil then return false end   -- (1) 빈 배치 얼리리턴(8번)
    local batch = self._withheld
    self._withheld = weakK()                               -- (2) 새 weak 테이블(H-9)
    self.flushes += 1
    if commit == false then return true end                -- 버리기(H-55)
    self.emitEpochMap:Sync(batch)                          -- (3) 전파 앞
    emitDown(self, batch)                                  -- (4)
    return true
end
function GateNode:_receive(from)
    local valueChanged = self.valueEpochMap:Update(from)
    local emitChanged  = self.emitEpochMap:Peek(from)      -- Update가 아니라 Peek
    if valueChanged then self:_invalidate() end
    if not (valueChanged or emitChanged) then return end   -- 규칙 3
    for _, e in ipairs(unfold(from)) do self._withheld[e] = true end
    self.onUpstreamEmit()
end
function GateNode:Get()
    if self.cacheCurrCount ~= self.cacheTargetCount then
        local target = self.cacheTargetCount
        self.cache = self._hold[1]:Get(); self.cacheCurrCount = target
        self._hold[1]:_track(self.valueEpochMap)
    elseif self.valueEpochMap:Refresh() then
        self:_invalidate(); local target = self.cacheTargetCount
        self.cache = self._hold[1]:Get(); self.cacheCurrCount = target
        self._hold[1]:_track(self.valueEpochMap)
    end
    return self.cache
end
local function Gate(self, setup)
    local node = setmetatable({
        _hold = {self}, _subs = weakK(),
        valueEpochMap = M.EpochMap(), emitEpochMap = M.EpochMap(),
        cacheTargetCount = 0, cacheCurrCount = nil, cache = nil,
        _withheld = weakK(), flushes = 0,
    }, GateNode)
    self:_addSub(node); self:_track(node.valueEpochMap)
    node.onUpstreamEmit = setup(function(commit) return node:_flush(commit) end)
    return node
end

-- ── Blocker (blocker-plan.md + H-63) ────────────────────────────────────
local Blocker = {}; Blocker.__index = Blocker
function M.Blocker() return setmetatable({IsBlocked = false, handles = weakK()}, Blocker) end
function Blocker:IsOn() return self.IsBlocked end
function Blocker:On() self.IsBlocked = true; return self end
function Blocker:_run(emit)
    local snap = {}; for h in pairs(self.handles) do snap[#snap+1] = h end   -- H-63 (3) 스냅샷
    for _, h in ipairs(snap) do h(emit) end
end
function Blocker:Off() self.IsBlocked = false; self:_run(true); return self end
function Blocker:OffWithoutEmit() self.IsBlocked = false; self:_run(false); return self end
function Blocker:Policy(emit)               -- blocker:Policy(emit) -> onUpstreamEmit
    local function handle(doEmit)
        if doEmit then emit() else emit(false) end   -- OffWithoutEmit = 흡수 집합 버리기(H-55)
    end
    self.handles[handle] = true             -- H-63 (1) weak-키 셋
    return function()                       -- H-63 (2) 강한 주인 = 이 클로저(upvalue `handle`)
        if handle == nil then return end
        if not self.IsBlocked then emit() end
    end
end
local function Block(self, blocker)
    return Gate(self, function(emit) return blocker:Policy(emit) end)
end
for _, T in ipairs({Source, State, GateNode}) do
    T.Compute, T.With, T.Gate, T.Block, T.Observer = Compute, With, Gate, Block, newObserver
end
M.Gate = function(up, setup) return Gate(up, setup) end

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
            k(value, self)                               -- 값 + Ref 자신(= Epoch)
        end
    end
    return self
end

-- ── Effect (effect-plan.md 생성자 / 훅 / Rerun / 네 진입점) ───────────
M.effectTrace = nil   -- 스파이크가 함수를 넣으면 fire 가드 판정을 기록한다
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
    local function fire(from)                          -- 공통 본문
        if not canExecute(self) then
            if M.effectTrace then M.effectTrace(self, "drop:canExecute", from) end
            return
        end
        if self._blocker:IsOn() then
            if M.effectTrace then M.effectTrace(self, "drop:blocker", from) end
            return
        end
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
    self:Rerun()                                        -- (2) 설치 — 생성 즉시 1회
    return self
end
function EffectHandle:_bindDestroying(inst)
    self:_unbindDestroying()
    self._destroyConn = M.onDestroying(inst, function()
        self:_unbindDestroying()
        self:_consumeCleanup()
    end)
    local depsChanged = self._epochs:Refresh()          -- Refresh **먼저**
    if not self._installed or depsChanged then self:Rerun() end
end
function EffectHandle:_unbindDestroying()
    if self._destroyConn then self._destroyConn:Disconnect(); self._destroyConn = nil end
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
        local wasAlive = canExecute(self)
        local c = self.fn(self)
        if wasAlive and not canExecute(self) then          -- H-143: 이 실행 중에 죽었다
            if c then c() end
            self._pending = false
        else
            self._cleanup = c
            self._installed = true
        end
    until not self._pending
    self._running = false
end
-- 네 진입점 — EffectHandle 자기 것(H-144 (b)). 공유는 레지스트리 둘 + canBound뿐.
local function resubscribeTail(self)
    local depsChanged = self._epochs:Refresh()
    if not self._installed or depsChanged then self:Rerun() end
end
function EffectHandle:WeakSubscribe()
    if not canBound(self) then
        error(if self.Subscribed then "already subscribed" else "already bound to an Instance", 2)
    end
    self.Subscribed = true
    WeakSubscribed[self] = true
    resubscribeTail(self)
    return self
end
function EffectHandle:Subscribe()
    if not canBound(self) then
        error(if self.Subscribed then "already subscribed" else "already bound to an Instance", 2)
    end
    self.Subscribed = true
    WeakSubscribed[self] = true
    Subscribed[self] = true                    -- 강한 킵이 선 **뒤에** 꼬리
    resubscribeTail(self)
    return self
end
function EffectHandle:WeakUnsubscribe()        -- 관대(H-133) — cleanup 안 건드림
    if Subscribed[self] ~= nil then error("subscribed strongly; use :Unsubscribe()", 2) end
    WeakSubscribed[self] = nil
    self.Subscribed = false
    return self
end
function EffectHandle:Unsubscribe()
    if Subscribed[self] == nil then error("not subscribed strongly; use :WeakUnsubscribe()", 2) end
    Subscribed[self] = nil
    WeakSubscribed[self] = nil
    self.Subscribed = false
    self:_consumeCleanup()
    return self
end

-- 상태 스냅샷(스파이크용)
function M.effectState(e)
    return ("installed=%s cleanup=%s Subscribed=%s reg[S]=%s reg[W]=%s canExecute=%s running=%s pending=%s"):format(
        tostring(e._installed == true), tostring(e._cleanup ~= nil), tostring(e.Subscribed == true),
        tostring(Subscribed[e] ~= nil), tostring(WeakSubscribed[e] ~= nil), tostring(canExecute(e)),
        tostring(e._running == true), tostring(e._pending == true))
end

return M
