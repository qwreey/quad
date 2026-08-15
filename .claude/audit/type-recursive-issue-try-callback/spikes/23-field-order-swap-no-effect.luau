--!strict
-- Does declaration order of Get/Compute fields affect the spurious
-- diagnostic from 22? Control variant requested by the task.
local function Compute<T, U>(self: Box<T>, fn: (Box<T>) -> U): Box<U>
	return nil :: any
end
export type Box<T> = {
	Compute: typeof(Compute),  -- swapped: Compute before Get
	Get: (self: Box<T>) -> T,
}

local n: Box<number> = nil :: any

local r2 = n:Compute<<number, string>>(function(a0)
	local check: number = a0:Get()
	return tostring(a0:Get())
end)
local wrong2: number = r2:Get()
-- RESULT: no effect. Same spurious read-only/read-write diagnostic as 22.
