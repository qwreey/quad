--[[
	quad-base 최상위 진입점.
	`.claude/base/architecture.md` 확정 결정 13 / `.claude/base/module-lifecycle-plan.md`
	"New()의 내부 구성 — InitXxx 팩토리 체이닝" / "RunInit — 함수 자체를
	릴레이션 키로 쓰는 멱등 가드" / "AddPlugin" 절 그대로.

	`require(quad-base)`는 이미 만들어진 기본 인스턴스 자체다 — 다중
	인스턴스화가 필요한 드문 경우에만 반환값의 `.New()`를 명시적으로 호출.

	`Quad` 타입 자체는 여기서 선언하지 않고 `quad-types`(워크스페이스
	패키지, 구현 없이 타입 계약만)에서 그대로 가져와 씀 — quad-roblox 같은
	백엔드 패키지가 이 무거운 quad-base 전체 대신 `quad-types`만 의존할 수
	있게 하기 위함(`.claude/base/project-setup-plan.md` "quad-types" 절).
]]

local Relate = require("@self/Relate")
local Brand = require("@self/Brand")
local Ref = require("@self/Ref")
local Void = require("@self/Void")
local QuadTypes = require("./roblox_packages/quad_types")
local InitDebug = require("@self/Debug")
local InitLifetimeHandle = require("@self/LifetimeHandle")
local State = require("@self/State")
local InitSource = require("@self/Source")
local InitStore = require("@self/Store")
local Observer = require("@self/Observer")
local Effect = require("@self/Effect")

type Quad = QuadTypes.Quad

-- (module, initFn) -> 이미 실행됐는가. New()가 몇 번 불려도 module마다
-- weak-키잉되므로 별도 정리 불필요(module이 GC되면 이 기록도 같이 사라짐).
local runInitRelate = Relate()

local function New(): Quad
	local module = {
		New = New,
		Version = "0.0.0",

		-- M2 공통 기반 — 의존 없는 잎 모듈 재export(`ROADMAP.md` M2 `H-80`)
		Relate = Relate,
		Void = Void,
		Ref = Ref,
		isEpoch = Brand.isEpoch,
		isSource = Brand.isSource,
		isState = Brand.isState,
		isStore = Brand.isStore,
		isObserver = Brand.isObserver,
		isEffect = Brand.isEffect,
		isBlocker = Brand.isBlocker,
		isModifier = Brand.isModifier,
		isRef = Brand.isRef,
		isPreRef = Brand.isPreRef,
		isPostRef = Brand.isPostRef,
	} :: Quad

	function module.RunInit(self, initFn)
		if runInitRelate:GetStrong(self, initFn) then
			return -- 이 module 인스턴스에 이 initFn은 이미 실행됨, no-op
		end
		runInitRelate:SetStrong(self, initFn, true) -- 실제 실행 전에 먼저 표시(순환 의존 대비)
		initFn(self)
	end

	function module.AddPlugin(self, pluginFn)
		local extension = pluginFn(self)
		for k, v in extension :: any do
			(self :: any)[k] = v
		end
		return self :: any
	end

	module:RunInit(InitDebug)
	module:RunInit(InitLifetimeHandle) -- 생명주기 4종 에러 스텁 — 백엔드가 덮어씀
	-- 반응형 코어(M2 단위 2) — `H-174`: 인스턴스별 팩토리. 각 Init이 자기 의존성을
	-- `module:RunInit(...)`로 직접 당겨오므로(멱등) 여기 순서는 무관하다.
	module:RunInit(State.Init)
	module:RunInit(InitSource)
	module:RunInit(InitStore)
	module:RunInit(Observer.Init) -- 단위 3 — 레지스트리 둘의 소유 모듈(`H-99`)
	module:RunInit(Effect.Init)
	-- 서브시스템이 늘어날 때마다 이 자리에 module:RunInit(InitXxx)를 순서 무관하게 추가

	return module
end

return New()
