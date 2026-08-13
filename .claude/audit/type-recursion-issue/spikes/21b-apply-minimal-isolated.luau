--!strict
-- 21의 진단이 *error-type*/*CYCLE*로 뒤덮여 있다는 지적 — 캐스케이드
-- 노이즈인지, 아니면 진짜 다른 문제인지 최소 형태로 재확인.
-- 분기(if)와 이중 Compute 호출을 다 걷어내고 "Apply 콜백 안에서
-- Compute를 한 번만 호출"하는 가장 단순한 형태로 축소.

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
	return self:Compute(function(h) return h:Get() * 2 end)
end)

print("21b done", result)
