--!strict
-- STYLE C: split StateData/State, inline method type in State, WITH `read`

type StateData<T> = {
    read Get: (self: StateData<T>) -> T,
}
type State<T> = StateData<T> & {
    read Compute: <U>(self: StateData<T>, func: (StateData<T>) -> U) -> State<U>,
}

local test = (nil :: any) :: State<number>

-- CHECK1: unannotated callback param -- does splitting auto-infer it as StateData<number>?
local r1 = test:Compute(function(a0)
    return a0
end)

-- CHECK2: annotated param, unannotated LHS, negative control on downstream :Get()
local r2 = test:Compute(function(a0: StateData<number>): number
    return 1
end)
local wrong2: string = r2:Get()

-- CHECK3: LHS annotated WRONG type
local wrong3: State<boolean> = test:Compute(function(a0: StateData<number>): number
    return 1
end)
