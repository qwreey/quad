--!nocheck
-- E70 mock runner (base — Roblox 프로바이더 없는 새 quad_base 인스턴스) — how-to_06-headless-testing-L180
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
-- ==== with how-to/06-headless-testing.md:134 ====
local q = Quad.New():UseProvider(myProvider)
--[[E70 보강 pre2]]
local function makeElement() return H.mock.Instance.new("Frame") end
local parent = H.mock.Instance.new("Frame")
-- ==== doc block how-to/06-headless-testing.md:180 ====
local data = q.Source({ { id = "a" }, { id = "b" } })
-- makeElement()는 이 백엔드가 만드는 요소, parent는 이 백엔드가 소유한 부모 인스턴스
local slot = q.Slot<<Instance>>():List(data, function(ctx: any): (any, any)
    if ctx.Item == q.KeyGone then
        return nil, ctx.UserData
    end
    return ctx.Prev or makeElement(), ctx.UserData
end, function(item)
    return item.id
end)

q.Dispatch.drive(parent, { slot })
assert(#parent:GetChildren() == 2, "두 요소가 붙었다")

data:Set({ { id = "b" } })
assert(#parent:GetChildren() == 1, "사라진 키의 요소는 파괴된다")
-- ==== E70 보강 post ====
print("L180 asserts ok")
print("<<END>>")
