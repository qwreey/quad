--!strict
-- Cross-check with --solver=old on the WINNER formulation (25) and the
-- chain (31). Expectation per typing-limits.md §8: old solver rejects
-- `typeof(namedFn)` recursive declarations outright, so this should be
-- rejected for reasons unrelated to explicit instantiation.
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
-- RESULT (run with `luau-analyze --solver=old`): rejected, but for
-- pre-existing reasons unrelated to this investigation: "read keyword is
-- illegal here" (old solver doesn't have property read/write modifiers at
-- all) and "Recursive type being used with different parameters" (the
-- typeof(namedFn) trick itself, per typing-limits.md §1③/§8, is
-- new-solver-only). No new information -- confirms this whole investigation
-- inherits the existing new-solver-only constraint, doesn't add a new one.
