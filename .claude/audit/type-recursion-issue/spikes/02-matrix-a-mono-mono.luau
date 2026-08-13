--!strict
-- 매트릭스 A: T도 U도 전부 제네릭 없이 완전 monomorphic.
-- 재귀적 self 타입(State가 자기 자신을 파라미터로 참조)만 남기고
-- 제네릭을 전부 제거하면 무주석 람다가 통과하는지 확인.

export type State = {
	Get: (self: State) -> number,
	Compute: (self: State, fn: (self: State) -> number) -> State,
}

local function fakeState(): State
	return (nil :: any) :: State
end

local state: State = fakeState()

local doubled = state:Compute(function(s) return s:Get() * 2 end)

print("02 mono-mono done")
