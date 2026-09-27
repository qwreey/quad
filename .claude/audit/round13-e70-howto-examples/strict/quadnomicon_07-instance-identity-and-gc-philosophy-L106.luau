--!strict
-- E70 strict (generated) — quadnomicon_07-instance-identity-and-gc-philosophy-L106
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
--[[E70 보강 pre]]
local __tplRoot: Frame = nil :: any
-- ==== doc block quadnomicon/07-instance-identity-and-gc-philosophy.md:106 ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration

local template = --[[E70 보강]] __tplRoot
local M = D.Mapper
local root = q.Claim(template:Clone(), M.Frame(M.Root)({
    M.TextLabel("Title")({ Text = "Hello" }),
    BackgroundTransparency = 0.25,
}))
-- root == 넣은 inst 그대로(타입도 그대로)
