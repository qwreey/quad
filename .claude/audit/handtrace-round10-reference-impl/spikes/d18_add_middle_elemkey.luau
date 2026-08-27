--!nocheck
-- Q3 실측: 중간 삽입 뒤 밀려난 요소의 길이 Observer가 살아 있고, 요소 키 조회가 새 자리를 준다
local q = require("./core9"); local D = require("./dispatch9")
local inst = q.newInst("inst")
local A, B = D.newSlot("A", {{name="a"}}), D.newSlot("B", {{name="b"}})
local O = D.newSlot("O", { A, B }); D.mountTop(inst, O)
D.rawAdd(O, D.newSlot("X", {{name="x"}}), 1)          -- 맨 앞 삽입 → A는 2번, B는 3번
local bk = D.getBookkeeping(O)
print("indexOfElement: X", bk.indexOfElement[O._elements[1]], "A", bk.indexOfElement[A], "B", bk.indexOfElement[B], "(기대 1 2 3)")
print("삽입 후 offsets: A", A.Offset:Get(), "(기대 1) B", B.Offset:Get(), "(기대 2)")
D.rawAdd(A, {name="a2"})                               -- A 길이 1→2 — 밀려난 A의 Observer가 살아있어야 B가 밀린다
print("A 성장 후 B.Offset", B.Offset:Get(), "(기대 3) | O.Length", O.Length:Get(), "(기대 4)")
