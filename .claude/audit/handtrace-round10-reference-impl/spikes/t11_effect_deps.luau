--!nocheck
local q = require("./core9")
local inst = q.newInst("inst")
-- (1) Ref dep: onRefFire → fire(ref) → Update(ref) → Rerun
local r = q.Ref(nil)
local runs, cleanups = 0, 0
local e = q.Effect(function(self) runs += 1; return function() cleanups += 1 end end, r)
print("생성 직후 runs", runs, "(기대 1)")
r:Set(1)   -- 아직 바인드 안 됨 → canExecute 거짓 → 무시
print("미바인드 Set 후 runs", runs, "(기대 1)")
q.bindLifetime(inst, e)   -- 캐치업: Refresh()가 r의 리비전 변화를 봄 → Rerun
print("바인드 캐치업 후 runs", runs, "(기대 2) cleanups", cleanups, "(기대 1)")
r:Set(2)
print("바인드 뒤 Set 후 runs", runs, "(기대 3)")
r:Set(2)   -- 같은 값이라도 Set은 새 리비전 → 한 번 더
print("같은 값 Set 후 runs", runs, "(기대 4)")
-- (2) 다이아몬드: A → b, A → c, Effect(fn, b, c) — A:Set 한 번에 fn 한 번
local A = q.Source(1)
local b = A:Compute(function(_) return A:Get() + 1 end)
local c = A:Compute(function(_) return A:Get() * 2 end)
local n = 0
local e2 = q.Effect(function() n += 1 end, b, c)
q.bindLifetime(inst, e2)
A:Set(5)
print("다이아몬드 A:Set 후 n", n, "(기대 2 = 설치 1 + 파동 1)")
-- (3) 혼합 deps: Ref + State 한 Effect에서, 각각 독립 발화
local m = 0
local e3 = q.Effect(function() m += 1 end, r, b)
q.bindLifetime(inst, e3)
r:Set(3); A:Set(6)
print("혼합 deps r:Set + A:Set 후 m", m, "(기대 3)")
-- (4) 무인자 state:Observer() 내부 콜백이 3-인자 루프에서 살아남는가
local s = q.Source(0)
local o = s:Observer()        -- function(targetState) targetState:Get() end
o:Subscribe()
local ok, err = pcall(function() s:Set(1) end)
print("무인자 Observer 전파:", if ok then "OK" else "ERROR " .. tostring(err))
-- (5) leaf 죽음 → cleanup 1회, 이후 Ref:Set 무시
q.destroyInst(inst)
print("destroy 후 cleanups", cleanups, "(기대: 직전 + 1)")
local before = runs; r:Set(9)
print("죽은 뒤 Set → runs 변화", runs - before, "(기대 0)")
