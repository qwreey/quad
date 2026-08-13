--!strict
-- 23과 동일하지만 진짜 이형 타입(T=number, D=string)으로 확인.

export type StateData<T> = {
	Get: (self: StateData<T>) -> T,
}
export type State<T> = StateData<T> & {
	Compute: <U>(self: StateData<T>, fn: (self: StateData<T>) -> U) -> State<U>,
}
export type Withable<T> = StateData<T> & {
	With: <D>(self: StateData<T>, dep: StateData<D>) -> WithResult<T, D>,
}
export type WithResult<T, D> = StateData<T> & {
	Compute: <U>(self: WithResult<T, D>, fn: (self: StateData<T>, dep: StateData<D>) -> U) -> State<U>,
}

local function fakeState<T>(v: T): State<T> & Withable<T>
	return (nil :: any) :: State<T> & Withable<T>
end

local n: State<number> & Withable<number> = fakeState(0)
local s: State<string> & Withable<string> = fakeState("x")

local combined = n:With(s):Compute(function(i, str)
	local numPart: number = i:Get()
	local strPart: string = str:Get()
	return numPart .. strPart
end)

print("24 done", combined)
