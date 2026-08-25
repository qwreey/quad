--!nocheck
-- 문서(base/state-epoch-plan.md §2~§5, base/source-state-plan.md 전파 모델,
-- base/gate-plan.md 4/8번, base/blocker-plan.md)를 그대로 옮긴 참조 구현.
-- 방어 코드(pcall 등)는 문서에 없으므로 넣지 않는다.

local M = {}

local function newWeakK() return setmetatable({}, {__mode = "k"}) end

-- ── EpochMap ────────────────────────────────────────────────────────────
local EpochMap = {}
EpochMap.__index = EpochMap
function M.EpochMap()
    return setmetatable({map = newWeakK()}, EpochMap)
end
local function unfold(from)
    -- Epoch 하나면 {from}, EpochSet이면 그 키들
    if from.Revision ~= nil then return {from} end
    local t = {}
    for e in from do t[#t+1] = e end
    return t
end
M.unfold = unfold
function EpochMap:Update(from)
    local changed = false
    for _, e in unfold(from) do
        if self.map[e] ~= e.Revision then
            changed = true
            self.map[e] = e.Revision
        end
    end
    return changed
end
function EpochMap:Sync(from)
    for _, e in unfold(from) do self.map[e] = e.Revision end
end
function EpochMap:Refresh()
    local changed = false
    for e, rev in self.map do
        if e.Revision ~= rev then changed = true; self.map[e] = e.Revision end
    end
    return changed
end
function EpochMap:TrackFrom(other)
    for e in other.map do self.map[e] = e.Revision end
end
-- 문서에 없는 연산(H-72). 게이트 판정용으로만 쓰고, 쓸 때마다 표시한다.
function EpochMap:PeekDiffers(from)
    for _, e in unfold(from) do
        if self.map[e] ~= e.Revision then return true end
    end
    return false
end

-- ── 전파 ────────────────────────────────────────────────────────────────
local function emitDown(node, from)
    -- H-23 확정: 구독자 집합을 배열로 스냅샷한 뒤 돈다
    local snapshot = {}
    for sub in node.subs do snapshot[#snapshot+1] = sub end
    for _, sub in snapshot do
        sub:_receive(from)
    end
end
M.emitDown = emitDown

-- ── Source ──────────────────────────────────────────────────────────────
local Source = {}
Source.__index = Source
function M.Source(v)
    return setmetatable({value = v, Revision = 0, subs = newWeakK()}, Source)
end
function Source:Get() return self.value end
function Source:Set(v)
    self.value = v
    self.Revision = bit32.bnot(-self.Revision)
    emitDown(self, self)
end
function Source:_track(map) map:Sync(self) end
function Source:_addSub(s) self.subs[s] = true end

-- ── State(Compute/With) ─────────────────────────────────────────────────
local State = {}
State.__index = State
function M.State(fn, deps, name)
    local self = setmetatable({
        fn = fn, deps = deps, name = name,
        valueEpochMap = M.EpochMap(), emitEpochMap = M.EpochMap(),
        rawInvalid = true, cache = nil, subs = newWeakK(),
        recomputes = 0,
    }, State)
    for _, d in deps do
        d:_addSub(self)
        d:_track(self.valueEpochMap)   -- Source면 Sync, State면 TrackFrom
    end
    return self
end
function State:_track(map) map:TrackFrom(self.valueEpochMap) end
function State:_addSub(s) self.subs[s] = true end
function State:_receive(from)
    local valueChanged = self.valueEpochMap:Update(from)
    local emitChanged  = self.emitEpochMap:Update(from)
    if valueChanged then self.rawInvalid = true end
    if valueChanged or emitChanged then emitDown(self, from) end
end
function State:_recompute()
    self.recomputes += 1
    self.cache = self.fn(self, self.cache, table.unpack(self.deps))
    self.rawInvalid = false
    for _, d in self.deps do d:_track(self.valueEpochMap) end
end
function State:Get()
    if self.rawInvalid then
        self:_recompute()
    elseif self.valueEpochMap:Refresh() then
        self.rawInvalid = true
        self:_recompute()
    end
    return self.cache
end

-- ── Observer(leaf) ──────────────────────────────────────────────────────
local Observer = {}
Observer.__index = Observer
function M.Observer(state, fn, name)
    local self = setmetatable({fn = fn, name = name, fires = 0}, Observer)
    state:_addSub(self)
    self.owner = state
    return self
end
function Observer:_receive(from)
    self.fires += 1
    self.fn(self, from)
end

-- ── GateNode ────────────────────────────────────────────────────────────
local GateNode = {}
GateNode.__index = GateNode
function M.Gate(upstream, setup, name)
    local self = setmetatable({
        up = upstream, name = name,
        valueEpochMap = M.EpochMap(), emitEpochMap = M.EpochMap(),
        rawInvalid = true, cache = nil, subs = newWeakK(),
        withheld = newWeakK(), flushes = 0,
    }, GateNode)
    upstream:_addSub(self)
    upstream:_track(self.valueEpochMap)
    local function emit() self:_flush() end
    self.onUpstreamEmit = setup(emit)
    return self
end
function GateNode:_track(map) map:TrackFrom(self.valueEpochMap) end
function GateNode:_addSub(s) self.subs[s] = true end
function GateNode:_flush()
    if next(self.withheld) == nil then return end   -- 8번: 빈 배치는 아무것도 안 함
    local batch = self.withheld
    self.withheld = newWeakK()                      -- 진입 시 스왑(H-9)
    self.flushes += 1
    self.emitEpochMap:Sync(batch)                   -- 전파할 때 갱신(§4 예외)
    emitDown(self, batch)
end
function GateNode:_discard()                        -- OffWithoutEmit 경로
    self.withheld = newWeakK()
end
function GateNode:_receive(from)
    -- 규칙 1~3을 먼저. 게이트는 emitEpochMap을 수신 시점에 갱신하지 않으므로
    -- 비교만 하는 연산이 필요하다(H-72) — PeekDiffers로 대신한다.
    local valueChanged = self.valueEpochMap:Update(from)
    local emitDiffers  = self.emitEpochMap:PeekDiffers(from)
    if valueChanged then self.rawInvalid = true end
    if not (valueChanged or emitDiffers) then return end   -- 규칙 3: 삼킴
    for _, e in unfold(from) do self.withheld[e] = true end
    self.onUpstreamEmit()
end
function GateNode:Get()
    if self.rawInvalid then
        self.cache = self.up:Get()
        self.rawInvalid = false
        self.up:_track(self.valueEpochMap)
    elseif self.valueEpochMap:Refresh() then
        self.cache = self.up:Get()
        self.up:_track(self.valueEpochMap)
    end
    return self.cache
end

-- ── Blocker ─────────────────────────────────────────────────────────────
local Blocker = {}
Blocker.__index = Blocker
function M.Blocker()
    return setmetatable({IsBlocked = false, handles = {}}, Blocker)
end
function Blocker:IsOn() return self.IsBlocked end
function Blocker:On() self.IsBlocked = true; return self end
function Blocker:_run(emit)
    for _, h in self.handles do h(emit) end
end
function Blocker:Off() self.IsBlocked = false; self:_run(true); return self end
function Blocker:OffWithoutEmit() self.IsBlocked = false; self:_run(false); return self end
-- blocker:Policy(emit) -> onUpstreamEmit
function Blocker:Policy(emit, discard)
    table.insert(self.handles, function(doEmit)
        if doEmit then emit() else (discard or function() end)() end
    end)
    return function()
        if not self.IsBlocked then emit() end
    end
end

return M
