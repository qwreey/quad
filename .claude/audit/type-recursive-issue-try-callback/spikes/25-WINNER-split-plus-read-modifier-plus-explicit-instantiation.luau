--!strict
-- WINNER: split (②) + explicit `read` property modifier on Get + full
-- explicit <<T,U>> instantiation. All three together remove the spurious
-- diagnostic from 22/23/24 entirely.
export type BoxData<T> = {
	read Get: (self: BoxData<T>) -> T,
}
local function Compute<T, U>(self: BoxData<T>, fn: (BoxData<T>) -> U): Box<U>
	return nil :: any
end
export type Box<T> = BoxData<T> & {
	Compute: typeof(Compute),
}

local n: Box<number> = nil :: any

local r2 = n:Compute<<number, string>>(function(a0)
	local check: number = a0:Get()
	return tostring(a0:Get())
end)
local wrong2: number = r2:Get()
-- RESULT: CLEAN. Only the genuine `wrong2` error remains. `a0` is
-- unannotated and correctly, soundly inferred as `BoxData<number>`-shaped.
-- The `read` marker matters because the inferred usage-derived shape for
-- `a0` is inherently read-only (it's only ever called, never assigned into)
-- — marking the real field `read` too makes both sides agree.
