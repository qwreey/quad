--!strict
-- 08 스파이크(raw value fn, option 2)도 Compute가 State<U>를 반환하는 한
-- 같은 문제(differing recursion)를 겪는지 확인 -- LHS 명시 주석을 빼고
-- 진짜 추론 결과를 봄.

export type State<T> = {
	Get: (self: State<T>) -> T,
	Compute: <U>(self: State<T>, fn: (T) -> U) -> State<U>, -- raw value 계약(옵션 2)
}

local function fakeState<T>(v: T): State<T>
	return (nil :: any) :: State<T>
end

local n: State<number> = fakeState(5)

-- LHS 주석 없이 raw value 콜백으로 Compute
local s = n:Compute(function(v: number): string return tostring(v) end)

local wrong: number = s:Get() -- s가 State<string>이어야 하므로 에러여야 함
local right: string = s:Get()

print("34 done", wrong, right)
