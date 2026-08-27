--!nocheck
-- 레인 A: `_hold` 불변식(하류→상류 강함, 상류→하류 weak) 실측 — 중간 State가 수거되지 않는가 + 음성 대조군
local q = require("./core10")
local A = q.Source(1)
local fired = 0
local inst = q.newInst("inst")
do
    -- A → B → C → Observer(leaf) — B/C를 아무도 로컬로 안 든다
    local o = A:Compute(function(s) return s:Get() + 1 end)
              :Compute(function(s) return s:Get() * 2 end)
              :Observer(function(t) fired += 1; t:Get() end)
    q.bindLifetime(inst, o)
end
collectgarbage(); collectgarbage()
local before = fired
A:Set(5)
print("(양성) 체인 GC 뒤 A:Set → Observer 발화", fired - before, "(기대 1 — 중간 State가 _hold로 살아남음)")

-- 음성 대조군: 말단이 아무 데도 안 묶이면 통째로 수거된다
local weakProbe = setmetatable({}, {__mode = "k"})
do
    local mid = A:Compute(function(s) return s:Get() end)
    weakProbe[mid] = true
    local o2 = mid:Observer(function() end)   -- 미바인드·미구독
    weakProbe[o2] = true
end
collectgarbage(); collectgarbage()
local alive = 0; for _ in pairs(weakProbe) do alive += 1 end
print("(음성) 말단 미바인드 체인 GC 뒤 생존 객체", alive, "(기대 0 — 상류→하류가 weak라 수거)")

-- 상류(A)의 구독자 집합이 수거된 자식을 자동으로 잊는가
local subs = 0; for _ in pairs(A._subs) do subs += 1 end
print("A._subs 크기", subs, "(기대 1 — 살아있는 leaf 체인의 B만)")

-- Effect: deps 강한 맵 + 내부 Observer; Effect가 leaf에 묶여 있으면 dep 체인 생존
local fired2 = 0
do
    local e = q.Effect(function() fired2 += 1 end,
        A:Compute(function(s) return s:Get() end):Compute(function(s) return s:Get() end))
    q.bindLifetime(inst, e)
end
collectgarbage(); collectgarbage()
local b2 = fired2
A:Set(6)
print("(양성) Effect deps 체인 GC 뒤 A:Set → fn", fired2 - b2, "(기대 1)")

-- Effect를 약하게만 구독하고 참조를 놓으면 통째로 수거(문서화된 UB — cleanup 안 불림)
local cleans = 0
do
    local e = q.Effect(function() return function() cleans += 1 end end, A)
    e:WeakSubscribe()
    weakProbe[e] = true
end
collectgarbage(); collectgarbage()
alive = 0; for _ in pairs(weakProbe) do alive += 1 end
print("(문서화된 UB) WeakSubscribe만 한 Effect 참조 놓기 → 생존", alive, "cleanup 호출", cleans, "(기대 0, 0)")

-- 중간 GateNode도 _hold로 산다
local fired3 = 0
do
    local b = q.Blocker()
    local o = A:Block(b):Compute(function(s) return s:Get() end):Observer(function() fired3 += 1 end)
    q.bindLifetime(inst, o)
    -- b(Blocker)는 여기서 놓는다 — 게이트 노드는 살아야 하고, Blocker의 handles는 weak
end
collectgarbage(); collectgarbage()
local b3 = fired3
A:Set(7)
print("(양성) A→Gate→Compute→Observer, Blocker 참조 놓음 → 발화", fired3 - b3, "(기대 1 — 통과 모드)")
