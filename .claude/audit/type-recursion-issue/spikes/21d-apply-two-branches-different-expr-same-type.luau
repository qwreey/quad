--!strict
-- 21c는 완전히 같은 본문이라 통과했음. 이번엔 두 분기의 "표현식은
-- 다르지만 최종 타입은 둘 다 number로 같음"인 경우도 통과하는지 확인 --
-- 21(실패)의 진짜 원인이 "표현식이 다르다"인지 "결과 타입이 갈린다"인지
-- 분리.

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
	return self:Compute(function(h) return h:Get() + 1 end)
end)

print("21d done", result)
