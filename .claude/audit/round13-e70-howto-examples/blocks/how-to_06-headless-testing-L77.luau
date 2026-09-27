local Quad = require("../luau_packages/quad_base")

local count = Quad.Source(0)
local isEven = count:Compute(function(c)
    return c:Get() % 2 == 0
end)

assert(count:Get() == 0, "초기값은 0")
assert(isEven:Get() == true, "0은 짝수")

count:Set(1)
assert(count:Get() == 1 and isEven:Get() == false, "파생 상태가 따라온다")
