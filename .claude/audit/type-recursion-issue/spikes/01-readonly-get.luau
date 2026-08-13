--!strict
-- 00의 에러 메시지가 "Get이 latter(추론된) 타입에서 read-only인데
-- former(선언된) 타입은 read-write를 요구한다"고 명시함.
-- State<T>의 Get을 read-only로 선언하면 방향이 맞아떨어져 풀리는지 확인.

export type State<T> = {
	read Get: (self: State<T>) -> T,
	Compute: <U>(self: State<T>, fn: (self: State<T>) -> U) -> State<U>,
}

local function fakeState<T>(v: T): State<T>
	return (nil :: any) :: State<T>
end

local state: State<number> = fakeState(0)

local doubled = state:Compute(function(s) return s:Get() * 2 end)

print("01 done")
