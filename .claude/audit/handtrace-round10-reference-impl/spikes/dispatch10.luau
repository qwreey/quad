--!nocheck
-- 10라운드 참조 구현 — 9라운드 전사물 `dispatch9.luau`(같은 폴더 보존)를 HEAD `0ec22fb`
-- 계약으로 갱신한 것. 옮긴 원문:
--   · dispatch-core-plan.md — getBookkeeping 초기화 열거(`indexOfElement` **weak-key**, H-145),
--       getOffsetAt / 두 필드 / 무효화 표 / recompute(H-124 `continue` 순서, 클램프, recomputeBlocker) /
--       setLength(5번째 `element`, 요소 캡처 조회) / setOffsetSource / 배치 게이팅
--   · slot-plan.md — Slot 생성자(Length·Offset·_baseObserver·_destroyed, Q2), makeBaseObserver,
--       materializeSlotTree(게이트→바인드→setOffsetSource 순서) / mountSlotTree / attachSlot,
--       unmountSlotTree / destroySlotTree(핸들 보존, `_destroyed`), rawAdd / rawReplace / rawRemove /
--       rawUnmount / rawDetach, spliceArraysUp/Down(세 배열 비우기, `index-1`), reindexFrom,
--       `H-29` 규약대로 쓴 rawMove(의사코드가 없는 함수 — **규약을 옮긴 것**이라 여기 결함은
--       규약 자체의 결함일 때만 발견이다), activateList/reconcile(`H-136` `ownsGate` 배치).
--   · 최상위 `SlotHandler.process`의 마운트/retractor(설치·해제 `setLength(inst,k,0)`) 흉내 — `H-145`.
-- 물리 op(native*)은 no-op 기록이고, 요소는 `{name=}` 테이블(길이 1) 또는 Slot.
-- ⚠️ Instance를 weak-key로 쓰는 경로는 흉내낼 수 없다 — 요소가 테이블이라 weak-key 자체는 동작하지만
--    Roblox Instance userdata의 weak-key 거동(`audit/gcconn-trick-verification.md` 미확인)은 별개다.
local q = require("./core10")
local D = {}
local None = setmetatable({}, {__tostring = function() return "None" end})
D.None = None
local Detach, KeyGone = setmetatable({}, {__tostring = function() return "Detach" end}),
                        setmetatable({}, {__tostring = function() return "KeyGone" end})
D.Detach, D.KeyGone = Detach, KeyGone
local isState = q.isState
local function isSlot(x) return type(x) == "table" and x.__isSlot == true end
D.isSlot = isSlot
local function weakK() return setmetatable({}, {__mode = "k"}) end

D.native = {}   -- 물리 op 기록
local function nativeLog(op, target, offset, elements, extra)
    local names = {}
    for _, e in ipairs(elements or {}) do names[#names+1] = tostring(e.name) end
    D.native[#D.native+1] = ("%s(%s@%s:[%s]%s)"):format(op, tostring(target.name), tostring(offset),
        table.concat(names, ","), if extra then "→" .. tostring(extra.name) else "")
end
local function nativeInsert(t, off, els) nativeLog("insert", t, off, els) end
local function nativeExtract(t, off, els, new) nativeLog("extract", t, off, els, new and new[1]) end
local function nativeRemove(t, off, els, new) nativeLog("remove", t, off, els, new and new[1]) end
local function nativeMove(t, from, els, to) nativeLog("move", t, from .. "→" .. to, els) end
local function nativeDispose(e) D.native[#D.native+1] = "dispose(" .. tostring(e.name) .. ")" end

-- ── 부기 (dispatch-core-plan.md "저장 위치") ─────────────────────────────
local books, blockers = weakK(), weakK()
local function getBookkeeping(ownerKey)
    local bk = books[ownerKey]
    if not bk then
        bk = { lengthList = {}, sourceList = {}, observers = {}, N = nil,
               offsetCache = {}, offsetCacheValidUpTo = 0, offsetSetUpTo = 0,
               recomputeBlocker = q.Blocker(),
               indexOfElement = weakK() }            -- H-145 weak-key
        books[ownerKey] = bk
    end
    return bk
end
local function getBlocker(ownerKey)
    local b = blockers[ownerKey]
    if not b then b = q.Blocker(); blockers[ownerKey] = b end
    return b
end
D.getBookkeeping, D.getBlocker, D.books = getBookkeeping, getBlocker, books

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
            error("Dispatch.getOffsetAt: lengthList[" .. i .. "] is nil — bookkeeping is broken", 1)
        end
        cur += contribution(bk, i)
        bk.offsetCache[i + 1] = cur
    end
    bk.offsetCacheValidUpTo = at
    return cur
end

D.log = {}
D.recomputes = 0
local function recompute(ownerKey, bk)
    D.recomputes += 1
    table.insert(D.log, "recompute(" .. tostring(ownerKey.name) .. ")")
    local sum = 0
    bk.recomputeBlocker:On()
    local prefix, i = {}, 1
    while i <= (bk.N or 0) do
        prefix[i] = sum
        local offset = bk.sourceList[i]
        if offset == nil then
            error("Dispatch.recompute: sourceList[" .. i .. "] is nil — bookkeeping is broken", 1)
        end
        local abs = D.getOffsetAt(ownerKey, i)
        bk.offsetSetUpTo = i
        if offset ~= None and offset:Get() ~= abs then
            offset:Set(abs)
        end
        if bk.offsetSetUpTo < i then          -- H-124: 되감기 판정이 읽기보다 먼저
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

function D.setLength(ownerKey, i, len, anchor, element)
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
        local observer = len:Observer(gatedRecompute)
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

-- ── splice / reindex (slot-plan.md 요구 목록) ────────────────────────────
local function reindexFrom(self, from)
    local bk = getBookkeeping(self)
    for i = from, #self._elements do bk.indexOfElement[self._elements[i]] = i end
end
local function spliceArraysUp(self, index)
    local bk = getBookkeeping(self)
    local N = bk.N or 0
    for i = N, index, -1 do
        bk.lengthList[i + 1] = bk.lengthList[i]; bk.sourceList[i + 1] = bk.sourceList[i]
        bk.observers[i + 1]  = bk.observers[i]
    end
    bk.lengthList[index] = 0            -- H-5 자리표시자
    bk.sourceList[index] = None
    bk.observers[index]  = nil          -- Q3: 비운 자리는 세 배열 전부
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
D.spliceArraysUp, D.spliceArraysDown, D.reindexFrom = spliceArraysUp, spliceArraysDown, reindexFrom

-- ── 소유권 (slot-plan.md "요소 소유권") — 최소형 ─────────────────────────
local elementOwner = setmetatable({}, {__mode = "kv"})   -- slot-plan.md: elementOwner는 전부 SetWeak(값도 weak) — 값이 키(요소)를 되참조하므로 강하면 샌다(H-71)
local function claimOwner(element, slot, fromDetached)
    local cur = elementOwner[element]
    if cur ~= nil and cur ~= slot then error("Slot: element already mounted elsewhere", 2) end
    if cur == slot and not fromDetached then error("Slot: element already in this Slot", 2) end
    elementOwner[element] = slot
end
local function releaseOwner(element, slot)
    if elementOwner[element] == slot then elementOwner[element] = nil end
end

-- ── Slot 값 타입 (Q2 생성자) ─────────────────────────────────────────────
local makeBaseObserver, materializeSlotTree, mountSlotTree, attachSlot, unmountSlotTree, destroySlotTree
local rawAdd, rawRemove, rawUnmount, rawDetach, rawReplace, rawMove

function D.newSlot(name, elements)
    local slot = { __isSlot = true, name = name, _elements = {},
                   Length = q.Source(0), Offset = q.Source(0),
                   _physicalTarget = nil, _mounted = false, _mountedInst = nil }
    slot._baseObserver = makeBaseObserver(slot)    -- 등록 즉시 1회는 가드가 삼킨다
    for _, e in ipairs(elements or {}) do rawAdd(slot, e) end
    return slot
end

makeBaseObserver = function(slot)
    return slot.Offset:Observer(function()
        if slot._physicalTarget == nil then return end
        local bk = getBookkeeping(slot)
        bk.offsetCacheValidUpTo, bk.offsetSetUpTo = 0, 0
        table.insert(D.log, "baseObs(" .. tostring(slot.name) .. ")")
        if getBlocker(slot):IsOn() or bk.recomputeBlocker:IsOn() then return end
        recompute(slot, bk)
    end)
end

local activateList
materializeSlotTree = function(slot, physicalTarget, ownerKey, position)
    if slot._destroyed then error("Slot: destroyed Slot cannot be mounted", 2) end
    slot._physicalTarget = physicalTarget
    local blocker = getBlocker(slot)
    blocker:On()
    q.bindLifetime(physicalTarget, slot._baseObserver)
    D.setOffsetSource(ownerKey, position, slot.Offset)
    if slot._listed and not slot._listActivated then
        activateList(slot, physicalTarget)
    else
        if slot._listed then activateList(slot, physicalTarget) end
        for i, element in ipairs(slot._elements) do
            if isSlot(element) then
                materializeSlotTree(element, physicalTarget, slot, i)
            else
                D.setOffsetSource(slot, i, None)
                D.setLength(slot, i, 1, physicalTarget, element)
            end
        end
    end
    blocker:OffWithoutEmit()
    local bk = getBookkeeping(slot)
    if not bk.recomputeBlocker:IsOn() then recompute(slot, bk) end
    D.setLength(ownerKey, position, slot.Length, physicalTarget, slot)
end
mountSlotTree = function(slot, physicalTarget)
    slot._mounted = true
    slot._mountedInst = physicalTarget
    local acc = slot.Offset:Get()
    for _, element in ipairs(slot._elements) do
        if isSlot(element) then
            mountSlotTree(element, physicalTarget); acc += element.Length:Get()
        else
            nativeInsert(physicalTarget, acc, { element }); acc += 1
        end
    end
end
attachSlot = function(slot, physicalTarget, ownerKey, position, mount)
    materializeSlotTree(slot, physicalTarget, ownerKey, position)
    if mount ~= false then mountSlotTree(slot, physicalTarget) end
end
D.materializeSlotTree, D.mountSlotTree, D.attachSlot = materializeSlotTree, mountSlotTree, attachSlot

unmountSlotTree = function(slot)
    local physicalTarget = slot._mountedInst
    for i = #slot._elements, 1, -1 do
        local element = slot._elements[i]
        if isSlot(element) then unmountSlotTree(element)
        elseif physicalTarget then nativeExtract(physicalTarget, D.getOffsetAt(slot, i), { element }) end
    end
    local bk = getBookkeeping(slot)
    for _, observer in pairs(bk.observers) do q.unbindLifetime(observer) end
    if slot._listObserver then q.unbindLifetime(slot._listObserver) end
    if slot._detachCleanup then q.unbindLifetime(slot._detachCleanup) end
    q.unbindLifetime(slot._baseObserver)
    slot._mounted, slot._mountedInst = false, nil
    slot._physicalTarget = nil
end
destroySlotTree = function(slot)
    if slot._destroyed then return end
    if slot._owned == false then unmountSlotTree(slot); return end
    for _, element in ipairs(slot._elements) do
        if isSlot(element) then destroySlotTree(element) else nativeDispose(element) end
    end
    if slot._detached then
        for key, element in pairs(slot._detached) do
            if isSlot(element) then destroySlotTree(element) else nativeDispose(element) end
            slot._detached[key] = nil
        end
    end
    if slot._detachCleanup then q.unbindLifetime(slot._detachCleanup); slot._detachCleanup = nil end
    if slot._listObserver then q.unbindLifetime(slot._listObserver) end
    q.unbindLifetime(slot._baseObserver)
    local bk = getBookkeeping(slot)
    for _, observer in pairs(bk.observers) do q.unbindLifetime(observer) end
    slot._mounted, slot._mountedInst = false, nil
    slot._physicalTarget = nil
    slot._destroyed = true
end
D.unmountSlotTree, D.destroySlotTree = unmountSlotTree, destroySlotTree

-- ── raw* ──────────────────────────────────────────────────────────────────
rawAdd = function(self, element, index, fromDetached)
    claimOwner(element, self, fromDetached)
    index = index or (#self._elements + 1)
    table.insert(self._elements, index, element)
    reindexFrom(self, index)
    if self._physicalTarget == nil then return index end
    spliceArraysUp(self, index)
    if isSlot(element) then
        attachSlot(element, self._physicalTarget, self, index, self._mounted)
    else
        D.setOffsetSource(self, index, None)
        if self._mounted then nativeInsert(self._mountedInst, D.getOffsetAt(self, index), { element }) end
        D.setLength(self, index, 1, self._physicalTarget, element)
    end
    return index
end
rawReplace = function(self, index, newElement, destroyOld)
    local oldElement = self._elements[index]
    claimOwner(newElement, self)
    releaseOwner(oldElement, self)
    self._elements[index] = newElement
    local bk0 = getBookkeeping(self)
    bk0.indexOfElement[oldElement] = nil
    bk0.indexOfElement[newElement] = index
    if not self._mounted then
        if destroyOld then
            if isSlot(oldElement) then destroySlotTree(oldElement) else nativeDispose(oldElement) end
        end
        if self._physicalTarget ~= nil then
            if isSlot(newElement) then attachSlot(newElement, self._physicalTarget, self, index, false)
            else
                D.setOffsetSource(self, index, None)
                D.setLength(self, index, 1, self._physicalTarget, newElement)
            end
        end
        return
    end
    local offset = D.getOffsetAt(self, index)
    if isSlot(oldElement) or isSlot(newElement) then
        if isSlot(oldElement) then
            if destroyOld then destroySlotTree(oldElement) else unmountSlotTree(oldElement) end
        else
            (if destroyOld then nativeRemove else nativeExtract)(self._mountedInst, offset, { oldElement })
        end
        if isSlot(newElement) then
            attachSlot(newElement, self._physicalTarget, self, index, self._mounted); return
        end
        D.setOffsetSource(self, index, None)
        nativeInsert(self._mountedInst, offset, { newElement })
    else
        (if destroyOld then nativeRemove else nativeExtract)(self._mountedInst, offset, { oldElement }, { newElement })
    end
    D.setLength(self, index, 1, self._physicalTarget, newElement)
end
local function removeLike(self, index, mode)   -- mode: "remove" | "unmount" | "detach"
    local element = self._elements[index]
    local bk = getBookkeeping(self)
    if bk.observers[index] then q.unbindLifetime(bk.observers[index]) end
    if mode ~= "detach" then releaseOwner(element, self) end
    if isSlot(element) then
        if mode == "remove" then destroySlotTree(element) else unmountSlotTree(element) end
    elseif self._mounted then
        if mode == "remove" then nativeRemove(self._mountedInst, D.getOffsetAt(self, index), { element })
        else nativeExtract(self._mountedInst, D.getOffsetAt(self, index), { element }) end
    elseif mode == "remove" then
        nativeDispose(element)
    end
    table.remove(self._elements, index)
    bk.indexOfElement[element] = nil
    reindexFrom(self, index)
    if self._physicalTarget ~= nil then
        spliceArraysDown(self, index)
        if not (getBlocker(self):IsOn() or bk.recomputeBlocker:IsOn()) then recompute(self, bk) end
    end
end
rawRemove  = function(self, index) removeLike(self, index, "remove") end
rawUnmount = function(self, index) removeLike(self, index, "unmount") end
rawDetach  = function(self, index) removeLike(self, index, "detach") end
-- rawMove — `H-29` 규약 1~6을 옮긴 것(의사코드 없음). 치환: _elements/indexOfElement/lengthList/
-- sourceList/observers 같은 순열, N 불변, 두 필드 minPos-1, 이동 구간 setLength 재등록, 물리는 _mounted로.
rawMove = function(self, from, to)
    if from == to then return end
    local bk = getBookkeeping(self)
    local element = table.remove(self._elements, from)
    table.insert(self._elements, to, element)
    reindexFrom(self, math.min(from, to))
    if self._physicalTarget == nil then return end
    local function permute(t)
        local v = table.remove(t, from); table.insert(t, to, v)
    end
    -- observers 배열은 구멍이 있을 수 있어 table.remove가 안 맞는다 — 수동 순열
    local newObs = {}
    for i = 1, bk.N do newObs[i] = bk.observers[i] end
    local mv = newObs[from]; table.remove(newObs, from); table.insert(newObs, to, mv)
    for i = 1, bk.N do bk.observers[i] = newObs[i] end
    permute(bk.lengthList); permute(bk.sourceList)
    local minPos = math.min(from, to)
    bk.offsetCacheValidUpTo = math.min(bk.offsetCacheValidUpTo, minPos - 1)
    bk.offsetSetUpTo        = math.min(bk.offsetSetUpTo,        minPos - 1)
    if self._mounted then
        local leaves = {}
        local function collect(e) if isSlot(e) then for _, c in ipairs(e._elements) do collect(c) end else leaves[#leaves+1] = e end end
        collect(element)
        nativeMove(self._mountedInst, from, leaves, to)
    end
    for p = minPos, math.max(from, to) do            -- 규약 4: 이동 구간 setLength 재등록
        D.setLength(self, p, bk.lengthList[p], self._physicalTarget, self._elements[p])
    end
end
D.rawAdd, D.rawRemove, D.rawUnmount, D.rawDetach, D.rawReplace, D.rawMove =
    rawAdd, rawRemove, rawUnmount, rawDetach, rawReplace, rawMove

-- ── :List / activateList / reconcile (slot-plan.md "구현", H-136 배치) ───
local function indexOfRaw(self, element) return getBookkeeping(self).indexOfElement[element] end
function D.List(slot, data, updateFn, keyFn)
    slot._listed = true
    slot._listData, slot._updateFn = data, updateFn
    slot._keyFn = keyFn or function(_, i) return i end
    if slot._physicalTarget then
        local blocker = getBlocker(slot); blocker:On()
        activateList(slot, slot._physicalTarget)
        blocker:OffWithoutEmit()
        local bk = getBookkeeping(slot)
        if not bk.recomputeBlocker:IsOn() then recompute(slot, bk) end
    end
    return slot
end
activateList = function(self, physicalTarget)
    if self._listActivated then
        if self._listObserver then q.bindLifetime(physicalTarget, self._listObserver) end
        q.bindLifetime(physicalTarget, self._detachCleanup)
        return
    end
    self._listActivated = true
    local keyFn, updateFn = self._keyFn, self._updateFn
    local offset = self.Offset
    local mounted, userdata, prevKeys = {}, {}, {}
    local function settle(key, result, detach, slotPos)
        local wasMounted = mounted[key]
        local detached = self._detached
        local wasDetached = detached and detached[key]
        local prev = wasMounted or wasDetached
        if detach then
            if wasMounted ~= nil then
                local idx = indexOfRaw(self, wasMounted)
                rawDetach(self, idx)
                self._detached = self._detached or {}
                self._detached[key], mounted[key] = wasMounted, nil
            end
        elseif result == nil then
            if prev ~= nil then
                if wasDetached ~= nil then
                    if isSlot(prev) then destroySlotTree(prev) else nativeDispose(prev) end
                else
                    rawRemove(self, indexOfRaw(self, wasMounted))
                end
            end
            mounted[key] = nil
            if detached then detached[key] = nil end
        elseif result == prev then
            if wasDetached ~= nil then
                detached[key] = nil
                rawAdd(self, prev, slotPos, true)
                mounted[key] = prev
            else
                local idx = indexOfRaw(self, wasMounted)
                if idx ~= slotPos then rawMove(self, idx, slotPos) end
            end
        else
            local element = result
            if wasDetached ~= nil then
                if isSlot(prev) then destroySlotTree(prev) else nativeDispose(prev) end
                detached[key] = nil
                rawAdd(self, element, slotPos)
            elseif wasMounted ~= nil then
                local idx = indexOfRaw(self, wasMounted)
                rawReplace(self, idx, element, true)
                if idx ~= slotPos then rawMove(self, idx, slotPos) end
            else
                rawAdd(self, element, slotPos)
            end
            mounted[key] = element
        end
    end
    local function reconcile(items)
        local keys, seen = {}, {}
        for i, item in ipairs(items) do
            local key = keyFn(item, i)
            if seen[key] then error("Slot:List — duplicate key: " .. tostring(key)) end
            seen[key] = true; keys[i] = key
        end
        local blocker = getBlocker(self)
        local ownsGate = not blocker:IsOn()
        if ownsGate then blocker:On() end
        local slotPos = 0
        for i, item in ipairs(items) do
            local key = keys[i]
            local prev = mounted[key] or (self._detached and self._detached[key])
            local candidateSlot = slotPos + 1
            local physIndex = D.getOffsetAt(self, candidateSlot) - offset:Get() + 1
            local result, ud = updateFn(item, physIndex, offset, prev, userdata[key])
            if result == None then result = nil end
            local detach = (result == Detach)
            if detach then result = nil end
            if result ~= nil then slotPos = candidateSlot end
            prevKeys[key] = true
            settle(key, result, detach, slotPos)
            userdata[key] = ud
        end
        for key in pairs(table.clone(prevKeys)) do
            if not seen[key] then
                local prev = mounted[key] or (self._detached and self._detached[key])
                local result, ud = updateFn(KeyGone, 0, offset, prev, userdata[key])
                if result == None then result = nil end
                local detach = (result == Detach)
                if detach then result = nil end
                if result ~= nil then error("Slot:List — KeyGone accepts only nil/None or Detach") end
                settle(key, result, detach, 0)
                userdata[key] = ud
                prevKeys[key] = nil
            end
        end
        if ownsGate then
            blocker:OffWithoutEmit()
            local bk = getBookkeeping(self)
            if not bk.recomputeBlocker:IsOn() then recompute(self, bk) end
        end
    end
    self._detachCleanup = q.Effect(function()
        return function()
            if not self._detached then return end
            for key, element in pairs(self._detached) do
                releaseOwner(element, self)
                if isSlot(element) then destroySlotTree(element) else nativeDispose(element) end
                self._detached[key] = nil
            end
        end
    end)
    q.bindLifetime(physicalTarget, self._detachCleanup)
    local data = self._listData
    if isState(data) then
        local observer = data:Observer(function() reconcile(data:Get()) end)
        self._listObserver = observer
        q.bindLifetime(physicalTarget, observer)
    else
        reconcile(data)
    end
end

-- ── 최상위 (Dispatch.drive + SlotHandler 흉내) ────────────────────────────
-- 최상위 배열 자리 k에 Slot을 붙인다: SlotHandler.process의 마운트 + retractor 반환.
function D.mountTop(inst, slot, k)
    k = k or 1
    local bl = getBlocker(inst); bl:On()
    attachSlot(slot, inst, inst, k)
    q.bindLifetime(inst, slot)
    bl:OffWithoutEmit()
    local bk = getBookkeeping(inst)
    if not bk.recomputeBlocker:IsOn() then recompute(inst, bk) end
    return function(nextValue)          -- retractor: State<Slot> 교체 = 언마운트(파괴 아님)
        if nextValue ~= slot then
            unmountSlotTree(slot)
            q.unbindLifetime(slot)
            D.setOffsetSource(inst, k, None)
            D.setLength(inst, k, 0)      -- 해제 호출엔 요소 인자가 없다(H-145)
        end
    end
end
-- 배열 자리 k에 plain 요소(InstanceChildHandler 흉내): None → Parent → setLength(1)
function D.mountChild(inst, child, k)
    D.setOffsetSource(inst, k, None)
    nativeInsert(inst, k - 1, { child })
    D.setLength(inst, k, 1, inst)
end
D.getBlockerOf = getBlocker
return D
