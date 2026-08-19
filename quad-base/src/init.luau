--[[
	quad-base 최상위 진입점.
	`.claude/base/architecture.md` 확정 결정 13 / `.claude/base/module-lifecycle-plan.md`
	"New()의 내부 구성 — InitXxx 팩토리 체이닝" / "RunInit — 함수 자체를
	릴레이션 키로 쓰는 멱등 가드" 절 그대로.

	`require(quad-base)`는 이미 만들어진 기본 인스턴스 자체다 — 다중
	인스턴스화가 필요한 드문 경우에만 반환값의 `.New()`를 명시적으로 호출.
]]

local Relate = require("@self/Relate")
local InitDebug = require("@self/Debug")

-- (module, initFn) -> 이미 실행됐는가. New()가 몇 번 불려도 module마다
-- weak-키잉되므로 별도 정리 불필요(module이 GC되면 이 기록도 같이 사라짐).
local runInitRelate = Relate()

type Quad = {
	New: () -> Quad,
	RunInit: (self: Quad, initFn: (Quad) -> any) -> (),
	debug: boolean,
}

local function New(): Quad
	local module = { New = New } :: Quad

	function module.RunInit(self, initFn)
		if runInitRelate:GetStrong(self, initFn) then
			return -- 이 module 인스턴스에 이 initFn은 이미 실행됨, no-op
		end
		runInitRelate:SetStrong(self, initFn, true) -- 실제 실행 전에 먼저 표시(순환 의존 대비)
		initFn(self)
	end

	module:RunInit(InitDebug)
	-- 서브시스템이 늘어날 때마다 이 자리에 module:RunInit(InitXxx)를 순서 무관하게 추가

	return module
end

return New()
