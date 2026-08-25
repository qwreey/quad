--!nocheck
local q = require("./core")
local A = q.Source(1)
local B = q.State(function(self, prev, a) return a:Get() * 10 end, {A}, "B")
local C = q.State(function(self, prev, a) return a:Get() * 100 end, {A}, "C")
local D = q.State(function(self, prev, b, c) return b:Get() + c:Get() end, {B, C}, "D")
local seen, depth = {}, 0
local O = q.Observer(D, function()
    table.insert(seen, D:Get())
    depth += 1
    if depth == 1 then A:Set(3) end   -- 전파 도중 동기 재진입 Set
end, "O")
D:Get()
A:Set(2)
print("관측 순서:", table.concat(seen, ","))
print("Observer 발화:", O.fires, "| D 재계산:", D.recomputes)
print("최종 D:Get() =", D:Get(), "(A=3이므로 330이어야 함)")
