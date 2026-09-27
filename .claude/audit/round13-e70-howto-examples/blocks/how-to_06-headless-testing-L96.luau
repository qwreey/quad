local raw = Quad.Source(0)
local gate = Quad.Blocker()
local gated = raw:Apply(gate)

gate:On()
raw:Set(1)
raw:Set(2)
assert(gated:Get() == 2, "값 자체는 항상 최신 — 막히는 것은 아래로의 전파다")
gate:Off()          -- 여기서 밀린 전파가 정확히 한 번
-- gate:OffWithoutEmit() -- 밀린 전파를 버리며 연다
