--!strict
-- 21b는 통과, 21은 실패. 유일한 차이는 21이 if-분기 두 개에서 각각
-- self:Compute(...)를 부른다는 것. 분기 자체가 문제인지, 아니면 21 특유의
-- "두 분기가 서로 다른 본문"이 문제인지 분리 -- 여기선 두 분기가 완전히
-- 같은 본문.

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
	return self:Compute(function(h) return h:Get() * 2 end)
end)

print("21c done", result)
