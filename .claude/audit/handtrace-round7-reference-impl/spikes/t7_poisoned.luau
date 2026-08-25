--!nocheck
local q = require("./core")
-- dispatch-core-plan.md "배치 등록을 안전하게 만드는 Blocker 게이팅" 그대로
local blockers = {}   -- Relate(ownerKey) 자리
local function getBlocker(owner)
    if not blockers[owner] then blockers[owner] = q.Blocker() end
    return blockers[owner]
end
local recomputes = 0
local function gatedRecompute(owner)
    if getBlocker(owner):IsOn() then return end   -- 배치 중이면 스킵
    recomputes += 1
end
local function drive(owner, positions)
    local bl = getBlocker(owner)
    bl:On()
    for _, p in positions do
        p()                       -- 각 position 처리(사용자 코드가 여기서 돈다)
        gatedRecompute(owner)     -- setLength가 트리거하는 자리
    end
    bl:OffWithoutEmit()           -- 4번: 배치 끝
    recomputes += 1               -- "그 직후 딱 한 번" 명시적 recompute
end

local inst = {}   -- ownerKey
print("-- 정상 배치 --")
drive(inst, {function() end, function() end})
print("recompute 횟수:", recomputes, "| blocker.IsOn():", getBlocker(inst):IsOn())

print("-- 두 번째 배치에서 사용자 코드가 error --")
local ok = pcall(drive, inst, {function() end, function() error("컴포넌트 실패") end})
print("drive가 던졌는가:", not ok, "| blocker.IsOn():", getBlocker(inst):IsOn(), "← 영구 On")

print("-- 이후 런타임 :Add() 등이 부르는 setLength --")
local before = recomputes
gatedRecompute(inst); gatedRecompute(inst); gatedRecompute(inst)
print("recompute가 몇 번 돌았나:", recomputes - before, "(0이면 그 owner는 영영 재계산 안 됨)")
print("-- 새 배치를 열어도 --")
pcall(drive, inst, {function() end})
print("blocker.IsOn():", getBlocker(inst):IsOn(), "| 총 recompute:", recomputes)
