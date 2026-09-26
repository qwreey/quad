--!strict
-- E58 strict (generated) — roblox_04-claim-mapper-L50
-- ==== page prologue roblox/04-claim-mapper.md (roblox_04-claim-mapper-L20.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
local M = D.Mapper
-- ==== doc block roblox/04-claim-mapper.md:50 (line offset marker) ====
-- template: Studio에서 만들어 둔(또는 Clone한) 트리
local function bindCard(template: Frame): Frame
	local title = q.Source("안녕")

	local root = q.Claim(template, M.Frame(M.Root)({
		BackgroundTransparency = 0.25,               -- 루트 자신의 props
		M.TextLabel("Title")({ Text = title }),      -- 이름이 "Title"인 직계 자식
		M.Frame("List")({                            -- 중첩도 된다
			M.TextLabel("Inner")({ Text = "깊은 자식" }),
		}),
	}))

	title:Set("반가워") -- claim한 트리도 반응형: 그대로 프로퍼티가 따라간다
	return root
end
