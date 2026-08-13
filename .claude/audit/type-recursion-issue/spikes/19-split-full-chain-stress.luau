--!strict
-- 14의 "쪼개기" 트릭을 실전 규모로 스트레스 테스트:
-- - State<T>:Compute 체이닝 (number -> string -> boolean, 서로 다른 T)
-- - State<State<T>> 중첩
-- - Source<T>가 State<T>를 구조적으로 만족 + Source도 같은 쪼개기 적용
-- - 전부 무주석 인라인 람다로

export type StateData<T> = {
	Get: (self: StateData<T>) -> T,
}
export type State<T> = StateData<T> & {
	Compute: <U>(self: StateData<T>, fn: (self: StateData<T>) -> U) -> State<U>,
}

export type SourceData<T> = StateData<T> & {
	Set: (self: SourceData<T>, value: T) -> (),
	Emit: (self: SourceData<T>) -> (),
}
export type Source<T> = SourceData<T> & {
	Compute: <U>(self: SourceData<T>, fn: (self: SourceData<T>) -> U) -> State<U>,
}

local function fakeState<T>(v: T): State<T>
	return (nil :: any) :: State<T>
end
local function fakeSource<T>(v: T): Source<T>
	return (nil :: any) :: Source<T>
end

-- 1) 기본: 무주석 람다로 체이닝, T가 매 단계 바뀜(number -> string -> boolean)
local n: State<number> = fakeState(5)
local s: State<string> = n:Compute(function(x) return tostring(x:Get()) end)
local b: State<boolean> = s:Compute(function(x) return #x:Get() > 0 end)

-- 2) State<State<T>> 중첩 -- 바깥 Compute의 U 자체가 State<number>
local nested: State<State<number>> = n:Compute(function(x) return fakeState(x:Get() + 1) end)
local unwrapped: State<number> = nested:Compute(function(x) return x:Get():Get() end)

-- 3) Source도 같은 패턴으로 Compute 체이닝 + Set/Emit
local src: Source<number> = fakeSource(0)
src:Set(10)
src:Emit()
local derived: State<string> = src:Compute(function(x) return tostring(x:Get()) end)

-- 4) Source가 State 자리에 구조적으로 들어가는지(서브타입)
local function useAsState<T>(st: State<T>): T
	return st:Get()
end
local viaSubtype: number = useAsState(src)

print("19 done", b, derived, unwrapped, viaSubtype)
