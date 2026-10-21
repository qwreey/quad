--!strict
--[[
ColorModel -- pure color math + the state model of the color picker.

[2026-10-21] A COPY of quad-roblox-material/src/ColorPicker/ColorModel.luau, public in devui as `Devui.ColorModel` (user
decision with the devplorer candidate list; name by a three-model review, audit/naming-devui-2026-10-21d/). devui does
not depend on the material kit, so the file is copied rather than required; a fix in one belongs in both.

The core works on plain numbers only, so the whole file runs (and is tested) under the plain `luau` CLI.
Roblox datatypes are touched in exactly two thin adapters at the bottom (`toColor3` / `fromColor3`).

== The state-model decision ===========================================================================

Problem. A picker whose state is a single Color3 (or an RGB triple) is lossy: black has no hue and no
saturation, grey has no hue. Drag the SV cursor to the black edge and back, and the hue snaps to red (what
`Color3:ToHSV()` returns for achromatic colors), the hue slider jumps, the SV field background changes
colour under the user's finger. The original picker had this bug (it re-derives HSV from a Color3 in
setColor and in the R/G/B/HEX boxes).

Decision. The canonical state is ONE `Source<HSV>` where `HSV = { H, S, V }`, all in 0..1:

  * every user gesture is expressed in the space it happens in: hue slider -> H only, SV drag -> S and V
    together (one atomic write, so observers never see "new S with old V"), H/S/V boxes -> one channel;
  * `Color3`, the R/G/B bytes, the HEX text, the hue-only background colour, the preview swatch and the
    SV-cursor ring grey are all DERIVED (`:Compute`) from it -- they can never disagree with each other
    and never feed back;
  * a write that arrives in a LOSSY space (R/G/B boxes, HEX box, an external Color3 / `Source<Color3>`
    two-way binding) goes through `fromRGBPreservingHue(r, g, b, previousHSV)`: when the new colour is
    achromatic (S == 0) the previous H is kept, when it is black (V == 0) the previous S is kept too.
    If the incoming colour is identical to what the previous HSV already renders, the previous HSV is
    returned unchanged (idempotent; no float drift and no needless wave).
  * the model deliberately does NOT quantise the state to 8 bit: the picker would otherwise "stick" to
    256 levels per channel while dragging. Bytes exist only at the display / write-in edge.

Cost: one 3-field table per drag event (the original allocated a Color3 + 3 numbers per event). `:Set`
always propagates (even an equal value; only `:SetIfChanged` compares, with `==`, which a fresh table never satisfies), so
callers guard with `equalsHSV(old, new)` before `:Set`.
Fine-grained derivations stay cheap: `hsv:Compute(function(c) return c.H end)` is a number State and dedups
by value, so the SV field background (H only) does not recompute while S/V are dragged.

Alternative considered: three number Sources H, S, V. Better per-channel dedup, but an SV drag writes two
of them -> two waves -> an `onUpdate` consumer sees a half-updated colour. Rejected: atomicity beats dedup.

== Text boxes =========================================================================================

`parseChannel(text, max)` is the single parser for the H/S/V/R/G/B boxes. It is lenient where the original
was (leading zeros, surrounding spaces, out-of-range clamps) and strict where the original crashed or
silently mangled ("-5" became 5; `("%d"):format(x*255)` truncates where a byte should round; a raw `tonumber` would take "0x10" as 16). The port should
commit a box live whenever the text parses (the original did, per keystroke) and, on FocusLost, rewrite the
box from the model (so an invalid or empty text simply reverts). Display scales: the original showed H/S/V
as 0..255 (`hue*255`), which is not what users expect from "H"; the model takes the scale as a parameter
(`Scale.Degrees` = 360/100/100 is the recommended default, `Scale.Legacy` = 255/255/255 reproduces the
original).

Everything here is allocation-free except where a table is the return value.
]]

export type HSV = { H: number, S: number, V: number }
export type RGB = { R: number, G: number, B: number }
export type Scale = { H: number, S: number, V: number }

local floor = math.floor
local abs = math.abs

local EPS = 1e-9

local ColorModel = {}

ColorModel.Scale = {
	Degrees = { H = 360, S = 100, V = 100 } :: Scale,
	Legacy = { H = 255, S = 255, V = 255 } :: Scale,
}

-- ============================================================ numbers

local function clamp(x: number, lo: number, hi: number): number
	if x ~= x then
		return lo -- NaN
	end
	if x < lo then
		return lo
	end
	if x > hi then
		return hi
	end
	return x
end
ColorModel.clamp = clamp

function ColorModel.clamp01(x: number): number
	return clamp(x, 0, 1)
end

--- 0..1 float -> 0..255 integer, round half up (the original truncated with `%d`: 0.5 -> 127).
function ColorModel.toByte(x: number): number
	return floor(clamp(x, 0, 1) * 255 + 0.5)
end

--- 0..255 (any number) -> 0..1 float, clamped.
function ColorModel.fromByte(n: number): number
	return clamp(n, 0, 255) / 255
end

-- ============================================================ HSV <-> RGB

--- h, s, v in 0..1 (h == 1 is the same red as h == 0) -> r, g, b in 0..1.
function ColorModel.hsvToRgb(h: number, s: number, v: number): (number, number, number)
	h, s, v = clamp(h, 0, 1), clamp(s, 0, 1), clamp(v, 0, 1)
	if s == 0 then
		return v, v, v
	end
	local sector = h * 6
	if sector >= 6 then
		sector = 0
	end
	local i = floor(sector)
	local f = sector - i
	local p = v * (1 - s)
	local q = v * (1 - s * f)
	local t = v * (1 - s * (1 - f))
	if i == 0 then
		return v, t, p
	elseif i == 1 then
		return q, v, p
	elseif i == 2 then
		return p, v, t
	elseif i == 3 then
		return p, q, v
	elseif i == 4 then
		return t, p, v
	end
	return v, p, q
end

--- r, g, b in 0..1 -> h in [0, 1), s, v in 0..1. Achromatic colours report h = 0 (and black s = 0);
--- use `fromRGBPreservingHue` when a previous HSV exists.
function ColorModel.rgbToHsv(r: number, g: number, b: number): (number, number, number)
	r, g, b = clamp(r, 0, 1), clamp(g, 0, 1), clamp(b, 0, 1)
	local max = math.max(r, g, b)
	local min = math.min(r, g, b)
	local d = max - min
	if max == 0 then
		return 0, 0, 0
	end
	local s = d / max
	if d == 0 then
		return 0, s, max
	end
	local h
	if max == r then
		h = ((g - b) / d) % 6
	elseif max == g then
		h = (b - r) / d + 2
	else
		h = (r - g) / d + 4
	end
	h = h / 6
	if h >= 1 then
		h = 0
	end
	return h, s, max
end

-- ============================================================ HSV values

function ColorModel.newHSV(h: number, s: number, v: number): HSV
	return { H = clamp(h, 0, 1), S = clamp(s, 0, 1), V = clamp(v, 0, 1) }
end

--- Exact-ish equality (|diff| < 1e-9 per channel). Guard `source:Set` with this.
function ColorModel.equalsHSV(a: HSV, b: HSV): boolean
	return abs(a.H - b.H) < EPS and abs(a.S - b.S) < EPS and abs(a.V - b.V) < EPS
end

--- r, g, b of an HSV as 0..1 floats. `Color3.new(ColorModel.toColor3Parts(hsv))` is the Color3.
function ColorModel.toColor3Parts(hsv: HSV): (number, number, number)
	return ColorModel.hsvToRgb(hsv.H, hsv.S, hsv.V)
end

--- r, g, b of an HSV as 0..255 integers.
function ColorModel.toBytes(hsv: HSV): (number, number, number)
	local r, g, b = ColorModel.hsvToRgb(hsv.H, hsv.S, hsv.V)
	return ColorModel.toByte(r), ColorModel.toByte(g), ColorModel.toByte(b)
end

--- The fully saturated colour of a hue (SV field background, hue handle fill).
function ColorModel.hueToRgb(h: number): (number, number, number)
	return ColorModel.hsvToRgb(h, 1, 1)
end

-- ============================================================ lossy writes keep what they can

--- A colour arrives as RGB (R/G/B boxes, HEX box, external Color3). Keep the previous hue when the colour
--- has none (S == 0) and the previous saturation when it has no saturation to report (V == 0).
function ColorModel.fromRGBPreservingHue(r: number, g: number, b: number, previous: HSV?): HSV
	r, g, b = clamp(r, 0, 1), clamp(g, 0, 1), clamp(b, 0, 1)
	if previous then
		local pr, pg, pb = ColorModel.hsvToRgb(previous.H, previous.S, previous.V)
		if abs(pr - r) < EPS and abs(pg - g) < EPS and abs(pb - b) < EPS then
			return previous
		end
	end
	local h, s, v = ColorModel.rgbToHsv(r, g, b)
	if previous then
		if v < EPS then
			return { H = previous.H, S = previous.S, V = 0 }
		elseif s < EPS then
			return { H = previous.H, S = 0, V = v }
		end
	end
	return { H = h, S = s, V = v }
end

--- Same, from 0..255 channel values (any number; clamped, not rounded).
function ColorModel.fromBytesPreservingHue(r: number, g: number, b: number, previous: HSV?): HSV
	return ColorModel.fromRGBPreservingHue(ColorModel.fromByte(r), ColorModel.fromByte(g), ColorModel.fromByte(b), previous)
end

--- Replace one of the displayed R/G/B bytes. The other two channels are first quantised to the bytes the
--- user currently sees (what you see is what you edit), then the result is merged hue-preserving.
function ColorModel.withRGBByte(previous: HSV, channel: "R" | "G" | "B", value: number): HSV
	local r, g, b = ColorModel.toBytes(previous)
	if channel == "R" then
		r = value
	elseif channel == "G" then
		g = value
	else
		b = value
	end
	return ColorModel.fromBytesPreservingHue(r, g, b, previous)
end

--- Replace one HSV channel (0..1). H, S, V edits are never lossy.
function ColorModel.withHSVChannel(previous: HSV, channel: "H" | "S" | "V", value: number): HSV
	value = clamp(value, 0, 1)
	if channel == "H" then
		return { H = value, S = previous.S, V = previous.V }
	elseif channel == "S" then
		return { H = previous.H, S = value, V = previous.V }
	end
	return { H = previous.H, S = previous.S, V = value }
end

-- ============================================================ HEX

--- "#RRGGBB" (upper case) from 0..1 floats; `withHash = false` gives "RRGGBB" (the original's format).
function ColorModel.rgbToHex(r: number, g: number, b: number, withHash: boolean?): string
	local s = string.format("%02X%02X%02X", ColorModel.toByte(r), ColorModel.toByte(g), ColorModel.toByte(b))
	if withHash == false then
		return s
	end
	return "#" .. s
end

function ColorModel.hsvToHex(hsv: HSV, withHash: boolean?): string
	local r, g, b = ColorModel.hsvToRgb(hsv.H, hsv.S, hsv.V)
	return ColorModel.rgbToHex(r, g, b, withHash)
end

--- Accepts "RRGGBB", "#RRGGBB", "RGB", "#RGB", any case, surrounding whitespace. Returns the colour as
--- 0..1 floats of the 8 bit values, or nil and a reason: "empty" | "length" | "character".
function ColorModel.parseHex(text: string): (RGB?, string?)
	local s = string.match(text, "^%s*(.-)%s*$") :: string
	if string.sub(s, 1, 1) == "#" then
		s = string.sub(s, 2)
	end
	if s == "" then
		return nil, "empty"
	end
	if string.find(s, "[^%x]") then
		return nil, "character"
	end
	local n = #s
	if n == 3 then
		s = string.gsub(s, ".", "%0%0") :: string
	elseif n ~= 6 then
		return nil, "length"
	end
	local r = tonumber(string.sub(s, 1, 2), 16) :: number
	local g = tonumber(string.sub(s, 3, 4), 16) :: number
	local b = tonumber(string.sub(s, 5, 6), 16) :: number
	return { R = r / 255, G = g / 255, B = b / 255 }, nil
end

--- parseHex + hue-preserving merge. nil, reason on invalid text.
function ColorModel.fromHexPreservingHue(text: string, previous: HSV?): (HSV?, string?)
	local rgb, reason = ColorModel.parseHex(text)
	if not rgb then
		return nil, reason
	end
	return ColorModel.fromRGBPreservingHue(rgb.R, rgb.G, rgb.B, previous), nil
end

-- ============================================================ text boxes

--- A numeric box (H/S/V/R/G/B). Returns the integer clamped into 0..max, or nil and a reason:
--- "empty" | "format". When the value had to be clamped the second return is "clamped" (value is non-nil).
--- Rounds half up; accepts "12", " 12 ", "012", "12.4", "+7", ".5"; rejects "-", "1e3", "0x10", "12px".
function ColorModel.parseChannel(text: string, max: number): (number?, string?)
	local s = string.match(text, "^%s*(.-)%s*$") :: string
	if s == "" then
		return nil, "empty"
	end
	if not (string.match(s, "^[+-]?%d+%.?%d*$") or string.match(s, "^[+-]?%.%d+$")) then
		return nil, "format"
	end
	local n = tonumber(s)
	if n == nil then
		return nil, "format"
	end
	local rounded = floor(n + 0.5)
	if rounded < 0 then
		return 0, "clamped"
	elseif rounded > max then
		return max, "clamped"
	end
	return rounded, nil
end

--- 0..1 channel -> displayed integer text for a box with range 0..max.
function ColorModel.channelText(value: number, max: number): string
	return string.format("%d", floor(clamp(value, 0, 1) * max + 0.5))
end

--- Box text -> 0..1 channel value (nil, reason if the text does not parse).
function ColorModel.channelFromText(text: string, max: number): (number?, string?)
	local n, note = ColorModel.parseChannel(text, max)
	if n == nil then
		return nil, note
	end
	return n / max, note
end

-- ============================================================ SV cursor ring grey

--- Grey (0..1) of the SV cursor's outer ring. Near the white corner (S = 0, V = 1) the ring is black so it
--- stays visible, fading to white once the distance from that corner reaches 0.25 (the original's
--- `__getCursorColor(X = S, Y = 1 - V)`).
function ColorModel.cursorRingGray(s: number, v: number): number
	local x, y = clamp(s, 0, 1), 1 - clamp(v, 0, 1)
	local length = math.sqrt(x * x + y * y)
	return 1 - clamp(0.25 - length, 0, 0.25) * 4
end

-- ============================================================ Roblox adapters (the only Color3 use)

function ColorModel.toColor3(hsv: HSV): Color3
	return Color3.new(ColorModel.hsvToRgb(hsv.H, hsv.S, hsv.V))
end

function ColorModel.fromColor3(color: Color3, previous: HSV?): HSV
	return ColorModel.fromRGBPreservingHue(color.R, color.G, color.B, previous)
end

return ColorModel
