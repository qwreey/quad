--!strict
--[[
	M3 slider track parts (the 2023+ form; androidx Compose material3 `SliderTokens` / `Slider.kt`): the track is split
	into pieces around the handle(s), each piece rounded FULL (8 px) at the track's outer end and 2 px at the end that
	faces a handle, with a 6 px space on each side of the 4 px handle (so a piece ends GAP = 2 + 6 = 8 px from the handle
	center). A 4 px stop indicator dot sits 8 px inside each outer end of an inactive piece; discrete sliders add one 4 px
	dot per step.

	GEOMETRY (host-relative px; W = host width, f = the value's fraction): the handle center travels from INSET = 8 to
	W - 8 (x = 8 + (W - 16) f — `Track.x(f)` as a UDim), so a piece reaching the host edge is exactly one outer radius
	long when the handle sits at that end. Pieces are written as Scale + Offset of the host, so a resize needs no work;
	only VISIBILITY needs pixels (`Width`, the host's AbsoluteSize.X): Compose hides an outer piece no longer than its
	outer radius and the middle piece of a range no longer than its inner radius — so does this file.

	ASYMMETRIC ROUNDING (`Track.outerPiece`): `UICorner` has ONE radius for all four corners, so a piece rounded 8 at one
	end and 2 at the other is composed from two non-overlapping rectangle clips:
	  Cap   a `ClipsDescendants` Frame of the outer radius' width (8 px) at the track end, holding a 16 px fill with
	        UICorner 8 — the clip keeps the fill's outer half: a half-pill, square on the inside.
	  Body  a `ClipsDescendants` Frame from there to the handle side, holding a fill 2 px wider than the clip with
	        UICorner 2 — the clip cuts the overhanging (rounded) end: square where it meets the cap, rounded 2 at the
	        handle side.
	The two clips touch at x = 8 and never overlap, so a translucent piece (disabled: onSurface @ 38 % / 12 %) has no
	darker seam. Cost: 6 instances per outer piece (2 clip Frames, 2 fill Frames, 2 UICorners), no per-frame work —
	a plain rectangle clip is not a CanvasGroup (no offscreen texture). Rejected: (a) two OVERLAPPING frames, a full
	piece with radius 8 and a radius-2 frame over its inner part (4 instances) — exact while opaque, but the overlap
	doubles the alpha of a translucent (disabled) piece; (b) opaque colors precomposited over `Surface` to dodge (a) —
	wrong on any other background (a card); (c) a 9-slice image — one more uploaded asset, and the radius would scale
	with nothing. The middle piece of a range is rounded 2 at both ends, so it is one Frame + UICorner (2).

	    Track.outerPiece({ Name, Outer = "Left" | "Right", Edge = State<UDim>, Visible, Color, Transparency }) -> { Frame }
	      Edge: the piece's INNER end (Left: where it stops; Right: where it starts) as a host UDim.
	    Track.middlePiece({ Name, From = State<UDim>, To = State<UDim>, Visible, Color, Transparency }) -> Frame
	    Track.stop({ Name, Outer = "Left" | "Right", Visible, Color, Transparency }) -> Frame      (4 px dot + UICorner)
	    Track.ticks({ Step, Range, Fracs = { State<number> }, ActiveFrom, ActiveTo, Width, SkipFirst, SkipLast,
	                  ShowTicks, Disabled, Theme }) -> { Instance }
	      one 4 px dot (+ UICorner) per step, hidden inside a handle gap (any of `Fracs`) and at the stop indicators;
	      color `SecondaryContainer` on the active track, `Primary` on the inactive (Compose `SliderDefaults.colors`:
	      activeTickColor = InactiveTrackColor, inactiveTickColor = ActiveTrackColor). Empty for a continuous slider,
	      `ShowTicks = false` or more than 100 steps.
	    Track.x(f) -> UDim          the handle center
	Constants: HEIGHT 16 (track), OUTER 8, INNER 2, INSET 8, GAP 8, HANDLE_W 4 / HANDLE_W_ACTIVE 2, HANDLE_H 44, DOT 4.
]]

local q = require("../Quad")
local Theme = require("../Theme")
local Tokens = require("../Tokens")
local Style = require("../Button/Style")
local D = q.Declaration

local HEIGHT = 16 -- SliderTokens.Active/InactiveTrackHeight
local OUTER = 8 -- outer corner: CornerFull of the 16 px track
local INNER = 2 -- Slider.kt TrackInsideCornerSize
local INSET = OUTER -- handle center at Min / Max (Slider.kt places the thumb at trackCornerSize + (w - 2 corner) f)
local HANDLE_W = 4 -- SliderTokens.HandleWidth
local HANDLE_W_ACTIVE = 2 -- SliderTokens.PressedHandleWidth / FocusHandleWidth
local HANDLE_H = 44 -- SliderTokens.HandleHeight
local SPACE = 6 -- SliderTokens.ActiveHandleLeadingSpace / TrailingSpace
local GAP = HANDLE_W / 2 + SPACE -- handle center -> piece end
local DOT = 4 -- SliderTokens.StopIndicatorSize
local MAX_TICKS = 100

local CORNER_FULL = Tokens.Shape.corner("Full")

local function x(f: number): UDim
	return UDim.new(f, INSET - 2 * INSET * f)
end

export type Animated = Theme.Animated

export type OuterOptions = {
	Name: string,
	Outer: "Left" | "Right",
	Edge: q.State<UDim>,
	Visible: q.State<boolean>,
	Color: Animated,
	Transparency: Animated,
}

local function clip(name: string, position: UDim2 | q.State<UDim2>, size: UDim2 | q.State<UDim2>, visible: q.State<boolean>, fill: Frame): Frame
	return D.Frame {
		Name = name,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = position,
		Size = size,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Visible = visible,
		fill,
	}
end

local function fill(position: UDim2, size: UDim2, radius: number, color: Animated, transparency: Animated): Frame
	return D.Frame {
		Name = "Fill",
		Position = position,
		Size = size,
		BackgroundColor3 = color,
		BackgroundTransparency = transparency,
		BorderSizePixel = 0,
		UICorner = UDim.new(0, radius),
	}
end

local function outerPiece(o: OuterOptions): { Instance }
	local left = o.Outer == "Left"
	local cap = clip(
		o.Name .. "Cap",
		if left then UDim2.fromScale(0, 0.5) else UDim2.new(1, -OUTER, 0.5, 0),
		UDim2.fromOffset(OUTER, HEIGHT),
		o.Visible,
		fill(UDim2.fromOffset(if left then 0 else -OUTER, 0), UDim2.fromOffset(2 * OUTER, HEIGHT), OUTER, o.Color, o.Transparency)
	)
	local bodyPosition: UDim2 | q.State<UDim2>
	local bodySize: q.State<UDim2>
	if left then
		bodyPosition = UDim2.new(0, OUTER, 0.5, 0)
		bodySize = o.Edge:Compute(function(self)
			local e = self:Get()
			return UDim2.new(e.Scale, e.Offset - OUTER, 0, HEIGHT)
		end)
	else
		bodyPosition = o.Edge:Compute(function(self)
			local e = self:Get()
			return UDim2.new(e.Scale, e.Offset, 0.5, 0)
		end)
		bodySize = o.Edge:Compute(function(self)
			local e = self:Get()
			return UDim2.new(1 - e.Scale, -OUTER - e.Offset, 0, HEIGHT)
		end)
	end
	local body = clip(
		o.Name .. "Body",
		bodyPosition,
		bodySize,
		o.Visible,
		-- 2 px wider than the clip on the cap side: that rounded end is cut off, the handle-side end stays rounded
		fill(UDim2.fromOffset(if left then -INNER else 0, 0), UDim2.new(1, INNER, 1, 0), INNER, o.Color, o.Transparency)
	)
	return { cap, body }
end

export type MiddleOptions = {
	Name: string,
	From: q.State<UDim>,
	To: q.State<UDim>,
	Visible: q.State<boolean>,
	Color: Animated,
	Transparency: Animated,
}

local function middlePiece(o: MiddleOptions): Frame
	local position: q.State<UDim2> = o.From:Compute(function(self)
		local a = self:Get()
		return UDim2.new(a.Scale, a.Offset, 0.5, 0)
	end)
	local size: q.State<UDim2> = o.From:Compute(function(self, _prev, to)
		local a, b = self:Get(), to:Get()
		return UDim2.new(b.Scale - a.Scale, b.Offset - a.Offset, 0, HEIGHT)
	end, o.To)
	return D.Frame {
		Name = o.Name,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = position,
		Size = size,
		Visible = o.Visible,
		BackgroundColor3 = o.Color,
		BackgroundTransparency = o.Transparency,
		BorderSizePixel = 0,
		UICorner = UDim.new(0, INNER),
	}
end

export type StopOptions = {
	Name: string,
	Outer: "Left" | "Right",
	Visible: q.State<boolean>,
	Color: Animated,
	Transparency: Animated,
}

local function stop(o: StopOptions): Frame
	return D.Frame {
		Name = o.Name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = if o.Outer == "Left" then UDim2.new(0, OUTER, 0.5, 0) else UDim2.new(1, -OUTER, 0.5, 0),
		Size = UDim2.fromOffset(DOT, DOT),
		Visible = o.Visible,
		BackgroundColor3 = o.Color,
		BackgroundTransparency = o.Transparency,
		BorderSizePixel = 0,
		UICorner = CORNER_FULL,
	}
end

export type TickOptions = {
	Step: number?,
	Range: number,
	Fracs: { q.State<number> }, -- handle fractions (their gaps hide ticks)
	ActiveFrom: q.State<number>?, -- nil = 0 (single slider)
	ActiveTo: q.State<number>,
	Width: q.State<number>,
	SkipFirst: boolean,
	SkipLast: boolean,
	ShowTicks: boolean?,
	Disabled: q.State<boolean>,
	Theme: Theme.Theme,
}

local function ticks(o: TickOptions): { Instance }
	local out: { Instance } = {}
	local step = o.Step
	if step == nil or o.ShowTicks == false then
		return out
	end
	local range = o.Range
	local count = math.floor(range / step + 1e-9)
	if count < 1 or count > MAX_TICKS then
		return out
	end
	local R = o.Theme.Raw
	local disabled = o.Disabled
	-- raw (not animated) like the M2 ticks: a dot switches color the moment a handle passes it
	local function pick(normal: q.State<Color3>, off: q.State<Color3>): q.State<Color3>
		return disabled:Compute(function(self, _prev, n, f)
			return if self:Get() then f:Get() else n:Get()
		end, normal, off)
	end
	local function pickNumber(off: number): q.State<number>
		return disabled:Compute(function(self)
			return if self:Get() then off else 0
		end)
	end
	-- disabled (Compose): active dots onSurface @ 12 % on the 38 % track, inactive dots onSurface @ 38 % on the 12 % track
	local onActive = pick(R.SecondaryContainer, R.OnSurface)
	local onInactive = pick(R.Primary, R.OnSurface)
	local onActiveT = pickNumber(Style.DisabledContainerTransparency)
	local onInactiveT = pickNumber(Style.DisabledContentTransparency)
	local from: q.State<number> = o.ActiveFrom or q.Source(0)
	local fracs = o.Fracs
	local f1 = fracs[1]
	local f2: q.State<number> = fracs[2] or f1
	for i = 0, count do
		if (i == 0 and o.SkipFirst) or (i == count and o.SkipLast) then
			continue
		end
		local t = i * step / range
		-- hidden while inside a handle gap: |t - f| * (W - 2 INSET) <= GAP (and before layout, W = 0)
		local visible: q.State<boolean> = o.Width:Compute(function(self, _prev, a, b)
			local span = self:Get() - 2 * INSET
			if span <= 0 then
				return false
			end
			return math.abs(t - a:Get()) * span > GAP and math.abs(t - b:Get()) * span > GAP
		end, f1, f2)
		local active: q.State<boolean> = from:Compute(function(self, _prev, to)
			return t >= self:Get() and t <= to:Get()
		end, o.ActiveTo)
		local color: q.State<Color3> = active:Compute(function(self, _prev, a, b)
			return if self:Get() then a:Get() else b:Get()
		end, onActive, onInactive)
		local transparency: q.State<number> = active:Compute(function(self, _prev, a, b)
			return if self:Get() then a:Get() else b:Get()
		end, onActiveT, onInactiveT)
		table.insert(
			out,
			D.Frame {
				Name = "Tick",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(t, INSET - 2 * INSET * t, 0.5, 0),
				Size = UDim2.fromOffset(DOT, DOT),
				Visible = visible,
				BackgroundColor3 = color,
				BackgroundTransparency = transparency,
				BorderSizePixel = 0,
				UICorner = CORNER_FULL,
			}
		)
	end
	return out
end

return {
	outerPiece = outerPiece,
	middlePiece = middlePiece,
	stop = stop,
	ticks = ticks,
	x = x,
	HEIGHT = HEIGHT,
	OUTER = OUTER,
	INNER = INNER,
	INSET = INSET,
	GAP = GAP,
	HANDLE_W = HANDLE_W,
	HANDLE_W_ACTIVE = HANDLE_W_ACTIVE,
	HANDLE_H = HANDLE_H,
	DOT = DOT,
}
