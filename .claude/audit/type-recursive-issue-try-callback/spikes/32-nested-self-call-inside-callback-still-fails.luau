--!strict
-- Nested self-call: callback body calls a0:Compute(...) again (quad's
-- :Apply factory / nested-Compute pattern, typing-limits.md §1② already
-- flags this as needing manual annotation under the split approach). Does
-- explicit instantiation rescue this case too?
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

local outer = n:Compute<<number, string>>(function(a0)
	-- nested call, ALSO explicitly instantiated
	local inner = a0:Compute<<number, boolean>>(function(a1)
		local v: number = a1:Get()
		return v > 0
	end)
	local b: boolean = inner:Get()
	return tostring(b)
end)

local ok: string = outer:Get()
local wrong: number = outer:Get()  -- should error
-- RESULT: FAILS. "Too many type parameters passed to function typed as
-- ... Expected at most 0 type parameters, but 2 provided." Because `a0`
-- itself is a duck-typed (usage-derived) shape, not the nominal
-- BoxData<number>, its `Compute` field gets concretized to a NON-generic
-- function type from this one call site -- so `a0:Compute<<...>>` has no
-- generics left to instantiate. Explicit instantiation on the OUTER call
-- does not propagate generics into the unannotated parameter's OWN nested
-- method calls. Consistent with typing-limits.md §1②'s existing caveat:
-- nested self-calls inside a callback (the :Apply factory pattern) still
-- need `function(a0: Box<T>)` parameter annotation regardless of this
-- investigation's findings.
