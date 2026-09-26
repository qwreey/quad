--!strict
-- E58 strict (generated) — roblox_04-claim-mapper-L132
-- ==== page prologue roblox/04-claim-mapper.md (roblox_04-claim-mapper-L20.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
local M = D.Mapper
-- ==== doc block roblox/04-claim-mapper.md:132 (line offset marker) ====
local function mount(existingScreenGui: ScreenGui, playerGui: Instance)
	local screen = q.Claim(existingScreenGui, M.ScreenGui(M.Root)({}))
	screen.Parent = playerGui -- 허용: 루트의 Parent는 부기 밖
end
