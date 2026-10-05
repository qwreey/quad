--!strict
--[[
	NumberFormat — PURE number/colour text helpers shared by the Input widgets (no engine, no quad: runs under plain
	`luau`, see test/spec.pure.numberformat.luau).

		format(v, pattern?, step?)       string      `string.format` with the pattern; "%d"/"%i" patterns round first
		defaultFormat(step?)             string      "%d" when step is integral, else "%.3f"
		parse(text)                      number?     trims; nil for "" / junk / nan / inf
		clamp(v, min?, max?)             number
		snap(v, step, origin?)           number      nearest multiple of `step` counted from `origin` (float noise removed)
		normalize(v, min?, max?, step?)  number      snap to step (from min) then clamp — the one rule every widget commits with
		commitText(text, min?, max?, step?)  number? parse + normalize (nil = invalid text: the widget reverts)
		toFraction(v, min, max)          number      0..1 (clamped); degenerate range -> 0
		fromFraction(f, min, max)        number
		pixelToFraction(x, trackX, trackW, grabW)  number   0..1, the grab centre follows the pointer
		toHex(r, g, b)                   string      "#rrggbb" from 0..255 numbers
		parseHex(text)                   (number?, number?, number?)   "#rgb" / "rgb" / "#rrggbb" / "rrggbb"
]]

local NumberFormat = {}

local function isFinite(n: number): boolean
	return n == n and n ~= math.huge and n ~= -math.huge
end

function NumberFormat.isIntegral(n: number): boolean
	return isFinite(n) and n == math.floor(n)
end

function NumberFormat.defaultFormat(step: number?): string
	if step ~= nil and NumberFormat.isIntegral(step) then
		return "%d"
	end
	return "%.3f"
end

function NumberFormat.format(v: number, pattern: string?, step: number?): string
	local p = pattern or NumberFormat.defaultFormat(step)
	if string.find(p, "%%[%-%+ #0-9]*[di]") then
		return string.format(p, math.floor(v + 0.5))
	end
	return string.format(p, v)
end

function NumberFormat.parse(text: string): number?
	local trimmed = string.match(text, "^%s*(.-)%s*$") :: string
	if trimmed == "" then
		return nil
	end
	local n = tonumber(trimmed)
	if n == nil or not isFinite(n) then
		return nil
	end
	return n
end

function NumberFormat.clamp(v: number, min: number?, max: number?): number
	if min ~= nil and v < min then
		v = min
	end
	if max ~= nil and v > max then
		v = max
	end
	return v
end

function NumberFormat.snap(v: number, step: number, origin: number?): number
	if step <= 0 or not isFinite(step) then
		return v
	end
	local o = origin or 0
	local r = math.floor((v - o) / step + 0.5) * step + o
	-- drop binary noise (0.1 * 3 = 0.30000000000000004)
	return tonumber(string.format("%.12g", r)) or r
end

function NumberFormat.normalize(v: number, min: number?, max: number?, step: number?): number
	if step ~= nil then
		v = NumberFormat.snap(v, step, min)
	end
	return NumberFormat.clamp(v, min, max)
end

function NumberFormat.commitText(text: string, min: number?, max: number?, step: number?): number?
	local n = NumberFormat.parse(text)
	if n == nil then
		return nil
	end
	return NumberFormat.normalize(n, min, max, step)
end

function NumberFormat.toFraction(v: number, min: number, max: number): number
	if max <= min then
		return 0
	end
	return NumberFormat.clamp((v - min) / (max - min), 0, 1)
end

function NumberFormat.fromFraction(f: number, min: number, max: number): number
	return min + NumberFormat.clamp(f, 0, 1) * (max - min)
end

function NumberFormat.pixelToFraction(x: number, trackX: number, trackW: number, grabW: number): number
	local span = trackW - grabW
	if span <= 0 then
		return 0
	end
	return NumberFormat.clamp((x - trackX - grabW / 2) / span, 0, 1)
end

function NumberFormat.toHex(r: number, g: number, b: number): string
	local function byte(n: number): number
		return math.floor(NumberFormat.clamp(n, 0, 255) + 0.5)
	end
	return string.format("#%02x%02x%02x", byte(r), byte(g), byte(b))
end

function NumberFormat.parseHex(text: string): (number?, number?, number?)
	local s = string.match(text, "^%s*#?(%x+)%s*$")
	if s == nil then
		return nil, nil, nil
	end
	if #s == 3 then
		local r, g, b = string.match(s, "^(%x)(%x)(%x)$")
		if r == nil or g == nil or b == nil then
			return nil, nil, nil
		end
		return tonumber(r .. r, 16), tonumber(g .. g, 16), tonumber(b .. b, 16)
	elseif #s == 6 then
		local r, g, b = string.match(s, "^(%x%x)(%x%x)(%x%x)$")
		if r == nil or g == nil or b == nil then
			return nil, nil, nil
		end
		return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
	end
	return nil, nil, nil
end

return NumberFormat
