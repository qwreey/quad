--!nocheck
-- 레인 A: leaf Effect의 fn이 자기 inst를 동기 파괴(Immediate 모드 흉내) → H-143 판정이 잡는가
local q = require("./core10")
local inst = q.newInst("inst")
local S = q.Source(0)
local cleans, runs = 0, 0
local e = q.Effect(function(self)
    runs += 1
    if runs == 2 then q.destroyInst(inst) end     -- 두 번째 실행에서 자기 inst 파괴
    return function() cleans += 1 end
end, S)
q.bindLifetime(inst, e)
print("bind 후", q.effectState(e), "runs", runs, "cleans", cleans)
S:Set(1)
print("fn 안 destroy 후", q.effectState(e), "runs", runs, "cleans", cleans, "(기대 cleans=2: 루프 머리 소진 1 + 즉시 소진 1)")
S:Set(2)
print("파괴 뒤 Set", "runs", runs, "(기대 2)")
