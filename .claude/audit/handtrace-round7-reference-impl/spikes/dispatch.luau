--!nocheck
-- base/dispatch-core-plan.md의 Length/Offset 부기를 확정 의사코드 그대로 옮긴 것.
-- getOffsetAt(접두합 캐시, 2026-08-21 G절 + H-3) / recompute(H-10 정정 반영) /
-- setLength / setOffsetSource / 배치 게이팅.
local q = require("./core")
local D = {}

local None = setmetatable({}, {__tostring = function() return "None" end})
D.None = None
local function isSlot(x) return type(x) == "table" and x.__isSlot == true end
local function isState(x) return type(x) == "table" and (getmetatable(x) ~= nil) and x.Get ~= nil end

local books, blockers = {}, {}
local function getBookkeeping(ownerKey)
    local bk = books[ownerKey]
    if not bk then
        bk = { lengthList = {}, sourceList = {}, observers = {}, N = nil,
               offsetCache = {}, invalidAfter = 0 }
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
    if bk.invalidAfter == 0 then
        bk.offsetCache[1] = if isSlot(ownerKey) then ownerKey.Offset:Get() else 0
        bk.invalidAfter = 1
    end
    if at <= bk.invalidAfter then
        return bk.offsetCache[at]
    end
    local cur = bk.offsetCache[bk.invalidAfter]
    for i = bk.invalidAfter, at - 1 do
        cur += contribution(bk, i)
        bk.offsetCache[i + 1] = cur
    end
    bk.invalidAfter = at
    return cur
end

local recomputes = 0
D.stats = function() return recomputes end
local function recompute(ownerKey, bk)
    recomputes += 1
    local sum = 0
    for i = 1, bk.N or 0 do
        local offset = bk.sourceList[i]
        if offset == nil then
            error("Dispatch.recompute: sourceList[" .. i .. "]가 nil — 부기가 깨졌음(계약상 None이어야 함)")
        end
        local abs = D.getOffsetAt(ownerKey, i)
        if offset ~= None and offset:Get() ~= abs then
            offset:Set(abs)
        end
        local v = bk.lengthList[i]
        sum += (if isState(v) then v:Get() else v)
    end
    if isSlot(ownerKey) and ownerKey.Length:Get() ~= sum then
        ownerKey.Length:Set(sum)
    end
end
D.recompute = recompute

function D.setLength(ownerKey, i, len, anchor)
    anchor = anchor or ownerKey
    local bk = getBookkeeping(ownerKey)
    local blocker = getBlocker(ownerKey)
    local oldObserver = bk.observers[i]
    if oldObserver then bk.observers[i] = nil end
    bk.lengthList[i] = len
    bk.N = math.max(bk.N or 0, i)
    bk.invalidAfter = math.min(bk.invalidAfter, i)

    local box = { pos = i }   -- [대조군용] 실제 위치를 가변 박스로 들면 splice가 고칠 수 있다
    local function gatedRecompute()
        bk.invalidAfter = math.min(bk.invalidAfter, box.pos)
        if not blocker:IsOn() then
            recompute(ownerKey, bk)
        end
    end
    if isState(len) then
        local observer = q.Observer(len, gatedRecompute)
        observer.pos = box.pos; observer.box = box
        bk.observers[i] = observer
        gatedRecompute()   -- "등록 즉시 1회 실행도 게이팅됨"
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

-- 테스트 편의: Slot 흉내(Length/Offset 공개 필드만)
function D.newSlot(name)
    return { __isSlot = true, name = name, Length = q.Source(0), Offset = q.Source(0) }
end
return D
