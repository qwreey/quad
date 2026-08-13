--!strict
-- <<...>>가 진짜 명시적 제네릭 인자 문법인지, 그리고 그걸로 문제 B
-- (Compute의 State<U> 반환 불안전성)를 우회할 수 있는지 결정적으로 확인.

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

-- 명시적으로 U=string이라고 못박음
local s = n:Compute<<string>>(function(x) return tostring(x:Get()) end)

local wrong: number = s:Get() -- 진짜 sound하면 여기서 에러여야 함
local right: string = s:Get()

print("40 done", wrong, right)
