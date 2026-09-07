--!strict
--[[
	검증 대상: 사용자 사고(2026-09-07 회신, post-implementation review Q1) — "'입력받는 곳'
	(children 유니언·setter 인자)에는 전체형 `State<T>` 대신 마커 필드 + `T` 하나만 보존하는
	마커 타입을 써도 되지 않나". 전체형 `State<T>`는 `Set(T)`/`Get(): T`가 양쪽 위치에 있어
	**불변**(`H-326`/`H-327`/`H-353`: `State<number>`가 `State<number | UDim>` 자리에 못 들어감).
	질문 셋: (1) 읽기 전용(`read`) 마커 필드는 T에 대해 공변인가, (2) 메소드가 잔뜩 붙은
	실제 State 모양 값이 그 마커 자리에 폭 서브타이핑으로 들어가는가, (3) 오타·다른 T는
	여전히 거부되는가(마커가 검사력을 잃지 않는가).
	실행: `luau-analyze --fflags=LuauSolverV2=true 34-*.luau`(새 솔버 — 프로젝트 test.sh와 같은
	축) 및 플래그 없이. 기대(새 솔버): L1·L3·L5 에러, L2·L4·L6·L7 통과.
	(quad-types 없이 자립 — 최소 재현. `number` vs `number | string`이 `H-353`의 유니언 자리 모양.)
]]

-- 전체형: 양쪽 위치의 T → 불변
type StateFull<T> = { Get: (self: StateFull<T>) -> T, Set: (self: StateFull<T>, v: T) -> (), Revision: number }
-- 마커(읽기 전용 팬텀 필드)
type Marker<T> = { read __quadState: true, read __quadValue: T }
-- 마커(읽기·쓰기 필드) — 대조군
type MarkerRW<T> = { __quadState: true, __quadValue: T }
-- 실제 State 모양: 마커 필드 + 메소드들
type StateReal<T> = {
	read __quadState: true,
	read __quadValue: T,
	Get: (self: StateReal<T>) -> T,
	Set: (self: StateReal<T>, v: T) -> (),
	Compute: <U>(self: StateReal<T>, fn: (T) -> U) -> StateReal<U>,
	Revision: number,
}

local sNum = (nil :: any) :: StateFull<number>
local rNum = (nil :: any) :: StateReal<number>
local rStr = (nil :: any) :: StateReal<string>

local L1: StateFull<number | string> = sNum -- L1: 기대 에러(전체형 불변)
local L2: Marker<number | string> = (nil :: any) :: Marker<number> -- L2: 기대 통과(read 공변)
local L3: MarkerRW<number | string> = (nil :: any) :: MarkerRW<number> -- L3: 기대 에러(rw 불변)
local L4: Marker<number | string> = rNum -- L4: 기대 통과(폭 서브타이핑 + 공변)
local L5: Marker<number> = rStr -- L5: 기대 에러(다른 T는 여전히 거부)

-- children 유니언 자리 모양(`NewChild`): 값 | 마커<값 | 다른 값>
type Child = string | Marker<string | number>
local L6: Child = rNum -- L6: 기대 통과
local L6b: Child = "x"

-- 제네릭 소비자가 마커에서 T를 복원하는가
local function take<T>(m: Marker<T>): T
	return m.__quadValue
end
local L7: number = take(rNum) -- L7: 기대 통과(T = number 추론)

print(L1, L2, L3, L4, L5, L6, L6b, L7)
