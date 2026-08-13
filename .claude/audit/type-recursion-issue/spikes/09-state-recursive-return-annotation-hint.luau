--!strict
-- 08과 같은 아이디어를 원래 State(재귀 self) 형태(00)에 적용 --
-- 파라미터 s는 무주석으로 두고 콜백의 "리턴 타입만" 명시하면 통과하는지.

export type State<T> = {
	Get: (self: State<T>) -> T,
	Compute: <U>(self: State<T>, fn: (self: State<T>) -> U) -> State<U>,
}

local function fakeState<T>(v: T): State<T>
	return (nil :: any) :: State<T>
end

local state: State<number> = fakeState(0)

local doubled = state:Compute(function(s): number return s:Get() * 2 end)

print("09 done")
