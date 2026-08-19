--[[
	quad-base 최상위 진입점.
	`.claude/base/architecture.md` 확정 결정 13 / `.claude/base/module-lifecycle-plan.md`
	"New()의 내부 구성 — InitXxx 팩토리 체이닝" 절 그대로.

	`require(quad-base)`는 이미 만들어진 기본 인스턴스 자체다 — 다중
	인스턴스화가 필요한 드문 경우에만 반환값의 `.New()`를 명시적으로 호출.
]]

local InitDebug = require("@self/Debug")

type Quad = {
	New: () -> Quad,
	debug: boolean,
}

local function New(): Quad
	local module = { New = New } :: Quad

	InitDebug(module)
	-- 서브시스템이 늘어날 때마다 이 자리에 InitXxx(module)를 순서 무관하게 추가

	return module
end

return New()
