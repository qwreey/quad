--!strict
local function Get<T>(self: State<T>): T return nil :: any end
local function Compute<T, U>(self: State<T>, func: (State<T>) -> U): State<U> return nil :: any end
type State<T> = { Get: typeof(Get), Compute: typeof(Compute) }

local test = (nil :: any) :: State<number>

-- 명시 LHS 오타입 (self-handle 파라미터로, 실제 계약대로)
local wrong: State<boolean> = test:Compute(function(a0: State<number>): number
    return 1
end)
