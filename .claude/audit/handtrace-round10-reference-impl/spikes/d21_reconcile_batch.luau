--!nocheck
-- H-136/Q10: `:List` 재실행 reconcile이 배치 Blocker 하나로 도는가 — {a,b} → {b,a,c} → {b} 사이클별 recompute 수
local q = require("./core10"); local D = require("./dispatch10")
local inst = q.newInst("inst")
local items = q.Source({ "a", "b" })
local made = {}
local slot = D.newSlot("L")
D.List(slot, items, function(item, physIndex, offset, prev, ud)
    if item == D.KeyGone then return nil end
    if prev then return prev end
    local e = { name = item }; made[item] = e
    return e
end, function(item) return item end)
D.mountTop(inst, slot, 1)
local function names() local t = {}; for _, e in ipairs(slot._elements) do t[#t+1] = e.name end; return table.concat(t, ",") end
print("최초 population:", names(), "| Length", slot.Length:Get(), "| recomputes", D.recomputes)
local function cycle(list, label)
    local l0, n0 = #D.log, #D.native
    items:Set(list)
    local rl, ri = 0, 0
    for i = l0 + 1, #D.log do if D.log[i] == "recompute(L)" then rl += 1 elseif D.log[i] == "recompute(inst)" then ri += 1 end end
    print(("%s: %s | Length %d | recompute(L) %d (기대 1) recompute(inst) %d | 물리 op: %s"):format(label, names(), slot.Length:Get(),
        rl, ri, table.concat(D.native, " ", n0 + 1)))
    local bk = D.getBookkeeping(slot)
    local offs = {}; for i = 1, bk.N do offs[i] = tostring(bk.sourceList[i] == D.None and "-" or bk.sourceList[i]:Get()) end
    print(("   bk.N=%d lengthList={%s} validUpTo=%d setUpTo=%d blocker=%s"):format(bk.N,
        table.concat(bk.lengthList, ",", 1, bk.N), bk.offsetCacheValidUpTo, bk.offsetSetUpTo, tostring(D.getBlockerOf(slot):IsOn())))
end
cycle({ "b", "a", "c" }, "{b,a,c}")
cycle({ "b" }, "{b}")
cycle({ "d", "b" }, "{d,b}")
-- 중첩 Slot 요소와 Length 전파
local inner = D.newSlot("inner", { {name="i1"}, {name="i2"} })
local items2 = q.Source({ "p", "q" })
local slot2 = D.newSlot("L2")
D.List(slot2, items2, function(item, physIndex, offset, prev)
    if item == D.KeyGone then return nil end
    if prev then return prev end
    if item == "q" then return inner end
    return { name = item }
end, function(item) return item end)
local inst2 = q.newInst("inst2")
D.mountTop(inst2, slot2, 1)
print("중첩: L2.Length", slot2.Length:Get(), "(기대 3) inner.Offset", inner.Offset:Get(), "(기대 1)")
D.rawAdd(inner, {name="i3"})
print("inner에 추가 → L2.Length", slot2.Length:Get(), "(기대 4)")
items2:Set({ "q", "p" })
print("리오더 {q,p} → inner.Offset", inner.Offset:Get(), "(기대 0) L2.Length", slot2.Length:Get(), "(기대 4)")
local bk2 = D.getBookkeeping(slot2)
print("   p의 offset(getOffsetAt 2) =", D.getOffsetAt(slot2, 2), "(기대 3)")
