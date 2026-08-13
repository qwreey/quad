--!strict
-- 중요한 캐비엇 확인: 쪼개기 트릭에서 콜백이 받는 s는 StateData<T>
-- (Get만 있음)로 타이핑됨 -- State<T>(Compute 포함)가 아님. 그러면
-- 콜백 "안에서" s:Compute(...)를 또 호출하는 중첩 패턴은 타입 에러가
-- 나야 정상. 실제로 그런지, 그리고 이게 실사용에서 문제가 되는 패턴인지
-- 확인.

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

-- 콜백 안에서 받은 s로 또 Compute를 거는 중첩 -- 예상: 타입 에러
-- (s: StateData<number>엔 Compute 필드가 없음)
local nested = n:Compute(function(s)
	local inner = s:Compute(function(s2) return s2:Get() * 2 end)
	return inner:Get()
end)

print("20 done", nested)
