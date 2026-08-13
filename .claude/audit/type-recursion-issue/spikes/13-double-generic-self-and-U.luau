--!strict
-- 04/11이 실패한 이유가 "Compute 필드 타입 선언 안에 State라는 이름이
-- 리터럴로 재귀 등장"하는 것이라는 가설. Compute의 self 파라미터를
-- 리터럴 State가 아니라 완전히 자유로운 제네릭 Self로 바꾸면(sub-try5
-- 패턴처럼) 필드 선언 자체에서 재귀 언급이 사라짐 -- 이게 U와 같이 있어도
-- 통과하는지 확인.

export type State = {
	Get: (self: State) -> number,
	Compute: <Self, U>(self: Self, fn: (self: Self) -> U) -> U,
}

local function fakeState(): State
	return (nil :: any) :: State
end

local state: State = fakeState()

local doubled = state:Compute(function(s) return s:Get() * 2 end)

print("13 done")
