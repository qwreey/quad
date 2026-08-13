--!strict
-- 10/07이 통과한 이유는 "Compute가 자기참조 타입 자신의 필드가 아니라"는
-- 점이었음. 그런데 실사용에선 `state:Compute(fn)` 메소드 문법이 꼭
-- 필요함. 절충안: State를 둘로 쪼개서 -- StateData<T>는 Get만 담아
-- 자기참조하고(Compute를 언급 안 함), Compute는 별도로 선언한 뒤
-- 교차 타입(&)으로 합쳐 state 값 자체엔 여전히 Compute가 필드로 붙어있게
-- 함. Compute의 self 파라미터 타입은 State<T>(전체, Compute 포함) 대신
-- StateData<T>(Compute 미포함)를 가리키게 해서 재귀 사슬을 끊음.

export type StateData<T> = {
	Get: (self: StateData<T>) -> T,
}
export type State<T> = StateData<T> & {
	Compute: <U>(self: StateData<T>, fn: (self: StateData<T>) -> U) -> State<U>,
}

local function fakeState<T>(v: T): State<T>
	return (nil :: any) :: State<T>
end

local state: State<number> = fakeState(0)

local doubled = state:Compute(function(s) return s:Get() * 2 end)

print("14 done")
