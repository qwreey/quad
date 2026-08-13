--!strict
--[[
	검증 대상: Source<T>가 구조적으로 State<T>를 만족하는(self 타이핑 +
	State 참조가 섞인 제네릭 :Compute) 설계가 Luau 타입 솔버에서 안전하게
	추론되는지 — 실제 실행이 아니라 타입 체크(luau-analyze) 대상.

	배경: .claude/base/source-state-plan.md "검증 필요(확정 아님, M0 스파이크
	대상)" 절, ROADMAP.md M0 2번째 항목.

	핵심 우려: State<T>가 거꾸로 Source를 참조하는 "상호 재귀"는 Luau
	솔버가 취약한 패턴 — 그래서 아래 State<T>는 Source를 전혀 참조하지
	않도록 독립적으로 먼저 정의하고, Source<T>만 State<T>를 단방향으로
	참조하게 구성함. 타입은 사용자 선호대로 &(교차)가 아니라 손으로
	펼쳐 씀(런타임 구현 델리게이션과는 별개 축이라 상관없음).

	실행: `luau-analyze 08-type-source-satisfies-state.luau`
	(로컬에 luau-analyze가 없으면 Luau 공식 릴리즈의 CLI 툴체인 설치 필요 —
	https://github.com/luau-lang/luau/releases, 또는 lune 배포판에 포함된 것)

	기대 결과: 에러 없이 통과하거나, 통과 안 하면 정확히 *어느 줄에서*
	*무슨 에러*가 나는지가 다음 결정에 중요한 정보임 — 에러가 나면 그
	메시지를 그대로 가져와서 알려줄 것.
]]

-- State<T>는 Source를 절대 참조하지 않음(단방향 의존을 위한 핵심 제약)
export type State<T> = {
	Get: (self: State<T>) -> T,
	With: (self: State<T>, ...State<any>) -> State<any>,
	Compute: <U>(self: State<T>, fn: (T) -> U) -> State<U>,
}

-- Source<T>만 State<T>를 참조(단방향) — self 타이핑(Source<T> 자신을 가리킴)과
-- 바깥 타입 참조(State<U>)가 섞인 제네릭 메소드가 바로 검증 대상
export type Source<T> = {
	Get: (self: Source<T>) -> T,
	With: (self: Source<T>, ...State<any>) -> State<any>,
	Compute: <U>(self: Source<T>, fn: (T) -> U) -> State<U>,
	Set: (self: Source<T>, value: T) -> (),
	Emit: (self: Source<T>) -> (),
}

-- 1. Source 값을 만드는 흉내 생성자(런타임 구현은 아직 없으므로 타입만 맞추는 더미)
local function fakeSource<T>(default: T): Source<T>
	return (nil :: any) :: Source<T>
end

-- 2. State<T>를 요구하는 함수에 Source<T>를 그대로 넘길 수 있는가
--    (구조적 서브타이핑 — "Source가 State를 만족함" 절의 핵심 주장)
local function useAsState<T>(s: State<T>): T
	return s:Get()
end

local mySource: Source<number> = fakeSource(0)
local viaSubtype: number = useAsState(mySource) -- 여기가 타입체크 되는지가 핵심

-- 3. Compute 체이닝이 제네릭을 타고 잘 흐르는가(Source -> State<string> -> State<boolean>)
local derived1: State<string> = mySource:Compute(function(n: number): string
	return tostring(n)
end)
local derived2: State<boolean> = derived1:Compute(function(s: string): boolean
	return #s > 0
end)

-- 4. store.key가 Source<T>를 직접 반환한다는 모델(레코드 필드 읽기/쓰기 대칭)
export type Store = {
	-- 실제로는 defaults의 각 키를 Source<...>로 매핑하는 mapped type이 이상적이지만
	-- Luau에 mapped type이 없으므로(2026-08 시점) 구체 예시 하나로만 검증
	Health: Source<number>,
}

local function useStore(store: Store)
	store.Health:Set(100) -- 쓰기
	local hp: number = store.Health:Get() -- 읽기 — 같은 필드 타입(Source<number>)으로 대칭
	return hp
end

print("이 파일은 luau-analyze로만 의미가 있음 (런타임 실행은 그냥 통과함)")
print(viaSubtype, derived2)
