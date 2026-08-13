--!strict
-- 27/28에서 Compute의 "리턴 타입"(U/State<U>)이 Unifiable<Error>로 새는
-- 걸 확인했음. 그런데 콜백의 "파라미터"(s: StateData<T>) 자체는 여전히
-- 제대로 추론되고 있는지는 별개로 확인 필요 -- 파라미터에 대해 존재하지
-- 않는 필드/메소드를 부르면 정상적으로 잡히는지 테스트.

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

-- 존재하지 않는 메소드 호출 -- 파라미터 타입이 진짜 StateData<number>로
-- 추론되고 있다면 여기서 "Key 'NoSuchMethod' not found" 에러가 나야 함
local bad = n:Compute(function(x) return x:NoSuchMethod() end)

-- 존재하지 않는 필드 산술도 확인
local bad2 = n:Compute(function(x) return x.value + 1 end) -- StateData엔 value 필드 없음

print("29 done", bad, bad2)
