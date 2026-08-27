--!nocheck
-- 레인 A: EffectHandle 상태 기계 — 모든 진입점 × 모든 상태의 전이를 실제 값으로 찍는다.
-- 열: installed / cleanup 보유 / .Subscribed / 강한 레지스트리 / 약한 레지스트리 / canExecute / running / pending
local q = require("./core10")
local function row(label, e, extra) print(("%-46s | %s%s"):format(label, q.effectState(e), if extra then "  " .. extra else "")) end
local function try(f) local ok, err = pcall(f); return ok, err end

local S = q.Source(0)
local runs, cleans = 0, 0
local function mk(...) return q.Effect(function(self) runs += 1; return function() cleans += 1 end end, ...) end

print("== (1) 생성자 → Subscribe → Unsubscribe → Subscribe(재구독) → WeakUnsubscribe(교차 error) ==")
local e = mk(S)
row("생성 직후", e, ("runs=%d cleans=%d"):format(runs, cleans))
S:Set(1)
row("미구독 상태 Set(1) — 버려져야", e, ("runs=%d"):format(runs))
e:Subscribe()
row("Subscribe (Refresh 캐치업 → Rerun 1회)", e, ("runs=%d cleans=%d"):format(runs, cleans))
S:Set(2)
row("구독 중 Set(2)", e, ("runs=%d cleans=%d"):format(runs, cleans))
e:Unsubscribe()
row("Unsubscribe (cleanup 1회, installed=false)", e, ("runs=%d cleans=%d"):format(runs, cleans))
e:Subscribe()
row("재Subscribe (not installed → Rerun)", e, ("runs=%d cleans=%d"):format(runs, cleans))
print("  Subscribe 두 번:", select(2, try(function() e:Subscribe() end)))
print("  강구독에 WeakUnsubscribe:", select(2, try(function() e:WeakUnsubscribe() end)))
e:Unsubscribe()

print("\n== (2) WeakSubscribe → WeakUnsubscribe(관대, cleanup 미소진) → 재WeakSubscribe ==")
local e2 = mk(S)
e2:WeakSubscribe()
row("WeakSubscribe", e2, ("runs=%d cleans=%d"):format(runs, cleans))
e2:WeakUnsubscribe()
row("WeakUnsubscribe — cleanup 유지, installed 유지", e2, ("runs=%d cleans=%d"):format(runs, cleans))
e2:WeakUnsubscribe()
row("WeakUnsubscribe 두 번 — 통과(H-133)", e2)
S:Set(3)
row("약해제 상태 Set(3) — 버려져야", e2, ("runs=%d"):format(runs))
e2:WeakSubscribe()
row("재WeakSubscribe (dep 변했음 → Rerun)", e2, ("runs=%d cleans=%d"):format(runs, cleans))
local e2b = mk()
e2b:WeakSubscribe(); e2b:WeakUnsubscribe(); local r0 = runs; e2b:WeakSubscribe()
row("deps 없음: Weak해제→재구독 (변화 없음 → no-op)", e2b, ("runs 변화=%d (기대 0)"):format(runs - r0))
print("  약구독에 Unsubscribe:", select(2, try(function() e2:Unsubscribe() end)))

print("\n== (3) leaf: bindLifetime → unbindLifetime(포탈) → 재bind → destroy ==")
local inst, inst2 = q.newInst("inst"), q.newInst("inst2")
local e3 = mk(S)
q.bindLifetime(inst, e3)
row("bindLifetime (Refresh 캐치업: dep 변함 → Rerun)", e3, ("runs=%d cleans=%d"):format(runs, cleans))
print("  leaf에 Subscribe:", select(2, try(function() e3:Subscribe() end)))
print("  leaf에 WeakSubscribe:", select(2, try(function() e3:WeakSubscribe() end)))
print("  leaf에 Unsubscribe:", select(2, try(function() e3:Unsubscribe() end)))
print("  leaf에 WeakUnsubscribe(관대):", select(2, try(function() e3:WeakUnsubscribe() end)))
row("  ↑ 그 뒤 상태 (installed/cleanup 그대로여야)", e3)
print("  leaf를 다른 inst에 bind:", select(2, try(function() q.bindLifetime(inst2, e3) end)))
q.unbindLifetime(e3)
row("unbindLifetime — cleanup 미소진, installed 유지", e3, ("cleans=%d"):format(cleans))
S:Set(4)
row("언바인드 상태 Set(4) — 버려져야", e3, ("runs=%d"):format(runs))
q.bindLifetime(inst2, e3)
row("재bind(포탈) — Refresh true → Rerun", e3, ("runs=%d cleans=%d"):format(runs, cleans))
q.destroyInst(inst2)
row("inst2 destroy — Destroying → cleanup 1회", e3, ("cleans=%d"):format(cleans))
S:Set(5)
row("파괴 뒤 Set(5) — 버려져야", e3, ("runs=%d"):format(runs))
local inst3 = q.newInst("inst3")
q.bindLifetime(inst3, e3)
row("파괴 뒤 재bind — not installed → Rerun (H-65)", e3, ("runs=%d cleans=%d"):format(runs, cleans))
q.unbindLifetime(e3)
e3:Subscribe()
row("unbind 뒤 Subscribe로 전환 (허용)", e3, ("runs=%d cleans=%d"):format(runs, cleans))
e3:Unsubscribe()

print("\n== (4) fn 안 자기 해제 (H-143) ==")
local e4runs, e4cleans = 0, 0
local S4 = q.Source(0)
local e4; e4 = q.Effect(function(self)
    e4runs += 1
    if e4runs == 2 then self:Unsubscribe() end
    return function() e4cleans += 1 end
end, S4)
e4:Subscribe()
S4:Set(6)
row("Set → fn 안 Unsubscribe → 반환 cleanup 즉시 소진", e4, ("e4cleans=%d (기대 2: 직전 소진 1 + 즉시 소진 1) runs=%d"):format(e4cleans, e4runs))
S4:Set(7)
row("죽은 뒤 Set(7) — 버려져야", e4, ("runs=%d"):format(e4runs))

print("\n== (5) fn 안 self:Rerun() (재진입 지연) ==")
local n5 = 0
local e5 = q.Effect(function(self) n5 += 1; if n5 == 1 then self:Rerun() end end)
row("생성자 안 자기 Rerun → pending으로 한 번 더", e5, ("n5=%d (기대 2)"):format(n5))

print("\n== (6) fn 안 dep Set (재진입) ==")
local n6, S6 = 0, q.Source(0)
local e6 = q.Effect(function(self) n6 += 1; if n6 == 2 then S6:Set(99) end end, S6)
e6:Subscribe(); S6:Set(1)
row("구독 중 Set → fn이 dep Set → pending 재실행", e6, ("n6=%d (기대 3)"):format(n6))
e6:Unsubscribe()
