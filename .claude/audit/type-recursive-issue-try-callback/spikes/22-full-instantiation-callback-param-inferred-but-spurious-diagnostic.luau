--!strict
-- FULL explicit instantiation (both T and U given, T matches self) on
-- quad's actual recursive self-handle shape.
local function Compute<T, U>(self: Box<T>, fn: (Box<T>) -> U): Box<U>
	return nil :: any
end
export type Box<T> = {
	Get: (self: Box<T>) -> T,
	Compute: typeof(Compute),
}

local n: Box<number> = nil :: any

local r2 = n:Compute<<number, string>>(function(a0)
	local check: number = a0:Get()  -- body typechecks fine, no error here
	return tostring(a0:Get())
end)
local wrong2: number = r2:Get()  -- correctly errors (downstream sound)
-- RESULT: `a0` IS correctly inferred (unannotated!) as a structural shape
-- matching `Box<number>` well enough that the callback body typechecks and
-- downstream typing is sound (wrong2 correctly errors). BUT the call line
-- itself gets ONE extra spurious diagnostic: "`Get` is a read-only property
-- in the latter type, but the former type requires a read-write property."
-- This is Luau inferring a0's type FROM USAGE (duck-typed, "only ever
-- read") rather than binding it to the nominal Box<number>, and that
-- inferred read-only shape doesn't structurally unify with Box<T>'s
-- (implicitly read-write) `Get` field. See 23-26 for the fix.
