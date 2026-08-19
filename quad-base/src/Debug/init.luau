--[[
	InitDebug(module) — `module.debug` 표면 설치.
	`.claude/base/module-lifecycle-plan.md` "모듈 표면의 디버그 플래그" /
	"RunInit — 함수 자체를 릴레이션 키로 쓰는 멱등 가드" 절 그대로.

	멱등 가드는 `module:RunInit(InitDebug)` 호출부(`init.luau`)가 이미
	보장하므로, 이 파일은 조건 없이 딱 한 번만 실행된다는 전제로 그냥
	뮤테이션만 하면 됨 — 자기 자신의 가드를 따로 안 둠.
]]

local function Init(module: any)
	module.debug = false
end

return Init
