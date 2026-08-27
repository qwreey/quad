--!nocheck
local q = require("./core9"); local D = require("./dispatch9")
-- inst > O { a(plain), S{ t1, t2 }, b(plain) }  — 형제 offset 전파 대조군
local inst = q.newInst("inst")
local t1, t2 = D.newSlot("t1", {{name="t1x"}}), D.newSlot("t2", {{name="t2x"}})
local S = D.newSlot("S", { t1, t2 })
local O = D.newSlot("O", { {name="a"}, S, {name="b"} })
D.mountTop(inst, O)
print("O.Length", O.Length:Get(), "(기대 4) | S.Offset", S.Offset:Get(), "(기대 1) | t1", t1.Offset:Get(), "(1) t2", t2.Offset:Get(), "(2) | S.Length", S.Length:Get(), "(2)")
-- t1이 커지면 t2와 b가 밀린다
t1.Length:Set(3)
print("after t1=3: S.Length", S.Length:Get(), "(기대 4) | t2.Offset", t2.Offset:Get(), "(기대 4) | O.Length", O.Length:Get(), "(기대 6)")
print("log:", table.concat(D.log, " "))
