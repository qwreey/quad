--!strict
local NF = require("../src/Inputs/NumberFormat")

local function eq(a: any, b: any, msg: string)
	if a ~= b then
		error(`{msg}: expected {tostring(b)}, got {tostring(a)}`, 2)
	end
end

-- format
eq(NF.format(1.5, "%.2f"), "1.50", "format %.2f")
eq(NF.format(3, nil, 1), "3", "integral step -> %d")
eq(NF.format(2.6, "%d"), "3", "%d rounds")
eq(NF.format(2.4, nil, 1), "2", "%d rounds down")
eq(NF.format(1, nil, nil), "1.000", "default %.3f")
eq(NF.format(1, nil, 0.5), "1.000", "fractional step -> %.3f")
eq(NF.format(7, "%03d"), "007", "%03d flag")
eq(NF.format(12.5, "%.1f px"), "12.5 px", "suffix kept")
eq(NF.defaultFormat(2), "%d", "defaultFormat integral")
eq(NF.defaultFormat(0.1), "%.3f", "defaultFormat fractional")

-- parse
eq(NF.parse("  12.5 "), 12.5, "parse trims")
eq(NF.parse("-3"), -3, "parse negative")
eq(NF.parse("1e2"), 100, "parse exponent")
eq(NF.parse(""), nil, "parse empty")
eq(NF.parse("   "), nil, "parse blank")
eq(NF.parse("abc"), nil, "parse junk")
eq(NF.parse("12abc"), nil, "parse trailing junk")
eq(NF.parse("inf"), nil, "parse inf")
eq(NF.parse("nan"), nil, "parse nan")

-- clamp / snap / normalize
eq(NF.clamp(5, 0, 3), 3, "clamp max")
eq(NF.clamp(-5, 0, 3), 0, "clamp min")
eq(NF.clamp(5, nil, nil), 5, "clamp none")
eq(NF.clamp(5, nil, 3), 3, "clamp only max")
eq(NF.snap(0.34, 0.1), 0.3, "snap to 0.1")
eq(NF.snap(0.36, 0.1), 0.4, "snap up")
eq(NF.snap(7, 5, 1), 6, "snap with origin")
eq(NF.snap(0.30000000000000004, 0.1), 0.3, "float noise removed")
eq(NF.snap(4, 0), 4, "step 0 ignored")
eq(NF.normalize(11, 0, 10, 2), 10, "normalize clamps after snap")
eq(NF.normalize(-1, 0, 10, nil), 0, "normalize clamp no step")
eq(NF.normalize(5.4, nil, nil, 1), 5, "normalize snap only")
eq(NF.commitText("7.3", 0, 10, 1), 7, "commitText")
eq(NF.commitText("99", 0, 10, nil), 10, "commitText clamps")
eq(NF.commitText("x", 0, 10, nil), nil, "commitText invalid")

-- fractions
eq(NF.toFraction(5, 0, 10), 0.5, "toFraction")
eq(NF.toFraction(50, 0, 10), 1, "toFraction clamps")
eq(NF.toFraction(1, 3, 3), 0, "degenerate range")
eq(NF.fromFraction(0.25, 0, 100), 25, "fromFraction")
eq(NF.fromFraction(2, 0, 100), 100, "fromFraction clamps")
-- track x=100 w=200, grab 20: centre range 110..290
eq(NF.pixelToFraction(110, 100, 200, 20), 0, "pixel at left centre")
eq(NF.pixelToFraction(290, 100, 200, 20), 1, "pixel at right centre")
eq(NF.pixelToFraction(200, 100, 200, 20), 0.5, "pixel middle")
eq(NF.pixelToFraction(0, 100, 200, 20), 0, "pixel outside left")
eq(NF.pixelToFraction(999, 100, 200, 20), 1, "pixel outside right")
eq(NF.pixelToFraction(5, 0, 10, 10), 0, "zero span")

-- hex
eq(NF.toHex(255, 0, 128), "#ff0080", "toHex")
eq(NF.toHex(300, -4, 15.4), "#ff000f", "toHex clamps")
local r, g, b = NF.parseHex("#FF0080")
eq(r, 255, "hex r")
eq(g, 0, "hex g")
eq(b, 128, "hex b")
r, g, b = NF.parseHex(" 0a0 ")
eq(r, 0, "short r")
eq(g, 170, "short g")
eq(b, 0, "short b")
r, g, b = NF.parseHex("#12345")
eq(r, nil, "bad length")
r = NF.parseHex("zzzzzz")
eq(r, nil, "bad digits")
r = NF.parseHex("")
eq(r, nil, "empty")

print("spec.pure.numberformat: ALL PASS")
