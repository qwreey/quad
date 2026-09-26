--!strict
-- E58 strict (generated) — roblox_03-d-modifier-L130
-- ==== page prologue roblox/03-d-modifier.md (roblox_03-d-modifier-L22.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local RobloxModule = require("../../../../quad-roblox/src") --[[E58: 문서의 자리표시 <quad-roblox 모듈>]] -- 클래스별 Modifier 타입의 유일한 공개 경로(루트 재수출 — 생성 모듈 자체는 require 경로가 없습니다)
local D = q.Declaration
-- ==== doc block roblox/03-d-modifier.md:130 (line offset marker) ====
local bumped = D.Modifier.Frame():ZIndex(2):ZIndex(function(old)
	if type(old) == "number" then
		return old + 1
	end
	return 1
end)
-- bumped의 ZIndex는 3, 원본은 그대로 2
