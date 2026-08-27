--!nocheck
-- 레인 B: `:List` × Detach × KeyGone × 재등장(재마운트) × 파괴 — settle 분기 전부를 값으로
local q = require("./core10"); local D = require("./dispatch10")
local inst = q.newInst("inst")
local items = q.Source({ "a", "b", "c" })
local created, disposed = {}, {}
local slot = D.newSlot("L")
D.List(slot, items, function(item, physIndex, offset, prev, ud)
    if item == D.KeyGone then return D.Detach end          -- 사라진 키는 홀드
    if prev then return prev end
    local e = { name = item }; created[#created+1] = item
    return e
end, function(item) return item end)
D.mountTop(inst, slot, 1)
local function names() local t = {}; for _, e in ipairs(slot._elements) do t[#t+1] = e.name end; return table.concat(t, ",") end
local function detachedKeys() local t = {}; for k in pairs(slot._detached or {}) do t[#t+1] = k end; table.sort(t); return table.concat(t, ",") end
print("population:", names(), "| created", table.concat(created, ","))
items:Set({ "a", "c" })
print("{a,c}: mounted", names(), "| detached", detachedKeys(), "| Length", slot.Length:Get(), "| 물리:", table.concat(D.native, " ", #D.native - 0))
local n0 = #D.native
items:Set({ "a", "b", "c" })
print("{a,b,c} 재등장: mounted", names(), "| detached", detachedKeys(), "| created 추가?", #created, "(기대 3 — 재사용) | 물리:", table.concat(D.native, " ", n0 + 1))
local bk = D.getBookkeeping(slot)
print("  bk.N", bk.N, "lengthList", table.concat(bk.lengthList, ",", 1, bk.N), "indexOfElement[b] =", bk.indexOfElement[slot._elements[2]])
-- KeyGone 뒤 새 값 반환은 error
local slot2 = D.newSlot("L2"); local items2 = q.Source({ "x" })
D.List(slot2, items2, function(item, _, _, prev) if item == D.KeyGone then return { name = "new" } end; return prev or { name = item } end, function(i) return i end)
local inst2 = q.newInst("inst2"); D.mountTop(inst2, slot2, 1)
print("KeyGone에 새 값:", select(2, pcall(function() items2:Set({}) end)))
-- Detach 홀드 중 Slot 파괴 → _detached도 파괴
n0 = #D.native
D.destroySlotTree(slot)
print("destroySlotTree 뒤 물리:", table.concat(D.native, " ", n0 + 1), "| _destroyed", slot._destroyed)
print("파괴된 Slot 재마운트:", select(2, pcall(function() D.mountTop(q.newInst("i3"), slot, 1) end)))
