--!strict
--[[
	검증 대상: `[Attribute<<boolean>> "name"] = value`처럼 제네릭 파라미터로
	타입을 명시하는 특수 DI 키를 테이블 리터럴에 쓸 때, `=` 뒤 `value`의
	타입이 실제로 그 제네릭 파라미터로 좁혀지는지 — Luau 타입 솔버가
	"이 계산된 키의 제네릭 인스턴스에 따라 옆 값의 타입이 달라진다"는
	이질적인(heterogeneous) 매핑을 실제로 풀 수 있는지가 핵심.

	배경: .claude/base/attribute-plan.md "[실측 필요, M0/M10]" 절
	(2026-08-09 열한 번째 세션에 새로 명시된 항목 — base 문서 자신이
	"미검증"이라고 못박아둔 몇 안 되는 곳). 문서 원문: "Luau 솔버가 이
	조합을 못 풀면 value가 any로 남을 수 있음 — 단, 타입 추론이 안
	되더라도 런타임 동작에는 영향 없음". 이 스크립트는 그 예상을 실제
	Luau로 확인하는 것.

	실행: `luau-analyze 12-type-attribute-generic-key-narrowing.luau`
	(또는 luau-lsp로 이 파일을 열어 인라인 진단을 확인 — 사용자가 직접
	luau-lsp로 확인할 예정)

	참고: 이건 Roblox 실제 SetAttribute API 타입이 아니라, "제네릭 DI 키 +
	테이블 리터럴 값 타입 연동"이라는 메커니즘 자체만 최소로 흉내낸
	것 — Roblox 전역 타입이 필요 없어서 luau-lsp의 sourcemap 없이도
	그대로 확인 가능함.
]]

-- SpecialKey<T> — Attribute<<T>>(name)이 반환하는 "타입이 실린 키" 흉내
type SpecialKey<T> = { __attributeKeyBrand: T }

local function Attribute<T>(name: string): SpecialKey<T>
	return (nil :: any) :: SpecialKey<T>
end

-- ===== 시도 1: 동질적(homogeneous) 인덱스 시그니처 — 항상 통과해야 함(비교군) =====
-- 이 방식은 "이 테이블의 모든 특수 키가 전부 boolean 값이어야 한다"는
-- 고정된 단일 인스턴스라, 애초에 여러 타입을 섞을 수 없음 — 진짜 검증
-- 대상이 아니라 대조군.
type HomogeneousParams = {
	[SpecialKey<boolean>]: boolean,
}

local homo: HomogeneousParams = {
	[Attribute("Enabled")] = true, -- 이건 당연히 통과해야 함
}

-- ===== 시도 2: 이질적(heterogeneous) — 한 테이블에 boolean/number Attribute를 섞음 =====
-- 이게 진짜 검증 대상: SpecialKey<T>의 T가 키마다 달라도 값이 그 T로
-- 각각 좁혀지는가? (TypeScript의 mapped/conditional type이 있어야 되는
-- 문제 — Luau에 해당 기능이 없으면 아래 셋 중 하나가 일어날 것으로 예상:
-- (a) 두 번째 대입에서 타입 에러, (b) 값 타입이 조용히 any/union으로
-- 뭉개짐, (c) 테이블 타입 자체를 선언하는 시점에 에러)

local mixedProps: { [SpecialKey<any>]: any } = {} -- 일단 any로 도피한 버전(항상 통과할 것)
mixedProps[Attribute("Enabled")] = true
mixedProps[Attribute("Count")] = 5

-- 진짜 물어볼 질문: 개별 대입 표현식 하나만 놓고 봤을 때, Luau가
-- `Attribute<T>(name)`의 제네릭 인스턴스화 결과로 옆의 값 리터럴 타입을
-- 체크/추론해주는지 — 함수 호출 결과 타입과 그 옆 대입값 사이의 관계는
-- "인덱스 시그니처"가 아니라 그냥 "함수 반환 타입에 맞는 변수 대입"
-- 문제로 좁혀서 아래처럼 직접 테스트:

local function setAttributeTyped<T>(key: SpecialKey<T>, value: T)
	-- 실제로는 여기서 SetAttribute(inst, name, value)를 호출하겠지만,
	-- 이 스파이크는 타입 추론 자체만 봄
end

setAttributeTyped(Attribute("Enabled"), true) -- T=boolean으로 추론돼 통과해야 함
setAttributeTyped(Attribute("Count"), 5) -- T=number로 추론돼 통과해야 함
setAttributeTyped(Attribute("Enabled"), 5) -- <- 여기가 핵심: T=boolean인데 5(number)를 넘김.
-- 이게 타입 에러로 잡히면(기대하는 결과) "제네릭 키 함수 호출 패턴"은
-- 최소한 함수 인자 형태로는 잘 작동한다는 뜻 — 그럼 테이블 리터럴
-- `{[Attribute<<T>>(name)] = value}` 안에서도 Luau가 "이건 사실
-- 위 setAttributeTyped 호출과 같은 형태"로 취급해주는지가 다음 질문.

print("런타임 실행은 의미 없음 — luau-analyze/luau-lsp 진단만 확인할 것")
print(homo, mixedProps)

--[[
	확인 포인트 (luau-analyze / luau-lsp):
	1. `setAttributeTyped(Attribute("Enabled"), 5)` 줄에서 실제로 타입
	   에러가 나는가? — 나면 "함수 인자 형태의 제네릭 키+값 연동"은
	   Luau가 지원한다는 뜻.
	2. 위가 통과한다면, 그 다음으로 `mixedProps[Attribute("Enabled")] =
	   5`처럼 **인덱스 대입 문법**으로도 같은 체크가 되는지 직접 추가해
	   실험해볼 것(이 파일엔 일부러 안 넣어둠 — `{[SpecialKey<T>]: T}`류
	   제네릭 인덱스 시그니처를 실제로 선언할 수 있는지부터 luau-lsp가
	   에러를 내는지 먼저 볼 것).
	3. 최종적으로 "제네릭 DI 키를 테이블 리터럴 안에서 쓸 때 값 타입이
	   실제로 좁혀지는지"에 대한 결론이 나오면 attribute-plan.md의
	   "[실측 필요, M0/M10]" 캐비엇을 그 결과로 갱신할 것 — 안 되는 걸로
	   확인되면 "정적 체크는 `BooleanAttribute`류 정적 타입 패밀리 쪽만
	   신뢰 가능"이라는 문서의 fallback 결론이 확정됨.
]]
