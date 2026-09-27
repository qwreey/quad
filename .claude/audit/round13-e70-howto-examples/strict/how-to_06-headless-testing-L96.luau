--!strict
-- E70 strict (generated) — how-to_06-headless-testing-L96
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
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
-- ==== doc block how-to/06-headless-testing.md:96 ====
local raw = Quad.Source(0)
local gate = Quad.Blocker()
local gated = raw:Apply(gate)

gate:On()
raw:Set(1)
raw:Set(2)
assert(gated:Get() == 2, "값 자체는 항상 최신 — 막히는 것은 아래로의 전파다")
gate:Off()          -- 여기서 밀린 전파가 정확히 한 번
-- gate:OffWithoutEmit() -- 밀린 전파를 버리며 연다
