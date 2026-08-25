--!nocheck
local q = require("./core")
-- A ──> gated(Block) ──┐
--  └──> plain ─────────┴──> Effect(fn, gated, plain)
local A = q.Source(1)
local plain = q.State(function(self, prev, a) return a:Get() end, {A}, "plain")
local b = q.Blocker()
local gated = q.Gate(A, function(emit) return b:Policy(emit) end, "gated")

-- effect-plan.md의 확정 의사코드 그대로: 공용 EpochMap 하나, true일 때만 Rerun
local epochs = q.EpochMap()
local runs = {}
local function onDep(self, from)
    if epochs:Update(from) then
        table.insert(runs, ("run(gated=%s, plain=%s)"):format(tostring(gated:Get()), tostring(plain:Get())))
    end
end
local o1 = q.Observer(gated, onDep, "dep_gated")
local o2 = q.Observer(plain, onDep, "dep_plain")

b:On()
print("blocker ON — 이 구간의 변경은 gated 쪽에서 유보되어야 한다")
A:Set(2)
print("fn 실행 기록:", table.concat(runs, " | "))
print("gated가 아직 붙들고 있나:", next(gated.withheld) ~= nil)
b:Off()
print("Off() 이후 fn 실행 기록:", table.concat(runs, " | "))
print("gated observer 발화 횟수:", o1.fires, "| plain observer:", o2.fires)
