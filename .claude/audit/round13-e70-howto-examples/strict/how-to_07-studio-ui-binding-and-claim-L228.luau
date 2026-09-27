--!strict
-- E70 strict (generated) — how-to_07-studio-ui-binding-and-claim-L228
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_07-studio-ui-binding-and-claim-L11) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
local M = D.Mapper
--[[E70 보강 pre]]
local existingScreenGui: ScreenGui = nil :: any
local rows = q.Slot<<Instance>>()
local player = game:GetService("Players").LocalPlayer
-- ==== doc block how-to/07-studio-ui-binding-and-claim.md:228 ====
local screen = q.Claim(existingScreenGui, M.ScreenGui(M.Root)({ rows }))
screen.Parent = player:WaitForChild("PlayerGui") -- 허용: 루트의 Parent는 부기 밖
