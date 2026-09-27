--!strict
-- E70 strict (generated) — how-to_06-headless-testing-L149
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
-- ==== with how-to/06-headless-testing.md:134 ====
local q = Quad.New():UseProvider(myProvider)
--[[E70 보강 pre2]]
local host: any = nil
-- ==== doc block how-to/06-headless-testing.md:149 ====
local hp = q.Source(100)
local runs = 0
local observer = hp:Observer(function()
    runs += 1
end)
assert(runs == 1, "등록 즉시 1회 발화한다")

hp:Set(90)
assert(runs == 1, "아직 아무 인스턴스에도 안 묶였다 — 변경은 보류된다")

q.Backend.bindLifetime(host, observer)   -- host는 이 백엔드가 소유한 인스턴스
assert(runs == 2, "묶는 순간 보류분이 한 번 재생된다")

hp:Set(80)
assert(runs == 3, "이후 변경은 그대로 발화")

q.dispose(host)                  -- quad가 관리하는 값을 버리는 정본 경로(밖에서 :Destroy()해도 결과는 같다)
hp:Set(70)
assert(runs == 3, "인스턴스가 죽으면 더 이상 발화하지 않는다")
