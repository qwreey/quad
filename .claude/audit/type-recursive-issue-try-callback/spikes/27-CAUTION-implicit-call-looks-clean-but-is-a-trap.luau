--!strict
-- CAUTION / FALSE POSITIVE: same split+read fix as 25, but WITHOUT explicit
-- <<T,U>> instantiation (plain implicit call). Does the `read` fix
-- accidentally also rescue the implicit-call case that typing-limits.md §1③
-- already established doesn't work?
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

local r2 = n:Compute(function(a0)
	local check: number = a0:Get()
	return tostring(a0:Get())
end)
local wrong2: number = r2:Get()
-- RESULT ON ITS OWN LOOKS CLEAN: no spurious diagnostic, `check` typechecks,
-- `wrong2` correctly errors. BUT this is misleading — see 28, which adds
-- negative controls INSIDE the callback body and reveals this "success" is
-- pure duck-typing-from-usage (unsound), not real inference. Do not read
-- this file's clean result in isolation as "implicit calls now work".
