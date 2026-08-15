--!strict
-- STYLE B: named functions + typeof, single self-referencing type, WITH `read`

local function Get<T>(self: State<T>): T
    return nil :: any
end
local function Compute<T, U>(self: State<T>, func: (State<T>) -> U): State<U>
    return nil :: any
end

type State<T> = {
    read Get: typeof(Get),
    read Compute: typeof(Compute),
}

local test = (nil :: any) :: State<number>

-- CHECK1
local r1 = test:Compute(function(a0)
    return a0
end)

-- CHECK2
local r2 = test:Compute(function(a0: State<number>): number
    return 1
end)
local wrong2: string = r2:Get()

-- CHECK3
local wrong3: State<boolean> = test:Compute(function(a0: State<number>): number
    return 1
end)
