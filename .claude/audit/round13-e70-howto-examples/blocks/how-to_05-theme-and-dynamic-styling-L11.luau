-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("@game/ReplicatedStorage/Client/UI/Quad")
local D = q.Declaration
-- 클래스별 Modifier 타입(`FrameModifier`/`IntoTextButton` 등)은 quad_roblox 패키지 루트가 내보낸다
local RobloxModule = require("@game/ReplicatedStorage/roblox_packages/quad_roblox")
