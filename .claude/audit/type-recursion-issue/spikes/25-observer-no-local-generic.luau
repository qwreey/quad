--!strict
-- Observer는 state:Observer(fn) 메소드지만 U 같은 로컬 제네릭 반환이 없음
-- (EffectHandle을 반환할 뿐, State<U>를 만들지 않음) -- 그래서 굳이 쪼개기
-- 트릭 없이도 self:State<T> 그대로 필드로 둬도 무주석 람다가 통과하는지 확인
-- (matrix B 패턴과 동일한 결일 것으로 예상).

export type EffectHandle = {
	Unsubscribe: (self: EffectHandle) -> (),
}
export type State<T> = {
	Get: (self: State<T>) -> T,
	Observer: (self: State<T>, fn: (self: State<T>) -> ()) -> EffectHandle,
}

local function fakeState<T>(v: T): State<T>
	return (nil :: any) :: State<T>
end

local n: State<number> = fakeState(5)

local handle = n:Observer(function(s)
	print(s:Get() * 2)
end)

print("25 done", handle)
