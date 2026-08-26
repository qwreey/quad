--!strict
-- ⚠️ [2026-08-26, 8라운드 `H-121`] 이 파일이 모델링한 "With로 모은 값이
--   콜백에 포지셔널로 넘어온다"는 **quad의 확정 콜백 계약이 아니다.**
--   확정 계약은 `fn(self, previous?, ...trailingDeps)`이고, `:With`로 모은
--   값은 **클로저로 직접 읽는다**(`base/source-state-plan.md`).
--   이 스파이크의 측정값(타입 추론 자체)은 그대로 유효하지만, 여기 적힌
--   호출 모양을 "확정 관용구"로 재인용하지 말 것.
-- 23과 동일하지만 진짜 이형 타입(T=number, D=string)으로 확인.

export type StateData<T> = {
	Get: (self: StateData<T>) -> T,
}
export type State<T> = StateData<T> & {
	Compute: <U>(self: StateData<T>, fn: (self: StateData<T>) -> U) -> State<U>,
}
export type Withable<T> = StateData<T> & {
	With: <D>(self: StateData<T>, dep: StateData<D>) -> WithResult<T, D>,
}
export type WithResult<T, D> = StateData<T> & {
	Compute: <U>(self: WithResult<T, D>, fn: (self: StateData<T>, dep: StateData<D>) -> U) -> State<U>,
}

local function fakeState<T>(v: T): State<T> & Withable<T>
	return (nil :: any) :: State<T> & Withable<T>
end

local n: State<number> & Withable<number> = fakeState(0)
local s: State<string> & Withable<string> = fakeState("x")

local combined = n:With(s):Compute(function(i, str)
	local numPart: number = i:Get()
	local strPart: string = str:Get()
	return numPart .. strPart
end)

print("24 done", combined)
