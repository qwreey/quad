--!strict
-- E58 strict (generated) — roblox_05-onchange-L79
-- ==== page prologue roblox/05-onchange.md (roblox_05-onchange-L19.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local RobloxModule = require("../../../../quad-roblox/src") --[[E58: 문서의 자리표시 <quad-roblox 모듈>]] -- 디스크립터 타입 `OnChangeDescriptor`의 공개 경로(루트 재수출)
local D = q.Declaration
-- ==== doc block roblox/05-onchange.md:79 (line offset marker) ====
local seen = {}
D.TextLabel({
	Text = "a", -- 문자 키: 아래 바인딩이 연결된 뒤에 쓰인다
	q.OnChange("Text", function(v)
		table.insert(seen, v) -- seen[1] == "a"
	end),
})
