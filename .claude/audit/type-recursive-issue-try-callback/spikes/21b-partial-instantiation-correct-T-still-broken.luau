--!strict
-- Follow-up to 21: give T CORRECTLY (matches self's actual T=number) and
-- leave U to be inferred from the callback's return. Confirms partial
-- instantiation is unconditionally broken on quad's recursive self type,
-- not just "wrong slot picked".
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

local r1 = n:Compute<<number>>(function(a0)
	local check: number = a0:Get()
	return tostring(a0:Get())
end)
local ok: string = r1:Get()       -- positive control — should be fine...
local wrong1: number = r1:Get()   -- ...and this should error
-- RESULT: still "Internal error: outstanding free or blocked type in
-- function call" AND the POSITIVE control (`ok`) itself fails — U stays an
-- unresolved bounded type `(string <: 'a <: never)` instead of resolving to
-- `string`. Partial instantiation on this recursive shape isn't just
-- unhelpful, it's actively worse than not instantiating at all.
