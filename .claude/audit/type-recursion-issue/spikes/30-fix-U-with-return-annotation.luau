--!strict
-- 27/28이 U(=State<U>의 U)가 Unifiable<Error>로 새는 걸 확인했음.
-- 콜백의 "리턴 타입"만 명시(파라미터는 여전히 무주석)하면 U가 제대로
-- 잡히는지 확인 -- 이게 되면 "파라미터는 무주석, 리턴만 명시"라는
-- 절충 관용구가 살아남음.

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

-- 파라미터는 무주석, 리턴 타입만 명시
local s = n:Compute(function(x): string return tostring(x:Get()) end)

local wrong: number = s:Get() -- s가 진짜 State<string>이면 여기서 에러여야 함
local right: string = s:Get()

print("30 done", wrong, right)
