--!strict
-- 대조군: "쪼개기 없이, 파라미터/리턴 둘 다 명시 주석"(=question.md
-- 선택지 1, 이미 known-working으로 알려진 경우)도 U가 진짜 정상 해소되는지
-- --annotate로 확인. 여기서도 Unifiable<Error>가 뜨면 이건 쪼개기와
-- 무관한 Luau 자체의 한계라는 뜻.

export type State<T> = {
	Get: (self: State<T>) -> T,
	Compute: <U>(self: State<T>, fn: (self: State<T>) -> U) -> State<U>,
}

local function fakeState<T>(v: T): State<T>
	return (nil :: any) :: State<T>
end

local n: State<number> = fakeState(5)

-- 파라미터/리턴 둘 다 명시
local s = n:Compute(function(x: State<number>): string return tostring(x:Get()) end)

local wrong: number = s:Get()
local right: string = s:Get()

print("31 done", wrong, right)
