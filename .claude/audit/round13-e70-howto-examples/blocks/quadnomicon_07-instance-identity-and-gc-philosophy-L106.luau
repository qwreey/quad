-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("@game/ReplicatedStorage/Client/UI/Quad")
local D = q.Declaration

local template = <Studio에서 만들어 둔 템플릿 Instance>
local M = D.Mapper
local root = q.Claim(template:Clone(), M.Frame(M.Root)({
    M.TextLabel("Title")({ Text = "Hello" }),
    BackgroundTransparency = 0.25,
}))
-- root == 넣은 inst 그대로(타입도 그대로)
