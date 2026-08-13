--!strict
-- 매트릭스 C: T는 고정(State, number만), U만 제네릭.
-- 00과 대조해 "T의 제네릭성"이 원인인지, "U의 제네릭성"이 원인인지 분리.

export type State = {
	Get: (self: State) -> number,
	Compute: <U>(self: State, fn: (self: State) -> U) -> U,
}

local function fakeState(): State
	return (nil :: any) :: State
end

local state: State = fakeState()

local doubled = state:Compute(function(s) return s:Get() * 2 end)

print("04 monoT-genericU done")
