--!strict
export type StateData<T> = { Get: (self: StateData<T>) -> T }
export type State<T> = StateData<T> & {
    Apply: <U>(self: State<T>, factory: (State<T>) -> U) -> U,
}
local s: State<number> = nil :: any

type GateFactory = typeof(setmetatable(
    {} :: { Flush: () -> (), Cancel: () -> () },
    {} :: { __call: (any, State<number>) -> State<number> }
))
local Debounced: GateFactory = nil :: any

-- (A) 제네릭이 아닌 평범한 함수 파라미터 자리에도 안 들어가는가?
local function takesFn(f: (State<number>) -> State<number>) return f(s) end
local a = takesFn(Debounced)

-- (B) 유니온으로 열면 되는가
local function takesEither(f: ((State<number>) -> State<number>) | GateFactory)
    return (f :: any)(s)
end
local b = takesEither(Debounced)
local b2 = takesEither(function(x: State<number>) return x end)
