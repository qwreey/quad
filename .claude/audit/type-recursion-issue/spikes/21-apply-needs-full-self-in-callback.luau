--!strict
-- 실사용 확인: tween-plan.md 341행 예시처럼 `:Apply`의 factory 콜백
-- "내부에서" `self:Compute(...)`를 또 호출하는 패턴이 실제로 존재함.
-- 즉 Apply의 콜백 파라미터는 Compute 없는 StateData가 아니라
-- 전체 State(=Compute 포함)여야 함 -- Compute와 요구사항이 다름.
--
-- 실험: receiver(self, 메소드 디스패치용)는 StateData로 쪼개서 유지하되
-- factory 콜백의 파라미터 타입만 전체 State<T>로 명시하면
-- (선언 자체가 아니라 "필드 시그니처 내부의 콜백 파라미터 위치"라
-- 재귀 문제를 안 일으키는지) 무주석으로 통과하는지 확인.

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

-- Apply 콜백 파라미터(self)가 무주석인데 그 안에서 :Compute를 또 호출
local result = n:Apply(function(self)
	if true then
		return self:Compute(function(h) return h:Get() * 2 end)
	end
	return self:Compute(function(h) return h:Get() end)
end)

print("21 done", result)
