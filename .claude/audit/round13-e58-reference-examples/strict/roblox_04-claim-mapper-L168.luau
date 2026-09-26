--!strict
-- E58 strict (generated) — roblox_04-claim-mapper-L168
-- ==== page prologue roblox/04-claim-mapper.md (roblox_04-claim-mapper-L20.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
local M = D.Mapper
-- ==== doc block roblox/04-claim-mapper.md:168 (line offset marker) ====
local function CardDescriptor(text: string)
	return M.Frame(M.Root)({ M.TextLabel("Title")({ Text = text }) })
end

local function bindAll(cards: { Frame })
	for _, card in cards do
		q.Claim(card, CardDescriptor("항목")) -- 매번 새 디스크립터
	end
end
