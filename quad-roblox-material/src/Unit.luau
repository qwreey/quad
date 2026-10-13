--!strict
--[[
	Unit — how a stored number is SHOWN, and read back from text. Not part of Material 3 (MDC has a label formatter, the
	`Format` prop; Compose has no value text at all): a kit addition for the Luau habit of keeping values as INTEGERS
	and scaling only for display — the value runs 0..10000 and reads "100.00" (user decision 2026-10-13).

	    local Percent: Unit.Unit = { Scale = 0.01, Suffix = "%" }       -- 2 decimals, from the scale
	    Slider({ Value = ratio, Min = 0, Max = 10000, Step = 1, KeyStep = 100, Unit = Percent })   -- label "37.25%"
	    Unit.format(Percent, 3725)      --> "37.25%"
	    Unit.parse(Percent, "37.25%")   --> 3725       (also "37.25", " 37.25 % ")

	Why integers: snapping, the "Max - Min is a multiple of Step" check and every `==` on the value are exact, and what
	is stored or sent carries no 0.30000000000000004. Why a TABLE and not only `Format`: a function cannot be run
	backwards — a unit can (`parse`), so the same definition serves a number typed into a field.

	Unit = { Scale, Decimals?, Prefix?, Suffix? }   (all `read`)
	  Scale      number   shown = value * Scale. Positive and finite.
	  Decimals   number?  digits after the point, 0..15. Default: taken from Scale when it is a power of ten (0.01 -> 2,
	                      0.1 -> 1, 1 / 10 / 100 -> 0); any other Scale (0.5, 2.54) must say it.
	  Prefix     string?  written before the number ("$"), default ""
	  Suffix     string?  written after it ("%", " px"), default ""

	format(unit, value) -> string    Prefix .. number .. Suffix; a value that rounds to zero has no minus sign.
	parse(unit, text) -> number?     the value for a text: surrounding spaces, the Prefix and the Suffix are optional;
	                                 nil when what is left is not a number (tonumber, so "1e3" and "0x10" are read the
	                                 way Luau reads them). The result is n / Scale, and when that is a whole number up
	                                 to float noise it IS the whole number (37.25 / 0.01 is 3725, not 3724.9999999999995).
	check(unit, level?)              raises on a malformed unit (the components call it at construction).
]]

export type Unit = {
	read Scale: number,
	read Decimals: number?,
	read Prefix: string?,
	read Suffix: string?,
}

local function decimalsOf(unit: Unit): number?
	local decimals = unit.Decimals
	if decimals ~= nil then
		return decimals
	end
	-- a power of ten: 0.01 -> 2, 0.1 -> 1, 1 and above -> 0
	local exponent = math.log10(unit.Scale)
	local whole = math.floor(exponent + 0.5)
	if math.abs(exponent - whole) > 1e-9 then
		return nil
	end
	return math.max(0, -whole)
end

local function check(unit: Unit, level: number?)
	local at = (level or 1) + 1
	if type(unit) ~= "table" then
		error(`Unit: expected a table \{ Scale, Decimals?, Prefix?, Suffix? \} (got {typeof(unit)})`, at)
	end
	local scale = unit.Scale
	if type(scale) ~= "number" or not (scale > 0) or scale == math.huge then
		error(`Unit: Scale must be a positive, finite number (got {tostring(scale)})`, at)
	end
	local decimals = unit.Decimals
	if decimals ~= nil and (type(decimals) ~= "number" or decimals < 0 or decimals > 15 or decimals % 1 ~= 0) then
		error(`Unit: Decimals must be a whole number from 0 to 15 (got {tostring(decimals)})`, at)
	end
	if decimals == nil and decimalsOf(unit) == nil then
		error(`Unit: Decimals is required when Scale ({scale}) is not a power of ten`, at)
	end
	if unit.Prefix ~= nil and type(unit.Prefix) ~= "string" then
		error(`Unit: Prefix must be a string (got {typeof(unit.Prefix)})`, at)
	end
	if unit.Suffix ~= nil and type(unit.Suffix) ~= "string" then
		error(`Unit: Suffix must be a string (got {typeof(unit.Suffix)})`, at)
	end
end

local function format(unit: Unit, value: number): string
	local decimals = decimalsOf(unit) or 0
	local text = string.format("%." .. decimals .. "f", value * unit.Scale)
	if tonumber(text) == 0 then
		text = string.format("%." .. decimals .. "f", 0) -- "-0.00" -> "0.00"
	end
	return (unit.Prefix or "") .. text .. (unit.Suffix or "")
end

local function trim(text: string): string
	return (string.gsub(text, "^%s*(.-)%s*$", "%1"))
end

local function parse(unit: Unit, text: string): number?
	local rest = trim(text)
	local prefix, suffix = unit.Prefix or "", unit.Suffix or ""
	local bare = trim(prefix)
	if bare ~= "" and string.sub(rest, 1, #bare) == bare then
		rest = trim(string.sub(rest, #bare + 1))
	end
	bare = trim(suffix)
	if bare ~= "" and #rest >= #bare and string.sub(rest, #rest - #bare + 1) == bare then
		rest = trim(string.sub(rest, 1, #rest - #bare))
	end
	local shown = tonumber(rest)
	if shown == nil or shown ~= shown or math.abs(shown) == math.huge then
		return nil
	end
	local value = shown / unit.Scale
	local whole = math.floor(value + 0.5)
	if math.abs(value - whole) <= 1e-9 * math.max(1, math.abs(value)) then
		return whole
	end
	return value
end

return table.freeze({
	check = check,
	format = format,
	parse = parse,
})
