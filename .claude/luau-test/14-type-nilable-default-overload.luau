--!strict
--[[
	검증 대상: `Source(default)`/`Ref(default)`의 `default` 인자를 생략할 수
	있는 건 오직 `T`가 nilable(`T?`)일 때뿐이라는 캐비엇(2026-08-09
	열한 번째 세션, 커밋 f198fd9 신규) — "타입으로 막을 수 있으면 막고
	안 되면 UB로 문서 경고"라고 base 문서가 적어둔 부분을 실제로 타입
	오버로드로 막을 수 있는지 검증.

	배경: .claude/base/bind-system-plan.md "[보강, 2026-08-09 열한 번째
	세션] Source(default)/Ref(default)의 default 인자가 '선택'이라는
	서술은 정확히는 T가 nil을 포함할 때만 성립함" 절. 문제 상황:
	`Ref<number>()`(default 생략)를 만들면 실제 런타임 값은 `nil`인데
	`T=number`(non-nilable)라고 선언하면 타입과 실제 값이 어긋남 —
	특히 `:Callback(fn)`이 등록 즉시 그 시점 값(nil)으로 1회 호출되므로
	이 어긋남이 바로 드러남.

	시도할 두 가지 설계:
	A) 단일 시그니처 `Ref<T>(default: T?): Ref<T>` — default를 항상
	   optional로 열어둠. 이러면 `Ref<number>()`가 타입 에러 없이
	   통과해버려서(캐비엇을 막지 못함) 이게 바로 지금 실제로 벌어지고
	   있는 문제 상황.
	B) 오버로드 흉내 — `default: T` 필수 시그니처와 `(): Ref<T?>`
	   무인자 시그니처 두 개를 함수 타입 교차(`&`)로 합쳐, "생략하면
	   자동으로 반환 타입이 T?로 바뀐다"를 강제할 수 있는지.

	실행: `luau-analyze 14-type-nilable-default-overload.luau` (또는
	luau-lsp)
]]

export type Ref<T> = {
	Value: T,
	Set: (self: Ref<T>, value: T) -> Ref<T>,
}

-- ===== A) 단일 시그니처 — default가 항상 optional(현재 캐비엇이 실제로 벌어지는 형태) =====

local function RefA<T>(default: T?): Ref<T>
	return (nil :: any) :: Ref<T>
end

local refA1: Ref<number> = RefA(5) -- 정상 — 통과해야 함
local refA2: Ref<number> = RefA() -- <- 문제의 그 케이스: default 생략, T=number(non-nilable)인데
-- 통과해버리면(기대되는 나쁜 결과) 이게 바로 캐비엇이 막고 싶어하는 구멍 —
-- 런타임엔 .Value가 nil인데 타입은 number라고 거짓말하는 상태가 됨.

-- ===== B) 오버로드 흉내 — 함수 타입 교차로 "생략 시 T?" 강제 시도 =====

type RefCtorOverload = (<T>(default: T) -> Ref<T>) & (<T>() -> Ref<T?>)

local RefB: RefCtorOverload = (nil :: any) :: RefCtorOverload

local refB1: Ref<number> = RefB(5) -- 정상 — 첫 번째 오버로드(T=number)로 통과해야 함
local refB2 = RefB() -- 두 번째 오버로드로 잡혀야 함 — 추론된 타입이 Ref<unknown?> 류가 될 것으로 예상
-- 아래가 진짜 확인 대상: refB2를 non-nilable Ref<number>에 대입하면 막히는가?
local refB2_annotated: Ref<number> = RefB() -- <- 이것도 에러가 나야 "막혔다"고 할 수 있음
-- (T가 추론 컨텍스트에서 number로 잡히면서 동시에 "무인자 오버로드라 T?
-- 여야 한다"는 두 요구가 충돌하는지가 관건 — 충돌해서 에러가 나면 성공,
-- 조용히 number로 통과해버리면 오버로드로도 못 막는다는 뜻)

-- 대조군 — nilable로 명시하면 항상 통과해야 함(오버로드가 정상 케이스는 안 막는지 확인)
local refB3: Ref<number?> = RefB()

print("런타임 실행은 의미 없음 — luau-analyze/luau-lsp 진단만 확인할 것")
print(refA1, refA2, refB1, refB2, refB2_annotated, refB3)

--[[
	확인 포인트:
	1. A) `refA2 = RefA()` 줄이 에러 없이 통과하는가? (예상: 통과함 —
	   이게 바로 "타입으로 못 막는" 현재 상태를 보여주는 대조군)
	2. B) `refB2_annotated: Ref<number> = RefB()` 줄이 에러가 나는가?
	   - 에러가 나면: 오버로드 방식으로 실제로 이 캐비엇을 타입 레벨에서
	     막을 수 있다는 뜻 — base 문서의 "타입으로 막을 수 있으면 막을 것"
	     을 실제 설계로 채택할 근거가 생김, `Source`/`Ref` 생성자를
	     이 오버로드 모양으로 다시 쓸 것.
	   - 에러가 안 나면(조용히 통과): Luau의 제네릭 함수 교차 타입
	     오버로드가 이 정도로 정교한 추론을 못 한다는 뜻 — 문서의
	     "안 되면 UB로 경고"가 fallback이 아니라 사실상 유일한 선택지로
	     확정됨.
	3. `refB3`(nilable로 명시한 정상 케이스)는 항상 통과하는가 — 오버로드
	   자체가 정상 사용까지 막아버리는 부작용은 없는지 확인.
	4. 이 결과가 나오면 `bind-system-plan.md`의 해당 캐비엇 절에 "실측
	   결과"로 반영할 것 — 지금은 "타입으로 막을 수 있으면 막고"라는
	   조건문으로만 적혀 있어서 결론이 필요함.
]]
