--!strict
local computeImpl = (nil :: any) :: <ImplT>() -> (
    <U>(self: Box<ImplT>, f: (Box<ImplT>) -> U) -> Box<U>
)
local getImpl = (nil :: any) :: <ImplT>() -> (
    (self: Box<ImplT>) -> ImplT
)
local boxImpl = (nil :: any) :: <ImplT>() -> {
    Compute: typeof(computeImpl<<ImplT>>()),
    Get: typeof(getImpl<<ImplT>>()),
}
type Box<T> = setmetatable<{ inner: T }, { __index: typeof(boxImpl<<T>>()) }>

local test = (nil :: any) :: Box<number>

-- U == T this time (number -> number, no type change)
local d1 = test:Compute(function(a0: Box<number>): number return a0:Get() + 1 end)
local ok: number = d1:Get()
local wrong: string = d1:Get()
