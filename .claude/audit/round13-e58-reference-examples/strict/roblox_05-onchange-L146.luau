--!strict
-- E58 strict (generated) — roblox_05-onchange-L146
-- ==== page prologue roblox/05-onchange.md (roblox_05-onchange-L19.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local RobloxModule = require("../../../../quad-roblox/src") --[[E58: 문서의 자리표시 <quad-roblox 모듈>]] -- 디스크립터 타입 `OnChangeDescriptor`의 공개 경로(루트 재수출)
local D = q.Declaration
-- ==== doc block roblox/05-onchange.md:146 (line offset marker) ====
local text = q.Source("")

local box = D.TextBox({
	Text = text,          -- in: Source → 프로퍼티
	q.Out("Text", text),  -- out: 프로퍼티 → Source
})
-- 사용자가 타이핑하면 text:Get()이 따라오고, text:Set("…")하면 입력창이 따라간다
