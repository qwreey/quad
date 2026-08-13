--!strict
-- 11 + 콜백 리턴 타입만 명시. "Compute가 자기참조 타입의 필드"라는 문제가
-- 리턴 타입 annotation 하나로 우회되는지(파라미터 s는 여전히 무주석).

export type State = {
	value: number,
	Compute: <U>(self: State, fn: (self: State) -> U) -> U,
}

local function fakeState(): State
	return (nil :: any) :: State
end

local state: State = fakeState()

local doubled = state:Compute(function(s): number return s.value * 2 end)

print("12 done")
