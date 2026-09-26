--!strict
-- E58 strict (generated) — roblox_04-claim-mapper-L81
-- ==== page prologue roblox/04-claim-mapper.md (roblox_04-claim-mapper-L20.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
local M = D.Mapper
-- ==== doc block roblox/04-claim-mapper.md:81 (line offset marker) ====
-- 새로 만든 자식과 매핑 자식을 한 배열에 섞어도 된다
local function bindMixed(template: Frame)
	return q.Claim(template, M.Frame(M.Root)({
		M.TextLabel("Title")({ Text = "매핑" }),
		D.TextLabel({ Text = "새로 만든 것" }),
		D.Modifier.Frame():BackgroundTransparency(0.5),
		q.None,
	}))
end
