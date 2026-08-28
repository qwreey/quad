--!strict
-- [2026-08-29 M2 단위 4] `state:Apply(factory)`의 파라미터 타입 표기 실측 — 결론: 교집합 오버로드(N/O).
-- 유니온 하나(`((State<T>) -> U) | { __apply: ... -> U }`)는 `Blocker`처럼 필드가 더 있는 객체를 제네릭 U 자리에서
-- 받지 못한다(너비 서브타이핑 실패, 인덱서 `[string]: any`로도 안 됨). 원문 스파이크 4개 중 통과한 마지막 것.
-- 소스: `qa-request/pre-implementation-handtrace-round11.md` `H-179`. 기대: 진단 2건(마지막 두 줄 음성 대조군)만.
export type StateData<T> = { Get: (self: StateData<T>) -> T }
-- N: 교집합 오버로드 — 함수 팩토리는 제네릭 U, 객체 팩토리는 비제네릭 any 반환
export type StateN<T> = StateData<T> & {
	Apply: (<U>(self: StateData<T>, factory: (StateN<T>) -> U) -> U) & ((self: StateData<T>, factory: { __apply: (self: any, state: any) -> any }) -> any),
}
type BlockerLike = { __apply: (self: any, state: any) -> any, IsBlocked: boolean, On: (self: any) -> any }
local b: BlockerLike = { IsBlocked = false, __apply = function(_s: any, st: any) return st end, On = function(s: any) return s end }
local n = (nil :: any) :: StateN<number>
local n1: StateN<number> = n:Apply(b)
local n3: number = n:Apply(function(s: StateN<number>): number return s:Get() end)
local nneg: string = n:Apply(function(s: StateN<number>): number return s:Get() end)
-- O: 순서 반대(객체 오버로드 먼저)
export type StateO<T> = StateData<T> & {
	Apply: ((self: StateData<T>, factory: { __apply: (self: any, state: any) -> any }) -> any) & (<U>(self: StateData<T>, factory: (StateO<T>) -> U) -> U),
}
local o = (nil :: any) :: StateO<number>
local o1: StateO<number> = o:Apply(b)
local o3: number = o:Apply(function(s: StateO<number>): number return s:Get() end)
local oneg: string = o:Apply(function(s: StateO<number>): number return s:Get() end)
