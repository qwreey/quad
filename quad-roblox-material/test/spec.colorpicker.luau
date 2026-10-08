--!strict
local H = require("./support/harness")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
local D = q.Declaration
local Tokens = require("../src/Tokens")
local Overlay = require("../src/Overlay")
local ColorPicker = require("../src/ColorPicker")
local ColorModel = require("../src/ColorPicker/ColorModel")
local Bounded = require("./support/bounded")

local L = Tokens.Color.Light
local UIS = H.UserInputService
local function dragConns(): number
	local u = UIS :: any
	return #u.InputChanged.connections + #u.InputEnded.connections + #u.WindowFocusReleased.connections
end
local function keyConns(): number
	return #(UIS :: any).InputBegan.connections
end
local baseDrag, baseKeys = dragConns(), keyConns()

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end
local function pos(x: number, y: number): Vector3
	return Vector3.new(x, y, 0)
end

type Rig = {
	root: any,
	value: any,
	changes: { Color3 },
	area: any,
	hue: any,
}

-- SV area at (100,50) 300x160; hue host at (100,230) 300x40 (rail 110..390)
local function rig(start: Color3?, extra: { [string]: any }?): Rig
	local value = q.Source(start or Color3.fromRGB(235, 153, 255))
	local r: Rig = { root = nil, value = value, changes = {}, area = nil, hue = nil }
	local props: any = {
		Value = value,
		OnChange = function(c: Color3)
			table.insert(r.changes, c)
		end,
	}
	if extra then
		for k, v in extra do
			props[k] = v
		end
	end
	r.root = ColorPicker.Panel(props)
	r.area = H.find(r.root, "SVArea")
	r.hue = H.find(r.root, "HueSlider")
	H.setAbs(r.root, 80, 40, 340, 500)
	H.setAbs(r.area, 100, 50, 300, 160)
	H.setAbs(r.hue, 100, 230, 300, 40)
	return r
end

local function hsvOf(r: Rig): ColorModel.HSV
	local c: Color3 = r.value:Get()
	return ColorModel.fromColor3(c, nil)
end

local function press(el: any, x: number, y: number)
	H.fire(el, "InputBegan", H.input({ Position = pos(x, y) }))
end
local function move(x: number, y: number)
	UIS.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = pos(x, y) }))
end
local function release(x: number, y: number)
	UIS.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = pos(x, y) }))
end

local function class(inst: any, name: string): { any }
	return H.findAll(inst, function(c: any)
		return c.ClassName == name
	end)
end
local function named(inst: any, name: string): { any }
	return H.findAll(inst, function(c: any)
		return c.Name == name
	end)
end
local function own(inst: any, className: string): any
	for _, c in inst:GetChildren() do
		if c.ClassName == className then
			return c
		end
	end
	return nil
end
local function typeInto(b: any, text: string)
	H.fire(b, "Focused")
	b.Text = text
end
local function lose(b: any)
	H.fire(b, "FocusLost", false)
end
local function hexBox(r: Rig): any
	return H.find(H.find(r.root, "TextField"), "Input")
end
local function internalHSV(r: Rig): ColorModel.HSV
	-- the picker's own canonical state is observable through the SV thumb + hue handle positions
	local t = H.find(r.area, "Thumb")
	local h = H.find(r.hue, "Halo")
	return { H = h.Position.X.Scale, S = t.Position.X.Scale, V = 1 - t.Position.Y.Scale }
end

H.section("mount: structure, tint, texts, instance count", function()
	local r = rig()
	local n = H.countDescendants(r.root)
	local function count(name: string): number
		return H.countDescendants(H.find(r.root, name)) + 1
	end
	print(`material panel instances: {n + 1} (host + {n} descendants)`)
	print(`  SV area {H.countDescendants(r.area) + 1}, hue slider {H.countDescendants(r.hue) + 1}, hex field {count("TextField")}, channels {count("Channels")}, swatches {count("Swatches")}, preview {count("Preview")}`)
	assert(H.countDescendants(r.area) + 1 == 12, "area, corner, stroke, 2 overlays (+corner, gradient), thumb (+corner, stroke)")
	assert(H.countDescendants(r.hue) + 1 == 11, "host, rail (+corner, gradient), halo, layer (3), handle (+corner, stroke)")
	assert(count("Preview") == 4 and count("TextField") == 13 and count("Channels") == 29 and count("Swatches") == 32)
	assert(n + 1 == 107, `panel total {n + 1}`)
	H.resetOutput()
	assert(r.root.Name == "ColorPicker" and r.root.AutomaticSize == Enum.AutomaticSize.Y)
	assert(r.area.Size == UDim2.new(1, 0, 0, 160) and own(r.area, "UICorner").CornerRadius == UDim.new(0, 12), "SV area rounded 12")
	local hsv = ColorModel.fromColor3(Color3.fromRGB(235, 153, 255), nil)
	assert(r.area.BackgroundColor3 == Color3.new(ColorModel.hueToRgb(hsv.H)), "SV tint = pure hue")
	local thumb = H.find(r.area, "Thumb")
	assert(near(thumb.Position.X.Scale, hsv.S) and near(thumb.Position.Y.Scale, 1 - hsv.V))
	assert(thumb.BackgroundColor3 == Color3.fromRGB(235, 153, 255) or near(thumb.BackgroundColor3.R, 235 / 255), "thumb fill = current")
	assert(thumb.Size == UDim2.fromOffset(20, 20) and own(thumb, "UICorner").CornerRadius == UDim.new(0.5, 0))
	assert(near(H.find(r.hue, "Halo").Position.X.Scale, hsv.H))
	assert(H.find(r.hue, "Handle").Size == UDim2.fromOffset(20, 20) and H.find(r.hue, "Halo").Size == UDim2.fromOffset(40, 40), "slider-like handle + halo")
	assert(#class(H.find(r.hue, "Rail"), "UIGradient") == 1)
	assert(hexBox(r).Text == "#EB99FF", hexBox(r).Text)
	assert(H.find(r.root, "Channel1").Text == "235" and H.find(r.root, "Channel2").Text == "153" and H.find(r.root, "Channel3").Text == "255")
	assert(H.find(H.find(r.root, "Box1"), "Label").Text == "R")
	assert(#named(r.root, "Swatch") == 8 and #named(H.find(r.root, "Recent"), "Swatch") == 0, "8 presets, no recents yet")
	assert(H.find(r.root, "RecentLabel").Visible == false and H.find(r.root, "Recent").Visible == false)
	assert(keyConns() == baseKeys and dragConns() == baseDrag, "no global connection at rest")
	assert(r.root.BackgroundTransparency == 1 and H.find(r.root, "DisabledVeil").Visible == false)
	assert(#r.changes == 0, "mount does not call OnChange")
	q.dispose(r.root)
	H.assertNoDebugOutput("mount")
end)

H.section("SV drag: atomic S/V write, mirrored to Value, hue untouched, recents at gesture end", function()
	local r = rig(Color3.fromRGB(100, 40, 200))
	local h0 = hsvOf(r).H
	press(r.area, 100, 50) -- top-left: S = 0, V = 1
	assert(dragConns() == baseDrag + 3, "three connections while dragging")
	local s = internalHSV(r)
	assert(near(s.S, 0) and near(s.V, 1) and near(s.H, h0), `press jumps: {s.H},{s.S},{s.V}`)
	assert(r.value:Get() == Color3.new(1, 1, 1), "Value follows (white)")
	move(250, 130) -- S = .5, V = .5
	s = internalHSV(r)
	assert(near(s.S, 0.5) and near(s.V, 0.5) and near(s.H, h0), "middle")
	H.finishTweens()
	assert(H.find(r.area, "Thumb").Size == UDim2.fromOffset(28, 28), "thumb grows while dragging")
	move(900, 900) -- outside: clamped to the bottom-right
	s = internalHSV(r)
	assert(near(s.S, 1) and near(s.V, 0) and near(s.H, h0), "clamped; black corner keeps the hue")
	assert(#H.find(r.root, "Recent"):GetChildren() == 1, "recent row has only its layout before the gesture ends")
	release(100, 210) -- bottom-left: S = 0, V = 0
	H.finishTweens()
	assert(dragConns() == baseDrag, "closed on release")
	assert(near(internalHSV(r).H, h0), "hue survived black and grey corners")
	assert(H.find(r.area, "Thumb").Size == UDim2.fromOffset(20, 20))
	assert(#r.changes >= 3, "OnChange per user change")
	assert(#named(H.find(r.root, "Recent"), "Swatch") == 1 and H.find(r.root, "Recent").Visible == true, "one recent swatch after the gesture")
	-- drag end by cancel (focus lost): no remember, no error
	press(r.area, 200, 100)
	UIS.WindowFocusReleased:Fire()
	assert(dragConns() == baseDrag)
	q.dispose(r.root)
	H.assertNoDebugOutput("sv drag")
end)

H.section("hue drag + hue preservation through black/grey from OUTSIDE writes", function()
	local r = rig(Color3.fromRGB(255, 0, 0))
	press(r.hue, 110 + 140, 250) -- middle of the rail -> H = .5
	assert(near(internalHSV(r).H, 0.5), "press maps onto the rail")
	assert(near(H.find(r.hue, "Halo").Position.X.Scale, 0.5))
	move(10, 250)
	assert(near(internalHSV(r).H, 0), "clamped left")
	release(110 + 280 * 0.3, 250)
	assert(near(internalHSV(r).H, 0.3), "release position counts")
	assert(near(H.find(r.hue, "Handle").BackgroundColor3.R, select(1, ColorModel.hueToRgb(0.3))), "handle fill = pure hue")
	local changesBefore = #r.changes
	r.value:Set(Color3.new(0, 0, 0)) -- an OUTSIDE write of black
	assert(near(internalHSV(r).H, 0.3), "black keeps the hue")
	r.value:Set(Color3.new(0.5, 0.5, 0.5))
	assert(near(internalHSV(r).H, 0.3) and near(internalHSV(r).S, 0), "grey keeps the hue")
	r.value:Set(Color3.fromRGB(0, 200, 0))
	assert(near(internalHSV(r).H, 1 / 3) and r.value:Get() == Color3.fromRGB(0, 200, 0), "a chromatic outside write wins")
	assert(#r.changes == changesBefore, "outside writes do not call OnChange")
	assert(hexBox(r).Text == "#00C800", "hex follows an outside write: " .. hexBox(r).Text)
	-- keys on the hue slider
	H.fire(r.hue, "SelectionGained")
	assert(keyConns() == baseKeys + 1)
	local h0 = internalHSV(r).H
	UIS.InputBegan:Fire(H.input({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Right }))
	assert(near(internalHSV(r).H, h0 + 0.01), "arrow = +1 %")
	UIS.InputBegan:Fire(H.input({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.End }))
	assert(near(internalHSV(r).H, 1))
	UIS.InputBegan:Fire(H.input({ UserInputType = Enum.UserInputType.Gamepad1, KeyCode = Enum.KeyCode.DPadLeft }))
	assert(near(internalHSV(r).H, 0.99))
	H.fire(r.hue, "SelectionLost")
	assert(keyConns() == baseKeys, "key connection closed on SelectionLost")
	q.dispose(r.root)
	H.assertNoDebugOutput("hue")
end)

H.section("keyboard on the SV area: nudges, closed on selection loss and on destroy", function()
	local r = rig(Color3.fromRGB(255, 0, 0))
	H.fire(r.area, "SelectionGained")
	assert(keyConns() == baseKeys + 1)
	local s0 = internalHSV(r)
	local function key(code: any)
		UIS.InputBegan:Fire(H.input({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = code }))
	end
	key(Enum.KeyCode.Left)
	assert(near(internalHSV(r).S, s0.S), "selected but not engaged: arrows do not nudge")
	key(Enum.KeyCode.Return) -- engage
	key(Enum.KeyCode.Left)
	assert(near(internalHSV(r).S, s0.S - 0.02) and near(internalHSV(r).V, s0.V))
	key(Enum.KeyCode.Down)
	assert(near(internalHSV(r).V, s0.V - 0.02))
	key(Enum.KeyCode.PageDown)
	assert(near(internalHSV(r).V, s0.V - 0.22), "page = 10 steps")
	key(Enum.KeyCode.Right)
	key(Enum.KeyCode.Up)
	assert(near(internalHSV(r).S, s0.S))
	assert(r.area.Selectable == true and r.area.NextSelectionLeft == r.area and r.area.NextSelectionUp == r.area, "engaged: all four pinned")
	assert(#named(H.find(r.root, "Recent"), "Swatch") == 0, "key presses do not flood the recents")
	H.fire(r.area, "SelectionLost")
	assert(keyConns() == baseKeys and #named(H.find(r.root, "Recent"), "Swatch") == 1, "the key session remembers once")
	q.dispose(r.root)
	assert(keyConns() == baseKeys, "closed on destroy while selected")
	H.assertNoDebugOutput("sv keys")
end)

H.section("D1 gamepad: the hue slider pins Left/Right only; the SV area pins nothing until engaged", function()
	local r = rig(Color3.fromRGB(255, 0, 0))
	assert(r.hue.NextSelectionLeft == r.hue and r.hue.NextSelectionRight == r.hue, "hue: horizontal pinned")
	assert(r.hue.NextSelectionUp == nil and r.hue.NextSelectionDown == nil, "hue: Up/Down still walk the selection on")
	assert(r.area.NextSelectionLeft == nil and r.area.NextSelectionRight == nil, "area: not pinned while merely selected")
	assert(r.area.NextSelectionUp == nil and r.area.NextSelectionDown == nil)
	H.fire(r.hue, "SelectionGained")
	local h0 = internalHSV(r).H
	UIS.InputBegan:Fire(H.input({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Up }))
	assert(near(internalHSV(r).H, h0), "Up is not mapped to the hue")
	H.fire(r.hue, "SelectionLost")
	q.dispose(r.root)
	H.assertNoDebugOutput("d1 hue")
end)

H.section("D1 SV engage mode: A engages (pin four, thick outline), A / B disengage, B never dismisses the dialog meanwhile", function()
	local overlay = Overlay.new()
	local screen = D.Frame { overlay.Layer }
	local dismissed = 0
	local h = overlay:Open({
		Content = function() return D.Frame { Name = "Content" } end,
		Scrim = true,
		DismissOnEscape = true,
		OnClose = function() dismissed += 1 end,
	})
	local r = rig(Color3.fromRGB(255, 0, 0))
	local function key(code: any, ut: any?)
		UIS.InputBegan:Fire(H.input({ UserInputType = ut or Enum.UserInputType.Gamepad1, KeyCode = code }), false)
	end
	local outline = H.find(r.area, "Outline")
	H.finishTweens()
	assert(outline.Thickness == 1)
	H.fire(r.area, "SelectionGained")
	key(Enum.KeyCode.ButtonA)
	H.finishTweens()
	assert(r.area.NextSelectionLeft == r.area and r.area.NextSelectionRight == r.area and r.area.NextSelectionUp == r.area and r.area.NextSelectionDown == r.area)
	assert(outline.Thickness == 5, "thicker while engaged: " .. outline.Thickness)
	key(Enum.KeyCode.ButtonB)
	assert(dismissed == 0 and h.IsOpen:Get(), "B that disengages does not dismiss the dialog (same event)")
	H.advance(0)
	H.finishTweens()
	assert(r.area.NextSelectionLeft == nil and r.area.NextSelectionDown == nil, "unpinned again")
	assert(outline.Thickness == 3, "focused look only")
	key(Enum.KeyCode.ButtonA)
	key(Enum.KeyCode.ButtonA) -- A toggles back
	H.advance(0)
	key(Enum.KeyCode.ButtonB)
	assert(dismissed == 1 and not h.IsOpen:Get(), "B dismisses once nothing is engaged any more")
	H.fire(r.area, "SelectionLost")
	-- selection loss while engaged releases the hold too
	local h2 = overlay:Open({ Content = function() return D.Frame {} end, DismissOnEscape = true })
	key(Enum.KeyCode.ButtonA)
	H.fire(r.area, "SelectionGained")
	key(Enum.KeyCode.Return, Enum.UserInputType.Keyboard)
	H.fire(r.area, "SelectionLost")
	H.advance(0)
	key(Enum.KeyCode.ButtonB)
	assert(not h2.IsOpen:Get(), "hold released after SelectionLost")
	assert(keyConns() == baseKeys, "no connection left")
	q.dispose(r.root)
	q.dispose(screen)
	H.assertNoDebugOutput("d1 engage")
end)

H.section("hex field: round trip, shorthand, invalid reverts", function()
	local r = rig(Color3.fromRGB(255, 0, 0))
	local hb = hexBox(r)
	assert(hb.Text == "#FF0000")
	typeInto(hb, "#00ff00")
	assert(r.value:Get() == Color3.fromRGB(255, 0, 0), "no commit while typing")
	lose(hb)
	assert(r.value:Get() == Color3.fromRGB(0, 255, 0) and hb.Text == "#00FF00", "blur commits and canonicalizes: " .. hb.Text)
	typeInto(hb, "f80")
	lose(hb)
	assert(r.value:Get() == Color3.fromRGB(255, 136, 0) and hb.Text == "#FF8800", "shorthand: " .. hb.Text)
	typeInto(hb, "zz")
	lose(hb)
	assert(r.value:Get() == Color3.fromRGB(255, 136, 0) and hb.Text == "#FF8800", "garbage reverts")
	typeInto(hb, "")
	lose(hb)
	assert(hb.Text == "#FF8800", "empty reverts")
	-- hue kept through hex black / white
	local h0 = internalHSV(r).H
	typeInto(hb, "000000")
	lose(hb)
	assert(near(internalHSV(r).H, h0), "black keeps hue")
	typeInto(hb, "#FFFFFF")
	lose(hb)
	assert(near(internalHSV(r).H, h0) and near(internalHSV(r).S, 0), "white keeps hue")
	assert(#named(H.find(r.root, "Recent"), "Swatch") >= 1, "hex commit is remembered")
	-- a drag while the hex field shows something else rewrites it
	press(r.area, 100, 50)
	release(100, 50)
	assert(hb.Text == "#FFFFFF")
	q.dispose(r.root)
	H.assertNoDebugOutput("hex")
end)

H.section("channel boxes: live commit, mode toggle, ranges, revert, wheel, tab", function()
	local r = rig(Color3.fromRGB(235, 153, 255))
	local b1, b2, b3 = H.find(r.root, "Channel1"), H.find(r.root, "Channel2"), H.find(r.root, "Channel3")
	typeInto(b2, "10")
	assert(r.value:Get().G * 255 - 10 < 1e-6 and math.abs(r.value:Get().G * 255 - 10) < 1e-6, "live commit of G")
	assert(r.value:Get().R == Color3.fromRGB(235, 0, 0).R, "R kept as the byte the user sees")
	lose(b2)
	assert(b2.Text == "10")
	typeInto(b2, "abc")
	lose(b2)
	assert(b2.Text == "10", "invalid reverts")
	typeInto(b2, "")
	lose(b2)
	assert(b2.Text == "10", "empty reverts")
	typeInto(b1, "999")
	lose(b1)
	assert(b1.Text == "255", "clamped")
	-- toggle to HSV
	H.fire(H.find(r.root, "ModeHSV"), "Activated", H.input({}), 1)
	H.finishTweens()
	assert(H.find(H.find(r.root, "Box1"), "Label").Text == "H" and H.find(H.find(r.root, "Box3"), "Label").Text == "V")
	local hsv = internalHSV(r)
	assert(b1.Text == tostring(math.floor(hsv.H * 360 + 0.5)) and b2.Text == tostring(math.floor(hsv.S * 100 + 0.5)), `HSV texts {b1.Text},{b2.Text},{b3.Text}`)
	typeInto(b3, "50")
	assert(near(internalHSV(r).V, 0.5), "V on the 0..100 scale")
	lose(b3)
	typeInto(b1, "400")
	assert(near(internalHSV(r).H, 1), "H clamps at 360")
	lose(b1)
	assert(b1.Text == "360")
	-- echo of the rounded display must not quantize the draft
	local before = internalHSV(r)
	b2.Text = b2.Text
	assert(near(internalHSV(r).S, before.S), "echo is not parsed back")
	-- wheel
	local s = tonumber(b2.Text) :: number
	H.fire(b2, "MouseWheelForward", 0, 0)
	assert(tonumber(b2.Text) == math.min(100, s + 1))
	-- tab: focus moves 1 -> 2
	local calls: { string } = {}
	for i, b in { b1, b2, b3 } do
		b.CaptureFocus = function()
			table.insert(calls, "capture " .. i)
		end
		b.ReleaseFocus = function()
			table.insert(calls, "release " .. i)
			H.fire(b, "FocusLost", false)
		end
	end
	typeInto(b1, "12\t")
	assert(calls[1] == "release 1" and calls[2] == "capture 2" and b1.Text == "12", table.concat(calls, ","))
	-- toggling back
	H.fire(H.find(r.root, "ModeRGB"), "Activated", H.input({}), 1)
	assert(H.find(H.find(r.root, "Box1"), "Label").Text == "R")
	q.dispose(r.root)
	H.assertNoDebugOutput("channels")
end)

H.section("swatches: click, selected ring, recents (order, dedup, cap)", function()
	local r = rig(Color3.fromRGB(10, 20, 30))
	local presets = named(H.find(r.root, "Presets"), "Swatch")
	assert(#presets == 8)
	local first = presets[1]
	local ring = own(first, "UIStroke")
	H.finishTweens()
	assert(ring.Thickness == 1 and ring.Color == L.OutlineVariant, "idle swatch")
	H.fire(first, "MouseEnter")
	H.finishTweens()
	assert(ring.Thickness == 2 and ring.Color == L.Outline, "hover")
	H.fire(first, "MouseLeave")
	H.fire(first, "Activated", H.input({}), 1)
	H.finishTweens()
	assert(r.value:Get() == Color3.fromRGB(0xB3, 0x26, 0x1E), "click sets the color")
	assert(ring.Thickness == 3 and ring.Color == L.Primary, "selected ring")
	assert(#named(H.find(r.root, "Recent"), "Swatch") == 1)
	H.fire(presets[2], "Activated", H.input({}), 1)
	H.fire(presets[3], "Activated", H.input({}), 1)
	local recents = named(H.find(r.root, "Recent"), "Swatch")
	assert(#recents == 3)
	-- newest first through LayoutOrder
	local byOrder: { [number]: any } = {}
	for _, s in recents do
		byOrder[s.LayoutOrder] = s
	end
	assert(byOrder[1].BackgroundColor3 == presets[3].BackgroundColor3 and byOrder[3].BackgroundColor3 == presets[1].BackgroundColor3, "newest first")
	-- clicking an old one moves it to the front, count stays
	H.fire(presets[1], "Activated", H.input({}), 1)
	recents = named(H.find(r.root, "Recent"), "Swatch")
	assert(#recents == 3, "dedup")
	for _, s in recents do
		byOrder[s.LayoutOrder] = s
	end
	assert(byOrder[1].BackgroundColor3 == presets[1].BackgroundColor3, "moved to the front (swatch reused)")
	for i = 4, 8 do
		H.fire(presets[i], "Activated", H.input({}), 1)
	end
	assert(#named(H.find(r.root, "Recent"), "Swatch") == 6, "capped at MaxRecent 6")
	-- a caller-owned Recent source: starts filled, is the same list
	local own1 = q.Source({ Color3.fromRGB(1, 2, 3), Color3.fromRGB(4, 5, 6) })
	local r2 = rig(nil, { Recent = own1, Swatches = { Color3.new(1, 0, 0), Color3.new(0, 1, 0) } })
	assert(#named(H.find(r2.root, "Presets"), "Swatch") == 2 and #named(H.find(r2.root, "Recent"), "Swatch") == 2 and H.find(r2.root, "Recent").Visible == true)
	H.fire(named(H.find(r2.root, "Presets"), "Swatch")[1], "Activated", H.input({}), 1)
	assert(#own1:Get() == 3 and own1:Get()[1] == Color3.new(1, 0, 0), "writes the caller's Source")
	q.dispose(r.root)
	q.dispose(r2.root)
	H.assertNoDebugOutput("swatches")
end)

H.section("preview: initial vs current, no update call", function()
	local r = rig(Color3.fromRGB(0, 0, 255))
	local grad = class(H.find(r.root, "Preview"), "UIGradient")[1]
	local function halves(): (Color3, Color3)
		local kp = grad.Color.Keypoints
		return kp[1].Value, kp[#kp].Value
	end
	local l, c = halves()
	assert(l == Color3.fromRGB(0, 0, 255) and c == l, "starts equal")
	typeInto(hexBox(r), "#FF0000")
	lose(hexBox(r))
	l, c = halves()
	assert(l == Color3.fromRGB(0, 0, 255) and c == Color3.fromRGB(255, 0, 0), "left = initial, right = current")
	-- an explicit Initial State
	local init = q.Source(Color3.fromRGB(9, 9, 9))
	local r2 = rig(Color3.fromRGB(200, 0, 0), { Initial = init })
	local g2 = class(H.find(r2.root, "Preview"), "UIGradient")[1]
	assert(g2.Color.Keypoints[1].Value == Color3.fromRGB(9, 9, 9))
	init:Set(Color3.fromRGB(1, 1, 1))
	assert(g2.Color.Keypoints[1].Value == Color3.fromRGB(1, 1, 1), "Initial State flows")
	q.dispose(r.root)
	q.dispose(r2.root)
	H.assertNoDebugOutput("preview")
end)

H.section("HSV prop: lossless external state; Value+HSV is an error; ShowChannels=false", function()
	local hsv = q.Source({ H = 0.6, S = 0.5, V = 0.5 } :: ColorModel.HSV)
	local root = ColorPicker.Panel({ HSV = hsv, ShowChannels = false })
	assert(H.find(root, "Channels") == nil, "no channel UI")
	local area = H.find(root, "SVArea")
	H.setAbs(area, 0, 0, 100, 100)
	press(area, 0, 100) -- V = 0
	release(0, 100)
	local c = hsv:Get()
	assert(near(c.V, 0) and near(c.H, 0.6), "canonical HSV keeps the hue at black")
	hsv:Set({ H = 0.1, S = 1, V = 1 })
	assert(near(H.find(H.find(root, "HueSlider"), "Halo").Position.X.Scale, 0.1), "outside write of the HSV source shows")
	assert(H.find(H.find(root, "TextField"), "Input").Text == ColorModel.hsvToHex({ H = 0.1, S = 1, V = 1 }), "hex follows the HSV source")
	local ok, err = pcall(function()
		return ColorPicker.Panel({ HSV = hsv, Value = q.Source(Color3.new()) })
	end)
	assert(not ok and string.find(tostring(err), "either HSV or Value", 1, true), tostring(err))
	q.dispose(root)
	H.assertNoDebugOutput("hsv prop")
end)

H.section("disabled: veil shown, pointer on the SV area / hue does nothing", function()
	local off = q.Source(true)
	local r = rig(Color3.fromRGB(255, 0, 0), { Disabled = off })
	local veil = H.find(r.root, "DisabledVeil")
	assert(veil.Visible == true and veil.Active == true)
	H.finishTweens()
	assert(veil.BackgroundTransparency == 0.38)
	local before = r.value:Get()
	press(r.area, 200, 100)
	assert(r.value:Get() == before and dragConns() == baseDrag, "no drag while disabled")
	assert(r.area.Selectable == false and r.hue.Selectable == false)
	off:Set(false)
	assert(veil.Visible == false and r.area.Selectable == true)
	press(r.area, 200, 100)
	assert(r.value:Get() ~= before)
	release(200, 100)
	q.dispose(r.root)
	H.assertNoDebugOutput("disabled")
end)

H.section("theme: dark scheme recolors the labels, swatch rings and toggle", function()
	local theme = require("../src/Theme").new({ Scheme = "dark" })
	local r = rig(nil, { Theme = theme })
	local D3 = Tokens.Color.Dark
	assert(H.find(H.find(r.root, "Box1"), "Label").TextColor3 == D3.OnSurfaceVariant)
	assert(H.find(r.root, "Channel1").TextColor3 == D3.OnSurface)
	assert(H.find(r.root, "ModeRGB").BackgroundColor3 == D3.SecondaryContainer, "selected segment")
	H.fire(H.find(r.root, "ModeHSV"), "Activated", H.input({}), 1)
	H.finishTweens()
	assert(H.find(r.root, "ModeHSV").BackgroundColor3 == D3.SecondaryContainer and H.find(r.root, "ModeRGB").BackgroundTransparency == 1)
	theme:SetScheme("light")
	H.finishTweens()
	assert(H.find(H.find(r.root, "Box1"), "Label").TextColor3 == L.OnSurfaceVariant, "follows a scheme switch")
	q.dispose(r.root)
	H.assertNoDebugOutput("theme")
end)

H.section("modal: draft vs committed, OK / Cancel / scrim, overlay back to baseline", function()
	local overlay = Overlay.new()
	local screen = D.Frame { overlay.Layer }
	local committed = q.Source(Color3.fromRGB(0, 0, 255))
	local recent = q.Source({} :: { Color3 })
	local confirms: { Color3 } = {}
	local cancels = 0
	local function open()
		return ColorPicker.Modal.open({
			Value = committed:Get(),
			Title = "Brand color",
			Overlay = overlay,
			Recent = recent,
			OnConfirm = function(c: Color3)
				table.insert(confirms, c)
				committed:Set(c)
			end,
			OnCancel = function()
				cancels += 1
			end,
		})
	end
	local handle = open()
	local dlg: any = H.find(screen, "Dialog")
	assert(dlg ~= nil and H.find(dlg, "Headline").Text == "Brand color" and dlg.Size == UDim2.fromOffset(360, 0))
	local panel = H.find(dlg, "ColorPicker")
	assert(panel ~= nil)
	print(`material modal instances (overlay entry incl. scrim): {H.countDescendants(screen)}`)
	H.resetOutput()
	local hb = H.find(H.find(panel, "TextField"), "Input")
	assert(hb.Text == "#0000FF")
	-- the notch matches the dialog surface
	assert(H.find(H.find(panel, "TextField"), "Label").BackgroundColor3 == L.SurfaceContainerHigh)
	-- edit the draft
	typeInto(hb, "#FF0000")
	lose(hb)
	assert(committed:Get() == Color3.fromRGB(0, 0, 255), "nothing committed before OK")
	local okBtn = class(H.find(dlg, "Actions"), "TextButton")[2]
	assert(H.find(okBtn, "Label").Text == "OK")
	H.fire(okBtn, "Activated", H.input({}), 1)
	assert(#confirms == 1 and confirms[1] == Color3.fromRGB(255, 0, 0) and committed:Get() == confirms[1] and cancels == 0, "OK commits the draft")
	assert(#recent:Get() == 1 and recent:Get()[1] == Color3.fromRGB(255, 0, 0))
	H.finishTweens()
	H.advance(0.3)
	assert(overlay.Count:Get() == 0 and #overlay.Layer:GetChildren() == 0, "overlay empty after close")
	assert(not handle.IsOpen:Get())
	-- cancel
	local _h2 = open()
	local dlg2: any = H.find(screen, "Dialog")
	local hb2 = H.find(H.find(dlg2, "TextField"), "Input")
	assert(hb2.Text == "#FF0000", "starts from the committed color")
	typeInto(hb2, "#00FF00")
	lose(hb2)
	H.fire(class(H.find(dlg2, "Actions"), "TextButton")[1], "Activated", H.input({}), 1)
	assert(cancels == 1 and #confirms == 1 and committed:Get() == Color3.fromRGB(255, 0, 0), "Cancel discards the draft")
	H.finishTweens()
	H.advance(0.3)
	assert(overlay.Count:Get() == 0)
	-- scrim = dismiss = cancel
	local h3 = open()
	H.fire(H.find(screen, "Scrim"), "Activated", H.input({}), 1)
	assert(cancels == 2 and not h3.IsOpen:Get())
	H.finishTweens()
	H.advance(0.3)
	assert(overlay.Count:Get() == 0 and #overlay.Layer:GetChildren() == 0)
	-- the default Recent source exists and is a Source
	assert(ColorPicker.Recent:Get() ~= nil and #ColorPicker.Defaults == 8)
	assert(ColorPicker.ColorModel == ColorModel)
	assert(dragConns() == baseDrag and keyConns() == baseKeys, "no connection survives the modals")
	q.dispose(screen)
	H.assertNoDebugOutput("modal")
end)

H.section("dispose mid-drag: connections closed, timers drained", function()
	local r = rig()
	press(r.area, 150, 90)
	assert(dragConns() == baseDrag + 3)
	H.fire(r.hue, "SelectionGained")
	q.dispose(r.root)
	assert(dragConns() == baseDrag and keyConns() == baseKeys, "destroyed mid-drag and while selected")
	H.advance(2)
	assert(H.pendingTimers() == 0)
	H.assertNoDebugOutput("dispose")
end)

H.section("D12 the selected swatch carries a check on the swatch itself (no extra instance)", function()
	local r = rig(Color3.fromRGB(10, 20, 30))
	local presets = named(H.find(r.root, "Presets"), "Swatch")
	local first, second = presets[1], presets[2]
	-- the check is the swatch ImageButton's own image (the Material check — Icons default), shown only when selected
	assert(first.ClassName == "ImageButton" and first.Image == "rbxassetid://6031094667")
	assert(first.ImageTransparency == 1 and second.ImageTransparency == 1)
	H.fire(first, "Activated", H.input({}), 1)
	H.finishTweens()
	assert(first.ImageTransparency == 0 and second.ImageTransparency == 1, "the selected swatch shows the check")
	assert(first.ImageColor3 == Color3.new(1, 1, 1) or first.ImageColor3 == Color3.new(0, 0, 0), "contrasting color")
	H.fire(second, "Activated", H.input({}), 1)
	assert(first.ImageTransparency == 1 and second.ImageTransparency == 0)
	q.dispose(r.root)
	H.assertNoDebugOutput("swatch check")
end)

H.section("R2-12 key handlers re-check Disabled (selection gained while enabled, disabled afterwards)", function()
	local off = q.Source(false)
	local r = rig(Color3.fromRGB(255, 0, 0), { Disabled = off })
	local function key(code: any)
		UIS.InputBegan:Fire(H.input({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = code }))
	end
	H.fire(r.hue, "SelectionGained")
	off:Set(true)
	local h0 = internalHSV(r).H
	key(Enum.KeyCode.Right)
	assert(near(internalHSV(r).H, h0), "hue slider ignores keys while disabled")
	H.fire(r.hue, "SelectionLost")
	off:Set(false)
	H.fire(r.area, "SelectionGained")
	key(Enum.KeyCode.Return) -- engage
	off:Set(true)
	local s0 = internalHSV(r)
	key(Enum.KeyCode.Left)
	assert(near(internalHSV(r).S, s0.S), "SV area ignores keys while disabled")
	H.fire(r.area, "SelectionLost")
	q.dispose(r.root)
	assert(keyConns() == baseKeys)
	H.assertNoDebugOutput("disabled keys")
end)

H.section("R2-11 a drag inside a scrolling body switches its scrolling off for the drag and restores it (release, cancel, destroy)", function()
	local r = rig(Color3.fromRGB(100, 40, 200))
	local sf: any = D.ScrollingFrame { ScrollingEnabled = true, r.root }
	assert(sf.ScrollingEnabled == true)
	press(r.area, 150, 100)
	assert(sf.ScrollingEnabled == false, "SV drag locks the body scroll")
	release(150, 100)
	assert(sf.ScrollingEnabled == true, "restored on release")
	press(r.hue, 150, 250)
	assert(sf.ScrollingEnabled == false, "hue drag locks it too")
	UIS.WindowFocusReleased:Fire()
	assert(sf.ScrollingEnabled == true, "restored on cancel")
	press(r.area, 150, 100)
	q.dispose(sf)
	assert(dragConns() == baseDrag, "connections closed on destroy")
	H.assertNoDebugOutput("scroll lock")
end)

-- Studio QA 2026-10-08 (9th): the modal was cut off on a small screen. Dialog `Fit` scales the whole card (DatePicker
-- modal style); the mock has no layout, so the card's laid-out AbsoluteSize is set by hand (ratio = natural height / width).
H.section("modal on a small layer: the whole card scales to fit (no width cap, no scrolling body); the ripple under it", function()
	local overlay = Overlay.new()
	local screen = D.Frame { overlay.Layer }
	H.setAbs(overlay.Layer, 0, 0, 400, 360)
	local handle = ColorPicker.Modal.open({ Value = Color3.fromRGB(0, 120, 255), Overlay = overlay })
	local dlg: any = H.find(screen, "Dialog")
	assert(dlg.Size == UDim2.fromOffset(360, 0), "keeps its width (no cap at layer - 48)")
	assert(H.find(dlg, "BodyScroll") == nil, "no scrolling body (drag surfaces)")
	local scale = own(dlg, "UIScale")
	H.finishTweens()
	assert(scale.Scale == 1, "unlaid card: no fit yet")
	-- the engine lays the card out: natural 360 x 640 (shown at the current scale 1)
	H.setAbs(dlg, 20, -140, 360, 640)
	H.finishTweens()
	local want = math.min(1, (400 - 48) / 360, (360 - 48) / 640)
	assert(math.abs(scale.Scale - want) < 1e-5, "fit " .. want .. " got " .. scale.Scale)
	-- the scaled layout reports the same ratio: no refit loop
	H.setAbs(dlg, 112, 24, 360 * want, 640 * want)
	H.finishTweens()
	assert(math.abs(scale.Scale - want) < 1e-5, "stable under its own scale")
	-- the auto-width OK button under that UIScale: local-unit Offsets (never a partial Scale), ends covering it
	local ok: any = nil
	local buttons = H.findAll(dlg, function(x: any): boolean
		return x.Name == "Button"
	end)
	for _, b in buttons do
		local l = H.find(b, "Label")
		if l ~= nil and l.Text == "OK" then
			ok = b
		end
	end
	assert(ok ~= nil and ok.AutomaticSize == Enum.AutomaticSize.X)
	local layer: any = H.find(ok, "StateLayer")
	local k = scale.Scale
	H.setAbs(ok, 300, 300, 58 * k, 40 * k)
	H.setAbs(layer, 300, 300, 58 * k, 40 * k)
	H.fire(ok, "InputBegan", H.input({ Position = Vector3.new(300 + 50 * k, 300 + 30 * k, 0) }))
	local circle = H.find(ok, "RippleCircle")
	assert(circle ~= nil and circle.Position == UDim2.fromOffset(50, 30), "press point in LOCAL units: " .. tostring(circle and circle.Position))
	for _ = 1, 60 do
		H.advance(1 / 120)
		local p, z = circle.Position, circle.Size
		Bounded.assertNoScale(ok, "OK")
		if not Bounded.isCovered(circle) then
			assert(p.X.Offset >= 0 and p.Y.Offset >= 0 and p.X.Offset + z.X.Offset <= 58 and p.Y.Offset + z.Y.Offset <= 40, "inside the local 58 x 40")
		end
	end
	H.advance(0.5)
	Bounded.assertCovered(circle, "covers the button")
	H.fire(ok, "InputEnded", H.input({}))
	handle.Close(false)
	H.advance(0.6)
	q.dispose(screen)
	H.assertNoDebugOutput("modal fit")
end)

H.done()
