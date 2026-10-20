--!strict
local H = require("./support/harness")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
local Frame = q.Elem "Frame"
local ScreenGui = q.Elem "ScreenGui"
local FrameModifier = q.Modifier "Frame"
local Tokens = require("../src/Tokens")
local Progress = require("../src/Progress")

local L = Tokens.Color.Light

local function beats(): number
	return #(H.RunService :: any).Heartbeat.connections
end
local baseBeats = beats()

-- The loop only runs under a LayerCollector (ScreenGui, SurfaceGui, BillboardGui, plugin GUIs). The mock does not fire AncestryChanged on re-parenting, so
-- `live(host)` seats the host in a ScreenGui and fires the event the engine would.
-- the predicate sits outside `live<T>`: luau-lsp 1.70.1 checks an inline lambda's `return true` against the enclosing generic `T`
local function always(_: any): boolean
	return true
end
local function live<T>(host: T): (T, any)
	local gui = ScreenGui { host :: any }
	for _, d in H.findAll(gui, always) do
		local anyD: any = d
		anyD.AncestryChanged:Fire(d, gui)
	end
	return host, gui
end

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end
local function class(inst: any, name: string): { any }
	return H.findAll(inst, function(c: any)
		return c.ClassName == name
	end)
end

H.section("Linear determinate: structure, M3 2024 geometry (indicator, gap, track, stop)", function()
	local value = q.Source(0.4)
	local bar = Progress.LinearProgress({ Value = value })
	local count = H.countDescendants(bar)
	print("Linear determinate instances: " .. (count + 1))
	H.resetOutput()
	assert(count == 6, "indicator, track, stop (+3 UICorner) = 6, got " .. count)
	assert(bar.Size == UDim2.new(1, 0, 0, 4) and bar.BackgroundTransparency == 1 and bar.Visible == true)
	local ind, track, stop = H.find(bar, "Indicator"), H.find(bar, "Track"), H.find(bar, "Stop")
	H.finishTweens()
	assert(ind.Size == UDim2.new(0.4, 0, 1, 0) and ind.BackgroundColor3 == L.Primary)
	assert(track.Position == UDim2.new(0.4, 4, 0, 0) and track.Size == UDim2.new(0.6, -4, 1, 0), "4 px gap after the indicator")
	assert(track.BackgroundColor3 == L.SecondaryContainer and stop.Size == UDim2.fromOffset(4, 4) and stop.BackgroundColor3 == L.Primary)
	assert(track.Visible == true)
	value:Set(1)
	H.finishTweens()
	assert(ind.Size == UDim2.new(1, 0, 1, 0) and track.Visible == false, "100 %: track and stop hidden")
	value:Set(0)
	H.finishTweens()
	assert(ind.Size == UDim2.new(0, 0, 1, 0) and track.Position == UDim2.new(0, 0, 0, 0) and track.Size == UDim2.new(1, 0, 1, 0), "0 %: no gap")
	value:Set(1.7)
	H.finishTweens()
	assert(ind.Size == UDim2.new(1, 0, 1, 0), "clamped")
	value:Set(-3)
	H.finishTweens()
	assert(ind.Size == UDim2.new(0, 0, 1, 0))
	assert(H.find(ind, "_quad_round").CornerRadius == UDim.new(0.5, 0) or #class(ind, "UICorner") == 1)
	assert(beats() == baseBeats, "determinate has no frame loop")
	q.dispose(bar)
	H.assertNoDebugOutput("linear determinate")
end)

H.section("Linear: plain Value, Visible, Modifier overrides the base", function()
	local bar = Progress.LinearProgress({
		Value = 0.5,
		Visible = false,
		Modifier = FrameModifier():Size(UDim2.fromOffset(200, 6)),
	})
	assert(bar.Visible == false and bar.Size == UDim2.fromOffset(200, 6))
	assert(H.find(bar, "Indicator").Size == UDim2.new(0.5, 0, 1, 0))
	q.dispose(bar)
	H.assertNoDebugOutput("linear plain")
end)

H.section("Linear indeterminate: loop connects on mount, runs, hides, disconnects on dispose", function()
	local visible = q.Source(true)
	local bar = Progress.LinearProgress({ Visible = visible })
	assert(beats() == baseBeats, "built but not mounted under a LayerCollector: no Heartbeat connection")
	local _, gui = live(bar)
	assert(H.countDescendants(bar) == 5, "host UICorner + 2 bars + 2 UICorner")
	assert(bar.BackgroundColor3 == L.SecondaryContainer and bar.BackgroundTransparency == 0, "host is the track")
	assert(beats() == baseBeats + 1, "one Heartbeat connection after mount")
	local b1, b2 = H.find(bar, "Bar1"), H.find(bar, "Bar2")
	assert(b1.Visible == false and b2.Visible == false)
	H.advance(0.6) -- phase .3: bar 1 sweeping (head .5 * ... smooth), bar 2 not started
	assert(b1.Visible == true and b2.Visible == false)
	assert(b1.Size.X.Scale > 0 and b1.Position.X.Scale >= 0 and b1.Position.X.Scale + b1.Size.X.Scale <= 1 + 1e-6)
	local s1 = b1.Position.X.Scale
	H.advance(0.3) -- phase .45: both bars
	assert(b2.Visible == true and b1.Position.X.Scale ~= s1)
	H.advance(0.2)
	local snapshot = b1.Position.X.Scale
	-- hiding stops the loop and holds the geometry
	visible:Set(false)
	assert(bar.Visible == false and beats() == baseBeats, "hidden: disconnected")
	H.advance(0.5)
	assert(b1.Position.X.Scale == snapshot, "nothing moves while hidden")
	visible:Set(true)
	assert(beats() == baseBeats + 1)
	H.advance(0.2)
	-- bars stay inside the track at every phase
	for _ = 1, 40 do
		H.advance(0.05)
		for _, b in { b1, b2 } do
			if b.Visible then
				assert(b.Position.X.Scale >= 0 and b.Position.X.Scale + b.Size.X.Scale <= 1 + 1e-6, "bar inside the track")
			end
		end
	end
	q.dispose(gui)
	assert(beats() == baseBeats, "disposed: disconnected")
	H.advance(1)
	H.assertNoDebugOutput("linear indeterminate")
end)

local Circular = require("../src/Progress/Circular")
local OVERLAP = Circular.OVERLAP

-- inverse of Circular.cellRect: (thickness index 1..4, bit 0..8) of a piece
local function cellOf(piece: any): (number, number)
	local o = piece.ImageRectOffset
	local i = ((o.X - 5) // 170) * 6 + (o.Y - 5) // 170
	return i // 9 + 1, i % 9
end
-- the shown pieces of one arc ("Arc" = indicator, "Track"): { rot, deg }
local function shownPieces(host: any, prefix: string): { { rot: number, deg: number } }
	local out: { { rot: number, deg: number } } = {}
	local labels = H.findAll(host, function(x: any): boolean
		return x.ClassName == "ImageLabel" and string.match(x.Name, "^" .. prefix .. "%d+$") ~= nil
	end)
	for _, c in labels do
		local _, bit = cellOf(c)
		assert(tonumber(string.sub(c.Name, #prefix + 1)) == 2 ^ bit, "piece name = its cell's angle: " .. c.Name)
		if c.Visible then
			table.insert(out, { rot = c.Rotation, deg = 2 ^ bit })
		end
	end
	return out
end
-- follow the pieces end to end from `a` (each starts where the previous one's NOMINAL angle ends); every shown piece
-- must be used; returns the drawn end (the last piece's overhang included) and the piece count
local function chain(pieces: { { rot: number, deg: number } }, a: number): (number, number)
	local left = table.clone(pieces)
	local at, drawnEnd, count = a, a, 0
	while #left > 0 do
		local found = nil
		for i, p in left do
			if math.abs((p.rot - at + 180) % 360 - 180) < 1e-6 then
				found = i
				break
			end
		end
		assert(found ~= nil, "no piece starts at " .. at)
		local p = table.remove(left, found :: number) :: { rot: number, deg: number }
		drawnEnd = at + p.deg + OVERLAP
		at += p.deg
		count += 1
	end
	return drawnEnd, count
end
-- a cap centred on the stroke's centre line at `angle` (Scale only)
local function capAt(cap: any, rho: number, angle: number): boolean
	local a = math.rad(angle)
	local p = cap.Position
	return p.X.Offset == 0 and p.Y.Offset == 0 and math.abs(p.X.Scale - (0.5 + rho * math.sin(a))) < 1e-5
		and math.abs(p.Y.Scale - (0.5 - rho * math.cos(a))) < 1e-5
end
-- one arc drawn from `a` over `span` (Circular.luau "ONE ARC"): pieces, caps, count
local function checkArc(host: any, prefix: string, a: number, span: number, rho: number, what: string)
	local pieces = shownPieces(host, prefix)
	local s, e = H.find(host, prefix .. "Start"), H.find(host, prefix .. "End")
	if span <= 0 then
		assert(#pieces == 0 and not s.Visible and not e.Visible, what .. ": nothing drawn")
	elseif span >= 360 then
		local drawnEnd, n = chain(pieces, a)
		assert(math.abs(drawnEnd - (a + 360 + OVERLAP)) < 1e-6 and n == 4, what .. ": closed ring of 4 pieces, laps the join")
		assert(not s.Visible and not e.Visible, what .. ": no ends on a closed ring")
	else
		local drawnEnd, n = chain(pieces, a)
		if span > OVERLAP then
			assert(math.abs(drawnEnd - (a + span)) < 1e-6, `{what}: ink ends at {drawnEnd}, want {a + span}`)
		else
			assert(n == 0, what .. ": shorter than a piece: caps only")
		end
		assert(n <= 9, what .. ": at most 9 pieces, got " .. n)
		assert(s.Visible and e.Visible and capAt(s, rho, a % 360) and capAt(e, rho, (a + span) % 360), what .. ": caps at both ends")
	end
end

H.section("Circular pure rules: sheet cells, thickness pick, step, gap, layout, indeterminate pose", function()
	assert(Circular.cellRect(1, 0) == Vector2.new(5, 5) and Circular.cellRect(1, 5) == Vector2.new(5, 855))
	assert(Circular.cellRect(1, 6) == Vector2.new(175, 5) and Circular.cellRect(2, 0) == Vector2.new(175, 515))
	assert(Circular.cellRect(4, 8) == Vector2.new(855, 855), "cell 35: the last one")
	assert(Circular.SHEET_IMAGE == "rbxassetid://97823357785454", "the IMAGE id, not the Decal 92434906460089")
	local pick = Circular.pickThickness
	assert(pick(40, 2) == 1 and pick(40, 4) == 2 and pick(40, 6) == 3 and pick(40, 8) == 4)
	assert(pick(40, 1) == 1 and pick(40, 20) == 4 and pick(24, 3) == 2, "nearest; 0.125 is a tie -> the thinner 0.10")
	assert(Circular.stepFor(40, 0.1) == 2 and Circular.stepFor(129, 0.1) == 2 and Circular.stepFor(130, 0.1) == 1)
	assert(Circular.stepFor(122, 0.05) == 2 and Circular.stepFor(123, 0.05) == 1 and Circular.stepFor(146, 0.2) == 1)
	assert(near(Circular.centreRadius(0.1), 71 / 160))
	local gap = Circular.gapAngle
	assert(gap(40, 0.05, 2) == 18 and gap(40, 0.1, 2) == 22 and gap(40, 0.15, 2) == 28 and gap(40, 0.2, 2) == 34)
	local function lay(e: number, a: number, b: number, c: number)
		local x, y, z = Circular.layout(e, 22)
		assert(x == a and y == b and z == c, `layout({e}) = {x}, {y}, {z}`)
	end
	lay(0, 0, 0, 360)
	lay(4, 4, 8, 348) -- below the gap: the gap shrinks to the sweep (Compose min(sweep, gapSweep))
	lay(100, 100, 122, 216)
	lay(314, 314, 336, 2)
	lay(316, 316, 338, 0) -- track gone
	lay(360, 360, 0, 0)
	local pose = Circular.indeterminatePose
	local t0, p0 = pose(0)
	assert(t0 == 0 and near(p0, 0.1))
	local t1, p1 = pose(0.15)
	assert(near(t1, 27 + 45) and near(p1, 0.1 + 0.77 * 0.05), "global 180 deg/s + half of the first 90 deg jump")
	local t2, p2 = pose(1)
	assert(near(t2, 270) and near(p2, 0.1 + 0.77 / 3))
	local t3, p3 = pose(3)
	assert(near(t3, 0) and near(p3, 0.87), "540 + 2 jumps = 720: back at 12 o'clock, longest arc")
	local _, p4 = pose(6 - 1e-9)
	assert(math.abs(p4 - 0.1) < 1e-6, "the cycle closes")
end)

H.section("Circular determinate: sprite pieces + round caps, gap, every 2 degree step covered exactly", function()
	local value = q.Source(0.25)
	local c = Progress.CircularProgress({ Value = value })
	local count = H.countDescendants(c)
	print("Circular determinate instances: " .. (count + 1))
	H.resetOutput()
	assert(count == 24, "2 arcs x (8 pieces + 2 caps x (Frame + UICorner)) = 24, got " .. count)
	assert(c.Size == UDim2.fromOffset(40, 40) and c.BackgroundTransparency == 1)
	assert(#class(c, "UIStroke") == 0 and #class(c, "UIGradient") == 0 and #class(c, "CanvasGroup") == 0)
	assert(#H.findAll(c, function(x: any)
		return x.ClipsDescendants == true
	end) == 0, "no clipping")
	local p = H.find(c, "Arc64")
	assert(p.Image == "rbxassetid://97823357785454" and p.ImageRectSize == Vector2.new(160, 160) and p.ScaleType == Enum.ScaleType.Stretch)
	assert(p.Size == UDim2.fromScale(1, 1) and p.ImageColor3 == L.Primary and p.ZIndex == 2)
	assert(H.find(c, "Track64").ImageColor3 == L.SecondaryContainer and H.find(c, "Track64").ZIndex == 1, "track under the indicator")
	assert(select(1, cellOf(p)) == 2, "default 40 / 4 -> the 0.10 stroke")
	assert(H.find(c, "Arc1") == nil, "no 1 degree piece at step 2")
	for _, name in { "ArcStart", "ArcEnd", "TrackStart", "TrackEnd" } do
		local cap = H.find(c, name)
		assert(cap.Size == UDim2.fromScale(0.1, 0.1) and cap.AnchorPoint == Vector2.new(0.5, 0.5) and #class(cap, "UICorner") == 1)
	end
	assert(H.find(c, "ArcStart").BackgroundColor3 == L.Primary and H.find(c, "TrackEnd").BackgroundColor3 == L.SecondaryContainer)
	local rho = Circular.centreRadius(0.1)
	checkArc(c, "Arc", 0, 90, rho, "25 %")
	checkArc(c, "Track", 112, 360 - 90 - 44, rho, "25 % track")
	assert(beats() == baseBeats, "at rest: no frame loop")
	q.dispose(c)
	-- every quantised sweep, built fresh (construction draws without a loop)
	for e = 0, 360, 2 do
		local ring = Progress.CircularProgress({ Value = e / 360 })
		local ispan, ts, tspan = Circular.layout(e, 22)
		checkArc(ring, "Arc", 0, ispan, rho, `sweep {e}`)
		checkArc(ring, "Track", ts, tspan, rho, `sweep {e} track`)
		if e > 0 and e < 360 and tspan > 0 then
			assert(ts - e == math.min(e, 22), "the gap after the indicator")
			assert(360 - (ts + tspan) == math.min(e, 22), "the same gap before 12 o'clock")
		end
		q.dispose(ring)
	end
	-- a big ring quantises to 1 degree and has the 1 degree piece
	local big = Progress.CircularProgress({ Value = 0.5, Size = 200, Thickness = 20 })
	assert(H.countDescendants(big) == 26, "9 pieces per arc at step 1")
	local bigRho = Circular.centreRadius(0.1)
	for e = 1, 359, 7 do
		local r = Progress.CircularProgress({ Value = e / 360, Size = 200, Thickness = 20 })
		local g = Circular.gapAngle(200, 0.1, 1)
		local ispan, ts, tspan = Circular.layout(e, g)
		checkArc(r, "Arc", 0, ispan, bigRho, `big sweep {e}`)
		checkArc(r, "Track", ts, tspan, bigRho, `big sweep {e} track`)
		q.dispose(r)
	end
	q.dispose(big)
	H.assertNoDebugOutput("circular determinate")
end)

H.section("Circular determinate: a Value change eases (Medium2) in a Heartbeat that stops when it lands", function()
	local value = q.Source(0.25)
	local shown = q.Source(true)
	local c, gui = live(Progress.CircularProgress({ Value = value, Visible = shown }))
	local rho = Circular.centreRadius(0.1)
	assert(beats() == baseBeats, "mounted at rest: no loop")
	local track256 = H.find(c, "Track256")
	value:Set(0.75)
	assert(beats() == baseBeats + 1, "moving: one loop")
	H.advance(0.1)
	local arcEnd = (H.find(c, "ArcEnd") :: any)
	local mid = nil
	for e = 92, 268, 2 do
		if capAt(arcEnd, rho, e) then
			mid = e
		end
	end
	assert(mid ~= nil and mid > 90 and mid < 270, "part way")
	local ispan, ts, tspan = Circular.layout(mid :: number, 22)
	checkArc(c, "Arc", 0, ispan, rho, "mid-tween")
	checkArc(c, "Track", ts, tspan, rho, "mid-tween track")
	H.advance(0.25)
	checkArc(c, "Arc", 0, 270, rho, "landed")
	assert(beats() == baseBeats, "landed: the loop stops")
	-- a nudge keeps the big pieces (largest first from the fixed end): only the small ones near the moving end turn
	local arc256, trackRot = H.find(c, "Arc256"), nil
	value:Set(30 / 360) -- track 52..338: 286 = 2 + 256 + 16 + 8 + 4
	H.advance(0.4)
	trackRot = track256.Rotation
	assert(track256.Visible and arc256.Visible == false and near(trackRot, 338 - 2 - 256))
	value:Set(40 / 360) -- track 62..338: 276 = 2 + 256 + 16 + 2
	H.advance(0.4)
	assert(track256.Visible and track256.Rotation == trackRot, "the track's 256 piece stays put (anchored at the track end)")
	-- reversal mid-way continues from where it is
	value:Set(1)
	H.advance(0.1)
	value:Set(0)
	H.advance(0.4)
	checkArc(c, "Arc", 0, 0, rho, "back to 0")
	checkArc(c, "Track", 0, 360, rho, "0 %: closed track")
	assert(beats() == baseBeats)
	-- hidden while moving: the loop stops and resumes from the same place
	value:Set(1)
	H.advance(0.05)
	shown:Set(false)
	assert(beats() == baseBeats, "hidden: no loop")
	shown:Set(true)
	H.advance(0.4)
	checkArc(c, "Arc", 0, 360, rho, "100 %: closed ring")
	checkArc(c, "Track", 0, 0, rho, "100 %: no track")
	assert(beats() == baseBeats)
	-- clamped
	value:Set(-2)
	H.advance(0.4)
	checkArc(c, "Arc", 0, 0, rho, "clamped low")
	q.dispose(gui)
	assert(beats() == baseBeats)
	H.assertNoDebugOutput("circular tween")
end)

H.section("Circular: Thickness picks one of four sheet strokes; caps follow the drawn stroke", function()
	for i, t in { 2, 4, 6, 8 } do
		local c = Progress.CircularProgress({ Value = 0.5, Thickness = t })
		local ratio = Circular.THICK[i]
		local labels = H.findAll(c, function(x: any): boolean
			return x.ClassName == "ImageLabel"
		end)
		for _, pc in labels do
			assert(select(1, cellOf(pc)) == i, `Thickness {t}: every piece from row {i}`)
		end
		assert(H.find(c, "ArcEnd").Size == UDim2.fromScale(ratio, ratio), "cap diameter = the drawn stroke")
		local g = Circular.gapAngle(40, ratio, 2)
		checkArc(c, "Track", 180 + g, 180 - 2 * g, Circular.centreRadius(ratio), `Thickness {t} track`)
		q.dispose(c)
	end
	local small = Progress.CircularProgress({ Value = 0.5, Size = 24, Thickness = 3 })
	assert(small.Size == UDim2.fromOffset(24, 24) and select(1, cellOf(H.find(small, "Arc128"))) == 2, "3 / 24 -> 0.10 (2.4 px drawn)")
	q.dispose(small)
	H.assertNoDebugOutput("circular thickness")
end)

H.section("Circular indeterminate: one arc (no track) 10 %..87 % turning from Heartbeat; lifecycle", function()
	local visible = q.Source(true)
	local c, gui = live(Progress.CircularProgress({ Visible = visible, Size = 32 }))
	local n = H.countDescendants(c)
	print("Circular indeterminate instances: " .. (n + 1))
	H.resetOutput()
	assert(n == 12, "8 pieces + 2 caps x (Frame + UICorner) = 12, got " .. n)
	assert(H.find(c, "Track2") == nil and H.find(c, "TrackStart") == nil, "no track (Compose: transparent)")
	assert(beats() == baseBeats + 1)
	local rho = Circular.centreRadius(0.1) -- 4 / 32 = 0.125: a tie -> 0.10
	checkArc(c, "Arc", 0, 36, rho, "pose 0")
	local s = H.find(c, "ArcStart")
	local lo: number, hi: number = math.huge, -math.huge
	local clock = 0
	for _ = 1, 200 do
		H.advance(1 / 30)
		clock += 1 / 30
		local tail, p = Circular.indeterminatePose(clock)
		local span = math.round(p * 180) * 2
		checkArc(c, "Arc", tail, span, rho, "t " .. clock)
		assert(span >= 36 and span <= 314, "arc 10 %..87 %")
		lo = math.min(lo, span)
		hi = math.max(hi, span)
	end
	assert(lo <= 40 and hi >= 310, `breathes {lo}..{hi}`)
	visible:Set(false)
	assert(beats() == baseBeats and c.Visible == false)
	local frozen = s.Position
	H.advance(1)
	assert(s.Position == frozen, "frozen while hidden")
	visible:Set(true)
	assert(beats() == baseBeats + 1)
	H.advance(1 / 30)
	clock += 1 / 30
	local tail, p = Circular.indeterminatePose(clock)
	checkArc(c, "Arc", tail, math.round(p * 180) * 2, rho, "resumed on its own clock")
	q.dispose(gui)
	assert(beats() == baseBeats)
	H.assertNoDebugOutput("circular indeterminate")
end)

H.section("A-M1 the loop follows the host's ancestry: detaching the subtree disconnects, re-mounting reconnects", function()
	local bar, gui = live(Progress.LinearProgress({}))
	assert(beats() == baseBeats + 1)
	bar.Parent = nil
	local anyBar: any = bar
	anyBar.AncestryChanged:Fire(bar, nil)
	assert(beats() == baseBeats, "detached: no loop")
	local gui2 = ScreenGui {}
	bar.Parent = gui2
	anyBar.AncestryChanged:Fire(bar, gui2)
	assert(beats() == baseBeats + 1, "re-mounted: loop again")
	bar:Destroy()
	assert(beats() == baseBeats)
	q.dispose(gui)
	q.dispose(gui2)
	H.assertNoDebugOutput("ancestry")
end)

H.section("a mixed tree: two loops, determinate ones hold no connection, dispose leaves none", function()
	local root, gui = live(Frame {
		Progress.LinearProgress({}),
		Progress.CircularProgress({}),
		Progress.LinearProgress({ Value = 0.3 }),
		Progress.CircularProgress({ Value = 0.3 }),
	})
	assert(beats() == baseBeats + 2)
	H.advance(0.4)
	local all = H.findAll(root, function()
		return true
	end)
	q.dispose(gui)
	assert(beats() == baseBeats)
	for _, i in all do
		assert(H.isDestroyed(i), "undestroyed: " .. i.Name)
	end
	H.advance(2)
	assert(H.pendingTimers() == 0)
	H.assertNoDebugOutput("mixed dispose")
end)

H.section("LoadingIndicator: 8 instances, morphs + turns from Heartbeat while mounted and visible, Contained colors", function()
	local visible = q.Source(true)
	local ind = Progress.LoadingIndicator({ Visible = visible })
	assert(ind.Name == "LoadingIndicator" and ind.Size == UDim2.fromOffset(48, 48))
	local n = H.countDescendants(ind)
	print("LoadingIndicator instances: " .. (n + 1))
	H.resetOutput()
	assert(n == 7, "UICorner + 3 x (shape + UICorner) = 7, got " .. n)
	assert(ind.BackgroundTransparency == 1, "uncontained: no container")
	local s1, s2 = H.find(ind, "Shape1"), H.find(ind, "Shape2")
	assert(s1.BackgroundColor3 == L.Primary)
	assert(beats() == baseBeats, "not mounted: no loop")
	local _, gui = live(ind)
	assert(beats() == baseBeats + 1)
	H.advance(0.3)
	local r0 = s1.Rotation
	assert(r0 > 0, "it turns")
	-- the shape stays inside its 38 px box (spring overshoot is bounded by the sizes)
	for _ = 1, 60 do
		H.advance(0.05)
		for _, f in { s1, s2, H.find(ind, "Shape3") } :: { any } do
			assert(f.Size.X.Offset <= 38 * 1.15 and f.Size.Y.Offset <= 38 * 1.15, "inside the shape box: " .. tostring(f.Size))
			local c = class(f, "UICorner")[1]
			assert(c.CornerRadius.Scale >= 0 and c.CornerRadius.Scale <= 0.5)
		end
	end
	visible:Set(false)
	assert(beats() == baseBeats, "hidden: loop off")
	q.dispose(gui)
	-- the pose: a full cycle of six morphs returns to the first keyframe's shape
	local Loading = require("../src/Progress/LoadingIndicator")
	local p: any = { r1 = 0, r2 = 0, r3 = 0, w = 0, h = 0, c = 0 }
	Loading.pose(11 * 0.65 + 0.649, p) -- the end of the 12th morph (keyframe 6 -> 1): settled on keyframe 1
	local k1 = Loading.Keys[1]
	assert(math.abs(p.c - k1.c) < 0.01 and math.abs(p.w - k1.w) < 0.01, "cycle returns to the burst")
	assert(math.abs(((p.r2 - p.r1) % 360) - k1.o2) < 0.5, "burst offsets restored")
	-- contained
	local boxed = Progress.LoadingIndicator({ Contained = true, Size = 64 })
	assert(boxed.Size == UDim2.fromOffset(64, 64) and boxed.BackgroundTransparency == 0 and boxed.BackgroundColor3 == L.PrimaryContainer)
	assert(H.find(boxed, "Shape1").BackgroundColor3 == L.OnPrimaryContainer)
	q.dispose(boxed)
	H.assertNoDebugOutput("loading indicator")
end)

local Wavy = require("../src/Progress/Wavy")

-- the drawn curve at host x (Wavy.luau "ROUND ENDS"): Thickness 4 -> r 2, height 10 -> centre 5, Wavelength 40
local function curve(x: number, phase: number, amp: number): number
	return 5 - amp * math.sin(2 * math.pi * ((x - 2) / 40 + phase))
end
-- the strip's slide gives the phase the loop used this frame
local function phaseOf(strip: any): number
	return (-strip.Position.X.Offset / 40) % 1
end
-- the sheet frame shown by a period (inverse of Wavy.frameRect)
local function frameOf(period: any): number
	local o = period.ImageRectOffset
	return ((o.X - 16) // 512) * 12 + (o.Y - 10) // 85
end
-- a cap's centre y in px: its Position is a Scale of `Wave`'s fixed height 10 (an Offset would truncate); a UDim
-- Scale is a float32, so compare to 1e-4 px
local function capY(cap: any): number
	return cap.Position.Y.Scale * 10
end
local function nearPx(a: number, b: number): boolean
	return math.abs(a - b) < 1e-4
end
local function periods(bar: any): { any }
	return H.findAll(bar, function(c: any)
		return c.Name == "Period"
	end)
end

H.section("WavyProgress: Stretch periods of a sheet cell clipped to the value, round caps on the curve, gap + track + stop, strip slides", function()
	local value = q.Source(0.5)
	local shown = q.Source(true)
	local bar = Progress.WavyProgress({ Value = value, Visible = shown })
	assert(bar.Size == UDim2.new(1, 0, 0, 10), "height = 2.5 x Thickness 4")
	local wave, clip, track, strip = H.find(bar, "Wave"), H.find(bar, "Clip"), H.find(bar, "Track"), H.find(bar, "Strip")
	local s, e = H.find(bar, "Start"), H.find(bar, "End")
	assert(wave.ClipsDescendants ~= true and clip.ClassName == "Frame" and clip.ClipsDescendants == true, "plain clip, no CanvasGroup")
	assert(clip.Position == UDim2.fromOffset(2, 0) and clip.Size == UDim2.new(1, -4, 1, 0), "clip inset by the cap radius at both ends")
	local p0 = periods(bar)[1]
	assert(p0.ClassName == "ImageLabel" and p0.ScaleType == Enum.ScaleType.Stretch, "one Stretch period (Tile cannot show a sheet cell)")
	assert(p0.Size == UDim2.fromOffset(40, 10) and p0.Image == "rbxassetid://96568777229073", "the amplitude sheet")
	assert(p0.ImageRectSize == Vector2.new(480, 64) and frameOf(p0) == 0, "one cell, full amplitude")
	assert(p0.ImageColor3 == L.Primary and H.find(track, "Stop").BackgroundColor3 == L.Primary)
	for _, cap in { s, e } :: { any } do
		assert(cap.Size == UDim2.fromOffset(4, 4) and cap.AnchorPoint == Vector2.new(0.5, 0.5) and cap.BackgroundColor3 == L.Primary)
		assert(#class(cap, "UICorner") == 1 and cap.Visible == true and cap.Parent == wave)
	end
	assert(s.Position == UDim2.new(0, 2, 0.5, 0), "start cap at phase 0: on the centre line")
	H.finishTweens()
	assert(wave.Size == UDim2.new(0.5, 0, 0, 10) and track.Position == UDim2.new(0.5, 4, 0.5, 0) and track.Size == UDim2.new(0.5, -4, 0, 4))
	assert(H.countDescendants(bar) == 12, "host + 11 + 1 period before layout: " .. H.countDescendants(bar))
	H.setAbs(bar, 0, 0, 300, 10)
	local _, gui = live(bar)
	-- several frames: the caps follow the curve at the strip's phase, full amplitude 3
	local function capsOnCurve(len: number, what: string)
		local ph = phaseOf(strip)
		assert(s.Position.X == UDim.new(0, 2) and s.Position.Y.Offset == 0 and nearPx(capY(s), curve(2, ph, 3)), what .. ": start cap " .. tostring(s.Position))
		assert(e.Position.X == UDim.new(1, -2) and nearPx(capY(e), curve(len - 2, ph, 3)), what .. ": end cap " .. tostring(e.Position).. " want " .. curve(len - 2, ph, 3))
	end
	H.advance(0.25)
	assert(#periods(bar) == 9 and strip.Size == UDim2.new(0, 360, 1, 0), "ceil(300 / 40) + 1 periods")
	assert(H.countDescendants(bar) == 20, "12 + 8 more periods at 300 px: " .. H.countDescendants(bar))
	assert(strip.Position == UDim2.fromOffset(-10, 0), "a quarter wavelength travelled in 0.25 s: " .. tostring(strip.Position))
	assert(nearPx(capY(s), 2), "phase 1/4: the start cap at the crest (5 - 3)")
	capsOnCurve(150, "0.25 s")
	for n = 1, 7 do
		H.advance(0.13)
		capsOnCurve(150, "frame " .. n)
	end
	-- the fill changes: the end cap rides the clip's end (x through the layout, y at the new length)
	value:Set(0.8)
	H.finishTweens()
	H.advance(1 / 60)
	assert(wave.Size == UDim2.new(0.8, 0, 0, 10))
	capsOnCurve(240, "Value 0.8")
	-- shorter than a cap: no clip, both caps on one dot at x = r
	value:Set(0.005)
	H.finishTweens()
	H.advance(1 / 60)
	assert(clip.Visible == false and s.Visible and e.Visible, "L = 1.5 < 2r: the clip hides, the dot stays")
	assert(e.Position == s.Position and s.Position.X == UDim.new(0, 2) and nearPx(capY(s), curve(2, phaseOf(strip), 3)))
	value:Set(0)
	H.finishTweens()
	H.advance(1 / 60)
	assert(s.Visible == false and e.Visible == false and clip.Visible == false, "0 %: nothing drawn")
	value:Set(0.5)
	H.finishTweens()
	H.advance(1 / 60)
	assert(s.Visible and e.Visible and clip.Visible)
	capsOnCurve(150, "back to 0.5")
	-- hidden: the loop stops, strip and caps freeze together
	shown:Set(false)
	assert(beats() == baseBeats, "hidden: loop off")
	local sp, ep, xp = s.Position, e.Position, strip.Position
	H.advance(0.3)
	assert(s.Position == sp and e.Position == ep and strip.Position == xp, "frozen while hidden")
	shown:Set(true)
	H.advance(1 / 60)
	capsOnCurve(150, "shown again")
	value:Set(1)
	H.finishTweens()
	H.advance(1 / 60)
	assert(track.Visible == false and wave.Size == UDim2.new(1, 0, 0, 10))
	q.dispose(gui)
	assert(beats() == baseBeats)
	local thick = Progress.WavyProgress({ Value = 0.5, Thickness = 6, Wavelength = 60 })
	assert(thick.Size == UDim2.new(1, 0, 0, 15) and periods(thick)[1].Size == UDim2.fromOffset(60, 15))
	assert(H.find(thick, "Start").Size == UDim2.fromOffset(6, 6) and H.find(thick, "Clip").Size == UDim2.new(1, -6, 1, 0))
	H.finishTweens()
	assert(H.find(thick, "Track").Size == UDim2.new(0.5, -4, 0, 6), "track = Thickness")
	q.dispose(thick)
	assert(not pcall(function()
		Progress.WavyProgress({} :: any)
	end), "Value is required")
	H.assertNoDebugOutput("wavy")
end)

H.section("WavyProgress amplitude sheet: frame cells, Wavy off/on and Value 1 flatten 0 -> 23 and back, caps at the frame's amplitude, flat sleeps", function()
	assert(Wavy.frameRect(0) == Vector2.new(16, 10) and Wavy.frameRect(11) == Vector2.new(16, 945))
	assert(Wavy.frameRect(12) == Vector2.new(528, 10) and Wavy.frameRect(23) == Vector2.new(528, 945) and Wavy.LAST == 23)
	local value = q.Source(0.5)
	local wavy = q.Source(true)
	local bar = Progress.WavyProgress({ Value = value, Wavy = wavy })
	local p0 = periods(bar)[1]
	assert(frameOf(p0) == 0, "full amplitude at mount")
	local strip, s, e = H.find(bar, "Strip"), H.find(bar, "Start"), H.find(bar, "End")
	H.finishTweens()
	H.setAbs(bar, 0, 0, 300, 10)
	local _, gui = live(bar)
	H.advance(0.1)
	local function check(what: string)
		local i = frameOf(periods(bar)[1])
		for _, p in periods(bar) do
			assert(frameOf(p) == i, what .. ": every period on the same frame")
		end
		local amp = 3 * (1 - i / 23)
		local ph = if i < 23 then phaseOf(strip) else 0
		local len = H.find(bar, "Wave").Size.X.Scale * bar.AbsoluteSize.X
		assert(nearPx(capY(s), curve(2, ph, amp)) and nearPx(capY(e), curve(len - 2, ph, amp)), what .. ": caps at A(" .. i .. ")")
		return i
	end
	-- run a transition frame by frame: monotone, lands within Long2 (0.5 s) + a frame
	local function transition(toward: number, what: string)
		local last = frameOf(periods(bar)[1])
		local seen = {}
		for n = 1, 40 do
			H.advance(1 / 60)
			local i = check(what .. " frame " .. n)
			assert(if toward == 23 then i >= last else i <= last, what .. ": monotone")
			seen[i] = true
			last = i
			if i == toward then
				assert(n <= 31, what .. ": within 0.5 s (" .. n .. " frames)")
				break
			end
		end
		assert(last == toward, what .. ": landed on " .. toward .. ", got " .. last)
		local inner = 0
		for i in seen do
			if i ~= 0 and i ~= 23 then
				inner += 1
			end
		end
		assert(inner >= 10, what .. ": stepped through the frames (" .. inner .. " in between)")
	end
	wavy:Set(false)
	transition(23, "Wavy off")
	assert(nearPx(capY(s), 5) and nearPx(capY(e), 5), "flat: caps on the centre line")
	assert(beats() == baseBeats, "flat and landed: the loop sleeps")
	local xp = strip.Position
	H.advance(0.3)
	assert(strip.Position == xp, "asleep: nothing moves")
	wavy:Set(true)
	assert(beats() == baseBeats + 1, "Wavy on wakes the loop")
	transition(0, "Wavy on")
	-- complete: M3 flattens the finished bar
	value:Set(1)
	H.finishTweens()
	transition(23, "Value 1")
	assert(beats() == baseBeats)
	-- a resize wakes it (more periods may be needed), and it sleeps again
	H.setAbs(bar, 0, 0, 400, 10)
	assert(beats() == baseBeats + 1, "resize wakes")
	H.advance(1 / 60)
	assert(#periods(bar) == 11 and frameOf(periods(bar)[11]) == 23, "the new periods join on the current frame")
	assert(beats() == baseBeats, "asleep again")
	value:Set(0.5)
	assert(beats() == baseBeats + 1, "a Value below 1 wakes it")
	H.finishTweens()
	H.setAbs(bar, 0, 0, 300, 10)
	transition(0, "Value 0.5 again")
	-- a Value a float32 Scale cannot hold exactly still lets it sleep
	value:Set(0.3)
	H.finishTweens()
	wavy:Set(false)
	transition(23, "Wavy off at 0.3")
	assert(beats() == baseBeats, "asleep at 0.3")
	-- built complete: snapped flat, no swell on mount
	local done = Progress.WavyProgress({ Value = 1 })
	assert(frameOf(periods(done)[1]) == 23)
	q.dispose(done)
	q.dispose(gui)
	assert(beats() == baseBeats)
	H.assertNoDebugOutput("wavy sheet")
end)

H.done()
