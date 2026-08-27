--!nocheck
local q = require("./core")
-- gate-plan.md 4번: "하류가 또 다른 게이트면 받은 집합을 풀어 자기 withheld에 합친다.
-- 게이트가 몇 겹으로 겹쳐도 각 층이 자기 집합을 들고 있으므로 어느 층이 먼저 풀리든
-- 정보가 안 샌다"
local function run(order)
    local A, B = q.Source(1), q.Source(1)
    local w  = q.State(function(self, prev, a, b) return a:Get() + b:Get() end, {A, B}, "w")
    local b1, b2 = q.Blocker(), q.Blocker()
    local g1 = q.Gate(w,  function(emit) return b1:Policy(emit) end, "g1")
    local g2 = q.Gate(g1, function(emit) return b2:Policy(emit) end, "g2")
    local hits = {}
    local o = q.Observer(g2, function(self, from)
        local n = 0; for _ in from do n += 1 end
        table.insert(hits, ("v=%d, batch=%d"):format(g2:Get(), n))
    end, "o")
    b1:On(); b2:On()
    A:Set(2); B:Set(3)
    local function w1() return next(g1.withheld) ~= nil end
    local function w2() return next(g2.withheld) ~= nil end
    print(("[%s] 유보 중 g1=%s g2=%s | 발화 %d"):format(order, tostring(w1()), tostring(w2()), o.fires))
    if order == "상류 먼저" then b1:Off(); print("  b1:Off 후 g1=" .. tostring(w1()) .. " g2=" .. tostring(w2()) .. " 발화=" .. o.fires); b2:Off()
    else b2:Off(); print("  b2:Off 후 g1=" .. tostring(w1()) .. " g2=" .. tostring(w2()) .. " 발화=" .. o.fires); b1:Off() end
    print(("  최종 발화 %d | %s"):format(o.fires, table.concat(hits, " ; ")))
end
run("상류 먼저")
run("하류 먼저")
