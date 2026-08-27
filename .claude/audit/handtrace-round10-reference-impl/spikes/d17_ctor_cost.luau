--!nocheck
local q = require("./core9"); local D = require("./dispatch9")
D.remountFix = "ctor"
local s = D.newSlot("lonely")
print("생성 직후: Offset =", s.Offset:Get(), "| _baseObserver 존재 =", s._baseObserver ~= nil,
      "| bk 미생성(books에 없음) =", rawget(D, "x") == nil)
-- 미실체화 Slot에 Add — rawAdd의 _physicalTarget 얼리리턴이 그대로 성립하는가
local i = D.rawAdd(s, {name="q"})
print("미실체화 Add: index =", i, "| _elements =", #s._elements, "| 크래시 없음")
-- 실체화 후 정상 동작
local inst = q.newInst("i"); local O = D.newSlot("O", { s })
D.mountTop(inst, O)
print("마운트 후: O.Length =", O.Length:Get(), "(기대 1) | s.Offset =", s.Offset:Get(), "(기대 0)")
