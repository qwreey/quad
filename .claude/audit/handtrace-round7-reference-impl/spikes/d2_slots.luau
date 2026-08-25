--!nocheck
local q = require("./core"); local D = require("./dispatch")
-- Frame { Slot1, E(plain), Slot2 }
local inst = {}
local s1, s2 = D.newSlot("s1"), D.newSlot("s2")
local bl = D.getBlocker(inst); bl:On()
D.setOffsetSource(inst, 1, s1.Offset); D.setLength(inst, 1, s1.Length, inst)
D.setOffsetSource(inst, 2, D.None);    D.setLength(inst, 2, 1, inst)
D.setOffsetSource(inst, 3, s2.Offset); D.setLength(inst, 3, s2.Length, inst)
bl:OffWithoutEmit(); D.recompute(inst, D.getBookkeeping(inst))
print("초기: s1.Offset =", s1.Offset:Get(), "| s2.Offset =", s2.Offset:Get(), "| recompute:", D.stats())

print("-- 런타임에 Slot1이 3개가 됨 (s1.Length:Set(3)) --")
s1.Length:Set(3)
print("s1.Offset =", s1.Offset:Get(), "| s2.Offset =", s2.Offset:Get(), "(기대 4) | recompute:", D.stats())

print("-- Slot2도 2개가 됨 --")
s2.Length:Set(2)
print("s2.Offset =", s2.Offset:Get(), "(기대 4) | 4번 자리 offset =", D.getOffsetAt(inst,4), "(기대 6)")

print("-- Slot1이 다시 0개 --")
s1.Length:Set(0)
print("s2.Offset =", s2.Offset:Get(), "(기대 1) | 4번 자리 =", D.getOffsetAt(inst,4), "(기대 3)")
