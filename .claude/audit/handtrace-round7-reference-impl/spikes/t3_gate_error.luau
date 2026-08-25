--!nocheck
local q = require("./core")

print("=== (a) blocker:Off() 순회 중 한 핸들이 error ===")
local A = q.Source(1)
local B = q.Source(1)
local b = q.Blocker()
local g1 = q.Gate(A, function(emit) return b:Policy(emit) end, "g1")
local g2 = q.Gate(B, function(emit) return b:Policy(emit) end, "g2")
local seen1, seen2 = {}, {}
local o1 = q.Observer(g1, function() error("g1 하류에서 실패") end, "o1")
local o2 = q.Observer(g2, function() table.insert(seen2, g2:Get()) end, "o2")
b:On()
A:Set(2); B:Set(2)
print("보류 중 — g1.withheld 비었나:", next(g1.withheld) == nil, "| g2.withheld 비었나:", next(g2.withheld) == nil)
local ok, err = pcall(function() b:Off() end)
print("Off()가 던졌는가:", not ok, "|", err)
print("blocker.IsBlocked:", b.IsBlocked, "(이미 false — Off는 상태부터 바꾼다)")
print("g2가 아직 붙들고 있나(비었으면 flush됨):", next(g2.withheld) == nil, "| o2 발화:", o2.fires)
print("→ g2는 IsBlocked=false 인데도 밀린 통지를 못 내보냄. b:Off()를 다시 불러도:")
B.subs[g2] = B.subs[g2]  -- no-op
local ok2 = pcall(function() b:Off() end)
print("   두 번째 Off도 같은 자리에서 던짐:", not ok2, "| o2 발화:", o2.fires)

print()
print("=== (b) flush 도중 error → 떼어낸 배치가 소멸 ===")
local S = q.Source(1)
local bl = q.Blocker()
local g = q.Gate(S, function(emit) return bl:Policy(emit) end, "g")
local boom = true
local seen = {}
local o = q.Observer(g, function()
    if boom then error("하류 실패") end
    table.insert(seen, g:Get())
end, "o")
bl:On()
S:Set(2)
print("보류됨. withheld 비었나:", next(g.withheld) == nil)
pcall(function() bl:Off() end)
print("flush 진입 후 withheld 비었나(스왑됨):", next(g.withheld) == nil, "| flush 횟수:", g.flushes)
print("gate.emitEpochMap은 이미 Sync됨 → 같은 리비전은 이제 규칙 3으로 삼켜진다")
boom = false
-- 같은 리비전이 다른 경로로 다시 도착하는 상황을 재현
g:_receive(S)
print("같은 리비전 재도착 후 o 발화:", o.fires, "| 관측:", table.concat(seen, ","))
print("→ 배치는 사라졌고 재도착도 삼켜져, 그 변경에 대한 통지가 영영 안 나감")
print("   (값은 살아있다: g:Get() =", g:Get(), ")")
