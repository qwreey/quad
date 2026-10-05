--!strict
--[[
	The Classic picker's state, in one place. ONE `Source<HSV>` (the draft; see ColorModel.luau for why) and
	ONE `Source<Color3>` (the last confirmed color). Everything the window shows is a `:Compute` of those two:
	the Color3, the pure-hue color, the SV cursor ring grey, the H/S/V/R/G/B/HEX box texts, the preview halves.
	There is no second copy of the color anywhere, so there is nothing to synchronize by hand.

	Writers (all of them end in `commit`, the only place that `:Set`s the draft):
	  setHue(h)                    hue slider
	  setSV(s, v)                  SV field (one atomic write)
	  typeChannel(ch, text, final) a text box (live while typing, `final` = FocusLost)
	  nudge(ch, delta)             mouse wheel on a box
	  confirm() / cancel()         the buttons (cancel restores the last color and does NOT fire OnUpdate)
	`:Set` does not dedup in quad, so `commit` guards with `ColorModel.equalsHSV` (an equal draft never fires
	a wave or OnUpdate).

	Display scale is `ColorModel.Scale.Legacy` (0..255 for H, S, V, R, G, B) as in the original; hex has no `#`.
]]

local q = require("../../Quad")
local ColorModel = require("../ColorModel")

export type HSV = ColorModel.HSV
export type Channel = "H" | "S" | "V" | "R" | "G" | "B" | "HEX"

export type Options = {
	Value: q.Source<HSV>?,
	Initial: HSV?,
	LastColor: (Color3 | q.Source<Color3>)?,
	OnUpdate: ((color: Color3, h: number, s: number, v: number) -> ())?,
	OnConfirm: ((color: Color3, h: number, s: number, v: number) -> ())?,
	OnCancel: ((last: Color3, draft: Color3) -> ())?,
}

export type Model = {
	read hsv: q.Source<HSV>,
	read last: q.Source<Color3>,
	read color: q.State<Color3>,
	read hue: q.State<number>,
	read hueColor: q.State<Color3>,
	read ringGray: q.State<Color3>,
	read text: { [Channel]: q.State<string> },
	setHue: (h: number) -> (),
	setSV: (s: number, v: number) -> (),
	typeChannel: (ch: Channel, text: string, final: boolean) -> (),
	nudge: (ch: Channel, delta: number) -> (),
	confirm: () -> (),
	cancel: () -> (),
}

local MAX = ColorModel.Scale.Legacy.H -- 255 for every channel

local function new(o: Options): Model
	local hsv: q.Source<HSV> = o.Value or q.Source(o.Initial or { H = 0, S = 0, V = 1 })
	local lastInput = o.LastColor
	local last: q.Source<Color3>
	if lastInput == nil then
		last = q.Source(ColorModel.toColor3(hsv:Get()))
	elseif typeof(lastInput) == "Color3" then
		last = q.Source(lastInput :: Color3)
	else
		last = lastInput :: q.Source<Color3>
	end

	local color: q.State<Color3> = hsv:Compute(function(self)
		return ColorModel.toColor3(self:Get())
	end)
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
	-- the three byte channels packed in one number: ONE conversion per change, and a number dedups
	local packed: q.State<number> = hsv:Compute(function(self)
		local r, g, b = ColorModel.toBytes(self:Get())
		return r * 65536 + g * 256 + b
	end)

	local function channelText(pick: (HSV) -> number): q.State<string>
		return hsv:Compute(function(self)
			return ColorModel.channelText(pick(self:Get()), MAX)
		end)
	end
	local function byteText(shift: number): q.State<string>
		return packed:Compute(function(self)
			return tostring(math.floor(self:Get() / shift) % 256)
		end)
	end
	local text: { [Channel]: q.State<string> } = {
		H = channelText(function(c)
			return c.H
		end),
		S = channelText(function(c)
			return c.S
		end),
		V = channelText(function(c)
			return c.V
		end),
		R = byteText(65536),
		G = byteText(256),
		B = byteText(1),
		HEX = packed:Compute(function(self)
			local n = self:Get()
			return string.format("%06X", n)
		end),
	}

	local function commit(nextHSV: HSV)
		local cur = hsv:Get()
		if ColorModel.equalsHSV(cur, nextHSV) then
			return
		end
		hsv:Set(nextHSV)
		if o.OnUpdate then
			o.OnUpdate(ColorModel.toColor3(nextHSV), nextHSV.H, nextHSV.S, nextHSV.V)
		end
	end

	local function setHue(h: number)
		commit(ColorModel.withHSVChannel(hsv:Get(), "H", h))
	end

	local function setSV(s: number, v: number)
		local cur = hsv:Get()
		commit(ColorModel.newHSV(cur.H, s, v))
	end

	local function apply(cur: HSV, ch: Channel, n: number): HSV
		if ch == "H" or ch == "S" or ch == "V" then
			return ColorModel.withHSVChannel(cur, ch :: "H" | "S" | "V", n / MAX)
		end
		return ColorModel.withRGBByte(cur, ch :: "R" | "G" | "B", n)
	end

	local function typeChannel(ch: Channel, raw: string, final: boolean)
		local cur = hsv:Get()
		if ch == "HEX" then
			-- live commit only on a full 6 digits (3 digits would read as the #RGB shorthand mid-typing)
			local digits = string.match(raw, "^%s*#?(.-)%s*$") :: string
			if not final and #digits ~= 6 then
				return
			end
			local nextHSV = ColorModel.fromHexPreservingHue(raw, cur)
			if nextHSV then
				commit(nextHSV)
			end
			return
		end
		local n = ColorModel.parseChannel(raw, MAX)
		if n ~= nil then
			commit(apply(cur, ch, n))
		end
	end

	local function nudge(ch: Channel, delta: number)
		if ch == "HEX" then
			return
		end
		local cur = hsv:Get()
		local base: number
		if ch == "H" then
			base = math.floor(cur.H * MAX + 0.5)
		elseif ch == "S" then
			base = math.floor(cur.S * MAX + 0.5)
		elseif ch == "V" then
			base = math.floor(cur.V * MAX + 0.5)
		else
			local r, g, b = ColorModel.toBytes(cur)
			base = if ch == "R" then r elseif ch == "G" then g else b
		end
		commit(apply(cur, ch, ColorModel.clamp(base + delta, 0, MAX)))
	end

	local function confirm()
		local c = ColorModel.toColor3(hsv:Get())
		last:SetIfChanged(c)
		if o.OnConfirm then
			local cur = hsv:Get()
			o.OnConfirm(c, cur.H, cur.S, cur.V)
		end
	end

	local function cancel()
		local cur = hsv:Get()
		local draft = ColorModel.toColor3(cur)
		local lastColor = last:Get()
		local restored = ColorModel.fromColor3(lastColor, cur)
		if not ColorModel.equalsHSV(cur, restored) then
			hsv:Set(restored)
		end
		if o.OnCancel then
			o.OnCancel(lastColor, draft)
		end
	end

	return {
		hsv = hsv,
		last = last,
		color = color,
		hue = hue,
		hueColor = hueColor,
		ringGray = ringGray,
		text = text,
		setHue = setHue,
		setSV = setSV,
		typeChannel = typeChannel,
		nudge = nudge,
		confirm = confirm,
		cancel = cancel,
	}
end

return {
	new = new,
}
