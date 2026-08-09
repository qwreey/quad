--!strict
--[[
	검증 대상: 2026-08-09 열한 번째 세션(커밋 f198fd9)에서 뒤집힌 결정 —
	`isRef`/`isPreRef`가 "서로 배타적인 형제 브랜드"에서 "Source가 State를
	만족하는 것과 같은 포함 관계(PreRef가 Ref의 하위 개념)"로 재정정됨.
	이전엔 `isRef(preRefInstance) == false`였는데, 지금은
	`isRef(preRefInstance) == true`로 바뀜.

	이 파일은 두 부분으로 나뉨:
	A) 타입 체크 대상 — `PreRef<T>`가 구조적으로 `Ref<T>`를 만족하는지
	   (08번 파일이 Source/State에 대해 검증한 것과 정확히 같은 질문을
	   Ref/PreRef에 대해 재검증).
	B) 런타임 대상 — `isRef`/`isPreRef` predicate 합성이 문서에 적힌 대로
	   동작하는지, 그리고 `Dispatch/Leaf.luau`의 `(v=Ref)` 매치 핸들러가
	   이제 `isHandlable = isRef(v) and not isPreRef(v)`로 **명시적으로
	   좁혀야만** PreRef를 잘못 삼키지 않는다는 것.

	배경: .claude/base/bind-system-plan.md의 `Brand` 절
	("isRef(x)는 그 위에 Brand.get(x)==RefTag를 OR로 얹은 상위 개념")와
	"`(v=Ref)` children 배열 leaf 매치 핸들러... isRef(v) and not
	isPreRef(v)로 명시적으로 좁혀야 함" 부분.

	실행:
	  A) `luau-analyze 13-type-ref-preref-subtype.luau` (또는 luau-lsp)
	  B) `luau 13-type-ref-preref-subtype.luau` (런타임 부분은 그냥 통과함,
	     타입 에러가 있어도 런타임 실행 자체는 대부분 luau CLI가 그냥
	     진행시켜줌 — 확실히 하려면 A/B를 따로 luau-analyze/luau로 각각
	     돌려볼 것)
]]

-- ===== A) 타입 체크 대상 =====

export type Ref<T> = {
	Value: T,
	Set: (self: Ref<T>, value: T) -> Ref<T>,
	Callback: (self: Ref<T>, fn: (T) -> ()) -> Ref<T>,
	Wait: (self: Ref<T>, thread: thread?) -> Ref<T>,
}

-- PreRef는 "Ref 런타임을 재사용하되 브랜드 태그만 다름"이라고 문서가
-- 명시함 — 타입도 필드 구성이 완전히 동일해야 자연스러움(브랜드 차이는
-- 런타임 전용이라 정적 타입엔 안 드러남, 아래서 별도 nominal 표시로만 구분)
export type PreRef<T> = {
	Value: T,
	Set: (self: PreRef<T>, value: T) -> PreRef<T>,
	Callback: (self: PreRef<T>, fn: (T) -> ()) -> PreRef<T>,
	Wait: (self: PreRef<T>, thread: thread?) -> PreRef<T>,
}

local function fakePreRef<T>(default: T): PreRef<T>
	return (nil :: any) :: PreRef<T>
end

-- 시도: PreRef<T> 값을 Ref<T>가 필요한 자리에 그대로 넘길 수 있는가
local function useAsRef<T>(r: Ref<T>): T
	return r.Value
end

local myPreRef: PreRef<number> = fakePreRef(0)
local viaSubtype: number = useAsRef(myPreRef) -- <- 여기가 luau-analyze 확인 포인트

print("A) 타입 체크는 luau-analyze/luau-lsp로 확인 — 런타임은 그냥 통과")
print(viaSubtype)

-- ===== B) 런타임 대상 — Brand/isRef/isPreRef predicate 합성 =====

local Brand = {}
local registry = setmetatable({}, { __mode = "k" })
function Brand.set(x, tag)
	registry[x] = tag
end
function Brand.get(x)
	return registry[x]
end

local RefTag, PreRefTag = {}, {}

local function isPreRef(x)
	return Brand.get(x) == PreRefTag
end
local function isRef(x)
	-- 재정정된 합성 — PreRef가 Ref의 하위 개념(OR로 얹음)
	return isPreRef(x) or Brand.get(x) == RefTag
end

local function makeRef()
	local self = {}
	Brand.set(self, RefTag)
	return self
end
local function makePreRef()
	local self = {}
	Brand.set(self, PreRefTag)
	return self
end

local ref1 = makeRef()
local preref1 = makePreRef()

print()
print("=== B-1. isRef/isPreRef 기본 동작 ===")
print("isRef(ref1) =", isRef(ref1), "(true여야 함)")
print("isPreRef(ref1) =", isPreRef(ref1), "(false여야 함 — Ref는 PreRef가 아님)")
print("isRef(preref1) =", isRef(preref1), "(true여야 함 — 2026-08-09 재정정의 핵심)")
print("isPreRef(preref1) =", isPreRef(preref1), "(true여야 함)")

-- Dispatch/Leaf.luau의 (v=Ref) 매치 핸들러 흉내 — PreRef를 잘못 삼키면 안 됨
local function leafRefHandlerIsHandlable(v)
	return isRef(v) and not isPreRef(v)
end

print()
print("=== B-2. Leaf의 (v=Ref) 핸들러가 PreRef를 잘못 삼키지 않는가 ===")
print("leafRefHandlerIsHandlable(ref1) =", leafRefHandlerIsHandlable(ref1), "(true — 일반 Ref는 처리해야 함)")
print(
	"leafRefHandlerIsHandlable(preref1) =",
	leafRefHandlerIsHandlable(preref1),
	"(false여야 함 — PreRef는 pre-pass가 이미 처리했어야 하고, 이 핸들러가 또 삼키면 안 됨)"
)

assert(leafRefHandlerIsHandlable(ref1) == true, "일반 Ref가 Leaf 핸들러에서 거부됨 (버그)")
assert(leafRefHandlerIsHandlable(preref1) == false, "PreRef가 Leaf 핸들러에 잘못 잡힘 (버그 — 2026-08-09 재정정이 요구하는 명시적 좁히기 실패)")
print()
print("assert 전부 통과 — isRef(v) and not isPreRef(v) 조합이 기대대로 동작함")

--[[
	확인 포인트:
	A) luau-analyze/luau-lsp에서 `viaSubtype` 줄이 에러 없이 통과하는가 —
	   08번 파일이 Source/State에 대해 확인했던 것과 같은 결론(구조적
	   서브타이핑 성립)이 Ref/PreRef에도 그대로 적용되는지.
	B) 런타임 assert가 전부 통과하는가 — 특히 `isRef(preref1) == true`
	   (뒤집힌 결정 자체)와 `leafRefHandlerIsHandlable(preref1) == false`
	   (그 뒤집힘 때문에 Leaf 핸들러가 이제 반드시 `not isPreRef(v)`를
	   같이 확인해야 한다는 요구사항)가 실제로 필요한 조합인지.
]]
