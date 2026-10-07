--!strict
-- Slider: the M3 look (`src/Slider`), the M2 look (`src/M2/Slider.luau`) and the behaviour they share
-- (`src/Slider/Behavior.luau`). Behaviour sections run once per look; the shape sections are per look.
local H = require("./support/harness")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
local Tokens = require("../src/Tokens")
local Slider = require("../src/Slider")
local M2 = require("../src/M2")
local Material = require("../src")

local UIS = H.UserInputService
local function uisConns(): number
	local u = UIS :: any
	return #u.InputChanged.connections + #u.InputEnded.connections + #u.WindowFocusReleased.connections
end
local function keyConns(): number
	return #(UIS :: any).InputBegan.connections
end
local baseConns, baseKeys = uisConns(), keyConns()
local L = Tokens.Color.Light

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

-- A look under test: its constructor and its handle inset (px from a host edge to the handle center at Min / Max).
-- Every look is laid out with a 200 px RAIL starting at x = RAIL0, so the same rail fraction is the same pointer
-- position relative to the rail in both looks.
type LookCase = { Name: string, Make: (props: any) -> any, Inset: number }
local looks: { LookCase } = {
	{ Name = "M3", Make = Slider, Inset = 8 },
	{ Name = "M2", Make = M2.Slider, Inset = 10 },
}
local RAIL0 = 110
local function layout(look: LookCase, s: any)
	H.setAbs(s, RAIL0 - look.Inset, 50, 200 + 2 * look.Inset, 40)
end
local function press(s: any, x: number)
	H.fire(s, "InputBegan", H.input({ Position = Vector3.new(x, 60, 0) }))
end
local function move(x: number)
	UIS.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(x, 60, 0) }))
end
local function release(x: number)
	UIS.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(x, 60, 0) }))
end
local function key(code: any)
	UIS.InputBegan:Fire(H.input({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = code }))
end
-- px of a UDim on a host `w` wide
local function px(u: UDim, w: number): number
	return u.Scale * w + u.Offset
end

-- ── M3 shape ─────────────────────────────────────────────────────────────

H.section("M3 mount: three-part track, 4x44 bar handle, 6 px gaps, instance count", function()
	local s = Slider({ Value = q.Source(0.5) })
	assert(s.ClassName == "Frame" and s.Name == "Slider" and s.Size == UDim2.new(1, 0, 0, 44), "host 44 px tall (the handle)")
	local n = H.countDescendants(s)
	print("Slider (M3) descendants: " .. n .. " (+1 host = " .. (n + 1) .. ")")
	H.resetOutput()
	assert(n == 20, "2 outer pieces x (2 clips + 2 fills + 2 corners) + stop(2) + handle(3) + label(3) = 20, got " .. n)
	local W = 216
	H.setAbs(s, 0, 0, W, 44)
	local handle = H.find(s, "Handle")
	assert(handle.Size == UDim2.fromOffset(4, 44), "4 x 44 bar handle")
	assert(handle.Position == UDim2.new(0.5, 0, 0.5, 0), "center 8 + 200 * 0.5 = 108")
	local hx = px(handle.Position.X, W)
	-- active piece: cap [0, 8] + body [8, hx - 8]
	local aCap, aBody = H.find(s, "ActiveCap"), H.find(s, "ActiveBody")
	local iCap, iBody = H.find(s, "InactiveCap"), H.find(s, "InactiveBody")
	assert(aCap.Visible and aBody.Visible and iCap.Visible and iBody.Visible, "all pieces shown at 50 %")
	assert(px(aCap.Position.X, W) == 0 and aCap.Size == UDim2.fromOffset(8, 16), "active cap: the 8 px outer end")
	local aBodyL = px(aBody.Position.X, W)
	local aBodyR = aBodyL + px(aBody.Size.X, W)
	assert(aBodyL == 8, "body starts where the cap ends (no overlap, no seam)")
	assert(aBodyR == hx - 8, "active piece ends 6 px before the handle's left edge: " .. aBodyR)
	assert(hx - 2 - aBodyR == 6, "6 px gap on the left")
	local iBodyL = px(iBody.Position.X, W)
	local iBodyR = iBodyL + px(iBody.Size.X, W)
	assert(iBodyL - (hx + 2) == 6, "6 px gap on the right")
	assert(iBodyR == W - 8 and px(iCap.Position.X, W) == W - 8, "inactive body meets the cap at W - 8")
	assert(aBody.Size.Y.Offset == 16 and iBody.Size.Y.Offset == 16, "16 px track")
	-- rounding: each part is a rectangle clip around a rounded fill
	local clips: { any } = { aCap, aBody, iCap, iBody }
	for _, clipFrame in clips do
		assert(clipFrame.ClipsDescendants == true and clipFrame.BackgroundTransparency == 1, clipFrame.Name .. " clips")
	end
	local aCapFill, iCapFill = H.find(aCap, "Fill"), H.find(iCap, "Fill")
	assert(H.find(aCapFill, "_quad_round").CornerRadius == UDim.new(0, 8) and aCapFill.Size == UDim2.fromOffset(16, 16), "cap fill: 16 px pill, outer half kept")
	assert(aCapFill.Position == UDim2.fromOffset(0, 0) and iCapFill.Position == UDim2.fromOffset(-8, 0), "left keeps the left half, right the right half")
	local aBodyFill, iBodyFill = H.find(aBody, "Fill"), H.find(iBody, "Fill")
	assert(H.find(aBodyFill, "_quad_round").CornerRadius == UDim.new(0, 2) and H.find(iBodyFill, "_quad_round").CornerRadius == UDim.new(0, 2), "2 px inner corners")
	assert(aBodyFill.Position == UDim2.fromOffset(-2, 0) and aBodyFill.Size == UDim2.new(1, 2, 1, 0), "active body: rounded end cut on the cap side")
	assert(iBodyFill.Position == UDim2.fromOffset(0, 0) and iBodyFill.Size == UDim2.new(1, 2, 1, 0), "inactive body: rounded end cut on the cap side")
	-- colors
	assert(aCapFill.BackgroundColor3 == L.Primary and aBodyFill.BackgroundColor3 == L.Primary and handle.BackgroundColor3 == L.Primary)
	assert(iCapFill.BackgroundColor3 == L.SecondaryContainer and iBodyFill.BackgroundColor3 == L.SecondaryContainer)
	local stopDot = H.find(s, "StopEnd")
	assert(stopDot.Visible and stopDot.Size == UDim2.fromOffset(4, 4) and px(stopDot.Position.X, W) == W - 8 and stopDot.BackgroundColor3 == L.Primary, "stop dot")
	assert(H.find(s, "Label").Size.Y.Offset == 44 and H.find(s, "Label").Position == UDim2.new(0.5, 0, 0, -12), "M3 label pill 44 px, 12 px above")
	assert(H.find(s, "Label").BackgroundColor3 == L.InverseSurface)
	assert(s.Selectable == true and s.NextSelectionLeft == s and s.NextSelectionRight == s)
	assert(keyConns() == baseKeys and uisConns() == baseConns, "no global connection at rest")
	q.dispose(s)
	H.assertNoDebugOutput("m3 mount")
end)

H.section("M3 pieces hide at the ends (Compose: an outer piece no longer than its 8 px radius); before layout", function()
	local v = q.Source(0)
	local s = Slider({ Value = v, Min = 0, Max = 100 })
	assert(not H.find(s, "ActiveCap").Visible and not H.find(s, "InactiveCap").Visible, "nothing before layout (width 0)")
	H.setAbs(s, 0, 0, 216, 44)
	assert(not H.find(s, "ActiveCap").Visible and not H.find(s, "ActiveBody").Visible, "at Min: no active piece")
	assert(H.find(s, "InactiveCap").Visible and H.find(s, "StopEnd").Visible)
	v:Set(4) -- active piece 200 * 0.04 = 8 px: not longer than the radius
	assert(not H.find(s, "ActiveCap").Visible)
	v:Set(5) -- 10 px
	assert(H.find(s, "ActiveCap").Visible and H.find(s, "ActiveBody").Visible)
	v:Set(96) -- inactive piece 8 px
	assert(not H.find(s, "InactiveCap").Visible and not H.find(s, "StopEnd").Visible, "stop dot hides with its piece")
	v:Set(95)
	assert(H.find(s, "InactiveCap").Visible and H.find(s, "StopEnd").Visible)
	assert(H.find(s, "Handle").Position == UDim2.new(0.95, 8 - 16 * 0.95, 0.5, 0))
	q.dispose(s)
	H.assertNoDebugOutput("m3 hide")
end)

H.section("M3 handle narrows to 2 px while dragged / focused; focus ring on the handle", function()
	local look = looks[1]
	local s = Slider({ Value = q.Source(0), Min = 0, Max = 100 })
	layout(look, s)
	local handle = H.find(s, "Handle")
	local ring = H.find(handle, "FocusRing")
	assert(ring.ClassName == "UIStroke" and ring.Enabled == false)
	press(s, RAIL0 + 100)
	H.finishTweens()
	assert(handle.Size == UDim2.fromOffset(2, 44), "pressed / dragged: 2 px")
	release(RAIL0 + 100)
	H.fire(s, "InputEnded", H.input({}))
	H.finishTweens()
	assert(handle.Size == UDim2.fromOffset(4, 44))
	H.fire(s, "SelectionGained")
	H.finishTweens()
	assert(handle.Size == UDim2.fromOffset(2, 44) and ring.Enabled == true, "focused: 2 px + ring")
	H.fire(s, "MouseEnter")
	H.fire(s, "SelectionLost")
	H.finishTweens()
	assert(handle.Size == UDim2.fromOffset(4, 44) and ring.Enabled == false, "hover alone changes nothing (M3)")
	q.dispose(s)
	H.assertNoDebugOutput("m3 handle")
end)

H.section("M3 discrete: 4 px dots, hidden in the handle gap and at the stop dot, colors by side", function()
	local look = looks[1]
	local v = q.Source(0)
	local s = Slider({ Value = v, Min = 0, Max = 10, Step = 2 })
	layout(look, s)
	local ticks = H.findAll(s, function(c: any)
		return c.Name == "Tick"
	end)
	assert(#ticks == 5, "0,2,..,8 (the 10 is the stop dot) -> 5, got " .. #ticks)
	assert(ticks[1].Size == UDim2.fromOffset(4, 4) and H.find(ticks[1], "_quad_round") ~= nil, "4 px round dots")
	assert(not ticks[1].Visible, "the tick under the handle is hidden")
	assert(ticks[2].Visible and ticks[2].BackgroundColor3 == L.Primary, "inactive-side dot: Primary")
	press(s, RAIL0 + 85) -- 4.25 -> 4
	release(RAIL0 + 85)
	assert(v:Get() == 4)
	assert(ticks[1].Visible and ticks[1].BackgroundColor3 == L.SecondaryContainer, "active-side dot: SecondaryContainer")
	assert(not ticks[3].Visible, "4 is under the handle")
	assert(ticks[4].BackgroundColor3 == L.Primary)
	q.dispose(s)
	-- a 1-step-per-6-px slider: the neighbours of the handle fall inside its 8 px gap
	local dense = Slider({ Value = q.Source(10), Min = 0, Max = 40, Step = 1 })
	layout(look, dense) -- 5 px per step
	local dt = H.findAll(dense, function(c: any)
		return c.Name == "Tick"
	end)
	assert(#dt == 40)
	assert(not dt[10].Visible and not dt[11].Visible and not dt[12].Visible and dt[9].Visible and dt[13].Visible, "|t - f| * 200 <= 8 hidden")
	q.dispose(dense)
	H.assertNoDebugOutput("m3 ticks")
end)

H.section("M3 disabled: onSurface 38 % / 12 %", function()
	local s = Slider({ Value = q.Source(0.5), Disabled = true })
	H.setAbs(s, 0, 0, 216, 44)
	H.finishTweens()
	local aFill = H.find(H.find(s, "ActiveBody"), "Fill")
	local iFill = H.find(H.find(s, "InactiveBody"), "Fill")
	assert(aFill.BackgroundColor3 == L.OnSurface and near(aFill.BackgroundTransparency, 0.62))
	assert(iFill.BackgroundColor3 == L.OnSurface and near(iFill.BackgroundTransparency, 0.88))
	assert(H.find(s, "Handle").BackgroundColor3 == L.OnSurface and near(H.find(s, "Handle").BackgroundTransparency, 0.62))
	q.dispose(s)
	H.assertNoDebugOutput("m3 disabled")
end)

-- ── M2 shape ─────────────────────────────────────────────────────────────

H.section("M2 mount: thin track, round handle, halo, instance count", function()
	local s = M2.Slider({ Value = q.Source(0.5) })
	assert(s.ClassName == "Frame" and s.Name == "M2Slider" and s.Size == UDim2.new(1, 0, 0, 40))
	local n = H.countDescendants(s)
	print("M2.Slider descendants: " .. n .. " (+1 host = " .. (n + 1) .. ")")
	H.resetOutput()
	assert(n == 14, "Rail, 2 bars(+2 corners), Halo, layer(3), Handle(+corner), Label(+corner+padding) = 14, got " .. n)
	assert(H.find(s, "Rail").Size == UDim2.new(1, -20, 1, 0))
	assert(H.find(s, "Handle").Size == UDim2.fromOffset(20, 20) and H.find(s, "Halo").Size == UDim2.fromOffset(40, 40))
	assert(H.find(s, "Active").Size == UDim2.new(0.5, 0, 0, 4) and H.find(s, "Inactive").Size == UDim2.new(1, 0, 0, 4))
	assert(H.find(s, "Halo").Position == UDim2.fromScale(0.5, 0.5))
	assert(H.find(s, "Active").BackgroundColor3 == L.Primary and H.find(s, "Inactive").BackgroundColor3 == L.SurfaceVariant)
	assert(H.find(s, "Label").Size.Y.Offset == 28 and H.find(s, "Label").BackgroundColor3 == L.Primary, "M2 label pill")
	assert(H.find(s, "ActiveCap") == nil and H.find(s, "StopEnd") == nil, "no M3 parts")
	q.dispose(s)
	local nl = M2.Slider({ ShowLabel = false })
	assert(H.find(nl, "Label") == nil and H.countDescendants(nl) == 11)
	q.dispose(nl)
	local d = M2.Slider({ Value = q.Source(0), Min = 0, Max = 10, Step = 2 })
	local ticks = H.findAll(d, function(c: any)
		return c.Name == "Tick"
	end)
	assert(#ticks == 6 and ticks[1].Size == UDim2.fromOffset(2, 2), "M2: 2 px ticks, all six")
	assert(ticks[1].BackgroundColor3 == L.OnPrimary and ticks[6].BackgroundColor3 == L.OnSurfaceVariant)
	q.dispose(d)
	H.assertNoDebugOutput("m2 mount")
end)

H.section("M2 Source -> UI: halo and active track follow, clamped", function()
	local v = q.Source(0)
	local s = M2.Slider({ Value = v, Min = 0, Max = 100 })
	v:Set(25)
	assert(H.find(s, "Halo").Position == UDim2.fromScale(0.25, 0.5) and H.find(s, "Active").Size == UDim2.new(0.25, 0, 0, 4))
	v:Set(500)
	assert(H.find(s, "Halo").Position == UDim2.fromScale(1, 0.5), "clamped to the end")
	assert(H.find(s, "Label").Text == "500", "label shows the raw Value")
	q.dispose(s)
	H.assertNoDebugOutput("m2 source")
end)

-- ── the M2 namespace ─────────────────────────────────────────────────────

H.section("Material.M2 namespace: Slider / RangeSlider / Switch; defaults are M3", function()
	local m: any = Material
	assert(m.M2 ~= nil and m.M2.Slider == M2.Slider and m.M2.RangeSlider == M2.RangeSlider and m.M2.Switch == M2.Switch)
	assert(m.Slider == Slider and m.Slider ~= m.M2.Slider, "Material.Slider is the M3 look")
	local a, b = m.Slider({}), m.M2.Slider({})
	assert(a.Name == "Slider" and b.Name == "M2Slider")
	q.dispose(a)
	q.dispose(b)
end)

-- ── shared behaviour: every section runs for both looks ──────────────────

for _, look in looks do
	local make = look.Make
	local tag = look.Name .. " "

	H.section(tag .. "drag: press jumps, moves follow, release ends; UI -> Source; callbacks", function()
		local v = q.Source(0)
		local changes: { number } = {}
		local ends: { number } = {}
		local s = make({
			Value = v,
			Min = 0,
			Max = 100,
			OnChange = function(x: number)
				table.insert(changes, x)
			end,
			OnChangeEnd = function(x: number)
				table.insert(ends, x)
			end,
		})
		layout(look, s)
		assert(uisConns() == baseConns)
		press(s, RAIL0 + 50) -- 50 px into the 200 px rail -> 25
		assert(near(v:Get(), 25) and uisConns() == baseConns + 3, "press jumps to the pointer, 3 connections while dragging")
		assert(#ends == 0)
		H.finishTweens()
		assert(H.find(s, "Label").BackgroundTransparency == 0, "label shown while dragging")
		move(RAIL0 + 100)
		assert(near(v:Get(), 50))
		move(1000)
		assert(near(v:Get(), 100))
		move(-500)
		assert(near(v:Get(), 0))
		move(RAIL0 + 200)
		release(RAIL0 + 200)
		assert(near(v:Get(), 100) and #ends == 1 and near(ends[1], 100), "OnChangeEnd on release")
		assert(uisConns() == baseConns, "connections closed at release")
		H.finishTweens()
		assert(H.find(s, "Label").BackgroundTransparency == 1, "label hidden after release")
		assert(near(changes[1], 25) and near(changes[2], 50), "OnChange per user change")
		local count = #changes
		move(150)
		assert(#changes == count, "no drag: ignored")
		v:Set(25)
		press(s, RAIL0 + 50)
		assert(#changes == count, "changed-only")
		release(RAIL0 + 50)
		q.dispose(s)
		H.assertNoDebugOutput(tag .. "drag")
	end)

	H.section(tag .. "discrete: Step snaps, OnChange only on changed steps", function()
		local v = q.Source(0)
		local changes: { number } = {}
		local s = make({
			Value = v,
			Min = 0,
			Max = 10,
			Step = 2,
			OnChange = function(x: number)
				table.insert(changes, x)
			end,
		})
		layout(look, s)
		press(s, RAIL0 + 55) -- 2.75 -> 2
		assert(v:Get() == 2 and #changes == 1)
		move(RAIL0 + 70) -- 3.5 -> 4
		assert(v:Get() == 4 and #changes == 2)
		move(RAIL0 + 72) -- 3.6 -> still 4
		assert(v:Get() == 4 and #changes == 2, "same step is not a change")
		release(RAIL0 + 72)
		q.dispose(s)
		local off = make({ Min = 0, Max = 4, Step = 1, ShowTicks = false })
		assert(#H.findAll(off, function(c: any)
			return c.Name == "Tick"
		end) == 0)
		q.dispose(off)
		H.assertNoDebugOutput(tag .. "discrete")
	end)

	H.section(tag .. "keyboard: connection only while focused, closed on blur and destroy", function()
		local v = q.Source(5)
		local ends: { number } = {}
		local s = make({
			Value = v,
			Min = 0,
			Max = 10,
			Step = 1,
			OnChangeEnd = function(x: number)
				table.insert(ends, x)
			end,
		})
		key(Enum.KeyCode.Right)
		assert(v:Get() == 5, "not focused: ignored")
		H.fire(s, "SelectionGained")
		assert(keyConns() == baseKeys + 1, "one InputBegan connection while focused")
		H.fire(s, "SelectionGained")
		assert(keyConns() == baseKeys + 1, "not doubled")
		key(Enum.KeyCode.Right)
		assert(v:Get() == 6 and ends[1] == 6)
		key(Enum.KeyCode.Left)
		key(Enum.KeyCode.Left)
		assert(v:Get() == 4)
		key(Enum.KeyCode.PageUp)
		assert(v:Get() == 10, "page up clamps")
		key(Enum.KeyCode.Right)
		assert(v:Get() == 10 and #ends == 4, "clamped: no change, no OnChangeEnd")
		key(Enum.KeyCode.Home)
		assert(v:Get() == 0)
		key(Enum.KeyCode.End)
		assert(v:Get() == 10)
		key(Enum.KeyCode.DPadLeft)
		assert(v:Get() == 9)
		key(Enum.KeyCode.Up)
		key(Enum.KeyCode.Down)
		assert(v:Get() == 9, "Up/Down are not mapped")
		local sAny: any = s
		assert(sAny.NextSelectionLeft == s and sAny.NextSelectionRight == s and sAny.NextSelectionUp == nil and sAny.NextSelectionDown == nil)
		H.finishTweens()
		assert(H.find(s, "Label").BackgroundTransparency == 0, "label shown while focused")
		H.fire(s, "SelectionLost")
		assert(keyConns() == baseKeys, "closed on blur")
		H.fire(s, "SelectionGained")
		q.dispose(s)
		assert(keyConns() == baseKeys, "closed on destroy")
		H.assertNoDebugOutput(tag .. "keyboard")
	end)

	H.section(tag .. "continuous KeyStep default is range / 20", function()
		local v = q.Source(0)
		local s = make({ Value = v, Min = 0, Max = 1 })
		H.fire(s, "SelectionGained")
		key(Enum.KeyCode.Right)
		assert(near(v:Get(), 0.05))
		q.dispose(s)
		local s2 = make({ Value = v, Min = 0, Max = 1, KeyStep = 0.25 })
		H.fire(s2, "SelectionGained")
		key(Enum.KeyCode.Right)
		assert(near(v:Get(), 0.3))
		q.dispose(s2)
		H.assertNoDebugOutput(tag .. "keystep")
	end)

	H.section(tag .. "disabled blocks drag and keys", function()
		local v = q.Source(5)
		local dis = q.Source(true)
		local s = make({ Value = v, Min = 0, Max = 10, Disabled = dis })
		layout(look, s)
		assert(s.Interactable == false and s.Selectable == false)
		press(s, RAIL0 + 40)
		assert(v:Get() == 5 and uisConns() == baseConns, "no drag while disabled")
		H.fire(s, "SelectionGained")
		key(Enum.KeyCode.Right)
		assert(v:Get() == 5, "keys ignored while disabled")
		H.fire(s, "SelectionLost")
		dis:Set(false)
		press(s, RAIL0 + 40)
		assert(v:Get() ~= 5)
		release(RAIL0 + 40)
		q.dispose(s)
		H.assertNoDebugOutput(tag .. "disabled")
	end)

	H.section(tag .. "dispose mid-drag: connections closed, no OnChangeEnd; focus loss cancels", function()
		local ends = 0
		local v = q.Source(0)
		local s = make({
			Value = v,
			Min = 0,
			Max = 100,
			OnChangeEnd = function()
				ends += 1
			end,
		})
		layout(look, s)
		press(s, RAIL0 + 40)
		assert(uisConns() == baseConns + 3)
		q.dispose(s)
		assert(uisConns() == baseConns and ends == 0 and H.isDestroyed(s))
		local s2 = make({ Value = v, Min = 0, Max = 100, OnChangeEnd = function()
			ends += 1
		end })
		layout(look, s2)
		press(s2, RAIL0 + 40)
		UIS.WindowFocusReleased:Fire()
		assert(uisConns() == baseConns and ends == 0, "cancelled drag skips OnChangeEnd")
		q.dispose(s2)
		assert(keyConns() == baseKeys)
		H.assertNoDebugOutput(tag .. "dispose")
	end)

	H.section(tag .. "Format, ShowLabel = false, bad arguments", function()
		local s = make({ Value = q.Source(0.5), Format = function(x: number)
			return string.format("%d%%", x * 100)
		end })
		assert(H.find(s, "Label").Text == "50%")
		q.dispose(s)
		local nl = make({ ShowLabel = false })
		assert(H.find(nl, "Label") == nil)
		q.dispose(nl)
		local ok, err = pcall(function()
			make({ Min = 1, Max = 1 })
		end)
		assert(not ok and string.find(tostring(err), "Max must be greater than Min", 1, true), tostring(err))
		local ok2 = pcall(function()
			make({ Step = 0 })
		end)
		assert(not ok2, "Step must be positive")
		local d = make({ Value = q.Source(0.125) })
		assert(H.find(d, "Label").Text == "0.13" or H.find(d, "Label").Text == "0.12")
		q.dispose(d)
		H.assertNoDebugOutput(tag .. "format")
	end)
end

H.section("shared behaviour: the same input sequence gives the same values and callbacks in M3 and M2", function()
	local logs: { { string } } = {}
	for i, look in looks do
		local log: { string } = {}
		local v = q.Source(3)
		local s = look.Make({
			Value = v,
			Min = 0,
			Max = 20,
			Step = 0.5,
			OnChange = function(x: number)
				table.insert(log, "c" .. x)
			end,
			OnChangeEnd = function(x: number)
				table.insert(log, "e" .. x)
			end,
		})
		layout(look, s)
		press(s, RAIL0 + 37) -- 3.7 -> 3.5
		move(RAIL0 + 121)
		move(RAIL0 + 122) -- same step
		move(RAIL0 + 260)
		release(RAIL0 + 150)
		H.fire(s, "SelectionGained")
		key(Enum.KeyCode.Left)
		key(Enum.KeyCode.PageDown)
		key(Enum.KeyCode.End)
		key(Enum.KeyCode.Right)
		H.fire(s, "SelectionLost")
		table.insert(log, "v" .. v:Get())
		logs[i] = log
		q.dispose(s)
	end
	assert(#logs[1] > 6, "the sequence did something")
	assert(table.concat(logs[1], " ") == table.concat(logs[2], " "), table.concat(logs[1], " ") .. " vs " .. table.concat(logs[2], " "))
	H.assertNoDebugOutput("shared")
end)

H.done()
