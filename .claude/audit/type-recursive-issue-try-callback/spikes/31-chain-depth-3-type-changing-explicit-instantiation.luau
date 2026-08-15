--!strict
-- Chained calls with explicit <<T,U>> instantiation, type changing at each
-- step: number -> boolean -> string -> number. Uses the 25 (WINNER)
-- formulation throughout.
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

local r1 = n:Compute<<number, boolean>>(function(a0)
	local x: number = a0:Get()
	return x > 0
end)
local r2 = r1:Compute<<boolean, string>>(function(a1)
	local y: boolean = a1:Get()
	return tostring(y)
end)
local r3 = r2:Compute<<string, number>>(function(a2)
	local z: string = a2:Get()
	return #z
end)

-- positive controls
local ok1: boolean = r1:Get()
local ok2: string = r2:Get()
local ok3: number = r3:Get()

-- negative controls
local wrong1: number = r1:Get()   -- should error (r1 is Box<boolean>)
local wrong2: number = r2:Get()   -- should error (r2 is Box<string>)
local wrong3: string = r3:Get()   -- should error (r3 is Box<number>)
-- RESULT: fully clean chaining. All three callback params inferred
-- unannotated and correctly, no spurious diagnostics at any step, all
-- three positive controls pass, all three negative controls correctly
-- error. This is the strongest positive result in this investigation.
