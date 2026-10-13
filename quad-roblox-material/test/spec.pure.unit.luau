--!strict
-- Pure spec for Unit (plain `luau`, no engine): format, parse (the inverse), check.
local Unit = require("../src/Unit")
type Unit = Unit.Unit

local count, failed = 0, 0
local function check(cond: boolean, msg: string)
	count += 1
	if not cond then
		failed += 1
		print("FAIL: " .. msg)
	end
end
local function eq(a: any, b: any, msg: string)
	check(a == b, ("%s (got %s, want %s)"):format(msg, tostring(a), tostring(b)))
end
local function throws(f: () -> (), needle: string, msg: string)
	local ok, err = pcall(f)
	check(not ok and string.find(tostring(err), needle, 1, true) ~= nil, msg .. " should raise \"" .. needle .. "\" (got " .. tostring(err) .. ")")
end

local percent: Unit = { Scale = 0.01, Suffix = "%" }
local money: Unit = { Scale = 0.01, Prefix = "$" }
local plain: Unit = { Scale = 1 }
local tenth: Unit = { Scale = 0.1, Suffix = " s" }
local kilo: Unit = { Scale = 0.001, Decimals = 1, Suffix = " km" }
local half: Unit = { Scale = 0.5, Decimals = 1 }
local hundreds: Unit = { Scale = 100 }

-- format: Decimals from a power-of-ten Scale, an explicit Decimals wins, prefix / suffix
eq(Unit.format(percent, 3725), "37.25%", "0.01 -> 2 decimals")
eq(Unit.format(percent, 10000), "100.00%", "trailing zeros kept: the precision is the unit's")
eq(Unit.format(percent, 0), "0.00%", "zero")
eq(Unit.format(money, 199), "$1.99", "prefix")
eq(Unit.format(plain, 42), "42", "scale 1 -> 0 decimals")
eq(Unit.format(tenth, 15), "1.5 s", "0.1 -> 1 decimal")
eq(Unit.format(kilo, 12345), "12.3 km", "explicit Decimals over the scale's 3")
eq(Unit.format(half, 3), "1.5", "non power of ten with Decimals")
eq(Unit.format(hundreds, 3), "300", "scale above 1 -> 0 decimals")
eq(Unit.format(percent, -3725), "-37.25%", "negative")
eq(Unit.format(percent, -0.2), "0.00%", "a value that rounds to zero has no minus sign")
eq(Unit.format(tenth, 0.4), "0.0 s", "rounds down to zero")

-- parse: the inverse, on integers exactly
eq(Unit.parse(percent, "37.25%"), 3725, "back to the integer")
eq(Unit.parse(percent, "37.25"), 3725, "suffix optional")
eq(Unit.parse(percent, "  37.25 % "), 3725, "spaces")
eq(Unit.parse(money, "$1.99"), 199, "prefix")
eq(Unit.parse(money, "1.99"), 199, "prefix optional")
eq(Unit.parse(tenth, "1.5 s"), 15, "suffix with a space")
eq(Unit.parse(tenth, "1.5s"), 15, "suffix without its space")
eq(Unit.parse(plain, "42"), 42, "scale 1")
eq(Unit.parse(percent, "-5"), -500, "negative")
eq(Unit.parse(hundreds, "300"), 3, "scale above 1")
eq(Unit.parse(percent, "37.255"), 3725.5, "finer than the unit: not rounded (the caller snaps)")
eq(Unit.parse(percent, ""), nil, "empty")
eq(Unit.parse(percent, "%"), nil, "only the suffix")
eq(Unit.parse(percent, "abc"), nil, "not a number")
eq(Unit.parse(percent, "12abc%"), nil, "trailing junk")
eq(Unit.parse(percent, "nan"), nil, "nan")
eq(Unit.parse(percent, "inf"), nil, "inf")
-- every integer of a slider's domain survives format -> parse (the point of the unit)
local bad = 0
for v = 0, 10000 do
	if Unit.parse(percent, Unit.format(percent, v)) ~= v then
		bad += 1
	end
end
eq(bad, 0, "format -> parse is the identity on 0..10000 at Scale 0.01")
bad = 0
for v = -500, 500 do
	if Unit.parse(tenth, Unit.format(tenth, v)) ~= v then
		bad += 1
	end
end
eq(bad, 0, "format -> parse is the identity on -500..500 at Scale 0.1")

-- check
Unit.check(percent)
Unit.check(half)
throws(function() Unit.check(nil :: any) end, "expected a table", "nil")
throws(function() Unit.check({ Scale = 0 }) end, "Scale must be a positive", "zero scale")
throws(function() Unit.check({ Scale = -1 }) end, "Scale must be a positive", "negative scale")
throws(function() Unit.check({ Scale = math.huge }) end, "Scale must be a positive", "infinite scale")
throws(function() Unit.check({ Scale = "1" } :: any) end, "Scale must be a positive", "string scale")
throws(function() Unit.check({ Scale = 0.5 }) end, "Decimals is required", "non power of ten without Decimals")
throws(function() Unit.check({ Scale = 1, Decimals = 1.5 }) end, "Decimals must be a whole number", "fractional decimals")
throws(function() Unit.check({ Scale = 1, Decimals = 16 }) end, "Decimals must be a whole number", "too many decimals")
throws(function() Unit.check({ Scale = 1, Prefix = 1 } :: any) end, "Prefix must be a string", "prefix type")
throws(function() Unit.check({ Scale = 1, Suffix = true } :: any) end, "Suffix must be a string", "suffix type")

print(("unit: %d checks, %d failed"):format(count, failed))
if failed > 0 then
	error("unit spec failed")
end
