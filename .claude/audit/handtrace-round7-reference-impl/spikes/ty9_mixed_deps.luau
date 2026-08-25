--!strict
-- 7라운드 부록이 확인한 이형 팩은 StateData<number>/StateData<boolean>처럼
-- "같은 종류, 다른 타입 인자"였다. 실제 코드는 Source와 State가 섞인다.
export type StateData<T> = { Get: (self: StateData<T>) -> T }
export type SourceData<T> = { Get: (self: SourceData<T>) -> T, Revision: number }
export type State<T> = StateData<T> & {
    ComputeN: <U, D...>(self: StateData<T>, fn: (self: StateData<T>, prev: U?, D...) -> U, D...) -> U,
}

local s: State<string> = nil :: any
local a: SourceData<number> = nil :: any     -- store.a (Source)
local b: StateData<boolean> = nil :: any     -- 파생 State

local r = s:ComputeN(function(self, prev, d1: SourceData<number>, d2: StateData<boolean>)
    return if d2:Get() then d1:Get() else 0
end, a, b)
local rn: number = r

-- 무주석 콜백에서도 되는가(부록이 확인한 것과 같은 조건)
local r2 = s:ComputeN(function(self, prev, d1, d2)
    return d1:Get() + (if d2:Get() then 1 else 0)
end, a, b)
local rn2: number = r2

-- 음성 대조군: 순서를 바꿔 넘기면 걸려야 정상
local r3 = s:ComputeN(function(self, prev, d1: SourceData<number>, d2: StateData<boolean>)
    return 0
end, b, a)
