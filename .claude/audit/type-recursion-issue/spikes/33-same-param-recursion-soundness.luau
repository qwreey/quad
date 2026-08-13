--!strict
-- 결정적 대조군: Compute가 State<T>(같은 T)를 반환하면(=matrix B, 03과
-- 동일 패턴) 진짜 sound한지, 아니면 이것도 Unifiable<Error>인지 확인.

export type State<T> = {
	Get: (self: State<T>) -> T,
	Compute: (self: State<T>, fn: (self: State<T>) -> T) -> State<T>, -- U 없음, 항상 같은 T
}

local function fakeState<T>(v: T): State<T>
	return (nil :: any) :: State<T>
end

local n: State<number> = fakeState(5)
local doubled = n:Compute(function(x) return x:Get() * 2 end)

local wrong: string = doubled:Get() -- doubled가 State<number>면 여기서 에러여야 함
local right: number = doubled:Get()

print("33 done", wrong, right)
