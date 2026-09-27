--!strict
-- E70 strict (generated) — how-to_06-headless-testing-L134
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
--[[E70 보강 pre]]
local myProvider: any = (H and H.mock.mockProvider) or nil
-- ==== with how-to/06-headless-testing.md:77 ====
local Quad = require("../../../../quad-roblox/luau_packages/quad_base")

local count = Quad.Source(0)
local isEven = count:Compute(function(c)
    return c:Get() % 2 == 0
end)

assert(count:Get() == 0, "초기값은 0")
assert(isEven:Get() == true, "0은 짝수")

count:Set(1)
assert(count:Get() == 1 and isEven:Get() == false, "파생 상태가 따라온다")
-- ==== doc block how-to/06-headless-testing.md:134 ====
local q = Quad.New():UseProvider(myProvider)
