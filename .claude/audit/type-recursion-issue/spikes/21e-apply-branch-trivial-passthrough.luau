--!strict
-- 21과 정확히 같은 두 분기(h:Get()*2 vs h:Get())로 재현 -- 21d와 다른 점은
-- 두 번째 분기가 "그냥 h:Get()" 트리비얼 패스스루라는 것. 이게 원인인지
-- 최종 확인.

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

local result = n:Apply(function(self)
	if true then
		return self:Compute(function(h) return h:Get() * 2 end)
	end
	return self:Compute(function(h) return h:Get() end) -- 트리비얼 패스스루
end)

print("21e done", result)
