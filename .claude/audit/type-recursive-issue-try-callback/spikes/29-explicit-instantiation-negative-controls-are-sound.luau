--!strict
-- Same negative controls as 28, but WITH explicit <<T,U>> instantiation
-- (the 25 formulation). Does explicit instantiation make the check sound
-- (vs 28's duck-typing trap)?
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
	local badType: string = a0:Get()  -- should ERROR: Get() returns number
	a0:NoSuchMethod()                  -- should ERROR: no such method
	return tostring(a0:Get())
end)
local wrong2: number = r2:Get()
-- RESULT: sound. The call line now errors because the callback's inferred
-- shape (`Get` returning `string`, plus an extra `NoSuchMethod` field)
-- doesn't match the now-CONCRETE expected `(BoxData<number>) -> string`
-- (T=number is pinned by explicit instantiation, not left free to be
-- shaped by usage). One combined diagnostic covers both mistakes rather
-- than two separate ones, but it DOES fail analysis -- nothing slips
-- through silently. See 30 for confirmation that NoSuchMethod alone
-- (isolated from the badType mistake) is caught too.
