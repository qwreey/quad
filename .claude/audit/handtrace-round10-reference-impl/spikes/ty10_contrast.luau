--!strict
export type StateData<T> = { Get: (self: StateData<T>) -> T }
export type SourceData<T> = { Get: (self: SourceData<T>) -> T, Revision: number }
export type State<T> = StateData<T> & {
    Compute:  <U>(self: StateData<T>, fn: (self: StateData<T>, prev: U?) -> U) -> U,
    ComputeN: <U, D...>(self: StateData<T>, fn: (self: StateData<T>, prev: U?, D...) -> U, D...) -> U,
}
local s: State<number> = nil :: any
local a: SourceData<number> = nil :: any

-- (A) deps 0개 — typing-limits ②쪼개기가 확인한 "무주석 통과"
local r1 = s:Compute(function(self) return self:Get() * 2 end)
local n1: number = r1

-- (B) deps 1개 + 무주석
local r2 = s:ComputeN(function(self, prev, d1) return self:Get() + d1:Get() end, a)

-- (C) deps 1개 + dep만 주석
local r3 = s:ComputeN(function(self, prev, d1: SourceData<number>) return self:Get() + d1:Get() end, a)
local n3: number = r3
