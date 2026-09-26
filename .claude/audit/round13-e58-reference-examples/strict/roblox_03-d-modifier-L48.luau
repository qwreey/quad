--!strict
-- E58 strict (generated) — roblox_03-d-modifier-L48
-- ==== page prologue roblox/03-d-modifier.md (roblox_03-d-modifier-L22.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local RobloxModule = require("../../../../quad-roblox/src") --[[E58: 문서의 자리표시 <quad-roblox 모듈>]] -- 클래스별 Modifier 타입의 유일한 공개 경로(루트 재수출 — 생성 모듈 자체는 require 경로가 없습니다)
local D = q.Declaration
-- ==== doc block roblox/03-d-modifier.md:48 (line offset marker) ====
-- 빌더 체인
local base = D.Modifier.GuiObject()
	:Size(UDim2.fromOffset(160, 40))
	:BackgroundColor3(Color3.fromRGB(60, 130, 255))
	:Visible(true)

-- 테이블 형태(+ 병합 — 뒤 인자가 이긴다)
local boxed = D.Modifier.Frame({ BackgroundTransparency = 0.5 }, { Visible = false })

-- 숫자 키 자리에 놓으면 그 자리에서 필드가 펼쳐진다
local card = D.Frame({ boxed, D.Modifier.Frame():ZIndex(2) })
