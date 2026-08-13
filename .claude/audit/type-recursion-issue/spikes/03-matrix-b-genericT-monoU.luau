--!strict
-- 매트릭스 B: T는 제네릭(State<T>), U는 고정(Compute가 항상 State<T> 자기
-- 자신 타입을 반환 -- 즉 self map, U 제네릭 없음).

export type State<T> = {
	Get: (self: State<T>) -> T,
	Compute: (self: State<T>, fn: (self: State<T>) -> T) -> State<T>,
}

local function fakeState<T>(v: T): State<T>
	return (nil :: any) :: State<T>
end

local state: State<number> = fakeState(0)

local doubled = state:Compute(function(s) return s:Get() * 2 end)

print("03 genericT-monoU done")
