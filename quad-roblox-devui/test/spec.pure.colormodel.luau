--!strict
-- Pure spec for ColorModel (plain `luau`, no quad, no Roblox datatypes).
-- Run: luau quad-roblox-devui/test/spec.pure.colormodel.luau   (from the repo root). The same spec as the material kit's (the module is a copy).

local M = require("../src/ColorModel")

local passed, failed = 0, 0
local function check(cond: boolean, name: string)
	if cond then
		passed += 1
	else
		failed += 1
		print("FAIL: " .. name)
	end
end
local function near(a: number, b: number, eps: number?): boolean
	return math.abs(a - b) < (eps or 1e-9)
end
local function eq(a: any, b: any, name: string)
	if a == b then
		passed += 1
	else
		failed += 1
		print(("FAIL: %s (got %s, want %s)"):format(name, tostring(a), tostring(b)))
	end
end

-- ---------------------------------------------------------------- known colours
do
	local function rgb(h, s, v)
		local r, g, b = M.hsvToRgb(h, s, v)
		return M.toByte(r), M.toByte(g), M.toByte(b)
	end
	local r, g, b = rgb(0, 1, 1)
	check(r == 255 and g == 0 and b == 0, "red")
	r, g, b = rgb(1 / 3, 1, 1)
	check(r == 0 and g == 255 and b == 0, "green")
	r, g, b = rgb(2 / 3, 1, 1)
	check(r == 0 and g == 0 and b == 255, "blue")
	r, g, b = rgb(1 / 6, 1, 1)
	check(r == 255 and g == 255 and b == 0, "yellow")
	r, g, b = rgb(0.5, 1, 1)
	check(r == 0 and g == 255 and b == 255, "cyan")
	r, g, b = rgb(5 / 6, 1, 1)
	check(r == 255 and g == 0 and b == 255, "magenta")
	r, g, b = rgb(1, 1, 1)
	check(r == 255 and g == 0 and b == 0, "h=1 is red")
	r, g, b = rgb(0.3, 0, 0.5)
	check(r == 128 and g == 128 and b == 128, "grey 0.5 -> 128")
	r, g, b = rgb(0.8, 0.4, 1) -- the original's initial colour
	check(r == 235 and g == 153 and b == 255, "original initial colour (0.8,0.4,1) = 235,153,255")
end

-- ---------------------------------------------------------------- HSV -> RGB -> HSV round trip on a grid
do
	local worst = 0
	local n = 0
	for hi = 0, 59 do
		for si = 1, 10 do
			for vi = 1, 10 do
				local h, s, v = hi / 60, si / 10, vi / 10
				local r, g, b = M.hsvToRgb(h, s, v)
				local h2, s2, v2 = M.rgbToHsv(r, g, b)
				local dh = math.abs(h - h2)
				dh = math.min(dh, 1 - dh)
				worst = math.max(worst, dh, math.abs(s - s2), math.abs(v - v2))
				n += 1
			end
		end
	end
	check(worst < 1e-9, ("HSV round trip worst error %g over %d samples"):format(worst, n))
end

-- ---------------------------------------------------------------- RGB (bytes) -> HSV -> RGB (bytes) exact
do
	local bad = 0
	for r = 0, 255, 5 do
		for g = 0, 255, 5 do
			for b = 0, 255, 5 do
				local h, s, v = M.rgbToHsv(r / 255, g / 255, b / 255)
				local r2, g2, b2 = M.hsvToRgb(h, s, v)
				if M.toByte(r2) ~= r or M.toByte(g2) ~= g or M.toByte(b2) ~= b then
					bad += 1
				end
			end
		end
	end
	check(bad == 0, "byte RGB survives HSV round trip (" .. bad .. " mismatches)")
end

-- ---------------------------------------------------------------- bytes
eq(M.toByte(0), 0, "toByte 0")
eq(M.toByte(1), 255, "toByte 1")
eq(M.toByte(0.5), 128, "toByte 0.5 rounds half up (127.5 -> 128)")
eq(M.toByte(-3), 0, "toByte clamps low")
eq(M.toByte(7), 255, "toByte clamps high")
eq(M.toByte(0 / 0), 0, "toByte NaN -> 0")
check(near(M.fromByte(255), 1), "fromByte 255")
check(near(M.fromByte(300), 1), "fromByte clamps")
check(near(M.fromByte(-4), 0), "fromByte clamps low")
for i = 0, 255 do
	if M.toByte(M.fromByte(i)) ~= i then
		check(false, "byte round trip " .. i)
	end
end

-- ---------------------------------------------------------------- hex
eq(M.rgbToHex(1, 0.5, 0), "#FF8000", "rgbToHex")
eq(M.rgbToHex(0, 0, 0, false), "000000", "rgbToHex no hash")
eq(M.hsvToHex({ H = 0, S = 1, V = 1 }), "#FF0000", "hsvToHex red")
do
	local function hex(t: string): (number?, number?, number?, string?)
		local c, reason = M.parseHex(t)
		if not c then
			return nil, nil, nil, reason
		end
		return M.toByte(c.R), M.toByte(c.G), M.toByte(c.B), nil
	end
	local r, g, b, why = hex("#FF8000")
	check(r == 255 and g == 128 and b == 0 and why == nil, "parse #FF8000")
	r, g, b = hex("ff8000")
	check(r == 255 and g == 128 and b == 0, "parse lowercase, no hash")
	r, g, b = hex("  #f80 ")
	check(r == 255 and g == 136 and b == 0, "parse #RGB shorthand with spaces")
	r, g, b = hex("abc")
	check(r == 170 and g == 187 and b == 204, "parse abc")
	local _a, _b, _c
	_a, _b, _c, why = hex("")
	eq(why, "empty", "empty")
	_a, _b, _c, why = hex("#")
	eq(why, "empty", "lone hash")
	_a, _b, _c, why = hex("12345")
	eq(why, "length", "5 digits")
	_a, _b, _c, why = hex("1234567")
	eq(why, "length", "7 digits")
	_a, _b, _c, why = hex("12G456")
	eq(why, "character", "non-hex char")
	_a, _b, _c, why = hex("0xFFAA")
	eq(why, "character", "0x prefix rejected")
	_a, _b, _c, why = hex("#12 34 56")
	eq(why, "character", "inner space rejected")
	-- every byte colour on a grid survives text
	local bad = 0
	for r2 = 0, 255, 15 do
		for g2 = 0, 255, 15 do
			for b2 = 0, 255, 15 do
				local text = M.rgbToHex(r2 / 255, g2 / 255, b2 / 255)
				local c = M.parseHex(text)
				if not c or M.toByte(c.R) ~= r2 or M.toByte(c.G) ~= g2 or M.toByte(c.B) ~= b2 then
					bad += 1
				end
			end
		end
	end
	check(bad == 0, "hex text round trip")
end

-- ---------------------------------------------------------------- hue preservation (the central problem)
do
	local start = M.newHSV(0.8, 0.4, 1)

	-- drag V to 0 through the SV field, then come back: state is HSV, nothing is lost
	local black = M.withHSVChannel(start, "V", 0)
	check(black.H == 0.8 and black.S == 0.4, "V=0 keeps H and S in the HSV state")
	local back = M.withHSVChannel(black, "V", 1)
	check(M.equalsHSV(back, start), "V 1 -> 0 -> 1 returns the exact colour")

	-- a Color3 echo of black (external write / hex) would otherwise reset H to 0
	local r, g, b = M.toColor3Parts(black)
	check(r == 0 and g == 0 and b == 0, "black parts")
	local echoed = M.fromRGBPreservingHue(r, g, b, black)
	check(echoed.H == 0.8 and echoed.S == 0.4 and echoed.V == 0, "black echo keeps H and S")
	local naive_h = M.rgbToHsv(0, 0, 0)
	check(naive_h == 0, "(sanity) naive conversion would have lost the hue")

	-- external black written onto a coloured previous state: keeps previous H and S
	local ext = M.fromRGBPreservingHue(0, 0, 0, start)
	check(ext.H == 0.8 and ext.S == 0.4 and ext.V == 0, "external black keeps previous H,S")

	-- grey: keeps H, takes S = 0 and V
	local grey = M.fromRGBPreservingHue(0.5, 0.5, 0.5, start)
	check(grey.H == 0.8 and grey.S == 0 and near(grey.V, 0.5), "grey keeps H, S = 0")
	-- from grey back to a real colour: hue now comes from the colour
	local red = M.fromRGBPreservingHue(1, 0, 0, grey)
	check(red.H == 0 and red.S == 1 and red.V == 1, "chromatic colour takes its own hue")

	-- without a previous state achromatic colours fall back to h = 0, s = 0
	local none = M.fromRGBPreservingHue(0.3, 0.3, 0.3, nil)
	check(none.H == 0 and none.S == 0 and near(none.V, 0.3), "no previous: grey -> H 0")

	-- idempotence: echoing the rendered colour returns the very same table (no wave, no drift)
	local c = M.newHSV(0.123456, 0.654321, 0.777777)
	local cr, cg, cb = M.toColor3Parts(c)
	check(M.fromRGBPreservingHue(cr, cg, cb, c) == c, "echo of the rendered colour returns previous (identity)")

	-- B box edit on black: stays black-ish, hue kept
	local black2 = M.withRGBByte(black, "B", 0)
	check(black2.H == 0.8 and black2.S == 0.4 and black2.V == 0, "typing 0 into B on black changes nothing")
	local blue = M.withRGBByte(black, "B", 255)
	check(near(blue.H, 2 / 3) and blue.S == 1 and blue.V == 1, "typing 255 into B on black gives blue (its own hue)")

	-- achromatic by edit: set S to 0 then H stays
	local s0 = M.withHSVChannel(start, "S", 0)
	check(s0.H == 0.8, "S=0 edit keeps H")
	local fromHexGrey = M.fromHexPreservingHue("#808080", start)
	check(fromHexGrey ~= nil and (fromHexGrey :: M.HSV).H == 0.8, "hex grey keeps H")
	local bad, why = M.fromHexPreservingHue("#12", start)
	check(bad == nil and why == "length", "hex invalid -> nil, reason")
end

-- ---------------------------------------------------------------- channels via bytes
do
	local start = M.newHSV(0, 1, 1) -- red
	local g = M.withRGBByte(start, "G", 255)
	local r, gg, b = M.toBytes(g)
	check(r == 255 and gg == 255 and b == 0, "red + G=255 -> yellow")
	check(near(g.H, 1 / 6), "yellow hue")
	-- other channels are quantised to what the user sees before merging
	local odd = M.newHSV(0, 1, 0.5) -- r = 127.5 -> displayed 128
	local r2, g2, b2 = M.toBytes(M.withRGBByte(odd, "B", 0))
	check(r2 == 128 and g2 == 0 and b2 == 0, "other channels use the displayed byte")
end

-- ---------------------------------------------------------------- equality
do
	local a = M.newHSV(0.1, 0.2, 0.3)
	check(M.equalsHSV(a, { H = 0.1, S = 0.2, V = 0.3 }), "equalsHSV equal")
	check(not M.equalsHSV(a, { H = 0.1, S = 0.2, V = 0.3001 }), "equalsHSV differs")
	local c = M.newHSV(-1, 5, 0.5)
	check(c.H == 0 and c.S == 1 and c.V == 0.5, "newHSV clamps")
end

-- ---------------------------------------------------------------- parseChannel
do
	local v, note = M.parseChannel("42", 100)
	check(v == 42 and note == nil, "42")
	v, note = M.parseChannel("  42  ", 100)
	check(v == 42 and note == nil, "surrounding spaces")
	v = M.parseChannel("007", 255)
	check(v == 7, "leading zeros")
	v, note = M.parseChannel("300", 255)
	check(v == 255 and note == "clamped", "clamped high")
	v, note = M.parseChannel("-5", 255)
	check(v == 0 and note == "clamped", "negative clamps to 0 (original turned it into 5)")
	v = M.parseChannel("12.4", 255)
	check(v == 12, "decimal rounds down")
	v = M.parseChannel("12.5", 255)
	check(v == 13, "decimal rounds half up")
	v = M.parseChannel(".5", 255)
	check(v == 1, ".5")
	v = M.parseChannel("+7", 255)
	check(v == 7, "+7")
	v = M.parseChannel("360", 360)
	check(v == 360, "360 of 360")
	v, note = M.parseChannel("361", 360)
	check(v == 360 and note == "clamped", "361 of 360")
	v, note = M.parseChannel("", 255)
	check(v == nil and note == "empty", "empty")
	v, note = M.parseChannel("   ", 255)
	check(v == nil and note == "empty", "blank")
	for _, bad in { "-", "abc", "1e3", "0x10", "12px", "1 2", "1,5", "--3", "." } do
		v, note = M.parseChannel(bad, 255)
		check(v == nil and note == "format", "reject '" .. bad .. "'")
	end
	local f, n2 = M.channelFromText("50", 100)
	check(f ~= nil and near(f :: number, 0.5) and n2 == nil, "channelFromText")
	f = M.channelFromText("x", 100)
	check(f == nil, "channelFromText invalid")
	eq(M.channelText(0.8, 360), "288", "channelText H 0.8 -> 288")
	eq(M.channelText(0.4, 100), "40", "channelText S 0.4 -> 40")
	eq(M.channelText(1, 100), "100", "channelText 1")
	eq(M.channelText(0.8, M.Scale.Legacy.H), "204", "legacy 0.8*255 = 204")
	-- text <-> value round trip for every integer of every scale
	local bad = 0
	for _, max in { 100, 255, 360 } do
		for i = 0, max do
			local fv = M.channelFromText(tostring(i), max) :: number
			if M.channelText(fv, max) ~= tostring(i) then
				bad += 1
			end
		end
	end
	check(bad == 0, "channel text round trip")
end

-- ---------------------------------------------------------------- cursor ring grey
do
	check(near(M.cursorRingGray(0, 1), 0), "ring black at the white corner")
	check(near(M.cursorRingGray(1, 0), 1), "ring white far away")
	check(near(M.cursorRingGray(0.125, 1), 0.5), "ring half at distance 0.125")
	check(near(M.cursorRingGray(0.4, 0.4), 1), "ring white beyond 0.25")
end

-- ---------------------------------------------------------------- hueToRgb
do
	local r, g, b = M.hueToRgb(0.5)
	check(near(r, 0) and near(g, 1) and near(b, 1), "hueToRgb cyan")
end

print(("colormodel spec: %d passed, %d failed"):format(passed, failed))
if failed > 0 then
	error("spec failed")
end
