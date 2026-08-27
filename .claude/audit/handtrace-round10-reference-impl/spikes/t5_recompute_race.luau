--!nocheck
local q = require("./core")
-- D = Compute(A) 인데, fn 안에서 다른 코드가 A를 바꾼다
local A = q.Source(1)
local log = {}
local D = q.State(function(self, prev, a)
    local v = a:Get()
    table.insert(log, "fn이 읽은 A = " .. v)
    if v == 1 then A:Set(99) end   -- 재계산 도중 상류가 바뀜(부작용 있는 Compute)
    return v * 2
end, {A}, "D")

print("D:Get() =", D:Get(), "(A=1로 계산됨)")
print("A의 실제 값:", A:Get())
print("다시 D:Get() =", D:Get(), "  ← 기대값 198")
print("D 재계산 횟수:", D.recomputes)
print("로그:", table.concat(log, " / "))
print()
print("-- 이후 A를 또 바꾸면 회복되는가 --")
A:Set(5)
print("D:Get() =", D:Get(), "(회복됨)")
