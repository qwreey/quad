--!nocheck
-- H-145: 최상위 Slot 교체(해제 setLength(inst,k,0))가 옛 Slot 키를 못 지워도 weak-key라 GC로 빠지는가.
-- 요소가 테이블이라 weak-key 자체는 동작한다 — Instance userdata 키의 거동은 여기서 못 본다(한계).
local q = require("./core10"); local D = require("./dispatch10")
local inst = q.newInst("inst")
local probe = setmetatable({}, {__mode = "k"})
local retract
do
    local S1 = D.newSlot("S1", { {name="a"}, {name="b"} })
    probe[S1] = true
    retract = D.mountTop(inst, S1, 1)
    local bk = D.getBookkeeping(inst)
    print("마운트 후 bk(inst).indexOfElement[S1] =", bk.indexOfElement[S1], "lengthList[1] =", tostring(bk.lengthList[1]))
    local S2 = D.newSlot("S2", { {name="c"} })
    retract(S2)                         -- State<Slot> 교체: retractor(nextValue=S2) → 언마운트 + setLength(inst,1,0)
    print("교체(해제) 후 indexOfElement[S1] =", bk.indexOfElement[S1], "(해제엔 요소 인자가 없어 안 지워짐)")
    print("  S1 canExecute(_baseObserver) =", q.canExecute(S1._baseObserver), "| observers[1] =", tostring(bk.observers[1]))
end
retract = nil   -- retractor 클로저가 S1을 잡고 있으므로 놓는다(SlotHandler 체인 슬롯이 교체된 것에 해당)
collectgarbage(); collectgarbage()
local alive = 0; for _ in pairs(probe) do alive += 1 end
local cnt = 0; for _ in pairs(D.getBookkeeping(inst).indexOfElement) do cnt += 1 end
print("참조 놓고 GC → 옛 Slot 생존", alive, "(기대 0) | indexOfElement 항목 수", cnt, "(기대 0)")

-- 마운트 중인 요소는 절대 빠지지 않아야 한다(보장자: _elements + gatedRecompute 캡처)
local inst2 = q.newInst("inst2")
local outer = D.newSlot("outer", {})
D.mountTop(inst2, outer, 1)
do
    local inner = D.newSlot("inner", { {name="x"} })
    D.rawAdd(outer, inner)
    D.rawAdd(outer, {name="y"})
end
collectgarbage(); collectgarbage()
local bko = D.getBookkeeping(outer)
local keys = 0; for _ in pairs(bko.indexOfElement) do keys += 1 end
print("마운트 중 요소(로컬 참조 없음) GC 뒤 indexOfElement 항목", keys, "(기대 2 — _elements가 붙잡음)")
print("  inner.Length 변경 전파: outer.Length =", outer.Length:Get())
D.rawAdd(outer._elements[1], {name="z"})
print("  inner에 z 추가 → outer.Length =", outer.Length:Get(), "(기대 3)")
