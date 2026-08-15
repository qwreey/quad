--!strict
local function Map<T, U>(arr: {T}, fn: (T) -> U): {U}
    return {} :: any
end
local arr: {number} = {1,2,3}
local result = Map(arr, (function(a) return tostring(a) end) :: (number) -> string)
local ok: string = result[1]
