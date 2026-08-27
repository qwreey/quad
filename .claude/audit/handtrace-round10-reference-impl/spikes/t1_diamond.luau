--!nocheck
local q = require("./core")
-- A -> B -> D, A -> C -> D, Observer on D
local A = q.Source(1)
local B = q.State(function(self, prev, a) return a:Get() * 10 end, {A}, "B")
local C = q.State(function(self, prev, a) return a:Get() * 100 end, {A}, "C")
local D = q.State(function(self, prev, b, c) return b:Get() + c:Get() end, {B, C}, "D")
local seen = {}
local O = q.Observer(D, function() table.insert(seen, D:Get()) end, "O")
print("초기 D:Get() =", D:Get())
A:Set(2)
print("Observer 발화 횟수:", O.fires, "| 관측값:", table.concat(seen, ","))
print("D 재계산 횟수:", D.recomputes, "| B:", B.recomputes, "| C:", C.recomputes)
A:Set(3)
print("2회차 후 발화:", O.fires, "| 관측값:", table.concat(seen, ","))
