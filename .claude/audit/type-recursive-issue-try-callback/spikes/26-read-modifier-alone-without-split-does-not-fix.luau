--!strict
-- Does `read Get` alone (WITHOUT the split pattern) already fix 22? I.e. is
-- the split actually load-bearing, or would `read` alone have been enough?
local function Compute<T, U>(self: Box<T>, fn: (Box<T>) -> U): Box<U>
	return nil :: any
end
export type Box<T> = {
	read Get: (self: Box<T>) -> T,
	Compute: typeof(Compute),
}

local n: Box<number> = nil :: any

local r2 = n:Compute<<number, string>>(function(a0)
	local check: number = a0:Get()
	return tostring(a0:Get())
end)
local wrong2: number = r2:Get()
-- RESULT: no, `read` alone (no split) does NOT fix it — it just changes the
-- spurious diagnostic into a different, even more confusing recursive
-- <Cycle>-laden mismatch, because now the comparison is between two full
-- recursive Box<T> shapes (which structurally require BOTH Get and
-- Compute) instead of the split BoxData<T> (which only requires Get). The
-- split (②) is load-bearing for the 25 fix, not optional.
