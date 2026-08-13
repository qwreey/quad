--!strict
-- 결정적 질문: --annotate가 보여준 Unifiable<Error>가 진짜 "타입 체크가
-- 무력화됐다"는 뜻인지 확인. Compute 리턴값을 明시 주석 없이 받은 뒤,
-- 일부러 틀린 타입에 대입해서 정말 안 잡히는지 테스트.

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

-- 명시 주석 없이 받음(19의 s/b처럼 LHS에 State<string> 안 붙임)
local s = n:Compute(function(x) return tostring(x:Get()) end)

-- 일부러 틀린 타입 대입 -- 진짜 타입체크가 되고 있다면 여기서 에러가 나야 함
local wrong: number = s:Get() -- s는 State<string>이어야 하므로 Get()은 string. number에 대입하면 에러여야 정상
local right: string = s:Get()

print("27 done", wrong, right)
