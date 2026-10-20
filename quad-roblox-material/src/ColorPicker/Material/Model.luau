--!strict
--[[
	The Material picker's state, in one place. ONE `Source<HSV>` is the truth (see ColorModel.luau for why HSV and
	not Color3: black has no hue, grey has no hue). Everything the panel shows — the Color3, the pure-hue color,
	the SV thumb ring grey, the hex string, the three channel boxes' labels and texts — is a `:Compute` of it
	(plus the `mode` Source for the boxes). There is no second copy of the color anywhere.

	Writers (every user gesture ends in `commit`, the only place that `:Set`s the canonical Source):
	  setHue(h)                 hue slider                        (H only)
	  setSV(s, v)               SV area                           (one atomic write)
	  nudgeSV(ds, dv) / nudgeHue(dh)    keyboard / gamepad steps
	  setHex(text)              hex field (blur / Enter)          -> true when the text parsed
	  typeField(i, text)        channel box i (1..3) of the current mode, live while typing -> true when committed
	  nudgeField(i, delta)      mouse wheel on a channel box
	  setColor(c)               "use this color": swatches, external writes (hue-preserving)
	  remember()                push the current color to the recent list (called at gesture END, not per move)
	`:Set` does not dedup in quad, so `commit` guards with `ColorModel.equalsHSV`: an equal draft never fires a wave
	or OnChange.

	External two-way binding (the `Value: Source<Color3>` prop; the `HSV: Source<HSV>` prop needs none of this)
	  The canonical Source stays HSV. When a caller hands in a `Source<Color3>`, ONE `Effect` (`model.Sync`, the
	  caller places it in the array part of a host) keeps the two in step:
	    * deps: the canonical `hsv` Source, the derived `color` State (a diamond: `color` is a Compute of `hsv`, both
	      wake the node in the same wave and it runs once) and the caller's Source. The node READS `color`/`value` and
	      WRITES `hsv` and `value`, so both writes hit one of its own direct dependencies — the one defined self-write case
	      of an `Effect`;
	    * if the Source already equals what the HSV renders (within 1e-9) -> nothing to do (this is also what ends
	      the echo of our own write, and what keeps a float-exact Color3 round trip from re-firing the caller);
	    * else if the caller's value changed since the last time we looked -> an OUTSIDE write: pull it into the HSV
	      through `ColorModel.fromColor3(c, previousHSV)` (`fromRGBPreservingHue`): grey keeps the hue, black keeps
	      hue and saturation, so the picker never jumps to red because the caller wrote `Color3.new(0, 0, 0)`;
	    * else -> the PICKER changed: push `Value:SetIfChanged(color)`.
	  Why an Effect and not an Observer: an Observer is a final consumer and must not feed its own upstream; this
	  node writes its own direct dependencies (`hsv`, `value`), which is exactly the one defined self-write case of an
	  `Effect` (it re-runs once after `fn` returns, finds both sides equal and stops). Outside writes never reach `OnChange`.
]]

local q = require("../../Quad")
local ColorModel = require("../ColorModel")
local Util = require("../../Util")

export type HSV = ColorModel.HSV
export type Mode = "RGB" | "HSV"

export type Options = {
	HSV: q.Source<HSV>?,
	Value: q.Source<Color3>?,
	Initial: (Color3 | q.State<Color3>)?,
	Recent: q.Source<{ Color3 }>?,
	MaxRecent: number?,
	Mode: Mode?,
	OnChange: ((color: Color3) -> ())?,
}

export type Model = {
	read hsv: q.Source<HSV>,
	read color: q.State<Color3>,
	read initial: q.State<Color3>,
	read hue: q.State<number>,
	read hueColor: q.State<Color3>,
	read ringGray: q.State<Color3>,
	read hex: q.State<string>,
	read recent: q.Source<{ Color3 }>,
	read mode: q.Source<Mode>,
	read Sync: q.Effect?,
	fieldLabel: (i: number) -> q.State<string>,
	fieldText: (i: number) -> q.State<string>,
	setHue: (h: number) -> (),
	setSV: (s: number, v: number) -> (),
	nudgeSV: (ds: number, dv: number) -> (),
	nudgeHue: (dh: number) -> (),
	setHex: (text: string) -> boolean,
	typeField: (i: number, text: string) -> boolean,
	nudgeField: (i: number, delta: number) -> (),
	setColor: (c: Color3) -> (),
	remember: () -> (),
}

local DEG = ColorModel.Scale.Degrees
local RGB_LABELS = { "R", "G", "B" }
local HSV_LABELS = { "H", "S", "V" }

local function sameColor(a: Color3, b: Color3): boolean
	return math.abs(a.R - b.R) < 1e-9 and math.abs(a.G - b.G) < 1e-9 and math.abs(a.B - b.B) < 1e-9
end

-- the same color as the user sees it (8 bit per channel)
local function sameBytes(a: Color3, b: Color3): boolean
	return ColorModel.toByte(a.R) == ColorModel.toByte(b.R)
		and ColorModel.toByte(a.G) == ColorModel.toByte(b.G)
		and ColorModel.toByte(a.B) == ColorModel.toByte(b.B)
end

-- Newest first, no duplicates (same 8-bit color), at most `max` entries. Shared with the modal's OK button.
local function pushRecent(recent: q.Source<{ Color3 }>, c: Color3, max: number)
	local list = recent:Get()
	if list[1] ~= nil and sameBytes(list[1], c) then
		return
	end
	local nextList: { Color3 } = { c }
	for _, old in list do
		if #nextList >= max then
			break
		end
		if not sameBytes(old, c) then
			table.insert(nextList, old)
		end
	end
	recent:Set(nextList)
end

local function new(o: Options): Model
	if o.HSV ~= nil and o.Value ~= nil then
		Util.fail("ColorPicker", "pass either HSV or Value, not both")
	end
	local valueIn = o.Value
	local hsv: q.Source<HSV> = o.HSV
		or q.Source(if valueIn ~= nil then ColorModel.fromColor3(valueIn:Get(), nil) else { H = 0, S = 0, V = 1 })
	local mode = q.Source((o.Mode or "RGB") :: Mode)
	local recent: q.Source<{ Color3 }> = o.Recent or q.Source({} :: { Color3 })
	local maxRecent = o.MaxRecent or 6

	local color: q.State<Color3> = hsv:Compute(function(self)
		return ColorModel.toColor3(self:Get())
	end)
	local initial: q.State<Color3>
	local initialInput = o.Initial
	if initialInput == nil then
		initial = q.Source(ColorModel.toColor3(hsv:Get()))
	elseif typeof(initialInput) == "Color3" then
		initial = q.Source(initialInput :: Color3)
	else
		initial = initialInput :: q.State<Color3>
	end
	-- H alone is a number State: it dedups by value, so S/V drags do not recompute anything built on it
	local hue: q.State<number> = hsv:Compute(function(self)
		return self:Get().H
	end)
	local hueColor: q.State<Color3> = hue:Compute(function(self)
		return Color3.new(ColorModel.hueToRgb(self:Get()))
	end)
	local ringGray: q.State<Color3> = hsv:Compute(function(self)
		local c = self:Get()
		local g = ColorModel.cursorRingGray(c.S, c.V)
		return Color3.new(g, g, g)
	end)
	local hex: q.State<string> = color:Compute(function(self)
		local c = self:Get()
		return ColorModel.rgbToHex(c.R, c.G, c.B, true)
	end)

	local function commit(nextHSV: HSV)
		if ColorModel.equalsHSV(hsv:Get(), nextHSV) then
			return
		end
		hsv:Set(nextHSV)
		if o.OnChange then
			o.OnChange(ColorModel.toColor3(nextHSV))
		end
	end

	local function setHue(h: number)
		commit(ColorModel.withHSVChannel(hsv:Get(), "H", h))
	end
	local function setSV(s: number, v: number)
		commit(ColorModel.newHSV(hsv:Get().H, s, v))
	end
	local function nudgeSV(ds: number, dv: number)
		local c = hsv:Get()
		commit(ColorModel.newHSV(c.H, c.S + ds, c.V + dv))
	end
	local function nudgeHue(dh: number)
		local c = hsv:Get()
		-- the hue wraps like the color wheel does, but the slider is a line: clamp at both ends
		commit(ColorModel.withHSVChannel(c, "H", c.H + dh))
	end

	local function setHex(text: string): boolean
		local nextHSV = ColorModel.fromHexPreservingHue(text, hsv:Get())
		if nextHSV == nil then
			return false
		end
		commit(nextHSV)
		return true
	end

	-- box i of the current mode: RGB = bytes 0..255, HSV = degrees / percent
	local function channelOf(i: number): (string, number)
		if mode:Get() == "RGB" then
			return RGB_LABELS[i], 255
		end
		return HSV_LABELS[i], if i == 1 then DEG.H elseif i == 2 then DEG.S else DEG.V
	end

	local function apply(cur: HSV, ch: string, n: number, max: number): HSV
		if ch == "H" or ch == "S" or ch == "V" then
			return ColorModel.withHSVChannel(cur, ch :: "H" | "S" | "V", n / max)
		end
		return ColorModel.withRGBByte(cur, ch :: "R" | "G" | "B", n)
	end

	local function typeField(i: number, text: string): boolean
		local ch, max = channelOf(i)
		local n = ColorModel.parseChannel(text, max)
		if n == nil then
			return false
		end
		commit(apply(hsv:Get(), ch, n, max))
		return true
	end

	local function currentNumber(cur: HSV, ch: string, max: number): number
		if ch == "H" then
			return math.floor(cur.H * max + 0.5)
		elseif ch == "S" then
			return math.floor(cur.S * max + 0.5)
		elseif ch == "V" then
			return math.floor(cur.V * max + 0.5)
		end
		local r, g, b = ColorModel.toBytes(cur)
		return if ch == "R" then r elseif ch == "G" then g else b
	end

	local function nudgeField(i: number, delta: number)
		local ch, max = channelOf(i)
		local cur = hsv:Get()
		commit(apply(cur, ch, ColorModel.clamp(currentNumber(cur, ch, max) + delta, 0, max), max))
	end

	local labels: { q.State<string> } = {}
	local texts: { q.State<string> } = {}
	for i = 1, 3 do
		labels[i] = mode:Compute(function(self)
			return if self:Get() == "RGB" then RGB_LABELS[i] else HSV_LABELS[i]
		end)
		texts[i] = mode:Compute(function(self, _prev, h)
			local cur = h:Get()
			if self:Get() == "RGB" then
				local r, g, b = ColorModel.toBytes(cur)
				return tostring(if i == 1 then r elseif i == 2 then g else b)
			end
			local c = if i == 1 then cur.H elseif i == 2 then cur.S else cur.V
			return ColorModel.channelText(c, if i == 1 then DEG.H elseif i == 2 then DEG.S else DEG.V)
		end, hsv)
	end

	local function setColor(c: Color3)
		commit(ColorModel.fromColor3(c, hsv:Get()))
	end

	local function remember()
		pushRecent(recent, color:Get(), maxRecent)
	end

	local sync: q.Effect? = nil
	if valueIn ~= nil then
		local value: q.Source<Color3> = valueIn
		local lastSeen = value:Get()
		sync = q.Effect(function()
			local outside = value:Get()
			local mine = color:Get()
			if sameColor(outside, mine) then
				lastSeen = outside
				return
			end
			if outside ~= lastSeen then
				lastSeen = outside
				local cur = hsv:Get()
				local pulled = ColorModel.fromColor3(outside, cur)
				if not ColorModel.equalsHSV(cur, pulled) then
					hsv:Set(pulled) -- an outside write: no OnChange
				end
			else
				value:SetIfChanged(mine)
				lastSeen = mine
			end
		end, hsv, color, value)
	end

	return {
		hsv = hsv,
		color = color,
		initial = initial,
		hue = hue,
		hueColor = hueColor,
		ringGray = ringGray,
		hex = hex,
		recent = recent,
		mode = mode,
		Sync = sync,
		fieldLabel = function(i: number)
			return labels[i]
		end,
		fieldText = function(i: number)
			return texts[i]
		end,
		setHue = setHue,
		setSV = setSV,
		nudgeSV = nudgeSV,
		nudgeHue = nudgeHue,
		setHex = setHex,
		typeField = typeField,
		nudgeField = nudgeField,
		setColor = setColor,
		remember = remember,
	}
end

return {
	new = new,
	sameColor = sameColor,
	sameBytes = sameBytes,
	pushRecent = pushRecent,
}
