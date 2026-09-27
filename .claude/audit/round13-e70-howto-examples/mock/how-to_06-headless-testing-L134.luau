--!nocheck
-- E70 mock runner (base — Roblox 프로바이더 없는 새 quad_base 인스턴스) — how-to_06-headless-testing-L134
local H = require("../harness")
local task = H.task
--[[E70 보강 pre]]
local myProvider: any = (H and H.mock.mockProvider) or nil
-- ==== with how-to/06-headless-testing.md:77 ====
local Quad = H.Quad.New()

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
-- ==== E70 보강 post ====
print(q.Backend.bindLifetime ~= nil)
print("same provider again:", pcall(function() return q:UseProvider(myProvider) end))
print("other provider:", (select(2, pcall(function() return q:UseProvider(function() return {} end) end))))
print("<<END>>")
