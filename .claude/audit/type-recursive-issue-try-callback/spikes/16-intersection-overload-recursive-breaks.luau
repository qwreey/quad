--!strict
type Box<T> = {
    value: T,
    Compute: (<U>(self: Box<T>, fn: (Box<T>) -> U) -> Box<U>)
        & ((self: Box<number>, fn: (Box<number>) -> string) -> Box<string>),
}
local self1: Box<number> = (nil :: any) :: Box<number>
local r = self1:Compute(function(a) return tostring(a.value) end)
local ok: string = r.value
