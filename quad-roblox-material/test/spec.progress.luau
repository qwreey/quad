--!strict
local H = require("./support/harness")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
local D = q.Declaration
local Tokens = require("../src/Tokens")
local Progress = require("../src/Progress")

local L = Tokens.Color.Light

local function beats(): number
	return #(H.RunService :: any).Heartbeat.connections
end
local baseBeats = beats()

-- The loop only runs under a LayerCollector (ScreenGui, SurfaceGui, BillboardGui, plugin GUIs). The mock does not fire AncestryChanged on re-parenting, so
-- `live(host)` seats the host in a ScreenGui and fires the event the engine would.
local function live<T>(host: T): (T, any)
	local gui = D.ScreenGui { host :: any }
	for _, d in H.findAll(gui, function()
		return true
	end) do
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
		Modifier = D.Modifier.Frame():Size(UDim2.fromOffset(200, 6)),
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

H.section("Circular determinate: ring + two half-plane gradients", function()
	local value = q.Source(0.25)
	local c = Progress.CircularProgress({ Value = value })
	local count = H.countDescendants(c)
	print("Circular determinate instances: " .. (count + 1))
	H.resetOutput()
	assert(count == 13, "track (3) + 2 x (clip, ring, corner, stroke, gradient) = 13, got " .. count)
	assert(c.Size == UDim2.fromOffset(40, 40) and c.BackgroundTransparency == 1)
	local track = H.find(c, "Track")
	assert(H.find(track, "Stroke").Color == L.SecondaryContainer and H.find(track, "Stroke").Thickness == 4)
	local right, left = H.find(c, "ClipRight"), H.find(c, "ClipLeft")
	assert(right.ClipsDescendants == true and left.ClipsDescendants == true)
	assert(right.Position == UDim2.fromScale(0.5, 0) and right.Size == UDim2.fromScale(0.5, 1) and left.Position == UDim2.new())
	local rr, lr = H.find(right, "Ring"), H.find(left, "Ring")
	assert(rr.Size == UDim2.fromScale(2, 1) and rr.Position == UDim2.fromScale(-1, 0) and lr.Position == UDim2.new(), "rings span the full circle")
	local stroke = H.find(rr, "Stroke")
	assert(stroke.Color == L.Primary and stroke.BorderStrokePosition == Enum.BorderStrokePosition.Inner)
	local gr, gl = H.find(right, "Arc"), H.find(left, "Arc")
	local kps = gr.Transparency.Keypoints
	assert(#kps == 4 and kps[1].Value == 0 and kps[2].Value == 0 and kps[3].Value == 1 and kps[4].Value == 1 and near(kps[2].Time, 0.5), "hard step at 0.5")
	local function check(v: number, r: number, l: number)
		value:Set(v)
		H.finishTweens()
		assert(near(gr.Rotation, r) and near(gl.Rotation, l), `value {v}: right {gr.Rotation} left {gl.Rotation}, want {r}/{l}`)
	end
	check(0.25, 90, 180)
	check(0, 0, 180)
	check(0.5, 180, 180)
	check(0.75, 180, 270)
	check(1, 180, 360)
	check(2, 180, 360)
	check(-1, 0, 180)
	assert(beats() == baseBeats)
	q.dispose(c)
	H.assertNoDebugOutput("circular determinate")
end)

H.section("Circular: Size and Thickness props", function()
	local c = Progress.CircularProgress({ Value = 0.5, Size = 24, Thickness = 2 })
	assert(c.Size == UDim2.fromOffset(24, 24))
	assert(H.find(H.find(c, "ClipRight"), "Stroke").Thickness == 2)
	q.dispose(c)
	H.assertNoDebugOutput("circular props")
end)

H.section("Circular indeterminate: two unclipped rings rotate from Heartbeat; lifecycle", function()
	local visible = q.Source(true)
	local c, gui = live(Progress.CircularProgress({ Visible = visible, Size = 32 }))
	assert(H.countDescendants(c) == 11, "track (3) + 2 x (ring, corner, stroke, gradient) = 11, got " .. H.countDescendants(c))
	assert(#class(c, "CanvasGroup") == 0 and #H.findAll(c, function(x: any)
		return x.ClipsDescendants == true
	end) == 0, "no clipping under rotation")
	assert(beats() == baseBeats + 1)
	local g1, g2 = H.find(H.find(c, "Ring1"), "Arc"), H.find(H.find(c, "Ring2"), "Arc")
	assert(g1.Rotation == 0 and g2.Rotation == 0)
	H.advance(0.3)
	local r1, r2 = g1.Rotation, g2.Rotation
	assert(r1 > 0 and r2 > 0 and r1 < 360 and r2 < 360)
	assert(near(r1, 0.3 / 1.5 * 360), "one revolution per 1.5 s")
	H.advance(0.3)
	assert(g1.Rotation ~= r1 and g2.Rotation ~= r2)
	-- the head ring leads the tail ring by the breathing angle d in [0, 120]
	local seen = {} :: { number }
	for _ = 1, 30 do
		H.advance(0.05)
		local d = (g2.Rotation - g1.Rotation) % 360
		assert(d >= -1e-6 and d <= 120 + 1e-6, "arc length 180..300, got d=" .. d)
		table.insert(seen, d)
	end
	assert(math.max(table.unpack(seen)) - math.min(table.unpack(seen)) > 20, "arc breathes")
	visible:Set(false)
	assert(beats() == baseBeats and c.Visible == false)
	local frozen = g1.Rotation
	H.advance(1)
	assert(g1.Rotation == frozen)
	visible:Set(true)
	assert(beats() == baseBeats + 1)
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
	local gui2 = D.ScreenGui {}
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
	local root, gui = live(D.Frame {
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
		for _, f in { s1, s2, H.find(ind, "Shape3") } do
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

H.section("WavyProgress: tiled wave clipped to the value, gap + track + stop, strip slides, 7 instances at any width", function()
	local value = q.Source(0.5)
	local bar = Progress.WavyProgress({ Value = value })
	assert(bar.Size == UDim2.new(1, 0, 0, 10), "height = 2.5 x Thickness 4")
	local wave, track, strip = H.find(bar, "Wave"), H.find(bar, "Track"), H.find(bar, "Strip")
	assert(wave.ClassName == "Frame" and wave.ClipsDescendants == true, "nothing rotated: a plain clip, no CanvasGroup")
	assert(strip.ClassName == "ImageLabel" and strip.ScaleType == Enum.ScaleType.Tile)
	assert(strip.TileSize == UDim2.fromOffset(40, 10) and strip.Size == UDim2.new(1, 40, 1, 0), "one wavelength per tile, one spare")
	assert(strip.ImageColor3 == L.Primary and H.find(track, "Stop").BackgroundColor3 == L.Primary)
	H.finishTweens()
	assert(wave.Size == UDim2.fromScale(0.5, 1) and track.Position == UDim2.new(0.5, 4, 0.5, 0) and track.Size == UDim2.new(0.5, -4, 0, 4))
	assert(H.countDescendants(bar) == 6, "host + 6 = 7 instances at any width: " .. H.countDescendants(bar))
	H.setAbs(bar, 0, 0, 300, 10)
	local _, gui = live(bar)
	H.advance(0.25)
	assert(H.countDescendants(bar) == 6, "no growth with the width")
	assert(math.abs(strip.Position.X.Offset + 10) <= 1, "a quarter wavelength travelled in 0.25 s: " .. tostring(strip.Position))
	value:Set(1)
	H.finishTweens()
	assert(track.Visible == false and wave.Size == UDim2.fromScale(1, 1))
	q.dispose(gui)
	assert(beats() == baseBeats)
	local thick = Progress.WavyProgress({ Value = 0.5, Thickness = 6, Wavelength = 60 })
	assert(thick.Size == UDim2.new(1, 0, 0, 15) and H.find(thick, "Strip").TileSize == UDim2.fromOffset(60, 15))
	H.finishTweens()
	assert(H.find(thick, "Track").Size == UDim2.new(0.5, -4, 0, 6), "track = Thickness")
	q.dispose(thick)
	assert(not pcall(function()
		Progress.WavyProgress({} :: any)
	end), "Value is required")
	H.assertNoDebugOutput("wavy")
end)

H.done()
