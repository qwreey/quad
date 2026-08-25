--!strict
-- base/source-state-plan.md: state:Apply(factory) — `factory: (State<T>) -> U): U`
-- base/debounce-throttle-plan.md 5-4: Debounce{...}가 돌려주는 것은 __call 테이블
--   (setmetatable({}, {__call = ..., __index = {Flush=..., Cancel=...}}))
-- base/gate-plan.md 2번: "__call 테이블이 Luau에서 (State<T>) -> U 함수 타입 자리에
--   그대로 들어가는지가 불확실하다(들어가지 않는 쪽이 유력)" — 확인 안 하기로 접었음

export type StateData<T> = { Get: (self: StateData<T>) -> T }
export type State<T> = StateData<T> & {
    Compute: <U>(self: StateData<T>, fn: (self: StateData<T>) -> U) -> State<U>,
    Apply: <U>(self: State<T>, factory: (State<T>) -> U) -> U,
}

local s: State<number> = nil :: any

-- (A) 평범한 함수 팩토리 — 양성 대조군
local a = s:Apply(function(self: State<number>): State<number> return self end)

-- (B) __call 테이블 팩토리 — 5-4절이 확정한 모양
type GateFactory = typeof(setmetatable(
    {} :: { Flush: () -> (), Cancel: () -> () },
    {} :: { __call: (any, State<number>) -> State<number> }
))
local Debounced: GateFactory = nil :: any
local b = s:Apply(Debounced)

-- (C) 직접 호출은 되는가
local c = Debounced(s)
