-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("@game/ReplicatedStorage/Client/UI/Quad")
local RobloxModule = require(<quad-roblox 모듈>) -- 클래스별 Modifier 타입의 유일한 공개 경로(루트 재수출 — 생성 모듈 자체는 require 경로가 없습니다)
local D = q.Declaration
