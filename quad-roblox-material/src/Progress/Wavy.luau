--!strict
--[[
	M3 Expressive WAVY linear progress (determinate): the active indicator is a travelling sine wave instead of a flat
	bar; after a 4 px gap the flat track continues to its stop dot, like the flat LinearProgress. Round ends; the wave
	flattens out at 100 % (and whenever `Wavy` is false) and swells back, like M3.

	    Progress.WavyProgress({ Value = loaded })                -- Value: number | State<number>, 0..1 (required)
	    Progress.WavyProgress({ Value = 0.6, Thickness = 6, Wavelength = 60 })
	    Progress.WavyProgress({ Value = loaded, Wavy = not reducedMotion })

	Props (all `read`): Value (required — see "indeterminate" below), Thickness (stroke px, default 4), Wavelength (px,
	default 40), Wavy (boolean | State<boolean>?, default true: the wave's amplitude target — false flattens it into a
	straight stroke, true swells it back; at Value >= 1 it is flat regardless), Visible (boolean | State<boolean>?,
	default true; the wave stops travelling while not Visible), Theme, Modifier (Frame Modifier after the base: width,
	position, LayoutOrder ...), Hooks. Height = 2.5 x Thickness (10 by default) and the full amplitude is 0.75 x
	Thickness (3 by default) — FIXED ratios, see "HOW". Colors: wave + round ends + stop dot `Primary`, track
	`SecondaryContainer`. Returns the host `Frame`.

	HOW (Roblox has no path rendering): the wave is an IMAGE of one wavelength, repeated: a cell of the AMPLITUDE SPRITE
	SHEET `SHEET_IMAGE` (quad-roblox-material/assets/wavy-progress-sheet-1024.png, generator assets/gen-wave.py —
	its docstring is the rule's source): 1024 x 1024, 24 frames of one wavelength, 480 x 64 each, 2 columns x 12 rows, column-major, with gutters
	(16 px left/right holding the same wave continued, 10 / 11 px transparent above / below — edge-to-edge cells showed
	specks at the frame ends, texture filtering reads the neighbour): frame i at ImageRectOffset
	(512 * (i // 12) + 16, 85 * (i % 12) + 10), ImageRectSize (480, 64) (`frameRect`). Every frame has
	the same shape rule (measured on the PNGs): width W = 480, height H = 64, centre line H/2, y(u) = H/2 - A sin(2 pi u / W),
	stroke 0.4 H PERPENDICULAR to the curve, rising first from the centre line at u = 0, seamless in u; white,
	anti-aliased, transparent background; A(i) = 0.3 H (1 - i / 23): frame 0 = full amplitude, 23 = flat.
	ONE STRETCH ImageLabel PER WAVELENGTH (`Period`, Wavelength x height, k x Wavelength apart on the `Strip` Frame):
	`ScaleType.Tile` does not repeat an ImageRect cell — tiling is UV wrapping of the whole texture (Roblox staff,
	DevForum "ImageRectOffset/Size does not work with Tile ScaleType", t/3409510, 2025-02-06: as designed), so the
	single tiled ImageLabel of the first image version cannot show a sheet cell. Periods are added when the host gets
	wider (checked in the loop: ceil(width / Wavelength) + 1), never removed. The frame is ONE State (`frame`) bound
	to every period's ImageRectOffset — a frame change writes each period once, and a new period joins on the current
	frame. (Cell + Stretch is the combination the kit author has used for sprite sheets in production.)
	The strip is one wavelength wider than its clip and slides left by the phase every frame (its Position) — the
	periods move with it, so the wave travels. It sits in a plain `ClipsDescendants` frame (`Clip`, inside `Wave` whose
	size = Value, tweened Medium1 / Standard — "ROUND ENDS" below): nothing is rotated, so ordinary clipping works — no
	CanvasGroup (no offscreen texture, nothing reallocated on resize).
	Why an image (2026-10-07, replaced a polyline of 8 rotated Frames per wavelength + a CanvasGroup clip, 87 instances
	at 300 px): Roblox does not anti-alias the edges of rotated GuiObjects (DevForum "GUI Anti-Aliasing for Rotation",
	"Rotation causes frames' edges to be pixelated"), and a CanvasGroup renders through a texture whose resolution the
	engine lowers with the graphics level and memory (DevForum "CanvasGroups content is blurred!", "Is there anyway to
	get a consistent quality on Canvas Groups?") — the two likely causes of the low-resolution look seen in Studio (not
	separated by measurement). The stroke is anti-aliased in the image itself and downsampled by the engine's image
	filtering, so its edge should stay smooth (Studio QA to confirm).
	Fixed ratios: the stroke and amplitude scale WITH the height, so they cannot be set independently — `Thickness`
	sets the height (2.5 x) and the amplitude follows (M3's default 4 / 3 / 10 dp). `Wavelength` stretches each period
	horizontally: away from 4 x the height (40 for Thickness 4) the slopes steepen or flatten and a steep stroke looks
	a little thinner.

	ROUND ENDS (2026-10-07): the clip cuts the stroke square, so two round caps (`Start`, `End`: Frames of diameter
	`Thickness`, UICorner 0.5, Primary like the periods' ImageColor3) sit ON the sine curve at the clip's two ends and
	follow it every frame — the phase travels, so `Start` bobs up and down too. Layout: `Wave` (no clip, size = Value x
	a FIXED height, tweened) holds `Clip` (inset by the cap radius r = Thickness / 2 at BOTH ends: x from r to L - r,
	where L = Value x width) and the two caps, centred at x = r (`Start`) and x = L - r (`End`, Position (1, -r) of
	`Wave`, so its x follows the fill tween through the layout even while the loop is off; only its y is written per
	frame). So the stroke + caps span exactly [0, L] like the flat LinearProgress's pill, the 4 px gap to the track stays
	4 px, and nothing overhangs the host's left edge. A UDim Offset is an integer, so r is rounded (odd Thickness: half
	a pixel off, the same for the clip and the caps, so they still meet), the slide is whole pixels, and a cap's y is a
	SCALE of `Wave`'s fixed height (an Offset would truncate it).
	Curve: the strip starts at the clip's left edge (x = r) and sits at Position (-slide, 0), so at host x the drawn
	curve is
	    y(x) = height / 2 - A sin(2 pi ((x - r) / Wavelength + slide / Wavelength)),
	    slide = round((clock / PERIOD % 1) x Wavelength) px,   A = 0.75 Thickness (1 - frame / 23)
	(the frame ON SCREEN, not the eased level — the caps match the image) — `Wavelength` is the period's actual width, so
	stretching it stretches the formula with it. `clock` is the wave's own time, kept across the loop's restarts
	(a Value change re-runs it), so the wave never jumps.
	Why the clip ends AT the cap centres (not a radius earlier/later): a vertical cut through a band of perpendicular
	half-width r leaves corners r / cos(slope) above and below the centre — at most 0.105 r outside the cap's circle
	(slope 25.2 deg at full amplitude and the default 4 x height; a horizontal stretch keeps the vertical extent, so it
	stays <= 0.105 r for any `Wavelength`; smaller amplitudes are flatter): 0.21 px at Thickness 4, 0.32 px at 6 —
	sub-pixel, inside the edge's anti-aliasing. Cutting a radius earlier would leave a notch (the circle is a point at
	its leftmost x), later would expose more of the corner.
	Short fills: while L < 2r (the clip would be negative) `Clip` hides and BOTH caps sit at x = r — one dot of
	diameter `Thickness` (it may overlap the gap by up to Thickness - 4 - L px); at L = 0 the caps hide too (nothing
	drawn at 0 %, like the flat bar's zero-width pill). The tweened L is read every frame (`Wave.Size` x the host's
	`AbsoluteSize.X`), so a fill tween to 0 keeps its round ends until it lands.

	AMPLITUDE: the target is full while `Wavy` and Value < 1, else flat. A change eases the level over Long2 (0.5 s) x
	the distance left — swelling with Standard (Quart Out), flattening with EmphasizedAccelerate (Quint In): Compose's
	`IncreasingAmplitudeAnimationSpec` / `DecreasingAmplitudeAnimationSpec` (androidx WavyProgressIndicator.kt, both
	`MotionTokens.DurationLong2`), on the kit's easing mapping (Tokens/Motion.luau). The level is quantised to the
	sheet's 24 frames (at 60 Hz the steep end of an ease skips a few). A reversal mid-way continues from the current
	level. The level is snapped at construction (no swell on mount). While not Visible the transition pauses with the
	loop.

	Cost: host + Track(+UICorner, stop dot + UICorner) + Wave + Clip + Strip + caps 2 x (Frame + UICorner) + periods =
	12 + ceil(width / Wavelength) + 1 instances — GROWS WITH THE WIDTH: 21 at 300 px with the default Wavelength (the
	single tiled ImageLabel was 7 at any width, 11 with the caps; it cannot show a sheet cell — above). Before the
	first layout (width 0) there is one period: 13. One Heartbeat (`Loop.luau`,
	only while mounted, Visible and not asleep) writing 3 Positions per frame while wavy (strip, Start, End — 1 before
	the caps), one ImageRectOffset per period on each frame change during a transition (at most 23 changes per
	transition), and a Visible write on `Clip` / caps only when L crosses 0 or 2r. FLAT sleeps: the stroke is a
	straight line, so the strip is not moved and the caps sit on the centre line; once flat and the fill tween has
	landed the loop disconnects (nothing runs per frame — a `Wavy = false` bar costs no Heartbeat); a Value change,
	`Wavy` turning true or the host resizing (new periods may be needed) wakes it. While not Visible the loop stops and
	the caps freeze with the strip (both last written in the same step).

	`SHEET_IMAGE` = rbxassetid://96568777229073 (the sheet, uploaded by the kit author — the IMAGE id the Decal
	resolves to, not the Decal id). If the asset fails to load the wave is invisible; the caps, track and stop dot
	still show. (The single full-amplitude texture assets/wavy-progress-512x128.png, rbxassetid://78445787165309, is
	no longer used.)
	Indeterminate (no Value) is NOT built: use `LinearProgress({})` for unknown progress. Deviations from M3: the
	round ends are circles laid over a square cut (above — sub-pixel corners; with a `Wavelength` far from 4 x the
	height the stroke's perpendicular width drifts from `Thickness` while the caps stay `Thickness`, so they look
	slightly fatter / thinner than the line); the amplitude is full from just above 0 % to just below 100 % (Compose's
	default `indicatorAmplitude` is flat at <= 10 % and >= 95 %); amplitude and stroke are tied to the height (above).
]]

local q = require("../Quad")
local Tokens = require("../Tokens")
local Theme = require("../Theme")
local Util = require("../Util")
local Loop = require("./Loop")
local D = q.Declaration
local wavyName = D.Modifier.Frame():Name("WavyProgress")

export type Props = {
	read Value: number | q.State<number>,
	read Thickness: number?,
	read Wavelength: number?,
	read Wavy: (boolean | q.State<boolean>)?,
	read Visible: (boolean | q.State<boolean>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

-- The amplitude sprite sheet: assets/wavy-progress-sheet-1024.png, uploaded by the kit author (2026-10-07). The
-- IMAGE id (what the uploaded Decal resolves to — a Decal / classic T-shirt id is the parent asset, not usable here).
local SHEET_IMAGE = "rbxassetid://96568777229073"
local FRAME_W, FRAME_H, ROWS = 480, 64, 12
local COL_STRIDE, ROW_STRIDE, PAD_X, PAD_Y = 512, 85, 16, 10 -- the sheet's cell pitch and the gutter before each cell
local LAST = 23 -- frames 0 (full amplitude) .. 23 (flat)

local HEIGHT_PER_THICKNESS = 2.5 -- the texture: stroke 4/10, amplitude 3/10 of its height (ratios, so the 480 x 64 frame's 7.5:1 shape needs no change — Stretch absorbs it)
local AMP_PER_THICKNESS = 0.75 -- 3/10 of the height
local GAP = 4
local STOP = 4
local PERIOD = 1 -- seconds for the wave to travel one wavelength
local TAU = 2 * math.pi
local SWING = Tokens.Motion.Duration.Long2 -- a full amplitude transition, seconds
local full = UDim.new(0.5, 0)

-- the sheet cell of amplitude frame `i` (0 = full .. LAST = flat)
local function frameRect(i: number): Vector2
	return Vector2.new(COL_STRIDE * (i // ROWS) + PAD_X, ROW_STRIDE * (i % ROWS) + PAD_Y)
end

local function WavyProgress(props: Props): Frame
	if props.Value == nil then
		error("WavyProgress: Value is required (use LinearProgress({}) for indeterminate progress)", 2)
	end
	local theme = Theme.resolve(props.Theme)
	local visible = Util.asState(props.Visible, true)
	local wavy = Util.asState(props.Wavy, true)
	local thick = props.Thickness or 4
	local lambda = props.Wavelength or 40
	local height = thick * HEIGHT_PER_THICKNESS
	local maxAmp = thick * AMP_PER_THICKNESS
	-- the caps' centres sit `inset` px in from each end of the fill: the radius, rounded because a UDim Offset is an
	-- integer (odd Thickness: half a pixel off, the same for the clip and the caps, so they still meet)
	local inset = math.round(thick / 2)
	local mid = height / 2

	local value: q.State<number> = Util.asNumberState(props.Value, 0):Compute(function(self)
		return math.clamp(self:Get(), 0, 1)
	end)
	-- the amplitude target: full while Wavy and not complete (M3 flattens the finished bar)
	local wavyGoal: q.State<boolean> = wavy:Compute(function(self)
		return self:Get() and value:Get() < 1
	end, value)

	-- the curve's y at host x (see "ROUND ENDS"): the strip starts at the clip's left edge x = inset, slid by the phase
	local function curveY(x: number, phase: number, amp: number): number
		return mid - amp * math.sin(TAU * ((x - inset) / lambda + phase))
	end
	-- a cap's Position: x as given, y as a SCALE of `Wave`'s fixed height (an Offset would truncate to whole pixels)
	local function capAt(xScale: number, xOffset: number, y: number): UDim2
		return UDim2.new(xScale, xOffset, y / height, 0)
	end

	-- amplitude level (1 = full, 0 = flat), snapped at construction; eased toward `goal` in the loop
	local level = if wavyGoal:Get() then 1 else 0
	local goal, from, elapsed, span = level, level, 0, 0
	local frame = q.Source(math.round((1 - level) * LAST))
	local rectOffset: q.State<Vector2> = frame:Compute(function(self)
		return frameRect(self:Get())
	end)

	local function period(k: number): ImageLabel
		return D.ImageLabel {
			Name = "Period",
			Position = UDim2.fromOffset(k * lambda, 0),
			Size = UDim2.fromOffset(lambda, height),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = SHEET_IMAGE,
			ImageRectOffset = rectOffset,
			ImageRectSize = Vector2.new(FRAME_W, FRAME_H),
			ImageColor3 = theme.Color.Primary,
			ScaleType = Enum.ScaleType.Stretch,
		}
	end
	local periods = q.Slot({ period(0) } :: { Instance })
	local count = 1

	-- the loop sleeps once flat with the fill landed at `idleAt` (a Value); see "Cost"
	local idleAt = q.Source(-1)
	local active: q.State<boolean> = visible:Compute(function(self)
		return self:Get() and not (idleAt:Get() == value:Get() and not wavyGoal:Get())
	end, idleAt, value, wavyGoal)

	local host: GuiObject? = nil
	local wave: GuiObject? = nil
	local clip: GuiObject? = nil
	local strip: GuiObject? = nil
	local startCap: GuiObject? = nil
	local endCap: GuiObject? = nil
	local capsOn = value:Get() > 0
	local clipOn = capsOn
	local clock = 0 -- the wave's own time: survives the loop's restarts (each Value change re-runs it), so no jump
	local hook, effect = Loop.new(active, function(_t: number, dt: number)
		local h, w, c, st, s, e = host, wave, clip, strip, startCap, endCap
		if h == nil or w == nil or c == nil or st == nil or s == nil or e == nil then
			return
		end
		clock += dt
		idleAt:SetIfChanged(-1) -- awake: a stale idle mark must not put the next flat target straight to sleep
		-- amplitude: (re)start a transition when the target flips, then ease the level
		local want = if wavyGoal:Get() then 1 else 0
		if want ~= goal then
			goal, from, elapsed = want, level, 0
			span = SWING * math.abs(want - level)
		end
		if level ~= goal then
			elapsed += dt
			local p = if span > 0 then math.min(elapsed / span, 1) else 1
			local eased = if goal > from then 1 - (1 - p) ^ 4 else p ^ 5 -- Quart Out / Quint In
			level = if p >= 1 then goal else from + (goal - from) * eased
		end
		local i = math.round((1 - level) * LAST)
		frame:SetIfChanged(i)
		local amp = maxAmp * (1 - i / LAST)
		-- one period per wavelength of host width, plus one spare for the slide
		local need = math.ceil(h.AbsoluteSize.X / lambda) + 1
		if need > count then
			for k = count, need - 1 do
				periods:Add(period(k))
			end
			count = need
			st.Size = UDim2.new(0, count * lambda, 1, 0)
		end
		-- the slide in whole pixels (a UDim Offset is an integer); the caps use the phase actually drawn
		local slide = math.round(((clock / PERIOD) % 1) * lambda) % lambda
		local phase = slide / lambda
		if amp > 0 then -- flat: a straight line does not show the slide
			st.Position = UDim2.fromOffset(-slide, 0)
		end
		local size = w.Size.X
		local len = size.Scale * h.AbsoluteSize.X + size.Offset -- the tweened fill length L, px
		local on = len > 0
		if on ~= capsOn then
			capsOn = on
			s.Visible = on
			e.Visible = on
		end
		local long = len >= 2 * inset -- room for the clip between the two cap centres (L >= 2r)
		if long ~= clipOn then
			clipOn = long
			c.Visible = long
		end
		if on then
			local y0 = curveY(inset, phase, amp)
			s.Position = capAt(0, inset, y0)
			e.Position = if long then capAt(1, -inset, curveY(len - inset, phase, amp)) else capAt(0, inset, y0)
		end
		-- flat, settled and the fill tween landed (a UDim Scale is a float32: compare loosely): sleep until something changes
		if i == LAST and goal == 0 and math.abs(size.Scale - value:Get()) < 1e-6 then
			idleAt:SetIfChanged(value:Get())
		end
	end)

	local function cap(name: string, position: UDim2, set: (GuiObject) -> ())
		return D.Frame {
			Name = name,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = position,
			Size = UDim2.fromOffset(thick, thick),
			Visible = capsOn,
			BorderSizePixel = 0,
			BackgroundColor3 = theme.Color.Primary,
			UICorner = full,
			Util.preHook(set),
		}
	end

	local motion = q.Animate(Tokens.Motion.options("Medium1", "Standard"))
	-- a FIXED height (the periods' and the caps' frame of reference), whatever height a Modifier gives the host
	local waveSize: q.State<UDim2> = value:Compute(function(self)
		return UDim2.new(self:Get(), 0, 0, height)
	end)
	local trackPosition: q.State<UDim2> = value:Compute(function(self)
		local x = self:Get()
		return UDim2.new(x, if x > 0 then GAP else 0, 0.5, 0)
	end)
	local trackSize: q.State<UDim2> = value:Compute(function(self)
		local x = self:Get()
		return UDim2.new(1 - x, if x > 0 then -GAP else 0, 0, thick)
	end)
	local notFull: q.State<boolean> = value:Compute(function(self)
		return self:Get() < 1
	end)

	local startAmp = maxAmp * (1 - frame:Get() / LAST)
	local root = D.Frame {
		wavyName,
		D.Modifier.Frame():Size(UDim2.new(1, 0, 0, height)):BackgroundTransparency(1):BorderSizePixel(0),
		props.Modifier or q.None,
		Visible = visible,
		hook,
		effect,
		D.Frame {
			Name = "Track",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = trackPosition:Apply(motion),
			Size = trackSize:Apply(motion),
			Visible = notFull,
			BorderSizePixel = 0,
			BackgroundColor3 = theme.Color.SecondaryContainer,
			UICorner = full,
			D.Frame {
				Name = "Stop",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromOffset(STOP, STOP),
				BorderSizePixel = 0,
				BackgroundColor3 = theme.Color.Primary,
				UICorner = full,
			},
		},
		D.Frame {
			Name = "Wave",
			Size = waveSize:Apply(motion),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Util.preHook(function(inst)
				wave = inst
			end),
			D.Frame {
				Name = "Clip",
				-- from the start cap's centre to the end cap's (r inset at both ends, "ROUND ENDS")
				Position = UDim2.fromOffset(inset, 0),
				Size = UDim2.new(1, -2 * inset, 1, 0),
				Visible = clipOn,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ClipsDescendants = true,
				Util.preHook(function(inst)
					clip = inst
				end),
				D.Frame {
					Name = "Strip",
					-- periods start at the strip's left edge, so growing the clip as Value tweens does not move the wave
					Size = UDim2.new(0, lambda, 1, 0),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Util.preHook(function(inst)
						strip = inst
					end),
					periods,
				},
			},
			-- phase 0 until the first frame; `End`'s x follows the fill tween through `Wave`'s size
			cap("Start", capAt(0, inset, curveY(inset, 0, startAmp)), function(inst)
				startCap = inst
			end),
			cap("End", capAt(1, -inset, mid), function(inst)
				endCap = inst
			end),
		},
		table.unpack(Util.hooks(props.Hooks)),
	}
	host = root
	-- a wider host may need more periods: wake a sleeping (flat) loop
	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		idleAt:Set(-1)
	end)
	return root
end

return {
	WavyProgress = WavyProgress,
	frameRect = frameRect,
	LAST = LAST,
}
