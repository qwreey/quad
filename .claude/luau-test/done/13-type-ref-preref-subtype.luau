--!strict
--[[
	검증 대상(타입 전용, 런타임 대상 아님 — 절대 `luau`로 실행하지 말 것,
	`luau-analyze`/`luau-lsp`로만 확인): `PreRef<T>`/`PostRef<T>`가
	구조적으로 `Ref<T>`를 만족하는지(08번 파일이 Source/State에 대해
	검증한 것과 정확히 같은 질문).

	**[재작성, 2026-08-19]** 원래 이 파일은 타입(A)/런타임(B) 두 섹션이
	한 파일에 있었는데, A의 더미 스텁(`fakePreRef(0)`이 `nil`을 반환)이
	런타임에선 "attempt to index nil"로 죽어 B 섹션이 전혀 실행되지
	못했음(`luau-test/STATUS.md` 🟠 항목). 지금은 순수 타입 전용 파일로
	분리 — 런타임 검증은 `22-runtime-ref-preref-postref-brand.luau`가
	담당(PostRef까지 같이 커버, ROADMAP `luau-test/13` 재작성 지침).

	배경: `.claude/base/ref-plan.md`의 "`PostRef`" 절 —
	"`isPostRef`는 `isPreRef`와 같은 층위의 가장 구체적인 항등 체크이고,
	`isRef`가 그 위에 얹히는 상위 개념".

	실행: `luau-analyze 13-type-ref-preref-subtype.luau`
]]

export type Ref<T> = {
	Value: T,
	Set: (self: Ref<T>, value: T) -> Ref<T>,
	Callback: (self: Ref<T>, fn: (T) -> ()) -> Ref<T>,
	Wait: (self: Ref<T>, thread: thread?) -> Ref<T>,
}

-- PreRef/PostRef는 둘 다 "Ref 런타임을 재사용하되 브랜드 태그만 다름"이라고
-- 문서가 명시함 — 타입도 필드 구성이 완전히 동일해야 자연스러움(브랜드
-- 차이는 런타임 전용이라 정적 타입엔 안 드러남)
export type PreRef<T> = {
	Value: T,
	Set: (self: PreRef<T>, value: T) -> PreRef<T>,
	Callback: (self: PreRef<T>, fn: (T) -> ()) -> PreRef<T>,
	Wait: (self: PreRef<T>, thread: thread?) -> PreRef<T>,
}

export type PostRef<T> = {
	Value: T,
	Set: (self: PostRef<T>, value: T) -> PostRef<T>,
	Callback: (self: PostRef<T>, fn: (T) -> ()) -> PostRef<T>,
	Wait: (self: PostRef<T>, thread: thread?) -> PostRef<T>,
}

local function fakePreRef<T>(default: T): PreRef<T>
	return (nil :: any) :: PreRef<T>
end

local function fakePostRef<T>(default: T): PostRef<T>
	return (nil :: any) :: PostRef<T>
end

-- 시도: PreRef<T>/PostRef<T> 값을 Ref<T>가 필요한 자리에 그대로 넘길 수 있는가
local function useAsRef<T>(r: Ref<T>): T
	return r.Value
end

local myPreRef: PreRef<number> = fakePreRef(0)
local viaPreRefSubtype: number = useAsRef(myPreRef) -- <- luau-analyze 확인 포인트 1
print(viaPreRefSubtype)

local myPostRef: PostRef<number> = fakePostRef(0)
local viaPostRefSubtype: number = useAsRef(myPostRef) -- <- luau-analyze 확인 포인트 2
print(viaPostRefSubtype)

-- 음성 대조군 — 타입이 실제로 강제되는지(0 진단이 곧 안전은 아니므로)
local _wrongPreRef: string = useAsRef(myPreRef) -- 반드시 에러: number를 string으로
local _wrongPostRef: string = useAsRef(myPostRef) -- 반드시 에러: number를 string으로

--[[
	확인 포인트:
	1. `viaPreRefSubtype`/`viaPostRefSubtype` 줄이 에러 없이 통과하는가 —
	   구조적 서브타이핑이 PreRef/PostRef 둘 다에 성립하는지.
	2. 음성 대조군 두 줄이 정확히 TypeError로 걸리는가(안 걸리면 이
	   스파이크 자체가 아무것도 검증 못 하고 있다는 뜻).
	3. 이 파일은 절대 `luau`로 실행하지 말 것 — `fakePreRef`/`fakePostRef`가
	   런타임엔 `nil`이라 즉시 크래시함(의도된 것, 타입 전용).
]]
