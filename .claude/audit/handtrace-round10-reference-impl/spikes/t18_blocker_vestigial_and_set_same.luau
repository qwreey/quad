--!nocheck
-- 레인 A: (a) Effect 생성자의 사적 `_blocker`가 실제로 무엇을 막는가 — fire 가드 판정을 전부 기록
--         (b) Source:Set 동일값 emit(H-68) × state:Block × Effect/Observer 발화 수
local q = require("./core10")
local trace = {}
q.effectTrace = function(e, why) trace[why] = (trace[why] or 0) + 1 end

local A = q.Source(1)
local r = q.Ref(0)
local B = A:Compute(function(s) return s:Get() end)
local e = q.Effect(function() end, A, B, r)     -- Source + State + Ref dep
print("생성자 동안 fire 가드 판정:", "canExecute 드롭 =", trace["drop:canExecute"] or 0, "| blocker 드롭 =", trace["drop:blocker"] or 0)
e:Subscribe()
A:Set(2); r:Set(1)
print("구독 뒤 발화 중 blocker 드롭 =", trace["drop:blocker"] or 0, "(생성자 밖에선 blocker가 항상 Off)")
print("→ `_blocker`가 실제로 거른 발화 =", trace["drop:blocker"] or 0, "(0이면 canExecute 가드가 전부 먼저 걸렀다는 뜻)")
e:Unsubscribe()
q.effectTrace = nil

print("\n== 동일값 Set × Block × 발화 수 ==")
local S = q.Source(5)
local n = 0
local o = S:Observer(function() n += 1 end); o:Subscribe()
S:Set(5); S:Set(5)
print("같은 값 Set 두 번 → Observer 발화", n, "(기대 2 — H-68)")
local b = q.Blocker(); local g = S:Block(b)
local m = 0
local o2 = g:Observer(function() m += 1 end); o2:Subscribe()
b:On(); S:Set(5); S:Set(5); S:Set(5)
local cnt = 0; for _ in pairs(g._withheld) do cnt += 1 end
print("블록 중 같은 값 Set 세 번 → withheld 크기", cnt, "(기대 1 — 집합)")
b:Off()
print("Off → gated Observer 발화", m, "(기대 1)")
local e2n = 0
local e2 = q.Effect(function() e2n += 1 end, g); e2:Subscribe()
b:On(); S:Set(5); S:Set(5); b:Off()
print("Effect(gated): 블록 중 두 번 Set → Off → fn", e2n, "(기대 2 = 설치 1 + 배치 1)")
