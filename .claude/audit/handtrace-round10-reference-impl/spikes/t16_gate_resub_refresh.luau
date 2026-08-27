--!nocheck
-- 레인 A: state:Gate 유보 × Effect 재구독/재바인드 × EpochMap:Refresh / Peek / Update 조합
local q = require("./core10")
local function runs(e) return e._n end
local function mkEffect(...)
    local e; e = q.Effect(function(self) self._n = (self._n or 0) + 1 end, ...)
    return e
end

print("== (1) 게이트 유보 중 재구독: Refresh가 유보된 변경을 먼저 삼킨다 ==")
local A = q.Source(1)
local b = q.Blocker()
local gated = A:Block(b)
local e = mkEffect(gated)
e:Subscribe()
print("초기 runs", runs(e), "(기대 1)")
b:On()
A:Set(2)                                    -- gated가 유보. Effect엔 아무것도 안 온다
print("블록 중 A:Set → runs", runs(e), "(기대 1) | gated withheld:", next(gated._withheld) ~= nil)
e:Unsubscribe(); e:Subscribe()               -- 재구독 꼬리: Refresh()가 A의 새 리비전을 본다 → Rerun
print("재구독 후 runs", runs(e), "(기대 2 — 게이트가 잡고 있는데도 캐치업이 fn을 돌렸다)")
print("  fn이 읽는 gated:Get() =", gated:Get(), "(게이트는 값은 안 가림)")
b:Off()                                     -- 유보 풀림 → batch {A} → Effect Update(A) → 이미 최신 → 접힘
print("Off 후 runs", runs(e), "(기대 2 — 접힘, 중복 없음)")

print("\n== (2) 재바인드(포탈) 캐치업도 게이트를 우회한다 ==")
local A2 = q.Source(1); local b2 = q.Blocker(); local g2 = A2:Block(b2)
local e2 = mkEffect(g2)
local inst = q.newInst("inst")
q.bindLifetime(inst, e2)
b2:On(); A2:Set(2)
q.unbindLifetime(e2)
local inst2 = q.newInst("inst2")
q.bindLifetime(inst2, e2)
print("블록 중 언바인드→재바인드 후 runs", runs(e2), "(기대 2 — 캐치업이 게이트를 우회)")
b2:Off()
print("Off 후 runs", runs(e2), "(기대 2)")

print("\n== (3) emit(false) 버리기: Effect가 캐치업으로 이미 돌았다면? ==")
local A3 = q.Source(1); local g3 = A3:Gate(function(emit)
    return function() end                       -- 항상 유보(정책이 emit을 안 부름)
end)
local flush3 = nil
-- 정책 밖에서 emit 핸들을 얻으려고 Gate를 다시 감싼다
local A3b = q.Source(1); local disc
local g3b = A3b:Gate(function(emit) disc = emit; return function() end end)
local e3 = mkEffect(g3b); e3:Subscribe()
A3b:Set(2)
e3:Unsubscribe(); e3:Subscribe()
print("유보 중 재구독 runs", runs(e3), "(기대 2)")
print("emit(false) 반환:", disc(false), "(버릴 게 있었으니 true)")
A3b:Set(3)
print("버린 뒤 새 Set → runs", runs(e3), "(기대 2 — 여전히 유보 중)")
print("emit() 반환:", disc(), "→ runs", runs(e3), "(기대 3)")

print("\n== (4) 다이아몬드: A→gated, A→plain, Effect(fn, gated, plain) — 비게이트 경로가 게이트를 새게 한다 ==")
local A4 = q.Source(1); local b4 = q.Blocker()
local g4 = A4:Block(b4)
local p4 = A4:Compute(function(s) return s:Get() end)
local e4 = mkEffect(g4, p4); e4:Subscribe()
b4:On(); A4:Set(2)
print("블록 중 A:Set → runs", runs(e4), "(기대 2 — plain 경로가 Effect를 깨웠다; 게이트는 무의미)")
b4:Off()
print("Off 후 runs", runs(e4), "(기대 2 — 접힘)")

print("\n== (5) 게이트 위의 다이아몬드: A→B→G, A→C→G, 유보 중 두 번 도착 → 정책 두 번, 집합 하나 ==")
local A5 = q.Source(1)
local B5 = A5:Compute(function(s) return s:Get() end)
local C5 = A5:Compute(function(s) return s:Get() end)
local M5 = B5:With(C5)   -- fan-in
local policyCalls = 0
local g5 = M5:Gate(function(emit) return function() policyCalls += 1 end end)
local o5 = g5:Observer(function() end); o5:Subscribe()
A5:Set(2)
local cnt = 0; for _ in pairs(g5._withheld) do cnt += 1 end
print("A:Set 한 번 → 정책 호출", policyCalls, "(다이아몬드가 M5에서 접히면 1) | withheld 크기", cnt)

print("\n== (6) 게이트 → 게이트 (unfold) 유보 후 각각 풀기 ==")
local A6 = q.Source(1); local b6a, b6b = q.Blocker(), q.Blocker()
local g6a = A6:Block(b6a); local g6b = g6a:Block(b6b)
local fires = 0
local o6 = g6b:Observer(function(_, _, from) if from ~= nil then fires += 1 end end); o6:Subscribe()
b6a:On(); b6b:On(); A6:Set(2); A6:Set(3)
b6a:Off()
print("안쪽 게이트 풀림 → 바깥 withheld에 합류, 발화", fires, "(기대 0)")
b6b:Off()
print("바깥 풀림 → 발화", fires, "(기대 1)")
A6:Set(4)
print("둘 다 열린 뒤 Set → 발화", fires, "(기대 2)")

print("\n== (7) 게이트 유보 중 하류 Get()으로 앞당겨 읽기 → 풀릴 때 규칙 2(통지만) ==")
local A7 = q.Source(1); local b7 = q.Blocker(); local g7 = A7:Block(b7)
local d7 = g7:Compute(function(s) return s:Get() * 10 end)
local n7 = 0
local o7 = d7:Observer(function() n7 += 1 end); o7:Subscribe()
b7:On(); A7:Set(2)
print("유보 중 d7:Get() =", d7:Get(), "(기대 20 — 값은 안 가림) recomputes", d7.recomputes)
local rc = d7.recomputes
b7:Off()
print("Off 후 Observer 발화", n7, "(기대 1 — 통지는 온다) | 재계산 추가", d7.recomputes - rc, "(기대 0 — 규칙 2)")
