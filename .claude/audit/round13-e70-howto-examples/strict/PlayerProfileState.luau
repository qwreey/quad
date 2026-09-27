--!strict
-- E70 strict (generated) — how-to_04-network-and-input-bridge-L37
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_04-network-and-input-bridge-L22) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- ==== doc block how-to/04-network-and-input-bridge.md:37 ====
-- PlayerProfileState.luau (상태 레이어)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local q = require("./Quad") -- 01장의 설정 모듈

local ProfileStore = q.Store({
    Gold = q.Source(0),
    Level = q.Source(1),
})

local ProfileUpdated = ReplicatedStorage:WaitForChild("ProfileUpdated") :: RemoteEvent

ProfileUpdated.OnClientEvent:Connect(function(newData)
    if newData.Gold ~= nil then
        ProfileStore.Gold:Set(newData.Gold)
    end
    if newData.Level ~= nil then
        ProfileStore.Level:Set(newData.Level)
    end
end)

return ProfileStore
