--!strict
-- STYLE A: inline recursive generic method inside a single self-referencing type, WITH `read`

type State<T> = {
    read Get: (self: State<T>) -> T,
    read Compute: <U>(self: State<T>, func: (State<T>) -> U) -> State<U>,
}

local test = (nil :: any) :: State<number>

-- CHECK1: unannotated callback param -- is a0 inferred or unknown?
local r1 = test:Compute(function(a0)
    return a0
end)

-- CHECK2: annotated param, unannotated LHS, negative control on downstream :Get()
local r2 = test:Compute(function(a0: State<number>): number
    return 1
end)
local wrong2: string = r2:Get()

-- CHECK3: annotated param, LHS annotated WRONG type (negative control at assignment site)
local wrong3: State<boolean> = test:Compute(function(a0: State<number>): number
    return 1
end)
