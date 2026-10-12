--!strict
--[[
	M3 CircularProgress, determinate and indeterminate, drawn from ARC PIECES of a sprite sheet (user design 2026-10-07):
	every arc is a sum of power-of-two pieces (1, 2, 4, ... 256 degrees), each one ImageLabel turned into place with
	`Rotation`, and its two round ends are separate round Frames.

	    Progress.CircularProgress({ Value = loaded })              -- Value: number | State<number>, 0..1
	    Progress.CircularProgress({ Value = 0.4, Size = 48, Thickness = 6 })
	    Progress.CircularProgress({ Visible = busy })              -- no Value = indeterminate; the loop stops while hidden

	Props (all `read`): Value (nil = indeterminate), Size (the ring's diameter in px, default 40 — M3's indicator; its
	48 dp container is the caller's layout slot), Thickness (stroke px, default 4 — snapped to the sheet, "THICKNESS"),
	Visible (boolean | State<boolean>?, default true), Theme, Modifier (Frame Modifier after the base — keep the host
	SQUARE: the pieces fill it and are turned about its centre), Hooks. Colors: indicator + its ends `Primary`, track
	`SecondaryContainer` (determinate only). Returns the host `Frame`.

	THE SHEET `SHEET_IMAGE` (quad-roblox-material/assets/circular-arc-sheet-1024.png, generator assets/gen-arc.py — its
	docstring is the rule's source): 1024 x 1024, 36 cells of 160 x 160 on a 170 px pitch (5 px gutter all round — packed cells
	bled into the neighbour), COLUMN-major: cell i at ImageRectOffset
	(170 (i // 6) + 5, 170 (i % 6) + 5), ImageRectSize (160, 160) (`cellRect`); i = thickness index x 9 + angle index, thickness
	= 0.05 / 0.10 / 0.15 / 0.20 of the cell, angle = 2^k degrees (k = 0..8). Each cell is a ring whose OUTER edge is
	1 px inside the cell edge, the arc starting at 12 o'clock and running clockwise for 2^k + 2 degrees (the 2 degree
	OVERLAP hides the hairline seam between pieces laid end to end), flat radial cuts, white on transparent. An
	ImageLabel of the host's size (Stretch) draws that piece at the ring's diameter, and `Rotation` turns it about the
	host's centre — no clip, no CanvasGroup.

	ONE ARC = a start angle `a` and a span `s` (whole degrees, a multiple of the step, "QUANTISING"):
	  - 0 < s < 360: the pieces decompose n = s - OVERLAP in binary and are laid end to end from `a`: piece j starts
	    where the previous one's NOMINAL angle ends, so its +2 overhang lies under the next piece, and the last one's
	    overhang ends exactly at a + n + 2 = a + s. The ink covers [a, a + s] with no gap and no overshoot (the
	    generator's docstring lets the overshoot hide under the cap; decomposing s - 2 removes it instead — a round cap
	    does not cover the CORNERS of a flat cut 2 degrees beyond its centre: 1 px at 200 px with the thin stroke).
	    Two round caps (Frames, UICorner 0.5) sit on the stroke's centre line at `a` and `a + s`; each covers the
	    flat cut under it exactly (diameter = the drawn stroke) and adds the half-disc beyond — the M3 round end.
	    s <= 2 (n <= 0): no pieces, the two caps alone (a dot, slightly pinched in the middle on a big ring: at most
	    2 degrees between their centres).
	  - s >= 360: a closed ring, no ends: n = 360 (256 + 64 + 32 + 8) from `a`, the last piece's overhang laps over
	    the first piece (no seam at the join), caps hidden.
	  - s <= 0: everything hidden.
	  Piece order: LARGEST FIRST from the end that does not move — the indicator grows from 12 o'clock, so its pieces
	  run largest-first from `a`; the determinate track's END is fixed (at 360 - gap), so its pieces run largest-LAST
	  (rotation = a + s - 2 - (sum of the pieces from this one up)). A step changes the low bits, so only the small
	  pieces near the moving end turn; the big ones keep their Rotation. One ImageLabel per bit, always present:
	  unused bits are `Visible = false` (no creation or destruction while running). Rotation, Visible and the caps'
	  Position are cached in Lua and written only when they change.
	Cap geometry (Scale of the host, so no Offset rounding): diameter = ratio x size, centre at
	(0.5 + rho sin theta, 0.5 - rho cos theta) with rho = (79 - 80 ratio) / 160 — the cell's centre-line radius
	(outer 79 / 160, minus half the stroke).

	DETERMINATE (androidx Compose material3 ProgressIndicator.kt, `CircularProgressIndicator(progress, ..., gapSize)`):
	indicator = 12 o'clock + Value x 360 (`sweep`); the track starts `sweep + min(sweep, gapSweep)` after it and spans
	`360 - sweep - 2 min(sweep, gapSweep)`, where gapSweep = (gapSize + strokeWidth) / (pi x diameter) x 360 — the
	stroke width is added because round caps reach half a stroke past both arc ends, so the space LEFT between the two
	caps is about gapSize (`ProgressIndicatorDefaults.CircularIndicatorTrackGapSize` = `CircularProgressIndicatorTokens
	.TrackActiveSpace` 4 dp; stroke = `TrackThickness` 4 dp; track color `circularDeterminateTrackColor` =
	`ProgressIndicatorTokens.TrackColor` = SecondaryContainer; no stop indicator on the circular variant). Here the gap
	is that same formula with the DRAWN stroke and the host size: (4 + ratio x size) / (pi x size) x 360, rounded to
	the step — 22 degrees at the default 40 / 4 (Compose 22.9), leaving ~2.8 px between the cap edges on the centre
	line (Compose's formula on its own ring gives 3.2; it measures the gap on the full diameter, not the centre line).
	Shapes at the ends:
	  - 0 % (sweep rounds to 0): no indicator (Compose draws nothing for a zero sweep), the track is a closed ring.
	  - just above 0: the indicator is a dot (caps alone) and the gap shrinks with it (min(sweep, gapSweep)), so the
	    track's round ends touch the dot — Compose does the same; the indicator is drawn ABOVE (ZIndex 2 over 1).
	  - near 100 %: the track shrinks to a dot (span 2 or less) and is hidden once 360 - sweep - 2 gap <= 0 (from
	    ~314 degrees at the default: 360 - 2 x 22 - 2). Deviation: Compose passes that negative sweep to `drawArc`
	    unclamped (Skia then draws it counter-clockwise, under the indicator); it is clamped to 0 here.
	  - 100 % (sweep rounds to 360): the indicator is a closed ring, track hidden.
	A Value change eases the drawn fraction over Medium2 (0.3 s) with Standard on the kit's mapping (Quart Out,
	Tokens/Motion.luau) — the same tween as before the redraw — from wherever it is now (a reversal continues). The
	pieces are placed by Lua, so it runs in a Heartbeat (`Loop.luau`): only while mounted, Visible AND moving (`idleAt`
	!= Value); once it lands the loop disconnects. A change while unmounted or hidden is drawn (eased) once shown.

	INDETERMINATE (same file, `CircularProgressIndicator(modifier, color, strokeWidth, trackColor, ...)` + its specs):
	no track (`circularIndeterminateTrackColor` = Transparent). One arc, tail at R(t) and head at R(t) + p(t) x 360,
	t over a 6 s cycle (`CircularAnimationProgressDuration`):
	  - R = global + additional: global turns 1080 degrees per cycle linearly (`circularIndeterminateGlobalRotation
	    AnimationSpec`, 180 deg/s); additional jumps 90 degrees in 0.3 s at 0, 1.5, 3 and 4.5 s and holds in between
	    (`circularIndeterminateRotationAnimationSpec`, `CircularAnimationAdditionalRotationDelay` 1500 /
	    `...Duration` 300). Those jumps are LINEAR: Compose's `90f at 300 using EmphasizedDecelerate` puts the easing on
	    the interval STARTING at 300 ms (`KeyframesSpecConfig.using`: "the interval started with the just provided
	    timestamp"), a hold, and keyframes default to LinearEasing — followed as written, not as it may have been meant.
	  - p: 0.1 -> 0.87 linearly over 0..3 s, then 0.87 -> 0.1 with Standard over 3..6 s
	    (`circularIndeterminateProgressAnimationSpec`, `CircularIndeterminateMin/MaxProgress`, `CircularProgressEasing`
	    = EasingStandardCubicBezier — evaluated as Quart Out, the kit's Standard). So the head races ahead while the arc
	    grows, then the tail catches up while it shrinks; the shortest arc is 36 degrees (10 %), the longest 313.
	  Compose starts the arc at 3 o'clock (`startAngle = 0f` inside the rotation); it starts at 12 here — a constant
	  phase of a spinning arc, invisible. The tail angle is NOT quantised (Rotation takes any float); only the span is.

	QUANTISING: spans are whole multiples of `step` degrees — 2 normally; 1 when 2 degrees of the centre line would be
	longer than 2 px (rho x size x 2 pi / 180 > 2: size > 122 / 129 / 137 / 145 px for ratio 0.05 / 0.10 / 0.15 / 0.20;
	`stepFor`), so a step never moves an end by more than ~1 px. The 1 degree piece exists only at step 1 (8 pieces per
	arc at step 2, 9 at step 1). The rounding moves an END by at most step / 2 from the exact Value, never opens a
	seam: the caps are placed at the same quantised angles as the pieces they cover, and the gap is one constant
	quantised angle. Pieces per arc: the popcount of s - 2 — at most 7 at step 2 (s <= 358), 8 at step 1.

	THICKNESS: the sheet has four strokes, so `Thickness / Size` picks the NEAREST of 0.05 / 0.10 / 0.15 / 0.20 (a tie
	takes the thinner; `pickThickness`) and the ring is drawn with THAT ratio: the drawn stroke is ratio x Size, which
	may differ from the requested px (Size 24 / Thickness 3 = 0.125, a tie -> 0.10 = 2.4 px). The caps and the gap use
	the drawn stroke, not the requested one. Default 40 / 4 -> 0.10 (4 px). Above 160 px the cell is upscaled (softer
	edge).

	Cost: determinate 25 instances at step 2 (host + 2 arcs x (8 ImageLabels + 2 caps x (Frame + UICorner))), 27 at
	step 1; indeterminate 13 (one arc), 14 at step 1. (The UIStroke + UIGradient version was 14 / 12.) Per frame:
	determinate at rest 0 (no Heartbeat); during a Value tween, on a frame where the quantised angle moves, the writes
	of the pieces that changed — Rotation / Visible of the low-bit pieces of both arcs + the indicator's head cap and
	the track's tail cap: 7.75 on average per 2 degree step, 19 at most (a carry through every bit; measured over 0..360
	by simulating `placeArc`), 0 on frames where it does not move. Indeterminate: every frame turns every shown piece
	(<= 7 Rotation) + 2 cap Positions, + Visible toggles when the span crosses a bit (the old version wrote 2 Rotations).
	A whole-arc parent `Rotation` would cut that to 1 + changes, but relies on parent rotation reaching children — not
	used (not measured).

	`SHEET_IMAGE` = rbxassetid://97823357785454 — the IMAGE id the uploaded Decal (92434906460089) resolves to, not
	the Decal id (a Decal id in `Image` shows nothing). If the asset fails to load only the round caps show.
	Deviations from M3: the gap is measured as Compose does but on the drawn stroke and snapped to the step (above);
	near 100 % the track is clamped instead of Compose's negative sweep; Thickness snaps to four ratios; ends and gap
	move in 2 degree steps (1 on big rings); the circular WAVY (M3 Expressive) form is not built — binary pieces cannot
	compose a wave whose phase must be continuous along the arc; it needs a different generator (user, 2026-10-07:
	later).
]]

local q = require("../Quad")
local Tokens = require("../Tokens")
local Theme = require("../Theme")
local Util = require("../Util")
local Loop = require("./Loop")
local D = q.Declaration
local circularName = D.Modifier.Frame():Name("CircularProgress")

export type Props = {
	read Value: (number | q.State<number>)?,
	read Size: number?,
	read Thickness: number?,
	read Visible: (boolean | q.State<boolean>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

-- assets/circular-arc-sheet-1024.png, uploaded by the kit author (2026-10-07): the IMAGE id, not the Decal id
local SHEET_IMAGE = "rbxassetid://97823357785454"
local CELL, PITCH, PAD, ROWS = 160, 170, 5, 6
local THICK = { 0.05, 0.10, 0.15, 0.20 }
local OVERLAP = 2 -- degrees each piece is drawn past its nominal angle (gen-arc.py)
local GAP = 4 -- px, Compose CircularIndicatorTrackGapSize
local SWING = Tokens.Motion.Duration.Medium2
-- indeterminate (Compose ProgressIndicator.kt)
local CYCLE = 6
local SPIN = 1080 / CYCLE -- degrees per second, the global rotation
local JUMP_EVERY, JUMP_TIME = 1.5, 0.3
local MIN_P, MAX_P = 0.1, 0.87
local full = UDim.new(0.5, 0)

-- the sheet cell of thickness `thick` (1..4) and piece 2^bit degrees (bit 0..8)
local function cellRect(thick: number, bit: number): Vector2
	local i = (thick - 1) * 9 + bit
	return Vector2.new(PITCH * (i // ROWS) + PAD, PITCH * (i % ROWS) + PAD)
end

-- the nearest sheet thickness (index into THICK) for a requested stroke; a tie takes the thinner
local function pickThickness(size: number, thickness: number): number
	local want = thickness / size
	local best, bestD = 1, math.huge
	for i, r in THICK do
		local d = math.abs(want - r)
		if d < bestD - 1e-9 then
			best, bestD = i, d
		end
	end
	return best
end

-- the stroke's centre-line radius as a fraction of the diameter
local function centreRadius(ratio: number): number
	return (CELL / 2 - 1 - ratio * CELL / 2) / CELL
end

-- degrees per quantisation step: 1 once 2 degrees of the centre line exceed 2 px
local function stepFor(size: number, ratio: number): number
	return if size * centreRadius(ratio) * math.rad(2) > 2 then 1 else 2
end

-- Compose's gapSweep with the drawn stroke, rounded to the step
local function gapAngle(size: number, ratio: number, step: number): number
	local deg = (GAP + ratio * size) / (math.pi * size) * 360
	return math.max(step, math.round(deg / step) * step)
end

local function capPosition(rho: number, angle: number): UDim2
	local a = math.rad(angle)
	return UDim2.fromScale(0.5 + rho * math.sin(a), 0.5 - rho * math.cos(a))
end

-- determinate layout for an indicator sweep `e` (quantised degrees): indicator span, track start, track span
local function layout(e: number, g: number): (number, number, number)
	if e <= 0 then
		return 0, 0, 360
	elseif e >= 360 then
		return 360, 0, 0
	end
	local gg = math.min(e, g)
	return e, e + gg, math.max(360 - e - 2 * gg, 0)
end

-- the indeterminate pose at time t: tail angle (degrees, any float) and sweep fraction
local function indeterminatePose(t: number): (number, number)
	local c = t % CYCLE
	local jumps = 0
	for k = 0, 3 do
		local s = k * JUMP_EVERY
		if c >= s + JUMP_TIME then
			jumps += 90
		elseif c > s then
			jumps += 90 * (c - s) / JUMP_TIME
		end
	end
	local half = CYCLE / 2
	local p = if c < half
		then MIN_P + (MAX_P - MIN_P) * c / half
		else MAX_P - (MAX_P - MIN_P) * (1 - (1 - (c - half) / half) ^ 4)
	return (SPIN * c + jumps) % 360, p
end

type Arc = {
	pieces: { [number]: ImageLabel }, -- by bit
	rotation: { [number]: number }, -- last written
	shown: { [number]: boolean },
	tail: Frame,
	head: Frame,
	tailAt: number,
	headAt: number,
	capsOn: boolean,
	rho: number,
}

local function newArc(prefix: string, color: Theme.Animated, z: number, thick: number, step: number): (Arc, { Instance })
	local ratio = THICK[thick]
	local list: { Instance } = {}
	local pieces: { [number]: ImageLabel } = {}
	for bit = if step == 1 then 0 else 1, 8 do
		local piece = D.ImageLabel {
			Name = prefix .. tostring(bit32.lshift(1, bit)),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = SHEET_IMAGE,
			ImageRectOffset = cellRect(thick, bit),
			ImageRectSize = Vector2.new(CELL, CELL),
			ImageColor3 = color,
			ScaleType = Enum.ScaleType.Stretch,
			Visible = false,
			ZIndex = z,
		}
		pieces[bit] = piece
		table.insert(list, piece)
	end
	local function cap(name: string): Frame
		return D.Frame {
			Name = name,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(ratio, ratio),
			Visible = false,
			BorderSizePixel = 0,
			BackgroundColor3 = color,
			UICorner = full,
			ZIndex = z,
		}
	end
	local tail, head = cap(prefix .. "Start"), cap(prefix .. "End")
	table.insert(list, tail)
	table.insert(list, head)
	local arc: Arc = {
		pieces = pieces,
		rotation = {},
		shown = {},
		tail = tail,
		head = head,
		tailAt = -1,
		headAt = -1,
		capsOn = false,
		rho = centreRadius(ratio),
	}
	return arc, list
end

-- place an arc from `a` over `span` degrees (see "ONE ARC"); `anchorEnd`: lay the pieces largest-last
local function placeArc(arc: Arc, a: number, span: number, anchorEnd: boolean)
	local n, caps = 0, false
	if span >= 360 then
		n, anchorEnd = 360, false
	elseif span > 0 then
		n, caps = span - OVERLAP, true
	end
	local acc = 0
	for bit = 8, 0, -1 do
		local piece = arc.pieces[bit]
		if piece == nil then
			continue
		end
		local p = bit32.lshift(1, bit)
		local on = n > 0 and bit32.btest(n, p)
		if on then
			local r
			if anchorEnd then
				acc += p
				r = a + span - OVERLAP - acc
			else
				r = a + acc
				acc += p
			end
			r %= 360
			if arc.rotation[bit] ~= r then
				arc.rotation[bit] = r
				piece.Rotation = r
			end
		end
		if arc.shown[bit] ~= on then
			arc.shown[bit] = on
			piece.Visible = on
		end
	end
	if caps ~= arc.capsOn then
		arc.capsOn = caps
		arc.tail.Visible = caps
		arc.head.Visible = caps
	end
	if caps then
		local ta, ha = a % 360, (a + span) % 360
		if ta ~= arc.tailAt then
			arc.tailAt = ta
			arc.tail.Position = capPosition(arc.rho, ta)
		end
		if ha ~= arc.headAt then
			arc.headAt = ha
			arc.head.Position = capPosition(arc.rho, ha)
		end
	end
end

local function CircularProgress(props: Props): Frame
	local theme = Theme.resolve(props.Theme)
	local visible = Util.asState(props.Visible, true)
	local size = props.Size or 40
	local thick = pickThickness(size, props.Thickness or 4)
	local ratio = THICK[thick]
	local step = stepFor(size, ratio)
	local function quantise(deg: number): number
		return math.round(deg / step) * step
	end

	local indicator, indicatorParts = newArc("Arc", theme.Color.Primary, 2, thick, step)
	local tree: { [any]: any } = {
		circularName,
		D.Modifier.Frame():Size(UDim2.fromOffset(size, size)):BackgroundTransparency(1):BorderSizePixel(0),
		props.Modifier or q.None,
		Visible = visible,
	}
	local function finish(parts: { Instance }): Frame
		for _, p in parts do
			table.insert(tree, p)
		end
		for _, h in Util.hooks(props.Hooks) do
			table.insert(tree, h)
		end
		return D.Frame(tree :: any)
	end

	if props.Value == nil then
		local function pose(t: number)
			local tail, p = indeterminatePose(t)
			placeArc(indicator, tail, quantise(p * 360), false)
		end
		pose(0)
		local clock = 0 -- the spinner's own time: survives the loop's restarts (hide / show), so no jump back to pose 0
		local hook, effect = Loop.new(visible, function(_t: number, dt: number)
			clock += dt
			pose(clock)
		end)
		table.insert(tree, hook)
		table.insert(tree, effect)
		return finish(indicatorParts)
	end

	local track, trackParts = newArc("Track", theme.Color.SecondaryContainer, 1, thick, step)
	local value: q.State<number> = Util.asNumberState(props.Value, 0):Compute(function(self)
		return math.clamp(self:Get(), 0, 1)
	end)
	local g = gapAngle(size, ratio, step)
	local lastE = -1
	local function draw(fraction: number)
		local e = quantise(fraction * 360)
		if e == lastE then
			return
		end
		lastE = e
		local ispan, ts, tspan = layout(e, g)
		placeArc(indicator, 0, ispan, false)
		placeArc(track, ts, tspan, true)
	end
	local shown = value:Get() -- the drawn fraction, eased toward Value
	draw(shown)
	local goal, from, elapsed = shown, shown, 0
	-- the loop sleeps once the drawn fraction has landed on `idleAt` (a Value); see "DETERMINATE"
	local idleAt = q.Source(shown)
	local moving: q.State<boolean> = visible:Compute(function(self)
		return self:Get() and idleAt:Get() ~= value:Get()
	end, idleAt, value)
	local hook, effect = Loop.new(moving, function(_t: number, dt: number)
		idleAt:SetIfChanged(-1) -- awake: a stale idle mark must not put a return to it straight to sleep
		local want = value:Get()
		if want ~= goal then
			goal, from, elapsed = want, shown, 0
		end
		if shown ~= goal then
			elapsed += dt
			local p = math.min(elapsed / SWING, 1)
			shown = if p >= 1 then goal else from + (goal - from) * (1 - (1 - p) ^ 4) -- Quart Out (Standard)
		end
		draw(shown)
		if shown == goal then
			idleAt:SetIfChanged(goal)
		end
	end)
	table.insert(tree, hook)
	table.insert(tree, effect)
	local parts = table.clone(trackParts)
	for _, p in indicatorParts do
		table.insert(parts, p)
	end
	return finish(parts)
end

return {
	CircularProgress = CircularProgress,
	-- pure helpers (specs)
	cellRect = cellRect,
	pickThickness = pickThickness,
	centreRadius = centreRadius,
	stepFor = stepFor,
	gapAngle = gapAngle,
	layout = layout,
	indeterminatePose = indeterminatePose,
	THICK = THICK,
	OVERLAP = OVERLAP,
	SHEET_IMAGE = SHEET_IMAGE,
}
