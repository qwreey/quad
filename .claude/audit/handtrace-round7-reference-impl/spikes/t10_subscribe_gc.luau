--!nocheck
local q = require("./core")
local SubscribedObservers = {}
local function Subscribe(o) SubscribedObservers[o] = true; o.Subscribed = true; return o end

-- Observer가 상류를 되참조하지 않는 형태(확정 서술: 구독 엣지는 하류로 weak,
-- Observer를 살리는 건 gchold 또는 전역 레지스트리)
local Obs = {}
Obs.__index = Obs
function Obs.new(state, fn) local o = setmetatable({fn = fn, fires = 0}, Obs); state:_addSub(o); return o end
function Obs:_receive(from) self.fires += 1; self.fn(self, from) end

local A = q.Source(1)
local fires = 0
local o
do
    local mid = q.State(function(self, prev, a) return a:Get() * 2 end, {A}, "mid")
    o = Subscribe(Obs.new(mid, function() fires += 1 end))
end
collectgarbage("collect"); collectgarbage("collect")
A:Set(2)
print("Observer 발화:", fires, "  ← 공개 계약(\"예외 없이 그냥 계속 돎\")대로면 1")
local n = 0; for _ in A.subs do n += 1 end
print("A의 구독자 수:", n, "  ← 중간 State가 수거됐으면 0")
print("Observer는 레지스트리에 살아있다:", SubscribedObservers[o] == true, "| 그러나 다시는 안 울린다")
