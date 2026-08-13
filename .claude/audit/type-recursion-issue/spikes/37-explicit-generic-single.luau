--!strict
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
local s = n:Compute<string>(function(x) return tostring(x:Get()) end)
local wrong: number = s:Get()
local right: string = s:Get()
print("37 done", wrong, right)
