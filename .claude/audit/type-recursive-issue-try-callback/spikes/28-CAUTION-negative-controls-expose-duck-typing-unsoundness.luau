--!strict
-- Negative controls for 27: is a0's inferred type ACTUALLY the nominal
-- BoxData<number>, or is Luau just duck-typing a shape FROM the callback
-- body's own usage (i.e. tautologically "consistent" with whatever the body
-- happens to do, catching nothing)?
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
	local badType: string = a0:Get()  -- should ERROR: Get() returns number
	a0:NoSuchMethod()                  -- should ERROR: no such method
	return tostring(a0:Get())
end)
local wrong2: number = r2:Get()
-- RESULT: confirms unsoundness.
--   * `a0:NoSuchMethod()` produces ZERO error -- Luau just duck-types a
--     `NoSuchMethod` field into existence on a0's inferred shape, because
--     nothing constrains a0 to the real BoxData<number>.
--   * `local badType: string = a0:Get()` also produces no error AT THAT
--     LINE -- instead the solver infers Get's return type as `string` to
--     satisfy it, which then conflicts with the later `tostring(a0:Get())`
--     usage that also needs Get, producing a confusing downstream error
--     ("No valid instantiation could be inferred for generic type parameter
--     T... expected number|string, at most number&string") instead of a
--     clear "badType is wrong" message at the actual mistake's location.
-- This is the SAME class of danger typing-limits.md already documents for
-- unannotated self-ref params (old REPORT section 4, spikes 06/07): the
-- callback body is checked against a shape inferred FROM the body itself,
-- not against the real type, so genuine misuse can go silently uncaught.
