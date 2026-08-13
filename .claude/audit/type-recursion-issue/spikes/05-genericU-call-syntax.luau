--!strict
-- 04(monoT, genericU)이 실패했음. 원인이 ":" 메소드 호출(암묵적 self
-- 바인딩) 때문인지, 아니면 U가 로컬 제네릭이라는 사실 자체 때문인지
-- 분리 -- 똑같은 타입을 일반 함수 호출 문법으로 불러봄(self를 명시 인자로).

export type State = {
	Get: (self: State) -> number,
	Compute: <U>(self: State, fn: (self: State) -> U) -> U,
}

local function fakeState(): State
	return (nil :: any) :: State
end

local state: State = fakeState()

-- 메소드 호출(:) 대신 함수 호출(.)로 self를 명시 인자로 넘김
local doubled = state.Compute(state, function(s) return s:Get() * 2 end)

print("05 done")
