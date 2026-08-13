--!strict
-- 결정적 확인: LHS 명시 주석이 "RHS를 검증"해주진 않지만(28에서 확인),
-- 최소한 "다운스트림에 올바른 타입을 바인딩"은 해주는가?
-- 이게 되면 "명시적 타입 바인딩 강제"가 실효성 있는 대응책이 됨.

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

-- LHS에 명시 주석
local s: State<string> = n:Compute(function(x) return tostring(x:Get()) end)

-- 다운스트림에서 s가 진짜 State<string>으로 취급되는가?
local ok: string = s:Get()          -- 맞는 사용 -- 통과해야 함
local bad: number = s:Get()         -- 틀린 사용 -- 에러나야 함(다운스트림 바인딩이 살아있다면)
local bad2 = s:NoSuchMethod()       -- 없는 메소드 -- 에러나야 함

print("43", ok, bad, bad2)
