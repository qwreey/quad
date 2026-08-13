--!strict
-- 21의 실패를 확인했으니, "Apply의 factory만 명시 주석을 요구"하는
-- 절충안이 실제로 동작하는지 확인 (self 파라미터에 타입 주석을 달면).

export type StateData<T> = {
	Get: (self: StateData<T>) -> T,
}
export type State<T> = StateData<T> & {
	Compute: <U>(self: StateData<T>, fn: (self: StateData<T>) -> U) -> State<U>,
	Apply: <U>(self: StateData<T>, factory: (self: State<T>) -> U) -> U,
}

local function fakeState<T>(v: T): State<T>
	return (nil :: any) :: State<T>
end

local n: State<number> = fakeState(5)

-- Compute는 여전히 무주석
local doubled = n:Compute(function(s) return s:Get() * 2 end)

-- Apply만 self에 타입 주석
local result = n:Apply(function(self: State<number>)
	return self:Compute(function(h) return h:Get() * 2 end)
end)

print("22 done", doubled, result)
