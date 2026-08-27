--!nocheck
-- 9라운드 참조 구현 — base/dispatch-core-plan.md(getOffsetAt / "두 필드" / 무효화 표 /
-- recompute(되감기·클램프·recomputeBlocker) / setLength(토큰·두 게이트) / setOffsetSource)
-- + base/slot-plan.md(materializeSlotTree의 _baseObserver·꼬리 게이트, unmountSlotTree,
-- rawAdd, rawRemove, spliceArraysUp/Down 요구 목록)을 옮긴 전사물.
-- 물리 op(native*)은 no-op이고, 요소는 {name=} 테이블(길이 1) 또는 Slot.
local q = require("./core9")
local D = {}
D.remountFix = "ctor"   -- "none" | "a"(materialize 진입부 0,0) | "c"(bind/blocker를 emit 위로)
local None = setmetatable({}, {__tostring = function() return "None" end})
D.None = None
local isState = q.isState
local function isSlot(x) return type(x) == "table" and x.__isSlot == true end
D.isSlot = isSlot

local books, blockers = {}, {}
local function getBookkeeping(ownerKey)
    local bk = books[ownerKey]
    if not bk then
        bk = { lengthList = {}, sourceList = {}, observers = {}, indexOfElement = {}, N = nil,
               offsetCache = {}, offsetCacheValidUpTo = 0, offsetSetUpTo = 0,
               recomputeBlocker = q.Blocker() }
        books[ownerKey] = bk
    end
    return bk
end
local function getBlocker(ownerKey)
    local b = blockers[ownerKey]
    if not b then b = q.Blocker(); blockers[ownerKey] = b end
    return b
end
D.getBookkeeping, D.getBlocker = getBookkeeping, getBlocker

local function contribution(bk, i)
    local v = bk.lengthList[i]
    return (if isState(v) then v:Get() else v)
end

function D.getOffsetAt(ownerKey, at)
    local bk = getBookkeeping(ownerKey)
    if bk.offsetCacheValidUpTo == 0 then
        bk.offsetCache[1] = if isSlot(ownerKey) then ownerKey.Offset:Get() else 0
        bk.offsetCacheValidUpTo = 1
    end
    if at <= bk.offsetCacheValidUpTo then
        return bk.offsetCache[at]
    end
    local cur = bk.offsetCache[bk.offsetCacheValidUpTo]
    for i = bk.offsetCacheValidUpTo, at - 1 do
        if bk.lengthList[i] == nil then
            error("Dispatch.getOffsetAt: lengthList[" .. i .. "]가 nil — 부기가 깨졌음")
        end
        cur += contribution(bk, i)
        bk.offsetCache[i + 1] = cur
    end
    bk.offsetCacheValidUpTo = at
    return cur
end

D.log = {}
local function recompute(ownerKey, bk)
    table.insert(D.log, "recompute(" .. tostring(ownerKey.name) .. ")")
    local sum = 0
    bk.recomputeBlocker:On()
    local prefix, i = {}, 1
    while i <= (bk.N or 0) do
        prefix[i] = sum
        local offset = bk.sourceList[i]
        if offset == nil then
            error("Dispatch.recompute: sourceList[" .. i .. "]가 nil — 부기가 깨졌음(계약상 None이어야 함)")
        end
        local abs = D.getOffsetAt(ownerKey, i)
        bk.offsetSetUpTo = i
        if offset ~= None and offset:Get() ~= abs then
            offset:Set(abs)                    -- ← 사용자 코드가 돌 수 있는 자리
        end
        -- [Q1 (a), 사용자 확정] 되감기 판정이 `lengthList[i]` 읽기보다 **앞**.
        --   되감으면 `sum`은 `prefix[i]`로 복원되므로 새로 만든 sum은 어차피 버려진다.
        if bk.offsetSetUpTo < i then
            i = math.max(bk.offsetSetUpTo, 1)
            sum = prefix[i]
            continue
        end
        local v = bk.lengthList[i]
        sum += (if isState(v) then v:Get() else v)
        i += 1
    end
    bk.offsetSetUpTo = bk.N or 0
    bk.recomputeBlocker:OffWithoutEmit()
    if isSlot(ownerKey) and ownerKey.Length:Get() ~= sum then
        ownerKey.Length:Set(sum)
    end
end
D.recompute = recompute

function D.setLength(ownerKey, i, len, anchor, element)   -- [Q3] 5번째 = 그 자리의 요소
    anchor = anchor or ownerKey
    local bk = getBookkeeping(ownerKey)
    local blocker = getBlocker(ownerKey)
    local oldObserver = bk.observers[i]
    if oldObserver then q.unbindLifetime(oldObserver); bk.observers[i] = nil end
    bk.lengthList[i] = len
    bk.N = math.max(bk.N or 0, i)
    if element ~= nil then bk.indexOfElement[element] = i end
    bk.offsetCacheValidUpTo = math.min(bk.offsetCacheValidUpTo, i)
    bk.offsetSetUpTo        = math.min(bk.offsetSetUpTo,        i)
    local function gatedRecompute()
        local cur = if element ~= nil then bk.indexOfElement[element] else i
        bk.offsetCacheValidUpTo = math.min(bk.offsetCacheValidUpTo, cur)
        bk.offsetSetUpTo        = math.min(bk.offsetSetUpTo,        cur)
        if blocker:IsOn() then return end
        if bk.recomputeBlocker:IsOn() then return end
        recompute(ownerKey, bk)
    end
    if isState(len) then
        local observer = len:Observer(gatedRecompute)   -- 등록 즉시 1회도 게이팅
        q.bindLifetime(anchor, observer)
        bk.observers[i] = observer
    else
        gatedRecompute()
    end
end

function D.setOffsetSource(ownerKey, i, source)
    local bk = getBookkeeping(ownerKey)
    bk.sourceList[i] = source
    if source == None then return end
    local offset = D.getOffsetAt(ownerKey, i)
    if source:Get() ~= offset then source:Set(offset) end
end

-- ── splice (slot-plan.md 요구 목록: lengthList/sourceList/observers/tokens/indexOfToken/N, 두 필드 index-1) ──
local function spliceArraysUp(self, index)
    local bk = getBookkeeping(self)
    local N = bk.N or 0
    for i = N, index, -1 do
        bk.lengthList[i + 1] = bk.lengthList[i]; bk.sourceList[i + 1] = bk.sourceList[i]
        bk.observers[i + 1]  = bk.observers[i]
    end
    bk.lengthList[index] = 0            -- H-5 자리표시자
    bk.sourceList[index] = None
    bk.observers[index]  = nil          -- [Q3] 비운 자리는 세 배열 전부
    bk.N = N + 1
    bk.offsetCacheValidUpTo = math.min(bk.offsetCacheValidUpTo, index - 1)
    bk.offsetSetUpTo        = math.min(bk.offsetSetUpTo,        index - 1)
end
local function spliceArraysDown(self, index)
    local bk = getBookkeeping(self)
    local N = bk.N
    for i = index, N - 1 do
        bk.lengthList[i] = bk.lengthList[i + 1]; bk.sourceList[i] = bk.sourceList[i + 1]
        bk.observers[i]  = bk.observers[i + 1]
    end
    bk.lengthList[N], bk.sourceList[N], bk.observers[N] = nil, nil, nil
    bk.N = N - 1
    bk.offsetCacheValidUpTo = math.min(bk.offsetCacheValidUpTo, index - 1)
    bk.offsetSetUpTo        = math.min(bk.offsetSetUpTo,        index - 1)
end
D.spliceArraysUp, D.spliceArraysDown = spliceArraysUp, spliceArraysDown

-- ── Slot 최소형 ──────────────────────────────────────────────────────────
local makeBaseObserver
function D.newSlot(name, elements)
    local slot = { __isSlot = true, name = name, _elements = elements or {},
                   Length = q.Source(0), Offset = nil, _physicalTarget = nil, _mounted = false }
    if D.remountFix == "ctor" then
        -- Length와 **같은 자리**에서 Offset을 만든다(공개 필드 대칭).
        slot.Offset = q.Source(0)
        slot._baseObserver = makeBaseObserver(slot)   -- 등록 즉시 1회는 아래 가드가 삼킨다
    end
    return slot
end

local materializeSlotTree, unmountSlotTree
makeBaseObserver = function(slot)
    return slot.Offset:Observer(function()
        -- ⭐ 미실체화면 할 일이 없다 — 생성자에서 만들 때의 "등록 즉시 1회"를 여기서 삼킨다
        --   (그래야 bk/recomputeBlocker가 eager 생성되지 않는다).
        if slot._physicalTarget == nil then return end
        local bk = getBookkeeping(slot)
        bk.offsetCacheValidUpTo, bk.offsetSetUpTo = 0, 0
        table.insert(D.log, "baseObs(" .. tostring(slot.name) .. ")")
        if getBlocker(slot):IsOn() or bk.recomputeBlocker:IsOn() then return end
        recompute(slot, bk)
    end)
end

materializeSlotTree = function(slot, physicalTarget, ownerKey, position)
    slot._physicalTarget = physicalTarget
    local offsetSource = slot.Offset or q.Source(0)
    slot.Offset = offsetSource
    local blocker = getBlocker(slot)
    local function installBase()
        if slot._baseObserver then
            q.bindLifetime(physicalTarget, slot._baseObserver)
        else
            slot._baseObserver = makeBaseObserver(slot)
            q.bindLifetime(physicalTarget, slot._baseObserver)
        end
    end
    if D.remountFix == "ctor" then
        -- 분기 없음 — 관측자는 이미 있다. 게이트 → 바인드 → emit.
        blocker:On()
        q.bindLifetime(physicalTarget, slot._baseObserver)
        D.setOffsetSource(ownerKey, position, offsetSource)
    elseif D.remountFix == "c" then
        blocker:On()          -- (c): 게이트와 관측자를 emit **위로**
        installBase()
        D.setOffsetSource(ownerKey, position, offsetSource)
    else
        if D.remountFix == "a" then     -- (a): 진입부 명시 초기화
            local bk0 = getBookkeeping(slot)
            bk0.offsetCacheValidUpTo, bk0.offsetSetUpTo = 0, 0
        end
        D.setOffsetSource(ownerKey, position, offsetSource)
        blocker:On()
        installBase()
    end
    for i, element in ipairs(slot._elements) do
        if isSlot(element) then
            materializeSlotTree(element, physicalTarget, slot, i)
        else
            D.setOffsetSource(slot, i, None)
            D.setLength(slot, i, 1, physicalTarget, element)
        end
    end
    blocker:OffWithoutEmit()
    local bk = getBookkeeping(slot)
    if not bk.recomputeBlocker:IsOn() then recompute(slot, bk) end
    D.setLength(ownerKey, position, slot.Length, physicalTarget, slot)
end
D.materializeSlotTree = materializeSlotTree

unmountSlotTree = function(slot)
    for i = #slot._elements, 1, -1 do
        local element = slot._elements[i]
        if isSlot(element) then unmountSlotTree(element) end
    end
    local bk = getBookkeeping(slot)
    for _, observer in pairs(bk.observers) do q.unbindLifetime(observer) end
    if slot._baseObserver then q.unbindLifetime(slot._baseObserver) end
    slot._mounted, slot._mountedInst, slot._physicalTarget = false, nil, nil
end
D.unmountSlotTree = unmountSlotTree

-- 요소 소유권/래핑은 생략(트레이스 대상 아님)
local function reindexFrom(self, from)
    local bk = getBookkeeping(self)
    for i = from, #self._elements do bk.indexOfElement[self._elements[i]] = i end
end
function D.rawAdd(self, element, index)
    index = index or (#self._elements + 1)
    table.insert(self._elements, index, element)
    reindexFrom(self, index)
    if self._physicalTarget == nil then return index end
    spliceArraysUp(self, index)
    if isSlot(element) then
        materializeSlotTree(element, self._physicalTarget, self, index)
    else
        D.setOffsetSource(self, index, None)
        D.setLength(self, index, 1, self._physicalTarget, element)
    end
    return index
end

function D.rawRemove(self, index)
    local element = self._elements[index]
    local bk = getBookkeeping(self)
    if bk.observers[index] then q.unbindLifetime(bk.observers[index]) end
    if isSlot(element) then unmountSlotTree(element) end   -- (파괴 대신 언마운트로 흉내)
    table.remove(self._elements, index)
    bk.indexOfElement[element] = nil
    reindexFrom(self, index)
    spliceArraysDown(self, index)
    if not (getBlocker(self):IsOn() or bk.recomputeBlocker:IsOn()) then
        recompute(self, bk)
    end
end

-- 최상위 mount: inst를 owner로, slot을 position 1에
function D.mountTop(inst, slot)
    local bl = getBlocker(inst); bl:On()
    materializeSlotTree(slot, inst, inst, 1)
    bl:OffWithoutEmit()
    local bk = getBookkeeping(inst)
    if not bk.recomputeBlocker:IsOn() then recompute(inst, bk) end
end

return D
