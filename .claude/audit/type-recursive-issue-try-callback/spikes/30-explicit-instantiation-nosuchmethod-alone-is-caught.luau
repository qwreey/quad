--!strict
-- Isolate: does explicit instantiation catch a bogus method call even when
-- nothing else in the callback body is wrong?
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
	a0:NoSuchMethod()
	return tostring(a0:Get())
end)
local wrong2: number = r2:Get()
-- RESULT: caught. Call-site TypeError (shape mismatch: real BoxData<number>
-- has no NoSuchMethod field). Confirms 29 wasn't a fluke of having two
-- simultaneous mistakes.
