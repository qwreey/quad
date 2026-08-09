--!strict
--[[
	검증 대상: Modifier.Overridden(mod1, mod2, ...)가 서브타입 관계인
	서로 다른 Modifier 타입(FrameModifier <: GuiObjectModifier)을 섞을 때
	타입이 통과하는지 — 필드 setter가 전부 self를 반환하는 fluent 타입이라
	구조적 서브타이핑이 실제로 성립하는지가 관건.

	배경: .claude/base/modifier-plan.md 9-2번 절, ROADMAP.md M7.
	"막히는 지점"으로 문서가 지목한 것: `:BackgroundColor3` 같은 메소드가
	FrameModifier에서는 FrameModifier를, GuiObjectModifier에서는
	GuiObjectModifier를 리턴하므로 같은 이름 필드의 리턴 타입이 갈려서
	단순 구조적 서브타이핑이 깨질 수 있음.

	이 파일은 두 버전을 나란히 둠:
	  A) "정직한" 버전 — 메소드 리턴 타입이 각자 자기 자신
	  B) fallback 버전 — 문제가 생기면 쓸 `Overridden(...: any): any` 완화형
	luau-analyze를 돌려서 A가 실제로 어디서 막히는지(또는 안 막히는지)
	확인하는 게 목적.

	실행: `luau-analyze 09-type-modifier-overridden-subtype.luau`
]]

-- ===== A) 정직한 버전 =====

export type GuiObjectModifier = {
	-- Color3 대신 number로 단순화(luau-analyze 단독 실행 환경엔 Roblox 타입이 없을 수 있어서)
	BackgroundColor3: (self: GuiObjectModifier, v: number) -> GuiObjectModifier,
	Apply: (self: GuiObjectModifier, f: (GuiObjectModifier) -> GuiObjectModifier) -> GuiObjectModifier,
}

export type FrameModifier = {
	BackgroundColor3: (self: FrameModifier, v: number) -> FrameModifier,
	Apply: (self: FrameModifier, f: (FrameModifier) -> FrameModifier) -> FrameModifier,
	ClipsDescendants: (self: FrameModifier, v: boolean) -> FrameModifier, -- Frame 전용 필드
}

local function fakeFrameModifier(): FrameModifier
	return (nil :: any) :: FrameModifier
end

-- 시도 1: FrameModifier 값을 GuiObjectModifier 변수에 그대로 대입 — 통과하는가?
local frameMod: FrameModifier = fakeFrameModifier()
local asGuiObjectMod: GuiObjectModifier = frameMod -- <- 여기가 luau-analyze 에러 나는지 확인 포인트 1

-- 시도 2: Overridden을 GuiObjectModifier 시그니처로 선언하고 FrameModifier를 인자로 넘김
local function OverriddenHonest(...: GuiObjectModifier): GuiObjectModifier
	return (nil :: any) :: GuiObjectModifier
end
local result1 = OverriddenHonest(frameMod) -- <- 확인 포인트 2

-- ===== B) fallback(any) 버전 =====

local function OverriddenLoose(...: any): any
	return (nil :: any)
end
local result2 = OverriddenLoose(frameMod, asGuiObjectMod) -- 이건 항상 통과해야 함(any이므로)

print("런타임 실행 자체는 의미 없음 — luau-analyze 출력을 확인할 것")
print(result1, result2)

--[[
	확인 포인트:
	1. "시도 1"(asGuiObjectMod 대입)에서 luau-analyze가 에러를 내는가?
	   낸다면 정확한 에러 메시지(타입 불일치 상세)를 기록해둘 것 —
	   BackgroundColor3 필드의 리턴 타입 불일치 때문인지, 아니면 다른
	   이유인지가 다음 설계 결정에 중요함.
	2. "시도 2"(함수 인자로 넘기기)도 같은 결과가 나오는가, 아니면 대입과
	   함수 인자 전달이 Luau에서 다르게 취급되는가(공변성 처리 차이 가능성).
	3. A가 전부 막히면 -> .claude/base/modifier-plan.md 9-2번의 fallback대로
	   `Overridden(...: any): any`로 확정하고 이 항목을 M7에서 다시 열 것.
	   A가 통과하면 -> 서브타입 체이닝을 정식으로 타입에 반영할 수 있다는
	   뜻이니 그 결과를 modifier-plan.md에 반영할 것.
]]
