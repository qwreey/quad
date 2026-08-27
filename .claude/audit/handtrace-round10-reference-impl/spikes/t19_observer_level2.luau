--!nocheck
-- H-149 재검토: Observer:Subscribe의 콜론 위임 때문에 error level 2가 어느 줄을 가리키는가
local q = require("./core10")
local S = q.Source(0)
local inst = q.newInst("inst")
local o = S:Observer(function() end)
q.bindLifetime(inst, o)
local ok, err = pcall(function()
    o:Subscribe()      -- ← 사용자 호출부 (이 파일의 줄)
end)
print("Observer(leaf):Subscribe →", err)
local o2 = S:Observer(function() end)
q.bindLifetime(inst, o2)
local ok2, err2 = pcall(function()
    o2:WeakSubscribe() -- ← 사용자 호출부
end)
print("Observer(leaf):WeakSubscribe →", err2)
-- 대조: EffectHandle은 인라인이라 사용자 줄을 가리킨다
local e = q.Effect(function() end)
q.bindLifetime(inst, e)
local ok3, err3 = pcall(function()
    e:Subscribe()      -- ← 사용자 호출부
end)
print("Effect(leaf):Subscribe →", err3)
