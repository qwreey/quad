--!strict
-- Does typing-limits.md §1② ("split" BoxData/Box pattern) alone remove the
-- spurious diagnostic from 22, when combined with full explicit
-- instantiation?
export type BoxData<T> = {
	Get: (self: BoxData<T>) -> T,
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
-- RESULT: no, the split pattern alone does NOT remove the spurious
-- diagnostic — it just makes the "Expected" side of the diagnostic prettier
-- (`(BoxData<number>) -> string` instead of a `<Cycle>`-laden mess). The
-- underlying read-only vs read-write mismatch on `Get` is unchanged.
