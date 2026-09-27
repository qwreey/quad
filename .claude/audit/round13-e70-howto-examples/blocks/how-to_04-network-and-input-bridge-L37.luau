-- PlayerProfileState.luau (상태 레이어)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local q = require("@game/ReplicatedStorage/Client/UI/Quad") -- 01장의 설정 모듈

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
