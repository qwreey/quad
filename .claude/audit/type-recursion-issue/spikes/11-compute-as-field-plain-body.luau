--!strict
-- 10에서 "Compute가 필드가 아니라 자유 함수"라 통과했다는 가설을 더 좁힘.
-- 이번엔 Compute를 다시 State의 필드(자기참조)로 되돌리되, 콜백 본문은
-- s:Get() 대신 순수 데이터 필드 s.value로 단순화 -- 문제가 "Compute가
-- 자기참조 타입의 필드라는 것" 자체인지, "콜백 안에서 또 self참조 메소드
-- (Get)를 호출하는 중첩"인지 분리.

export type State = {
	value: number,
	Compute: <U>(self: State, fn: (self: State) -> U) -> U,
}

local function fakeState(): State
	return (nil :: any) :: State
end

local state: State = fakeState()

local doubled = state:Compute(function(s) return s.value * 2 end)

print("11 done")
