--!strict
-- <<...>>가 문제 B는 못 고쳤음. 그럼 문제 A(파라미터 self 추론)는
-- 고쳐주는지 확인 -- 쪼개기 없이 원본 재귀 타입 그대로, 명시 제네릭
-- 인자만 주는 방식으로 무주석 self 파라미터가 통과하는지.

export type State<T> = {
	Get: (self: State<T>) -> T,
	Compute: <U>(self: State<T>, fn: (self: State<T>) -> U) -> State<U>,
}

local function fakeState<T>(v: T): State<T>
	return (nil :: any) :: State<T>
end

local state: State<number> = fakeState(0)

-- 쪼개기 없이, self는 여전히 State<T>(재귀), 대신 명시 제네릭 인자 시도
local doubled = state:Compute<<number>>(function(s) return s:Get() * 2 end)

print("41 done", doubled)
