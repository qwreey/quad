--!strict
type Box<T> = { value: T }
local function Compute<T, U>(self: Box<T>, fn: (Box<T>) -> U): Box<U>
    return { value = fn(self) } :: any
end
type BoxM<T> = Box<T> & { Compute: typeof(Compute) }
local b: BoxM<number> = (nil :: any) :: BoxM<number>
local r = b:Compute(function(a) return tostring(a.value) end)
local ok: string = r.value
