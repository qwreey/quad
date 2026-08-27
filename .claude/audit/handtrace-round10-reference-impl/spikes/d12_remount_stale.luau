--!nocheck
-- H-125 후보: 언마운트→다른 베이스로 재마운트 시 setOffsetSource가 S.Offset을 바꾸는 순간
-- S._baseObserver는 unbindLifetime된 상태라 canExecute가 거짓 → 두 필드가 0으로 안 내려가
-- 재마운트 꼬리 recompute(S)가 옛 offsetCache[1](옛 베이스)을 그대로 쓴다.
local q = require("./core9"); local D = require("./dispatch9")
local inst = q.newInst("inst")
local t1, t2 = D.newSlot("t1", {{name="t1x"}}), D.newSlot("t2", {{name="t2x"}})
local S = D.newSlot("S", { t1, t2 })
local O = D.newSlot("O", { {name="a"}, {name="b"}, S })   -- S는 베이스 2에서 시작
D.mountTop(inst, O)
print("1차 마운트: S.Offset", S.Offset:Get(), "(기대 2) t1", t1.Offset:Get(), "(2) t2", t2.Offset:Get(), "(3)")
local bkS = D.getBookkeeping(S)
print("  S.bk: cacheValid", bkS.offsetCacheValidUpTo, "setUpTo", bkS.offsetSetUpTo, "cache[1]", bkS.offsetCache[1])
-- O에서 S를 뗀다(rawUnmount 상당: 언마운트 + splice) — 포탈
D.rawRemove(O, 3)
print("언마운트 후: canExecute(S._baseObserver) =", q.canExecute(S._baseObserver), "| S.Offset(보존)", S.Offset:Get())
-- 다른 owner O2(베이스 0)의 1번 자리에 재마운트
local O2 = D.newSlot("O2", {})
local inst2 = q.newInst("inst2")
D.mountTop(inst2, O2)
D.rawAdd(O2, S)      -- → materializeSlotTree(S, inst2, O2, 1)
print("재마운트: S.Offset", S.Offset:Get(), "(기대 0) | t1.Offset", t1.Offset:Get(), "(기대 0) | t2.Offset", t2.Offset:Get(), "(기대 1)")
print("  S.bk: cacheValid", bkS.offsetCacheValidUpTo, "setUpTo", bkS.offsetSetUpTo, "cache[1]", bkS.offsetCache[1], "(베이스 0이어야)")
if t1.Offset:Get() ~= 0 then print("  ❌ 자식 offset이 옛 베이스 위에 남았다") else print("  ✅ 정합") end
