--!strict
-- base/effect-plan.md: Effect(fn, ...deps) — deps는 State/Source(→Observer)와
-- Ref(→:Callback)가 섞인다. fn엔 deps가 안 넘어간다(H-14).
export type StateData<T> = { Get: (self: StateData<T>) -> T }
export type State<T> = StateData<T> & {
    Compute: <U>(self: StateData<T>, fn: (self: StateData<T>) -> U) -> State<U>,
}
export type Ref<T> = { Value: T?, Set: (self: Ref<T>, v: T) -> (), Callback: (self: Ref<T>, fn: (T) -> ()) -> () }
export type EffectHandle = { Rerun: (self: EffectHandle) -> (), Subscribe: (self: EffectHandle) -> () }

type Dep = State<any> | Ref<any>
local function Effect(fn: (self: EffectHandle) -> (() -> ())?, ...: Dep): EffectHandle
    return nil :: any
end

local n: State<number> = nil :: any
local b: State<boolean> = nil :: any
local r: Ref<Instance> = nil :: any

-- (A) State 하나
local e1 = Effect(function(self) return nil end, n)
-- (B) 이형 State 둘
local e2 = Effect(function(self) return nil end, n, b)
-- (C) State + Ref 섞기 — effect-plan.md가 확정한 대표 용례
local e3 = Effect(function(self) return nil end, n, r)
-- (D) 음성 대조군 — 아무 테이블이나 넣으면 걸려야 정상
local e4 = Effect(function(self) return nil end, {foo = 1})
