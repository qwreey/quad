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
	{ Name = "M3", Make = Slider, Inset = 6 },
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
	local W = 212
	H.setAbs(s, 0, 0, W, 44)
	local handle = H.find(s, "Handle")
	assert(handle.Size == UDim2.fromOffset(4, 44), "4 x 44 bar handle")
	assert(handle.Position == UDim2.new(0.5, 0, 0.5, 0), "center 6 + 200 * 0.5 = 106")
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
	assert(stopDot.Visible and stopDot.Size == UDim2.fromOffset(4, 4) and px(stopDot.Position.X, W) == W - 6 and stopDot.BackgroundColor3 == L.Primary, "stop dot: center 6 px from the track end")
	assert(H.find(s, "Label").Size.Y.Offset == 32 and H.find(s, "Label").Position == UDim2.new(0.5, 0, 0, -12), "M3 label pill 32 px (MDC Widget.Material3.Slider.Label minHeight), 12 px above (value-indicator.active.bottom-space)")
	do
		local lbl = H.find(s, "Label")
		local pad: any = nil
		for _, ch in lbl:GetChildren() do
			if ch.ClassName == "UIPadding" then
				pad = ch
			end
		end
		assert(pad ~= nil and pad.PaddingLeft == UDim.new(0, 10) and pad.PaddingRight == UDim.new(0, 10), "10 px side padding")
		assert(lbl.TextSize == 14 and lbl.FontFace.Weight == Enum.FontWeight.Regular, "LabelLarge size at the body-large weight (Regular)")
	end
	assert(H.find(s, "Label").BackgroundColor3 == L.InverseSurface)
	assert(s.Selectable == true and s.NextSelectionLeft == s and s.NextSelectionRight == s)
	assert(keyConns() == baseKeys and uisConns() == baseConns, "no global connection at rest")
	q.dispose(s)
	H.assertNoDebugOutput("m3 mount")
end)

H.section("M3 pieces vanish at the ends (a continuous piece is drawn for any length > 0, shrinking); before layout", function()
	local v = q.Source(0)
	local s = Slider({ Value = v, Min = 0, Max = 100 })
	assert(not H.find(s, "ActiveCap").Visible and not H.find(s, "InactiveCap").Visible, "nothing before layout (width 0)")
	H.setAbs(s, 0, 0, 212, 44)
	assert(not H.find(s, "ActiveCap").Visible and not H.find(s, "ActiveBody").Visible, "at Min: no active piece")
	assert(H.find(s, "InactiveCap").Visible and H.find(s, "StopEnd").Visible)
	v:Set(1) -- active piece 6 + 2 - 8 = 0 px
	assert(not H.find(s, "ActiveCap").Visible)
	v:Set(2) -- 2 px: a sliver, drawn
	assert(H.find(s, "ActiveCap").Visible and H.find(s, "ActiveBody").Visible)
	v:Set(99) -- inactive piece 212 - 204 - 8 = 0 px
	assert(not H.find(s, "InactiveCap").Visible and not H.find(s, "StopEnd").Visible)
	v:Set(98) -- 2 px sliver; the stop dot (center 6 px in) is not covered yet
	assert(H.find(s, "InactiveCap").Visible and not H.find(s, "StopEnd").Visible, "the stop dot waits until its piece covers it")
	v:Set(95) -- 8 px
	assert(H.find(s, "InactiveCap").Visible and H.find(s, "StopEnd").Visible)
	assert(H.find(s, "Handle").Position == UDim2.new(0.95, 6 - 12 * 0.95, 0.5, 0))
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

-- ── M3 variants (10th QA): sizes, vertical, centered, inset icons ─────────

local Icons = require("../src/Icons")
local function vpress(s: any, y: number)
	H.fire(s, "InputBegan", H.input({ Position = Vector3.new(70, y, 0) }))
end
local function vmove(y: number)
	UIS.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(70, y, 0) }))
end
local function vrelease(y: number)
	UIS.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(70, y, 0) }))
end

H.section("M3 sizes: XS / S / M / L / XL track, outer corner, handle height, stop dot 6 px in at every size (m3.material.io specs; tokens.xml sizes)", function()
	-- size -> track, outer corner, handle height (material-components-android slider tokens.xml 55~94)
	local rows: { { any } } = {
		{ "XS", 16, 8, 44 },
		{ "S", 24, 8, 44 },
		{ "M", 40, 12, 44 },
		{ "L", 56, 16, 68 },
		{ "XL", 96, 28, 108 },
	}
	for _, row in rows do
		local name, track, outer, handleH = row[1], row[2], row[3], row[4]
		local s = Slider({ Value = q.Source(0.5), Size = name })
		local W = 200 + 2 * 6
		assert(s.Size == UDim2.new(1, 0, 0, handleH), name .. ": host as tall as the handle")
		H.setAbs(s, 0, 0, W, handleH)
		local handle = H.find(s, "Handle")
		assert(handle.Size == UDim2.fromOffset(4, handleH), name .. ": 4 px handle, " .. handleH .. " tall")
		assert(px(handle.Position.X, W) == 6 + 100, name .. ": the handle travels from the stop dot (6 px in) at every size")
		local capFill = H.find(H.find(s, "ActiveCap"), "Fill")
		assert(capFill.Size == UDim2.fromOffset(2 * outer, track) and H.find(capFill, "_quad_round").CornerRadius == UDim.new(0, outer), name .. ": cap fill")
		assert(H.find(s, "ActiveCap").Size == UDim2.fromOffset(outer, track), name .. ": cap clip")
		assert(H.find(s, "ActiveBody").Size.Y.Offset == track, name .. ": track thickness")
		assert(H.find(H.find(s, "ActiveBody"), "_quad_round").CornerRadius == UDim.new(0, 2), name .. ": inside corner 2")
		local stopDot = H.find(s, "StopEnd")
		assert(px(stopDot.Position.X, W) == W - 6 and stopDot.Size == UDim2.fromOffset(4, 4), name .. ": stop dot")
		local aBody = H.find(s, "ActiveBody")
		assert(px(aBody.Position.X, W) + px(aBody.Size.X, W) == 6 + 100 - 8, name .. ": 6 px gap at every size")
		assert(H.countDescendants(s) == 20, name .. ": the size changes no count")
		q.dispose(s)
	end
	assert(not pcall(Slider, { Size = "XXL" :: any }), "an unknown Size is an error")
	H.assertNoDebugOutput("m3 sizes")
end)

H.section("M3 vertical: Min at the bottom, 44 x 4 handle, label on the left, Up/Down keys, Y drag; TopToBottom flips it", function()
	local v = q.Source(25)
	local ends: { number } = {}
	local s = Slider({
		Value = v,
		Min = 0,
		Max = 100,
		Orientation = "Vertical",
		OnChangeEnd = function(x: number)
			table.insert(ends, x)
		end,
	})
	assert(s.Size == UDim2.new(0, 44, 1, 0), "44 wide, the parent's height")
	local H0, L0 = 100, 212 -- top, length (rail 200 from y = 106)
	H.setAbs(s, 50, H0, 44, L0)
	local handle = H.find(s, "Handle")
	assert(handle.Size == UDim2.fromOffset(44, 4), "the handle turned: 44 wide, 4 tall")
	assert(handle.Position.X == UDim.new(0.5, 0) and px(handle.Position.Y, L0) == L0 - (6 + 50), "25 % up from the bottom")
	-- the active piece runs from the BOTTOM (Min) up to 8 px below the handle center
	local aCap, aBody = H.find(s, "ActiveCap"), H.find(s, "ActiveBody")
	assert(px(aCap.Position.Y, L0) == L0 - 8 and aCap.Size == UDim2.fromOffset(16, 8) and aCap.AnchorPoint == Vector2.new(0.5, 0), "cap at the bottom end")
	local hy = px(handle.Position.Y, L0)
	assert(px(aBody.Position.Y, L0) == hy + 8 and px(aBody.Position.Y, L0) + px(aBody.Size.Y, L0) == L0 - 8, "body from the handle gap down to the cap")
	assert(H.find(aBody, "Fill").Size == UDim2.new(1, 0, 1, 2) and H.find(aBody, "Fill").Position == UDim2.fromOffset(0, 0), "rounded end cut on the cap side (below)")
	local iCap = H.find(s, "InactiveCap")
	assert(px(iCap.Position.Y, L0) == 0 and H.find(iCap, "Fill").Position == UDim2.fromOffset(0, 0), "inactive cap at the top")
	assert(px(H.find(s, "StopEnd").Position.Y, L0) == 6, "stop dot at the top (Max)")
	local label = H.find(s, "Label")
	assert(label.AnchorPoint == Vector2.new(1, 0.5) and label.Position == UDim2.new(0, -12, 0.5, 0), "label 12 px left of the handle")
	-- pointer along Y: bottom = Min
	vpress(s, H0 + 6 + 50) -- 50 px below the rail top -> 75
	assert(near(v:Get(), 75), "press maps Y: " .. v:Get())
	vmove(H0 + 6 + 200)
	assert(near(v:Get(), 0))
	vrelease(H0 + 6 + 150)
	assert(near(v:Get(), 25) and ends[#ends] == 25)
	-- keys: Up / Down move the handle the way they point; Left / Right walk on (not pinned)
	local sa: any = s
	assert(sa.NextSelectionUp == s and sa.NextSelectionDown == s and sa.NextSelectionLeft == nil and sa.NextSelectionRight == nil, "Vertical pin")
	H.fire(s, "SelectionGained")
	key(Enum.KeyCode.Up)
	assert(near(v:Get(), 30), "Up = toward Max (Min at the bottom): " .. v:Get())
	key(Enum.KeyCode.DPadDown)
	key(Enum.KeyCode.Down)
	assert(near(v:Get(), 20))
	key(Enum.KeyCode.Right)
	key(Enum.KeyCode.Left)
	assert(near(v:Get(), 20), "Left / Right do nothing")
	key(Enum.KeyCode.PageUp)
	assert(near(v:Get(), 70))
	key(Enum.KeyCode.Home)
	assert(v:Get() == 0)
	H.fire(s, "SelectionLost")
	q.dispose(s)

	-- TopToBottom (Compose's default): Min at the top
	local t = q.Source(25)
	local top = Slider({ Value = t, Min = 0, Max = 100, Orientation = "Vertical", TopToBottom = true })
	H.setAbs(top, 50, H0, 44, L0)
	assert(px(H.find(top, "Handle").Position.Y, L0) == 6 + 50, "25 % down from the top")
	assert(px(H.find(top, "ActiveCap").Position.Y, L0) == 0, "active piece from the top")
	vpress(top, H0 + 6 + 150)
	assert(near(t:Get(), 75))
	vrelease(H0 + 6 + 150)
	H.fire(top, "SelectionGained")
	key(Enum.KeyCode.Up)
	assert(near(t:Get(), 70), "Up = toward Min when Min is at the top")
	H.fire(top, "SelectionLost")
	q.dispose(top)
	assert(not pcall(Slider, { TopToBottom = true }), "TopToBottom on a horizontal slider is an error")
	assert(not pcall(Slider, { Orientation = "Diagonal" :: any }), "a bad Orientation is an error")
	assert(keyConns() == baseKeys and uisConns() == baseConns)
	H.assertNoDebugOutput("m3 vertical")
end)

H.section("M3 centered: the active piece joins the middle and the handle on either side; middle fixed; own Value starts there", function()
	local sBody: any, eBody: any, active: any
	local own = Slider({ Min = -50, Max = 50, Centered = true })
	local W = 212 -- rail 200, middle at 106
	H.setAbs(own, 0, 0, W, 44)
	assert(px(H.find(own, "Handle").Position.X, W) == 106, "own Value starts at (Min + Max) / 2")
	local n = H.countDescendants(own)
	assert(n == 25, "Start/End outer pieces 12 + Active 3 + two stops 4 + handle 3 + label 3 = 25, got " .. n)
	-- at the middle: no active piece, both inactive pieces stop 8 px from the handle
	sBody, eBody, active = H.find(own, "StartBody"), H.find(own, "EndBody"), H.find(own, "Active")
	assert(not active.Visible, "no active piece at the middle")
	assert(px(sBody.Position.X, W) + px(sBody.Size.X, W) == 98 and px(eBody.Position.X, W) == 114)
	assert(H.find(own, "StopStart").Visible and H.find(own, "StopEnd").Visible and px(H.find(own, "StopStart").Position.X, W) == 6, "stop dots at both ends")
	q.dispose(own)

	local v = q.Source(25)
	local s = Slider({ Value = v, Min = -50, Max = 50, Centered = true })
	H.setAbs(s, 0, 0, W, 44)
	sBody, eBody, active = H.find(s, "StartBody"), H.find(s, "EndBody"), H.find(s, "Active")
	-- 25 -> f .75, handle at 156: Start [.., 100] (6 before the middle), Active [106, 148], End [164, ..]
	assert(px(sBody.Position.X, W) + px(sBody.Size.X, W) == 100, "inactive piece stops 6 px before the middle")
	assert(active.Visible and px(active.Position.X, W) == 106 and px(active.Position.X, W) + px(active.Size.X, W) == 148, "active: middle -> 8 px before the handle")
	assert(H.find(H.find(active, "Fill"), "_quad_round").CornerRadius == UDim.new(0, 2) and H.find(active, "Fill").BackgroundColor3 == L.Primary, "inner corners 2 at both ends")
	assert(px(eBody.Position.X, W) == 164)
	-- below the middle: mirrored
	v:Set(-25) -- handle at 56
	assert(px(sBody.Position.X, W) + px(sBody.Size.X, W) == 48, "Start ends 8 px before the handle")
	assert(px(active.Position.X, W) == 64 and px(active.Position.X, W) + px(active.Size.X, W) == 106, "active: 8 px after the handle -> the middle")
	assert(px(eBody.Position.X, W) == 112, "End starts 6 px after the middle")
	-- drag across the middle: the active piece follows on either side
	H.setAbs(s, RAIL0 - 6, 50, W, 40)
	press(s, RAIL0 + 190)
	assert(near(v:Get(), 45))
	release(RAIL0 + 10)
	assert(near(v:Get(), -45))
	q.dispose(s)

	-- ticks: none at the two stops, none within 6 px of the middle (Compose tickCenterGap), active between middle and handle
	local d = q.Source(30)
	local ds = Slider({ Value = d, Min = -50, Max = 50, Step = 10, Centered = true })
	H.setAbs(ds, 0, 0, W, 44)
	local ticks = H.findAll(ds, function(c: any)
		return c.Name == "Tick"
	end)
	assert(#ticks == 9, "11 steps minus both stop dots = 9, got " .. #ticks)
	-- ticks[i] is t = i / 10 (0 and 1 are the stop dots); value 30 -> f .8, handle at 6 + 160 = 166
	assert(not ticks[5].Visible, "no tick at the middle")
	assert(ticks[6].Visible and ticks[6].BackgroundColor3 == L.SecondaryContainer, "between the middle and the handle: active color")
	assert(not ticks[8].Visible, "under the handle")
	assert(ticks[9].Visible and ticks[9].BackgroundColor3 == L.Primary, "past the handle: inactive color")
	assert(ticks[4].Visible and ticks[4].BackgroundColor3 == L.Primary, "the other side: inactive")
	q.dispose(ds)
	H.assertNoDebugOutput("m3 centered")
end)

H.section("M3 inset icons (M+): 10 px inside their piece, hidden below icon + 20, tick colors; the stop dot yields to an end icon", function()
	local v = q.Source(146) -- Min 0, Max 292: the M rail is 292 px on a 304 px host (inset 6), 1 px per unit
	local s = Slider({
		Value = v,
		Min = 0,
		Max = 292,
		Size = "M",
		TrackIconActiveStart = "check",
		TrackIconActiveEnd = "rbxassetid://7",
		TrackIconInactiveStart = "\u{266A}",
		TrackIconInactiveEnd = "close",
	})
	local W = 304
	H.setAbs(s, 0, 0, W, 44)
	assert(H.countDescendants(s) == 24, "20 + one instance per icon")
	local as, ae = H.find(s, "TrackIconActiveStart"), H.find(s, "TrackIconActiveEnd")
	local is, ie = H.find(s, "TrackIconInactiveStart"), H.find(s, "TrackIconInactiveEnd")
	assert(as.ClassName == "ImageLabel" and as.Image == Icons.Defaults.check and as.Size == UDim2.fromOffset(24, 24), "an Icons name: its image, 24 px at M")
	assert(ae.Image == "rbxassetid://7" and is.ClassName == "TextLabel" and is.Text == "\u{266A}" and is.TextSize == 24, "URL image; text = glyph")
	-- handle at 6 + 146 = 152: active [0, 144], inactive [160, 304]; icon centers 10 + 12 px in from a piece end
	assert(px(as.Position.X, W) == 22 and px(ae.Position.X, W) == 144 - 22, "active icons")
	assert(px(is.Position.X, W) == 160 + 22 and px(ie.Position.X, W) == W - 22, "inactive icons")
	assert(as.AnchorPoint == Vector2.new(0.5, 0.5) and as.Position.Y == UDim.new(0.5, 0))
	assert(as.ImageColor3 == L.SecondaryContainer and is.TextColor3 == L.Primary, "on the active piece SecondaryContainer, on the inactive Primary")
	assert(not H.find(s, "StopEnd").Visible, "the end icon takes the stop dot's place")
	-- the active piece is v - 2 px long: shown from icon + 20 = 44 (MDC calculateTrackIconBounds: >=)
	v:Set(46)
	assert(as.Visible and ae.Visible, "44 px piece: shown")
	v:Set(45)
	assert(not as.Visible and not ae.Visible, "43 px piece: hidden")
	v:Set(246) -- inactive piece 304 - 252 - 8 = 44
	assert(is.Visible and ie.Visible)
	v:Set(247)
	assert(not is.Visible and not ie.Visible and H.find(s, "StopEnd").Visible, "end icon hidden: the stop dot is back")
	q.dispose(s)
	-- glyph fallback of a name
	Icons.override({ check = false })
	local g = Slider({ Size = "XL", TrackIconActiveStart = "check" })
	local gi = H.find(g, "TrackIconActiveStart")
	assert(gi.ClassName == "TextLabel" and gi.Text == Icons.glyph("check") and gi.TextSize == 32, "XL icon 32; glyph without the image")
	Icons.override({ check = Icons.Defaults.check })
	q.dispose(g)
	assert(not pcall(Slider, { TrackIconActiveStart = "check" }), "XS has no icon size: an error")
	assert(not pcall(Slider, { Size = "S", TrackIconActiveStart = "check" }), "S: an error")
	assert(not pcall(Slider, { Size = "M", Centered = true, TrackIconActiveStart = "check" }), "standard slider only")
	H.assertNoDebugOutput("m3 icons")
end)

-- ── end pieces shrink instead of popping (user, Studio 2026-10-08) ──────────

-- The visible along-axis length of a clipped piece: its cap clip + body clip when shown, else 0.
local function pieceLength(s: any, name: string, host: number, vertical: boolean): number
	local cap, body = H.find(s, name .. "Cap"), H.find(s, name .. "Body")
	if not cap.Visible and not body.Visible then
		return 0
	end
	local function along(f: any): number
		return px(if vertical then f.Size.Y else f.Size.X, host)
	end
	return along(cap) + math.max(along(body), 0)
end

-- Sweeps a value from `from` to `to` in 0.125-unit steps (a quarter px of handle travel on the 200 px rail) and
-- asserts the piece length is monotone (direction `dir` = -1 shrinking), never above the track, never jumps more than
-- 3 px between two frames (UDim offsets are whole numbers: cap and body each truncate, and the regime switch trades a
-- fractional host-fraction length for a truncated one) and is
-- NEVER shown-then-hidden while longer than 3 px; returns the lengths.
local function sweep(label: string, set: (v: number) -> (), length: () -> number, from: number, to: number, dir: number, host: number, each: (() -> ())?): { number }
	local out: { number } = {}
	local n = math.floor(math.abs(to - from) / 0.125)
	local sign = if to >= from then 1 else -1
	for i = 0, n do
		set(from + sign * 0.125 * i)
		if each ~= nil then
			each()
		end
		local len = length()
		assert(len >= 0 and len <= host + 1e-6, label .. ": length within the track: " .. len)
		table.insert(out, len)
		if i > 0 then
			local d = len - out[i]
			assert(math.abs(d) <= 3.01, label .. ": no jump at step " .. i .. ": " .. out[i] .. " -> " .. len)
			assert(d * dir >= -3.01, label .. ": monotone at step " .. i .. ": " .. out[i] .. " -> " .. len)
		end
	end
	return out
end
local function reachesZeroSmoothly(label: string, lens: { number })
	assert(lens[#lens] == 0, label .. ": ends at 0, got " .. lens[#lens])
	local sawSliver = false
	for i = 2, #lens do
		if lens[i] == 0 and lens[i - 1] > 0 then
			assert(lens[i - 1] <= 3.01, label .. ": hidden while still " .. lens[i - 1] .. " px long")
			sawSliver = true
		end
	end
	assert(sawSliver, label .. ": never went from a positive length to 0")
end

-- Every rounded fill of a piece keeps its size: along the axis never shorter than 2 x its UICorner radius, and the
-- radius itself constant (cap OUTER, body / middle INNER) — UICorner clamps its radius to half the frame's smaller
-- side, so a shrinking fill would visibly change the curve (user, Studio 2026-10-08).
local function checkFills(s: any, host: number, vertical: boolean, fills: { [string]: number }, tag: string)
	for name, radius in fills do
		local clipFrame = H.find(s, name)
		local f = H.find(clipFrame, "Fill")
		local r = H.find(f, "_quad_round").CornerRadius
		assert(r == UDim.new(0, radius), tag .. ": " .. name .. " radius constant " .. radius .. ", got " .. tostring(r))
		local clipAlong = px(if vertical then clipFrame.Size.Y else clipFrame.Size.X, host)
		local along = px(if vertical then f.Size.Y else f.Size.X, math.max(clipAlong, 0))
		local across = if vertical then px(f.Size.X, clipFrame.Size.X.Offset) else px(f.Size.Y, clipFrame.Size.Y.Offset)
		assert(along >= 2 * radius - 1e-6, tag .. ": " .. name .. " fill " .. along .. " px >= 2 x radius " .. radius)
		assert(across >= 2 * radius - 1e-6, tag .. ": " .. name .. " fill across " .. across .. " >= 2 x " .. radius)
	end
end

H.section("M3 ends: the piece beyond a handle shrinks to 0 (no pop) — XS and XL, horizontal, vertical, centered", function()
	for _, size in { "XS", "XL" } do
		for _, vertical in { false, true } do
			local v = q.Source(50)
			local s = Slider({ Value = v, Min = 0, Max = 100, Size = size :: any, Orientation = if vertical then "Vertical" else nil })
			local host = 212
			if vertical then
				H.setAbs(s, 0, 0, if size == "XL" then 108 else 44, host)
			else
				H.setAbs(s, 0, 0, host, if size == "XL" then 108 else 44)
			end
			local tag = size .. (if vertical then " vertical" else " horizontal")
			-- vertical: Min at the bottom; the along-axis length is read the same way
			local set = function(x: number)
				v:Set(x)
			end
			local outer = if size == "XL" then 28 else 8
			local fills = { InactiveCap = outer, ActiveCap = outer, InactiveBody = 2, ActiveBody = 2 }
			local each = function()
				checkFills(s, host, vertical, fills, tag)
			end
			local inactive = sweep(tag .. " inactive", set, function()
				return pieceLength(s, "Inactive", host, vertical)
			end, 70, 100, -1, host, each)
			reachesZeroSmoothly(tag .. " inactive", inactive)
			local active = sweep(tag .. " active", set, function()
				return pieceLength(s, "Active", host, vertical)
			end, 30, 0, -1, host, each)
			reachesZeroSmoothly(tag .. " active", active)
			-- the stop dot never shows without its piece under it, and is back once the piece covers its center
			v:Set(100)
			assert(not H.find(s, "StopEnd").Visible, tag .. ": no stop dot at the end")
			v:Set(0)
			assert(H.find(s, "StopEnd").Visible and pieceLength(s, "Inactive", host, vertical) > 6, tag .. ": stop dot back")
			q.dispose(s)
		end
	end
	-- XL: a 26 px piece (below outer 28) keeps the full 56 px cap fill and the 28 px curve; only the clip windows are short
	local v = q.Source(0)
	local s = Slider({ Value = v, Min = 0, Max = 100, Size = "XL" })
	H.setAbs(s, 0, 0, 212, 108)
	v:Set(86) -- handle 178: run = 212 - 178 - 8 = 26 px
	local capFill = H.find(H.find(s, "InactiveCap"), "Fill")
	assert(capFill.Size == UDim2.fromOffset(56, 96) and H.find(capFill, "_quad_round").CornerRadius == UDim.new(0, 28), "cap fill keeps its size and radius")
	assert(H.find(s, "InactiveCap").Size == UDim2.fromOffset(26, 96), "the cap clip window follows the piece")
	assert(px(capFill.Position.X, 212) == 26 - 56, "the fill stays on the track end (its inner part is cut)")
	v:Set(80) -- handle 166: run = 38: the full cap window again, the body takes the rest
	assert(H.find(s, "InactiveCap").Size == UDim2.fromOffset(28, 96), "full cap window above the outer radius")
	assert(math.abs(pieceLength(s, "Inactive", 212, false) - 38) < 2)
	q.dispose(s)

	-- centered: the Start / End pieces shrink toward their ends, the active piece grows out of the middle
	for _, size in { "XS", "XL" } do
		local v2 = q.Source(0)
		local c = Slider({ Value = v2, Min = -50, Max = 50, Centered = true, Size = size :: any })
		H.setAbs(c, 0, 0, 212, if size == "XL" then 108 else 44)
		local tag = "centered " .. size
		local outer = if size == "XL" then 28 else 8
		local fills = { StartCap = outer, EndCap = outer, StartBody = 2, EndBody = 2, Active = 2 }
		local each = function()
			checkFills(c, 212, false, fills, tag)
		end
		local startLens = sweep(tag .. " start", function(x)
			v2:Set(x)
		end, function()
			return pieceLength(c, "Start", 212, false)
		end, -30, -50, -1, 212, each)
		reachesZeroSmoothly(tag .. " start", startLens)
		local endLens = sweep(tag .. " end", function(x)
			v2:Set(x)
		end, function()
			return pieceLength(c, "End", 212, false)
		end, 30, 50, -1, 212, each)
		reachesZeroSmoothly(tag .. " end", endLens)
		-- the middle piece: 0 at the middle, grows continuously (no frame hidden while longer than 1 px)
		local mid = H.find(c, "Active")
		local last = 0
		for i = 0, 400 do
			v2:Set(0.125 * i)
			each()
			local len = if mid.Visible then mid.Size.X.Offset + mid.Size.X.Scale * 212 else 0
			assert(math.abs(len - last) <= 2.01, tag .. ": active grows smoothly (whole-pixel offsets: within 2 px) at " .. i .. ": " .. last .. " -> " .. len)
			last = len
		end
		q.dispose(c)
	end
	H.assertNoDebugOutput("m3 ends")
end)

H.section("M3 stepped slider keeps the hard threshold (Compose: no corner shrinking with steps)", function()
	local v = q.Source(50)
	local s = Slider({ Value = v, Min = 0, Max = 100, Step = 1, Size = "XL" })
	H.setAbs(s, 0, 0, 212, 108)
	v:Set(97) -- inactive run = 212 - 200 - 8 = 4 px <= 28
	assert(not H.find(s, "InactiveCap").Visible and not H.find(s, "StopEnd").Visible, "stepped: hidden at or below the outer radius")
	v:Set(80) -- run 44 px
	assert(H.find(s, "InactiveCap").Visible and H.find(s, "InactiveCap").Size == UDim2.fromOffset(28, 96))
	q.dispose(s)
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
		-- review 2026-10-12 B1 (user decision 2026-10-13): the range must be a multiple of Step (MDC); float steps pass
		local ok3, err3 = pcall(function()
			make({ Min = 0, Max = 10, Step = 3 })
		end)
		assert(not ok3 and string.find(tostring(err3), "must be a multiple of Step", 1, true), tostring(err3))
		q.dispose(make({ Min = 0, Max = 1, Step = 0.1 }))
		q.dispose(make({ Min = 0, Max = 10000, Step = 25 }))
		local d = make({ Value = q.Source(0.125) })
		assert(H.find(d, "Label").Text == "0.13" or H.find(d, "Label").Text == "0.12")
		q.dispose(d)
		-- Unit (user decision 2026-10-13): an INTEGER value shown scaled; Format, when given, wins; a bad unit raises
		local ratio = q.Source(3725)
		local u = make({ Value = ratio, Min = 0, Max = 10000, Step = 1, Unit = { Scale = 0.01, Suffix = "%" } })
		assert(H.find(u, "Label").Text == "37.25%", "unit label: " .. H.find(u, "Label").Text)
		ratio:Set(10000)
		assert(H.find(u, "Label").Text == "100.00%", "the unit's precision, zeros kept: " .. H.find(u, "Label").Text)
		assert(H.find(u, "Tick") == nil, "more than 100 steps: no ticks")
		q.dispose(u)
		local both = make({
			Value = q.Source(50),
			Min = 0,
			Max = 100,
			Unit = { Scale = 0.01 },
			Format = function(v: number): string
				return "F" .. tostring(v)
			end,
		})
		assert(H.find(both, "Label").Text == "F50", "Format wins over Unit: " .. H.find(both, "Label").Text)
		q.dispose(both)
		local ok4, err4 = pcall(function()
			make({ Unit = { Scale = 0.5 } })
		end)
		assert(not ok4 and string.find(tostring(err4), "Decimals is required", 1, true), tostring(err4))
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
