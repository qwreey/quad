--[[
	InitDebug(module) — `module.debug` 표면 설치.
	`.claude/base/module-lifecycle-plan.md` "모듈 표면의 디버그 플래그" /
	"New()의 내부 구성 — InitXxx 팩토리 체이닝" 절 그대로.

	각 InitXxx가 따르는 멱등 가드 모양의 첫 실제 사례 — 파일 스코프
	`relate`(클로저 밖)로 "이 particular module 인스턴스에 이미 Init됐는가"를
	기록한다.
]]

local Relate = require("./Relate")

local relate = Relate() -- 파일 스코프, 이 Init 전체가 공유하는 단 하나의 인스턴스
local INITED = {} -- 이 파일 전용 유일 키(다른 InitXxx의 relate와 네임스페이스가 안 겹침)

local function Init(module: any)
	if relate:GetStrong(module, INITED) then
		return -- 이미 이 module 인스턴스엔 Init됨, no-op
	end
	relate:SetStrong(module, INITED, true) -- 실제 작업 전에 먼저 표시(순환 의존 대비)

	module.debug = false
end

return Init
