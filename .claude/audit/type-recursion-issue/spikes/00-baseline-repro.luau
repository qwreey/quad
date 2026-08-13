--!strict
-- 0-Y 베이스라인 재현: audit/luau-test-first-run-2026-08-13.md에 정리된
-- "지금 확정된 관용구" 최소 재현. 무주석 인라인 람다가 lazy State<T> 핸들을
-- 받는 계약에서 정말 타입에러가 나는지 확인.

export type State<T> = {
	Get: (self: State<T>) -> T,
	Compute: <U>(self: State<T>, fn: (self: State<T>) -> U) -> State<U>,
}

local function fakeState<T>(v: T): State<T>
	return (nil :: any) :: State<T>
end

local state: State<number> = fakeState(0)

-- 기대: 실패 (audit 문서 기준)
local doubled = state:Compute(function(s) return s:Get() * 2 end)

print("00 done")
