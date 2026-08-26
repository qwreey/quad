--!strict
-- ⚠️ [2026-08-26, 8라운드 `H-121`] 이 파일이 모델링한 "With로 모은 값이
--   콜백에 포지셔널로 넘어온다"는 **quad의 확정 콜백 계약이 아니다.**
--   확정 계약은 `fn(self, previous?, ...trailingDeps)`이고, `:With`로 모은
--   값은 **클로저로 직접 읽는다**(`base/source-state-plan.md`).
--   이 스파이크의 측정값(타입 추론 자체)은 그대로 유효하지만, 여기 적힌
--   호출 모양을 "확정 관용구"로 재인용하지 말 것 — `slot-plan.md`의 그
--   예시는 같은 라운드에 교정됐다.
-- slot-plan.md 914행 실제 코드: layoutOrder:With(offset):Compute(function(i, o)
--   return i:Get() + o:Get() end) -- With로 모은 뒤 Compute 콜백이 여러 개의
-- lazy 핸들을 무주석으로 받는 실사용 패턴을 split 트릭으로 재현.
-- With(...)는 이형 dep들을 모아 "self 자신 + deps"를 콜백에 그대로 넘기는
-- pass-through 노드로 모델링(bind-system-plan.md "trailing deps" 절 참고).

export type StateData<T> = {
	Get: (self: StateData<T>) -> T,
}
export type State<T> = StateData<T> & {
	Compute: <U>(self: StateData<T>, fn: (self: StateData<T>) -> U) -> State<U>,
}

-- With(dep) -- 단일 추가 의존성 버전(2개 합치기), 콜백이 (self, dep) 두
-- lazy 핸들을 받음. 실제로는 With가 별도 노드를 만들지만 여기선 타입
-- 추론 자체만 검증.
export type Withable<T> = StateData<T> & {
	With: <D>(self: StateData<T>, dep: StateData<D>) -> WithResult<T, D>,
}
export type WithResult<T, D> = StateData<T> & {
	Compute: <U>(self: WithResult<T, D>, fn: (self: StateData<T>, dep: StateData<D>) -> U) -> State<U>,
}

local function fakeState<T>(v: T): State<T> & Withable<T>
	return (nil :: any) :: State<T> & Withable<T>
end

local layoutOrder = fakeState(0)
local offset = fakeState(0)

local combined = layoutOrder:With(offset):Compute(function(i, o)
	return i:Get() + o:Get()
end)

print("23 done", combined)

-- 유저가 발견한 후속 케이스: combined에 체이닝 + 명시 타입 주석
local t = combined:Compute(function(self: StateData<number>)
	return true
end)
print("t check", t)
