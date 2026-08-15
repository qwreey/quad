--!strict
-- Does `Foo<<X>>(...)` with only ONE type arg let you target U while T is
-- inferred from self? Tested on quad's actual recursive self-handle shape.
-- Hypothesis under test: "you can skip T and give only U".
local function Compute<T, U>(self: Box<T>, fn: (Box<T>) -> U): Box<U>
	return nil :: any
end
export type Box<T> = {
	Get: (self: Box<T>) -> T,
	Compute: typeof(Compute),
}

local n: Box<number> = nil :: any

-- intent: "U=string, T inferred as number from self"
local r1 = n:Compute<<string>>(function(a0)
	local check: number = a0:Get()
	return tostring(a0:Get())
end)
local wrong1: number = r1:Get()
-- RESULT: `<<string>>` binds POSITIONALLY to the FIRST declared generic (T),
-- not to U. So this actually means "T=string" (conflicting with self's real
-- T=number), not "U=string, T inferred". The conflict manifests as an
-- "Internal error: outstanding free or blocked type in function call" plus
-- a confusing follow-on TypeError — NOT a clean rejection, NOT a working
-- partial-inference. See 21b for confirmation that even giving the CORRECT
-- leftmost T alone (not conflicting) still breaks with the same internal
-- error on this recursive type — so this isn't "wrong argument order", it's
-- "partial instantiation is broken here regardless of which arg you give".
