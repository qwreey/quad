--!strict
-- 27이 "무주석 LHS"에서 타입 안전성이 완전히 무력화됨을 보여줬음.
-- 그럼 19처럼 LHS에 명시 타입(local s: State<string> = ...)을 붙이면
-- 최소한 그 자리에서는 안전한지 확인 -- 만약 명시 LHS도 "틀린 타입"을
-- 넣었을 때 안 잡히면, Unifiable<Error>가 정말 any처럼 뭐든 다 받아
-- 삼킨다는 뜻이라 이 트릭 전체가 무의미해짐.

export type StateData<T> = {
	Get: (self: StateData<T>) -> T,
}
export type State<T> = StateData<T> & {
	Compute: <U>(self: StateData<T>, fn: (self: StateData<T>) -> U) -> State<U>,
}

local function fakeState<T>(v: T): State<T>
	return (nil :: any) :: State<T>
end

local n: State<number> = fakeState(5)

-- 콜백은 string을 반환하는데 LHS는 일부러 State<boolean>이라고 우김
-- -- 진짜 타입체크가 되고 있다면 여기서 에러가 나야 함
local wrongLHS: State<boolean> = n:Compute(function(x) return tostring(x:Get()) end)

print("28 done", wrongLHS)
