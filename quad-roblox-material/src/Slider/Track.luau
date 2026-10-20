--!strict
--[[
	M3 slider track parts (the 2023+ form; androidx Compose material3 `SliderTokens` / `Slider.kt`): the track is split
	into pieces around the handle(s), each piece rounded FULL at the track's outer end and 2 px at the end that faces a
	handle, with a 6 px space on each side of the 4 px handle (so a piece ends GAP = 2 + 6 = 8 px from the handle
	center). A 4 px stop indicator dot sits 6 px (its center) inside each outer end of an inactive piece; discrete sliders
	add one 4 px dot per step.

	ONE GEOMETRY PER SLIDER: `Track.new({ Size, Vertical, Flip })` returns the constants and builders of that slider.
	  Size      "XS" | "S" | "M" | "L" | "XL"   the M3 Expressive sizes (default XS — the classic 16 px slider):
	            material-components-android@60ff094 lib/java/com/google/android/material/slider/res/values/tokens.xml
	            55~94 (md.comp.slider.xsmall .. xlarge) through styles.xml 21~52 `Widget.Material3Expressive.Slider.*`:
	              size  track  outer corner  handle height  inset icon
	              XS    16     8             44             -
	              S     24     8             44             -
	              M     40     12            44             24
	              L     56     16            68             24
	              XL    96     28            108            32
	            and, for every size (styles.xml 56~73 `Widget.Material3.Slider` / SliderTokens): handle width 4 (2 while
	            pressed / focused), handle-track space 6, inside corner 2, stop indicator / tick 4.
	  Vertical  boolean?  the axis (MDC `android:orientation`, Compose `VerticalSlider`): the track is a column THICK px
	            wide, the handle is HANDLE_H wide and 4 tall
	  Flip      boolean?  Min at the axis' FAR end — the vertical slider with Min at the bottom (MDC's vertical; Compose
	            `topToBottom = false`). Horizontal sliders are never flipped (no right-to-left layout in this kit).

	COORDINATES: every builder takes positions along the axis as a `UDim` of the host's length measured FROM THE MIN END
	(Scale = fraction of the length, Offset = px). `g.x(f)` is the handle center at value fraction f:
	UDim.new(f, INSET - 2 INSET f) — the handle travels from INSET to L - INSET, and INSET = 6 px for EVERY size: the
	stop dot's center sits 6 px from the track end (its edge 4 px from it) and the handle center at value 0 / 1 sits on
	that dot. Source (user decision 2026-10-08, "m3.material.io Measurements first"): the m3.material.io slider specs
	(Measurements: https://lh3.googleusercontent.com/WLMws1Xen6XFUKvbCJS2NM4jwTMVmQxFlh8QhTslZGI-TR2eoFPXUp-ck8i0FhO_U2cy0cW5qnNP6Qkrsu1kJ-eztl1sJ_o5lHzXSUtr4FAMPw=s0
	and Configurations: https://lh3.googleusercontent.com/FH3TsHZ1NpVLh--XKKb2ygB9rd0bgZ6ig1vGxWhQu5HOFVbk_8CXIxMAVdJnPxKj3fojh8jFh6qDqm41tD0R3YRaK0luWcktoURO5RZfBsuO=s0)
	show the dot at the same ~6 dp from the end for XS .. XL, a static padding independent of the track thickness and the
	outer radius. THIS DEVIATES from the code: Compose `Slider.kt` 1059-1075 / 2511-2517 (thumb and dot at `cornerSize`)
	and MDC `BaseSlider` `trackSidePadding` with the track `trackCornerSize` past it both inset by the corner size.
	`g.phys` turns the coordinates into the host's own direction (left / top first); the builders do it themselves.
	Only VISIBILITY and SHRINKING need pixels (the host length).

	SHORT PIECES (`Run`): the piece beyond a handle gets shorter than its outer radius over a long stretch (XL: the
	outer radius is 28, the handle can sit 6 from the end). Compose `drawTrack` with `enableCornerShrinking` (the
	`Track(trackCornerSize)` overload and `CenteredTrack`, no steps) draws a piece for any length > 0 (threshold 0
	instead of `cornerSize` added, Slider.kt 2523-2526 / 2594-2597), so it narrows away instead of popping out. The user
	(Android device, 2026-10-08) sees the outer curve stay FIXED while the piece is masked away — so here only the clip
	windows move: the cap clip is min(OUTER, Run) long over a fill that keeps its 2 x OUTER size (anchored on the track
	end), the body clip is the rest over a fill of at least 2 x INNER (anchored on the handle side), and a middle piece
	is a clip window over a fill of at least 2 x INNER. A fill is never shorter than twice its UICorner radius, because
	UICorner clamps its radius to half the frame's smaller side — a shrinking fill would change the curve. Stepped
	sliders keep Compose's hard threshold (a piece no longer than its outer radius, or inner radius for a middle piece,
	is hidden); a continuous slider and (kit choice, Compose's range slider has no corner shrinking) a continuous range
	slider show any piece longer than 0.

	ASYMMETRIC ROUNDING (`g.outerPiece`): `UICorner` has ONE radius for all four corners, so a piece rounded OUTER at
	one end and 2 at the other is composed from two non-overlapping rectangle clips:
	  Cap   a `ClipsDescendants` Frame of the outer radius' length at the track end, holding a 2 x OUTER fill with
	        UICorner OUTER — the clip keeps the fill's outer half: a half-pill, square on the inside.
	  Body  a `ClipsDescendants` Frame from there to the handle side, holding a fill 2 px longer than the clip with
	        UICorner 2 — the clip cuts the overhanging (rounded) end: square where it meets the cap, rounded 2 at the
	        handle side.
	The two clips touch at OUTER and never overlap, so a translucent piece (disabled: onSurface @ 38 % / 12 %) has no
	darker seam. Cost: 6 instances per outer piece (2 clip Frames, 2 fill Frames, 2 UICorners), no per-frame work —
	a plain rectangle clip is not a CanvasGroup (no offscreen texture). Rejected: (a) two OVERLAPPING frames, a full
	piece with radius OUTER and a radius-2 frame over its inner part (4 instances) — exact while opaque, but the overlap
	doubles the alpha of a translucent (disabled) piece; (b) opaque colors precomposited over `Surface` to dodge (a) —
	wrong on any other background (a card); (c) a 9-slice image — one more uploaded asset, and the radius would scale
	with nothing. A piece rounded 2 at both ends (the middle of a range, the active piece of a centered slider) is a clip
	window over one fill + UICorner (2): 3 instances (see SHORT PIECES).
	Every position and size below the host is Offset or a host fraction (the host is not auto-sized: its size comes
	from the parent along the axis and HANDLE_H across).

	    g.outerPiece({ Name, End = "Min" | "Max", Edge = State<UDim>, Visible, Run, Color, Transparency }) -> { Frame }
	      Edge: the piece's INNER end (the end facing a handle) in min-end coordinates; Run: its length in px.
	    g.middlePiece({ Name, From = State<UDim>, To = State<UDim>, Visible, Run, Color, Transparency }) -> Frame
	    g.stop({ Name, End = "Min" | "Max", Visible, Color, Transparency }) -> Frame       (4 px dot + UICorner)
	    g.ticks({ Step, Range, Fracs = { State<number> }, ActiveFrom, ActiveTo, Length, SkipFirst, SkipLast,
	              CenterGap, ShowTicks, Disabled, Theme }) -> { Instance }
	      one 4 px dot (+ UICorner) per step, hidden inside a handle gap (any of `Fracs`), inside the centered slider's
	      center gap (`CenterGap`, see Slider) and at the stop indicators; color `SecondaryContainer` on the active track,
	      `Primary` on the inactive (Compose `SliderDefaults.colors`: activeTickColor = InactiveTrackColor,
	      inactiveTickColor = ActiveTrackColor). Empty for a continuous slider, `ShowTicks = false` or more than 100 steps.
	    g.onActive(disabled, theme) / g.onInactive(disabled, theme) -> (State<Color3>, State<number>)
	      the tick colors (raw) — also the inset icon colors (see Slider)
	    g.x(f) -> UDim     the handle center (min-end coordinates)
	    g.phys(u) -> UDim  min-end coordinates -> the host's own (left / top first)
	    g.point(u) -> UDim2  a centered thing (anchor 0.5, 0.5) at u on the track's center line
	    g.handleSize(narrow) -> UDim2   HANDLE_W (or HANDLE_W_ACTIVE) along the axis, HANDLE_H across
	    g.hostSize() -> UDim2   the default host size: the parent's length along the axis, HANDLE_H across
	    g.centerPx(length, f) -> number   the handle center in px from the min end
	Track.forLook(name, Size, Orientation, TopToBottom) -> Geometry   the looks' props validated (Vertical -> Flip unless
	    TopToBottom); Track.labelPlacement(g) -> (Position, AnchorPoint) of the value label in the handle
	Constants (read-only): THICK (track), OUTER, INNER 2, INSET 6 (= the stop dot's center, every size), GAP 8, SPACE 6, HANDLE_W 4 /
	HANDLE_W_ACTIVE 2, HANDLE_H, DOT 4, ICON (nil below M), Vertical, Flip.
]]

local q = require("../Quad")
local Theme = require("../Theme")
local Tokens = require("../Tokens")
local Style = require("../Button/Style")
local Util = require("../Util")
local Frame = q.Elem "Frame"

export type SizeName = "XS" | "S" | "M" | "L" | "XL"

type SizeRow = { Track: number, Outer: number, Handle: number, Icon: number? }

-- material-components-android@60ff094 slider/res/values/tokens.xml 55~94 (md.comp.slider.<size>)
local SIZES: { [SizeName]: SizeRow } = table.freeze({
	XS = table.freeze({ Track = 16, Outer = 8, Handle = 44, Icon = nil }),
	S = table.freeze({ Track = 24, Outer = 8, Handle = 44, Icon = nil }),
	M = table.freeze({ Track = 40, Outer = 12, Handle = 44, Icon = 24 }),
	L = table.freeze({ Track = 56, Outer = 16, Handle = 68, Icon = 24 }),
	XL = table.freeze({ Track = 96, Outer = 28, Handle = 108, Icon = 32 }),
}) :: any

local INNER = 2 -- Slider.kt TrackInsideCornerSize / MDC trackInsideCornerSize
local HANDLE_W = 4 -- SliderTokens.HandleWidth
local HANDLE_W_ACTIVE = 2 -- SliderTokens.PressedHandleWidth / FocusHandleWidth
local SPACE = 6 -- SliderTokens.ActiveHandleLeadingSpace / TrailingSpace
local GAP = HANDLE_W / 2 + SPACE -- handle center -> piece end
local DOT = 4 -- SliderTokens.StopIndicatorSize
local MAX_TICKS = 100
local STOP_INSET = 6 -- stop dot center (and handle center at Min / Max) from the track end, whatever the size: m3.material.io specs

local CORNER_FULL = Tokens.Shape.corner("Full")

export type Animated = Theme.Animated
export type End = "Min" | "Max"

export type GeometryOptions = {
	Size: SizeName?,
	Vertical: boolean?,
	Flip: boolean?,
}

export type OuterOptions = {
	Name: string,
	End: End,
	Edge: q.State<UDim>,
	Visible: q.State<boolean>,
	-- the piece's current length in px (0 before layout); a piece shorter than OUTER narrows by its clip windows only
	Run: q.State<number>,
	Color: Animated,
	Transparency: Animated,
}

export type MiddleOptions = {
	Name: string,
	From: q.State<UDim>,
	To: q.State<UDim>,
	Visible: q.State<boolean>,
	Run: q.State<number>, -- the piece's current length in px (0 before layout)
	Color: Animated,
	Transparency: Animated,
}

export type StopOptions = {
	Name: string,
	End: End,
	Visible: q.State<boolean>,
	Color: Animated,
	Transparency: Animated,
}

export type TickOptions = {
	Step: number?,
	Range: number,
	Fracs: { q.State<number> }, -- handle fractions (their gaps hide ticks)
	ActiveFrom: q.State<number>?, -- nil = 0 (single slider)
	ActiveTo: q.State<number>,
	Length: q.State<number>,
	SkipFirst: boolean,
	SkipLast: boolean,
	CenterGap: number?, -- px around the track center where no tick is drawn (centered slider)
	ShowTicks: boolean?,
	Disabled: q.State<boolean>,
	Theme: Theme.Theme,
}

export type Geometry = {
	read THICK: number,
	read OUTER: number,
	read INNER: number,
	read INSET: number,
	read GAP: number,
	read SPACE: number,
	read HANDLE_W: number,
	read HANDLE_W_ACTIVE: number,
	read HANDLE_H: number,
	read DOT: number,
	read ICON: number?,
	read Vertical: boolean,
	read Flip: boolean,
	read x: (f: number) -> UDim,
	read phys: (u: UDim) -> UDim,
	read point: (u: UDim) -> UDim2,
	read handleSize: (narrow: boolean) -> UDim2,
	read hostSize: () -> UDim2,
	read centerPx: (length: number, f: number) -> number,
	read outerPiece: (o: OuterOptions) -> { Instance },
	read middlePiece: (o: MiddleOptions) -> Frame,
	read stop: (o: StopOptions) -> Frame,
	read ticks: (o: TickOptions) -> { Instance },
	read onActive: (disabled: q.State<boolean>, theme: Theme.Theme) -> (q.State<Color3>, q.State<number>),
	read onInactive: (disabled: q.State<boolean>, theme: Theme.Theme) -> (q.State<Color3>, q.State<number>),
}

export type Orientation = "Horizontal" | "Vertical"

-- raw (not animated) picks like the M2 ticks: a dot switches color the moment a handle passes it
local function pick(disabled: q.State<boolean>, normal: q.State<Color3>, off: q.State<Color3>): q.State<Color3>
	return disabled:Compute(function(self, _prev, n, f)
		return if self:Get() then f:Get() else n:Get()
	end, normal, off)
end
local function pickNumber(disabled: q.State<boolean>, off: number): q.State<number>
	return disabled:Compute(function(self)
		return if self:Get() then off else 0
	end)
end

local function new(o: GeometryOptions?): Geometry
	local opts: GeometryOptions = o or {}
	local sizeName: SizeName = opts.Size or "XS"
	local row = SIZES[sizeName]
	local vertical = opts.Vertical == true
	local flip = vertical and opts.Flip == true
	local THICK, OUTER, HANDLE_H = row.Track, row.Outer, row.Handle
	local INSET = STOP_INSET -- handle center at Min / Max = the stop dots' centers

	local function x(f: number): UDim
		return UDim.new(f, INSET - 2 * INSET * f)
	end
	local function phys(u: UDim): UDim
		return if flip then UDim.new(1 - u.Scale, -u.Offset) else u
	end
	-- a UDim2 from an along-axis UDim and an across-axis UDim
	local function pair(along: UDim, across: UDim): UDim2
		return if vertical then UDim2.new(across, along) else UDim2.new(along, across)
	end
	local CENTER = UDim.new(0.5, 0)
	local function point(u: UDim): UDim2
		return pair(phys(u), CENTER)
	end
	local SEGMENT_ANCHOR = if vertical then Vector2.new(0.5, 0) else Vector2.new(0, 0.5)
	local function offsets(along: number, across: number): UDim2
		return if vertical then UDim2.fromOffset(across, along) else UDim2.fromOffset(along, across)
	end
	local function lengthSize(len: UDim): UDim2
		return pair(len, UDim.new(0, THICK))
	end

	local function clip(name: string, position: UDim2 | q.State<UDim2>, size: UDim2 | q.State<UDim2>, visible: q.State<boolean>, fill: Frame): Frame
		return Frame {
			Name = name,
			AnchorPoint = SEGMENT_ANCHOR,
			Position = position,
			Size = size,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Visible = visible,
			fill,
		}
	end

	local function fill(position: UDim2 | q.State<UDim2>, size: UDim2 | q.State<UDim2>, radius: UDim, color: Animated, transparency: Animated): Frame
		return Frame {
			Name = "Fill",
			Position = position,
			Size = size,
			BackgroundColor3 = color,
			BackgroundTransparency = transparency,
			BorderSizePixel = 0,
			UICorner = radius,
		}
	end

	local function outerPiece(p: OuterOptions): { Instance }
		-- the piece's outer end is the host's physical start (left / top) or its physical end
		local atStart = (p.End == "Min") ~= flip
		local run = p.Run
		local edge: q.State<UDim> = p.Edge:Compute(function(self)
			return phys(self:Get())
		end)
		-- SHORT PIECES: only the clip windows change, the rounded fills keep their size (so their corner radii never
		-- change — UICorner clamps its radius to half the frame's smaller side). The cap fill is always 2 x OUTER, kept
		-- on the track end, and its clip window is min(OUTER, Run) long; the body clip is the rest. A body fill is at
		-- least 2 x INNER long and kept on the handle side. Past SHORT the host-fraction formulas take over (the layout
		-- owns the length of a long piece, not a px state).
		local SHORT = OUTER + 2 * INNER
		local capLen: q.State<number> = run:Compute(function(self)
			return math.clamp(self:Get(), 0, OUTER)
		end)
		local capPosition: UDim2 | q.State<UDim2>
		local fillPosition: UDim2 | q.State<UDim2>
		if atStart then
			capPosition = pair(UDim.new(0, 0), CENTER)
			fillPosition = offsets(0, 0)
		else
			capPosition = capLen:Compute(function(self)
				return pair(UDim.new(1, -self:Get()), CENTER)
			end)
			fillPosition = capLen:Compute(function(self)
				return offsets(self:Get() - 2 * OUTER, 0)
			end)
		end
		local capSize: q.State<UDim2> = capLen:Compute(function(self)
			return offsets(self:Get(), THICK)
		end)
		local edgeBodySize: q.State<UDim2> = edge:Compute(function(self)
			local e = self:Get()
			return if atStart then lengthSize(UDim.new(e.Scale, e.Offset - OUTER)) else lengthSize(UDim.new(1 - e.Scale, -OUTER - e.Offset))
		end)
		local bodyLength = function(r: number): number
			return math.max(r - OUTER, 0)
		end
		local bodyPosition: q.State<UDim2> = edge:Compute(function(self, _prev, r: q.State<number>)
			if r:Get() >= SHORT then
				return if atStart then pair(UDim.new(0, OUTER), CENTER) else pair(self:Get(), CENTER)
			end
			return if atStart then pair(UDim.new(0, OUTER), CENTER) else pair(UDim.new(1, -r:Get()), CENTER)
		end, run)
		local bodySize: q.State<UDim2> = edgeBodySize:Compute(function(self, _prev, r: q.State<number>)
			if r:Get() >= SHORT then
				return self:Get()
			end
			return lengthSize(UDim.new(0, bodyLength(r:Get())))
		end, run)
		-- body fill: bodyLength + INNER long (its handle-side end rounded, the cap-side overhang cut off), never below 2 x INNER
		local bodyFillSize: q.State<UDim2> = run:Compute(function(self)
			local r = self:Get()
			if r >= SHORT then
				return pair(UDim.new(1, INNER), UDim.new(1, 0))
			end
			return pair(UDim.new(0, math.max(bodyLength(r) + INNER, 2 * INNER)), UDim.new(1, 0))
		end)
		local bodyFillPosition: UDim2 | q.State<UDim2>
		if atStart then
			bodyFillPosition = run:Compute(function(self)
				local r = self:Get()
				return offsets(-(if r >= SHORT then INNER else math.max(INNER, 2 * INNER - bodyLength(r))), 0)
			end)
		else
			bodyFillPosition = offsets(0, 0)
		end
		local cap = clip(
			p.Name .. "Cap",
			capPosition,
			capSize,
			p.Visible,
			fill(fillPosition, offsets(2 * OUTER, THICK), UDim.new(0, OUTER), p.Color, p.Transparency)
		)
		local body = clip(
			p.Name .. "Body",
			bodyPosition,
			bodySize,
			p.Visible,
			fill(bodyFillPosition, bodyFillSize, UDim.new(0, INNER), p.Color, p.Transparency)
		)
		return { cap, body }
	end

	local function middlePiece(p: MiddleOptions): Frame
		local position: q.State<UDim2> = p.From:Compute(function(self, _prev, to)
			return pair(phys(if flip then to:Get() else self:Get()), CENTER)
		end, p.To)
		local size: q.State<UDim2> = p.From:Compute(function(self, _prev, to)
			local a, b = self:Get(), to:Get()
			return lengthSize(UDim.new(b.Scale - a.Scale, b.Offset - a.Offset))
		end, p.To)
		-- a clip window over a fill that is never shorter than 2 x INNER (UICorner would shrink its radius otherwise),
		-- kept on the window's physical start; a short piece just narrows the window
		local fillSize: q.State<UDim2> = p.Run:Compute(function(self)
			local r = self:Get()
			return if r >= 2 * INNER then pair(UDim.new(1, 0), UDim.new(1, 0)) else pair(UDim.new(0, 2 * INNER), UDim.new(1, 0))
		end)
		return clip(p.Name, position, size, p.Visible, fill(UDim2.fromOffset(0, 0), fillSize, UDim.new(0, INNER), p.Color, p.Transparency))
	end

	local function stop(p: StopOptions): Frame
		return Frame {
			Name = p.Name,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = point(if p.End == "Min" then UDim.new(0, INSET) else UDim.new(1, -INSET)),
			Size = UDim2.fromOffset(DOT, DOT),
			Visible = p.Visible,
			BackgroundColor3 = p.Color,
			BackgroundTransparency = p.Transparency,
			BorderSizePixel = 0,
			UICorner = CORNER_FULL,
		}
	end

	-- tick (and inset icon) colors: on the active track SecondaryContainer, on the inactive Primary; disabled (Compose):
	-- onSurface @ 12 % on the 38 % active track, onSurface @ 38 % on the 12 % inactive track
	local function onActive(disabled: q.State<boolean>, theme: Theme.Theme): (q.State<Color3>, q.State<number>)
		local R = theme.Raw
		return pick(disabled, R.SecondaryContainer, R.OnSurface), pickNumber(disabled, Style.DisabledContainerTransparency)
	end
	local function onInactive(disabled: q.State<boolean>, theme: Theme.Theme): (q.State<Color3>, q.State<number>)
		local R = theme.Raw
		return pick(disabled, R.Primary, R.OnSurface), pickNumber(disabled, Style.DisabledContentTransparency)
	end

	local function ticks(t: TickOptions): { Instance }
		local out: { Instance } = {}
		local step = t.Step
		if step == nil or t.ShowTicks == false then
			return out
		end
		local range = t.Range
		local count = math.floor(range / step + 1e-9)
		if count < 1 or count > MAX_TICKS then
			return out
		end
		local onA, onAT = onActive(t.Disabled, t.Theme)
		local onI, onIT = onInactive(t.Disabled, t.Theme)
		local from: q.State<number> = t.ActiveFrom or q.Source(0)
		local fracs = t.Fracs
		local f1 = fracs[1]
		local f2: q.State<number> = fracs[2] or f1
		local centerGap = t.CenterGap
		for i = 0, count do
			if (i == 0 and t.SkipFirst) or (i == count and t.SkipLast) then
				continue
			end
			local tf = i * step / range
			-- hidden while inside a handle gap: |t - f| * (L - 2 INSET) <= GAP (and before layout, L = 0); and inside
			-- the center gap of a centered slider: |t - 1/2| * (L - 2 INSET) <= CenterGap
			local visible: q.State<boolean> = t.Length:Compute(function(self, _prev, a, b)
				local span = self:Get() - 2 * INSET
				if span <= 0 then
					return false
				end
				if centerGap ~= nil and math.abs(tf - 0.5) * span <= centerGap then
					return false
				end
				return math.abs(tf - a:Get()) * span > GAP and math.abs(tf - b:Get()) * span > GAP
			end, f1, f2)
			local active: q.State<boolean> = from:Compute(function(self, _prev, to)
				return tf >= self:Get() and tf <= to:Get()
			end, t.ActiveTo)
			local color: q.State<Color3> = active:Compute(function(self, _prev, a, b)
				return if self:Get() then a:Get() else b:Get()
			end, onA, onI)
			local transparency: q.State<number> = active:Compute(function(self, _prev, a, b)
				return if self:Get() then a:Get() else b:Get()
			end, onAT, onIT)
			table.insert(
				out,
				Frame {
					Name = "Tick",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = point(x(tf)),
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

	return table.freeze({
		THICK = THICK,
		OUTER = OUTER,
		INNER = INNER,
		INSET = INSET,
		GAP = GAP,
		SPACE = SPACE,
		HANDLE_W = HANDLE_W,
		HANDLE_W_ACTIVE = HANDLE_W_ACTIVE,
		HANDLE_H = HANDLE_H,
		DOT = DOT,
		ICON = row.Icon,
		Vertical = vertical,
		Flip = flip,
		x = x,
		phys = phys,
		point = point,
		handleSize = function(narrow: boolean): UDim2
			local w = if narrow then HANDLE_W_ACTIVE else HANDLE_W
			return offsets(w, HANDLE_H)
		end,
		hostSize = function(): UDim2
			return pair(UDim.new(1, 0), UDim.new(0, HANDLE_H))
		end,
		centerPx = function(length: number, f: number): number
			return INSET + (length - 2 * INSET) * f
		end,
		outerPiece = outerPiece,
		middlePiece = middlePiece,
		stop = stop,
		ticks = ticks,
		onActive = onActive,
		onInactive = onInactive,
	}) :: any
end

-- a look's geometry from its props, validated (`Util.fail` blames the caller of the look — Slider / RangeSlider)
local function forLook(name: string, size: SizeName?, orientation: Orientation?, topToBottom: boolean?): Geometry
	if size ~= nil and SIZES[size] == nil then
		Util.fail(name, `Size must be "XS", "S", "M", "L" or "XL", got {tostring(size)}`)
	end
	if orientation ~= nil and orientation ~= "Horizontal" and orientation ~= "Vertical" then
		Util.fail(name, `Orientation must be "Horizontal" or "Vertical", got {tostring(orientation)}`)
	end
	local vertical = orientation == "Vertical"
	if topToBottom ~= nil and not vertical then
		Util.fail(name, `TopToBottom is for Orientation = "Vertical"`)
	end
	return new({ Size = size, Vertical = vertical, Flip = vertical and topToBottom ~= true })
end

-- the value label: 12 px above the handle (value-indicator.active.bottom-space), or 12 px left of it when vertical
local function labelPlacement(g: Geometry): (UDim2, Vector2)
	if g.Vertical then
		return UDim2.new(0, -12, 0.5, 0), Vector2.new(1, 0.5)
	end
	return UDim2.new(0.5, 0, 0, -12), Vector2.new(0.5, 1)
end

return {
	new = new,
	forLook = forLook,
	labelPlacement = labelPlacement,
	SIZES = SIZES,
}
