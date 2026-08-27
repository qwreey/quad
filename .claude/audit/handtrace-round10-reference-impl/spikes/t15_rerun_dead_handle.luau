--!nocheck
-- H-147 재검토: 진입 시점에 이미 죽은 핸들에서 Rerun()이 불리면.
local q = require("./core10")
local S = q.Source(0)
local function row(l, e, x) print(("%-52s | %s  %s"):format(l, q.effectState(e), x or "")) end

print("== 케이스 (1): 직전 cleanup이 self:Unsubscribe()를 부른다 ==")
local runs1, cleans1 = 0, 0
local e1; e1 = q.Effect(function(self)
    runs1 += 1
    return function() cleans1 += 1; if cleans1 == 1 then self:Unsubscribe() end end
end, S)
e1:Subscribe()
S:Set(1)   -- Rerun: 루프 머리 _consumeCleanup → cleanup이 Unsubscribe → wasAlive=false → fn 실행(!)
row("Set 후", e1, ("runs=%d (죽은 뒤 fn이 돌았으면 2) cleans=%d"):format(runs1, cleans1))
S:Set(2)
row("다음 Set — 버려짐", e1, ("runs=%d"):format(runs1))
e1:Subscribe()   -- 재구독: _installed가 true라 resubscribeTail이 Rerun을 생략(Refresh는 true)
row("재Subscribe — Refresh true라 Rerun은 돈다", e1, ("runs=%d cleans=%d"):format(runs1, cleans1))
e1:Unsubscribe()
row("Unsubscribe — 고아였던 cleanup이 여기서 소진되는가", e1, ("cleans=%d"):format(cleans1))

print("\n== 케이스 (2): Unsubscribe 뒤 타이머의 self:Rerun() ==")
local runs2, cleans2 = 0, 0
local e2 = q.Effect(function(self) runs2 += 1; return function() cleans2 += 1 end end, S)
e2:Subscribe(); e2:Unsubscribe()
row("Unsubscribe 직후", e2, ("runs=%d cleans=%d"):format(runs2, cleans2))
e2:Rerun()   -- 타이머 흉내
row("죽은 핸들 Rerun() — fn 실행 + cleanup 저장", e2, ("runs=%d cleans=%d"):format(runs2, cleans2))
collectgarbage()   -- 아무도 안 잡으면 cleanup은 영영 안 불린다(사용자가 e2를 잡고 있는 한 남아 있다)
e2:Subscribe()
row("재Subscribe — installed=true, Refresh false → Rerun 생략", e2, ("runs=%d cleans=%d"):format(runs2, cleans2))
e2:Unsubscribe()
row("Unsubscribe — 죽은 실행의 cleanup이 소진됨", e2, ("cleans=%d (소진됐으면 2)"):format(cleans2))

print("\n== 케이스 (3): leaf 파괴 뒤 타이머의 self:Rerun() ==")
local inst = q.newInst("inst")
local runs3, cleans3 = 0, 0
local e3 = q.Effect(function(self) runs3 += 1; return function() cleans3 += 1 end end, S)
q.bindLifetime(inst, e3)
q.destroyInst(inst)
row("destroy 직후", e3, ("runs=%d cleans=%d"):format(runs3, cleans3))
e3:Rerun()
row("죽은 leaf 핸들 Rerun()", e3, ("runs=%d cleans=%d BindData(gcconn dead)=%s"):format(runs3, cleans3, tostring(q.BindData[e3] ~= nil)))
local inst2 = q.newInst("inst2")
q.bindLifetime(inst2, e3)
row("재bind — installed=true라 Refresh 없으면 Rerun 생략", e3, ("runs=%d cleans=%d"):format(runs3, cleans3))
q.destroyInst(inst2)
row("inst2 destroy — 그 cleanup 소진", e3, ("cleans=%d"):format(cleans3))

print("\n== 케이스 (0) 대조군: 생성자 최초 Rerun은 죽은 게 아니라 '산 적 없음' ==")
local e0 = q.Effect(function() return function() end end)
row("생성 직후 (installed=true여야 — H-143 회귀 대조)", e0)
