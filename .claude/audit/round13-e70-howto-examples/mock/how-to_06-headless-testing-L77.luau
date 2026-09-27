--!nocheck
-- E70 mock runner (base — Roblox 프로바이더 없는 새 quad_base 인스턴스) — how-to_06-headless-testing-L77
local H = require("../harness")
local task = H.task
-- ==== doc block how-to/06-headless-testing.md:77 ====
local Quad = H.Quad.New()

local count = Quad.Source(0)
local isEven = count:Compute(function(c)
    return c:Get() % 2 == 0
end)

assert(count:Get() == 0, "초기값은 0")
assert(isEven:Get() == true, "0은 짝수")

count:Set(1)
assert(count:Get() == 1 and isEven:Get() == false, "파생 상태가 따라온다")
-- ==== E70 보강 post ====
print("L77 asserts ok")
print("<<END>>")
