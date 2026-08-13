--!strict
--[[
	검증 대상: `:Compute(fn, ...)`의 trailing deps를 `fn`의 위치 인자로도
	노출하는 확장(2026-08-11 후속 세션)이 Luau generic type pack으로
	타입 가능한지.

	배경: base/bind-system-plan.md "trailing deps를 `fn`에 lazy positional
	인자로도 노출" 절. `self`는 이미 raw 값이 아니라 State<T> 핸들로
	넘어가는 게 확정돼 있고(2026-08-07), trailing deps도 같은 원칙(State<U>
	핸들)으로 `fn`에 노출하고 싶음.

	**순서는 이미 정정되어 확정됨 — `fn(self, previous?, ...deps)`.**
	처음엔 `previous?`를 deps 팩 뒤에 두려 했으나(팩 뒤에 고정 인자),
	Luau 값 레벨 `...`(vararg)가 파라미터 리스트 맨 끝에만 올 수 있는 것과
	똑같이 타입 레벨 제네릭 팩도 항상 맨 끝이어야 한다는 사용자 지적으로
	`previous?`를 팩 **앞**(self 바로 다음)으로 옮김 — 이 파일의 (C)는 그
	잘못된(옛) 순서가 실제로 막히는지 보여주는 음성 대조군, (D)는 정정된
	순서가 통과하는지 보여주는 양성 대조군. 남은 진짜 불확실성은 (B) 서로
	다른 타입의 deps 여러 개를 제네릭 팩 하나로 표현 가능한지뿐.

	실행: luau-analyze 15-type-compute-trailing-deps-typepack.luau
	(또는 luau-lsp)

	[정정, 2026-08-13 첫 실측 라운드] 위 실행 결과는 **파싱 실패
	(SyntaxError)** — 아래 (C) 음성 대조군의 옛-순서 타입 표기가
	`TypeError`가 아니라 `SyntaxError`로 걸려서 파일 전체가 파싱 단계에서
	막힘. 그 결과 (A)/(B)/(D)를 포함해 이 파일의 어떤 섹션도 개별적으로
	검증되지 못한 상태 — 위 "이미 정정되어 확정됨"/"남은 진짜 불확실성은
	(B)뿐"이라는 서술은 재작성 전까지는 검증되지 않은 기대치로 읽을 것.
	재작성 시 (C) 대조군을 별도 파일/블록으로 격리해야 함. 상세는
	`luau-test/STATUS.md` 🟠 항목. 다만 `:Compute(fn)` lazy 핸들 계약
	충돌 자체(`question.md` 0-Y)는 이 파일과 별개로 다른 최소 재현으로
	이미 확인됨 — 이 파일의 파싱 실패가 0-Y 판단을 바꾸지 않음.
]]

export type State<T> = {
	Get: (self: State<T>) -> T,
}

-- ===== A) self + 단일 dep(대조군) — 팩 없이 고정 인자로 정확히 좁혀지는지 =====

local function ComputeA<T, U, V>(
	self: State<T>,
	fn: (State<T>, State<U>) -> V,
	dep: State<U>
): State<V>
	return (nil :: any) :: State<V>
end

local selfState: State<number> = (nil :: any) :: State<number>
local depString: State<string> = (nil :: any) :: State<string>
local depBool: State<boolean> = (nil :: any) :: State<boolean>

local resultA = ComputeA(selfState, function(s, d)
	local n: number = s:Get() -- s가 State<number>로 좁혀지는지
	local str: string = d:Get() -- d가 State<string>으로 좁혀지는지
	return n
end, depString)

-- ===== B) 이형(heterogeneous) 다중 deps — 제네릭 타입 팩(U...)으로 시도 =====

-- 관건: dep1(State<string>)과 dep2(State<boolean>)처럼 서로 다른 타입을
-- 하나의 제네릭 팩 U...에 넣었을 때, fn 정의부에서 각 원소가 개별 타입으로
-- 정확히 풀리는가 — 아니면 팩이 "동종 타입 하나"로만 취급돼 못 넣거나
-- any/unknown으로 뭉개지는가.
local function ComputeB<T, V, U...>(
	self: State<T>,
	fn: (State<T>, U...) -> V,
	...: U...
): State<V>
	return (nil :: any) :: State<V>
end

local resultB = ComputeB(selfState, function(s, ...)
	local a, b = ...
	-- a는 State<string>, b는 State<boolean>으로 각각 좁혀져야 정확한 것 —
	-- 아래 두 줄이 에러 없이 통과하는지가 핵심 확인 지점
	local str: string = a:Get()
	local bool: boolean = b:Get()
	return s:Get()
end, depString, depBool)

-- ===== C) [음성 대조군] previous를 팩 뒤에 고정 인자로 — 막혀야 정상 =====

-- 처음 제안했던(틀린) 순서. Luau 값 레벨 `...`(vararg)는 파라미터 리스트
-- 맨 끝에만 올 수 있다는 제약이 있음 — 타입 레벨 제네릭 팩(U...)도 함수
-- 타입 시그니처에서 같은 제약을 받는다면, 팩 뒤에 고정 타입(V?)이 오는
-- 아래 정의 자체가 파싱/타입체크 단계에서 막혀야 함. **이 줄이 에러
-- 없이 통과해버리면 오히려 예상과 다른 결과** — 그러면 원래 "previous를
-- 마지막에 두는" 안도 다시 검토 대상이 됨.
local function ComputeC<T, V, U...>(
	self: State<T>,
	fn: (State<T>, U..., V?) -> V, -- <- 팩 U... 뒤에 고정 V?가 오는(틀린) 시그니처
	...: U...
): State<V>
	return (nil :: any) :: State<V>
end

-- ===== D) [양성 대조군] previous를 팩 앞, self 바로 다음에 — 통과해야 정상 =====

-- 정정된 순서: 고정 인자(previous?)가 먼저, 그 뒤에 팩(U...)이 오는 정상
-- 모양. Luau 문법상 무리 없이 통과할 것으로 예상됨 — 여기서 막히면 이
-- 확장 전체를 재검토해야 함(previous 위치를 어디로 옮겨도 안 되는 셈이라).
local function ComputeD<T, V, U...>(
	self: State<T>,
	fn: (State<T>, V?, U...) -> V, -- <- previous?가 먼저, 팩 U...은 맨 끝
	previous: V?,
	...: U...
): State<V>
	return (nil :: any) :: State<V>
end

local resultD = ComputeD(selfState, function(s, prev, a, b)
	local n: number = s:Get()
	local str: string = a:Get()
	local bool: boolean = b:Get()
	return n
end, nil, depString, depBool)

print("런타임 실행은 의미 없음 — luau-analyze/luau-lsp 진단만 확인할 것")
print(resultA, resultB, resultD)

--[[
	확인 포인트:
	1. A) `s`/`d`가 각각 `State<number>`/`State<string>`으로 정확히
	   좁혀지는가 — 단일 고정 dep는 기존 self 타이핑과 같은 방식이라
	   통과할 것으로 예상(대조군, 실패하면 B/C/D를 볼 것도 없이 기반
	   자체가 문제).
	2. B) `ComputeB` 호출부의 `a:Get()`/`b:Get()` 두 줄이 타입 에러 없이
	   통과하는가 — 통과하면 "이형 다중 deps를 제네릭 팩으로 표현 가능"
	   확정, 실패하면(예: `a`/`b`가 `unknown`이나 첫 dep 타입으로만
	   뭉개짐) "제네릭 팩은 동종 타입 전용이라 이형 deps는 못 태운다"는
	   결론.
	3. C) [음성 대조군] `ComputeC` 정의 자체가 파싱/타입체크 에러로
	   막히는가 — **막혀야 예상대로**(previous를 팩 뒤에 두면 안 된다는
	   근거가 되는 줄). 만약 이 줄이 에러 없이 통과해버리면, "previous는
	   무조건 팩 앞"이라는 이번 정정 자체가 불필요했다는 뜻이라 base
	   문서를 다시 봐야 함.
	4. D) [양성 대조군] `ComputeD` 정의와 `resultD` 호출부(특히
	   `a:Get()`/`b:Get()`가 정확한 타입으로 좁혀지는지)가 전부 에러 없이
	   통과하는가 — 통과하면 `fn(self, previous?, ...deps)` 순서가
	   base 문서 확정대로 최종 시그니처로 채택됨.
	5. 결과에 따라 `base/bind-system-plan.md` "trailing deps를 fn에 lazy
	   positional 인자로도 노출" 절에 실측 결과로 반영할 것:
	   - B/D 통과, C 실패(예상대로) → 지금 base 문서에 적힌
	     `fn(self, previous?, ...deps)` 시그니처 그대로 최종 확정.
	   - B 실패 → 위치 인자 노출은 동종 타입 dep 1개(A 방식)로만 한정하거나,
	     `U...`를 `...any`로 열어 런타임 계약으로만 관리하는 방향 재검토.
	   - C가 예상과 달리 통과 → previous 위치 제약 자체를 재검토(D도 같이
	     통과한다면 둘 다 되는 셈이라 어느 쪽이든 상관없다는 뜻).
]]
