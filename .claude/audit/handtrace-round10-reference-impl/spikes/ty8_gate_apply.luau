--!strict
export type StateData<T> = { Get: (self: StateData<T>) -> T }
export type State<T> = StateData<T> & {
    Compute: <U>(self: StateData<T>, fn: (self: StateData<T>) -> U) -> State<U>,
    Apply: <U>(self: State<T>, factory: (State<T>) -> U) -> U,
    Gate: (self: State<T>, setup: (emit: () -> ()) -> (() -> ())) -> State<T>,
    Block: (self: State<T>, blocker: Blocker) -> State<T>,
}
export type SourceData<T> = { Get: (self: SourceData<T>) -> T, Revision: number }
export type Source<T> = SourceData<T> & {
    Set: (self: SourceData<T>, v: T) -> SourceData<T>,
    Apply: <U>(self: Source<T>, factory: (State<T>) -> U) -> U,
    Gate: (self: Source<T>, setup: (emit: () -> ()) -> (() -> ())) -> State<T>,
}
export type Blocker = {
    On: (self: Blocker) -> Blocker,
    Off: (self: Blocker) -> Blocker,
    OffWithoutEmit: (self: Blocker) -> Blocker,
    IsOn: (self: Blocker) -> boolean,
    IsBlocked: boolean,
    Policy: (self: Blocker, emit: () -> ()) -> (() -> ()),
}

local st: State<number> = nil :: any
local src: Source<number> = nil :: any
local b: Blocker = nil :: any

-- (A) gate-plan.md 5번의 확정 형태
local g1 = st:Gate(function(emit) return b:Policy(emit) end)
-- (B) tween-plan.md의 관용구 — Source에 State용 팩토리를 붙인다
local Animate: (self: State<number>) -> State<number> = nil :: any
local a1 = src:Apply(Animate)
local a2 = st:Apply(Animate)
-- (C) Debounce 정책 모양 — 자기 Blocker를 사적으로 하나 갖는 setup
local d = st:Gate(function(emit)
    local mine: Blocker = nil :: any
    local pass = mine:Policy(emit)
    return function() pass() end
end)
-- (D) 음성 대조군 — gate-plan.md가 "문법 오류"라고 정정한 형태
local bad = st:Gate(b.Policy)
