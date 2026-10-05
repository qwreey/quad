--!strict
local H = require("./support/harness")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
local ClassicColorPicker = require("../src/ColorPicker/Classic")
local Demo = require("../src/ColorPicker/Classic/Demo")
local ColorModel = require("../src/ColorPicker/ColorModel")

local UIS = H.UserInputService
local function uisConns(): number
	local u = UIS :: any
	return #u.InputChanged.connections + #u.InputEnded.connections + #u.WindowFocusReleased.connections
end
local baseConns = uisConns()

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

type Rig = {
	root: any,
	hsv: any,
	updates: { string },
	confirms: { string },
	cancels: { string },
	field: any,
	hue: any,
}

local function pos(x: number, y: number): Vector3
	return Vector3.new(x, y, 0)
end

-- mounts one window (Dark) and gives the mock the layout numbers it lacks
local function rig(initial: any?, last: Color3?): Rig
	local hsv = q.Source((initial or { H = 0.8, S = 0.4, V = 1 }) :: any)
	local r: Rig = { root = nil, hsv = hsv, updates = {}, confirms = {}, cancels = {}, field = nil, hue = nil }
	r.root = ClassicColorPicker({
		Theme = "Dark",
		Value = hsv :: any,
		LastColor = last or Color3.fromRGB(222, 0, 222),
		OnUpdate = function(_c: Color3, h: number, s: number, v: number)
			table.insert(r.updates, `{h},{s},{v}`)
		end,
		OnConfirm = function(c: Color3)
			table.insert(r.confirms, tostring(c))
		end,
		OnCancel = function(l: Color3, d: Color3)
			table.insert(r.cancels, `{l}|{d}`)
		end,
	})
	r.field = H.find(r.root, "SaturationBrightnessPicker")
	r.hue = H.find(r.root, "HuePicker")
	H.setAbs(r.root, 500, 100, 230, 418)
	H.setAbs(r.field, 516, 142, 198, 198) -- inner (padded) rect: 520..710 x 146..336
	H.setAbs(r.hue, 516, 350, 198, 14) -- inner track: 521..709
	return r
end

local function cur(r: Rig): ColorModel.HSV
	return r.hsv:Get()
end

local function drag(el: any, from: Vector3, moves: { Vector3 }, to: Vector3?)
	H.fire(el, "InputBegan", H.input({ Position = from }))
	for _, m in moves do
		UIS.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = m }))
	end
	if to then
		UIS.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = to }))
	end
end

local function box(r: Rig, name: string): any
	return H.find(r.root, name)
end

local function typeInto(b: any, text: string)
	H.fire(b, "Focused")
	b.Text = text
end

local function lose(b: any)
	H.fire(b, "FocusLost", false)
end

H.section("mount: structure, theme, original sizes", function()
	local r = rig()
	local count = H.countDescendants(r.root)
	print(`classic window descendants: {count} (+1 host = {count + 1} instances)`)
	H.resetOutput()
	assert(r.root.Size == UDim2.fromOffset(230, 418))
	assert(r.root.BackgroundColor3 == Color3.fromRGB(41, 41, 41), "Dark window")
	assert(H.find(r.root, "TitleText").Text == "Color Picker" and H.find(r.root, "TitleText").Font == Enum.Font.GothamBold)
	assert(H.find(r.root, "CancelButton").Size == UDim2.fromOffset(63, 32) and H.find(r.root, "CancelButton").Text == "Cancel")
	assert(H.find(r.root, "SelectButton").BackgroundColor3 == Color3.fromRGB(106, 0, 255))
	assert(r.field.BackgroundColor3 == Color3.new(ColorModel.hueToRgb(0.8)), "SV tint = pure hue")
	assert(box(r, "HBox").Text == "204" and box(r, "SBox").Text == "102" and box(r, "VBox").Text == "255", "H/S/V on the 0..255 scale")
	assert(box(r, "RBox").Text == "235" and box(r, "GBox").Text == "153" and box(r, "BBox").Text == "255", "RGB bytes")
	assert(box(r, "HEXBox").Text == "EB99FF", "hex without #: " .. box(r, "HEXBox").Text)
	assert(near(H.find(r.root, "Handle").Position.X.Scale, 0.8))
	assert(near(H.find(r.root, "Cursor").Position.X.Scale, 0.4) and near(H.find(r.root, "Cursor").Position.Y.Scale, 0))
	local holder = H.find(r.root, "Holder")
	local order: { string } = {}
	for _, c in holder:GetChildren() do
		if c.LayoutOrder ~= nil and c.ClassName ~= "UIPadding" then
			order[c.LayoutOrder + 1] = c.Name
		end
	end
	assert(table.concat(order, ",") == "TitleBar,SaturationBrightnessPicker,HuePicker,HsvEditRow,RgbEditRow,HexEditRow,ConfirmBar", table.concat(order, ","))
	q.dispose(r.root)
	H.assertNoDebugOutput("mount")
end)

H.section("SV drag: writes S and V atomically, fake cursor only outside, system cursor toggled", function()
	local r = rig()
	drag(r.field, pos(520, 146), {}, nil) -- press on the top-left of the padded area
	assert(near(cur(r).S, 0) and near(cur(r).V, 1) and near(cur(r).H, 0.8), "press maps to S=0,V=1")
	assert((UIS.MouseIconEnabled :: any) == false, "system cursor hidden while dragging")
	assert(uisConns() == baseConns + 3)
	UIS.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = pos(615, 241) }))
	assert(near(cur(r).S, 0.5) and near(cur(r).V, 0.5), `middle: {cur(r).S},{cur(r).V}`)
	local fake = H.find(r.root, "FakeCursor")
	H.finishTweens()
	assert(fake.ImageTransparency == 1, "inside the field: no fake cursor")
	UIS.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = pos(900, 240) }))
	assert(near(cur(r).S, 1), "clamped at the right edge")
	H.finishTweens()
	assert(fake.ImageTransparency == 0, "far outside: fake cursor shown")
	assert(fake.Position == UDim2.fromOffset(900 - 500, 240 - 100), "fake cursor at the pointer, window space")
	-- the ring grows while pressed
	local ring = H.find(r.root, "Cursor")
	assert(ring.Size == UDim2.fromOffset(26, 26), "ring 26 px while pressed")
	UIS.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = pos(520, 336) }))
	H.finishTweens()
	assert(near(cur(r).S, 0) and near(cur(r).V, 0), "release position counts")
	assert((UIS.MouseIconEnabled :: any) == true and uisConns() == baseConns, "restored and closed")
	assert(ring.Size == UDim2.fromOffset(16, 16) and fake.ImageTransparency == 1)
	assert(#r.updates >= 3, "OnUpdate per user change")
	q.dispose(r.root)
	H.assertNoDebugOutput("sv drag")
end)

H.section("hue drag: bubble pops, handle follows, hue survives black and back", function()
	local r = rig()
	local bubble = H.find(r.root, "PreviewBubble")
	assert((bubble.Visible :: any) == false)
	H.finishTweens()
	assert(near(H.find(bubble, "BubbleColor").BackgroundColor3.R, ColorModel.hueToRgb(0.8)))
	drag(r.hue, pos(521 + 94, 357), {})
	assert((bubble.Visible :: any) == true, "bubble visible at once")
	assert(near(cur(r).H, 0.5), "press at the middle of the padded track")
	H.finishTweens()
	local scale = H.find(bubble, "UIScale") or H.findAll(bubble, function(c: any) return c.ClassName == "UIScale" end)[1]
	assert(scale.Scale == 1, "bubble scale 1")
	assert(H.find(r.root, "Fill").BackgroundTransparency == 1, "fill hidden while dragging")
	assert(near(H.find(r.root, "Handle").Position.X.Scale, 0.5))
	UIS.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = pos(100, 357) }))
	assert(near(cur(r).H, 0), "clamped at the left")
	UIS.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = pos(521 + 188 * 0.3, 357) }))
	assert(near(cur(r).H, 0.3), "release position counts")
	H.finishTweens()
	assert(scale.Scale == 0 and (bubble.Visible :: any) == false, "hidden after the shrink COMPLETES")
	assert(H.find(r.root, "Fill").BackgroundTransparency == 0)
	-- H=0.3 is now set; go to black through the RGB boxes and come back: hue/saturation are kept
	local s0 = cur(r).S
	typeInto(box(r, "HEXBox"), "000000")
	lose(box(r, "HEXBox"))
	assert(near(cur(r).V, 0) and near(cur(r).H, 0.3) and near(cur(r).S, s0), "black keeps H and S")
	typeInto(box(r, "HEXBox"), "FFFFFF")
	lose(box(r, "HEXBox"))
	assert(near(cur(r).H, 0.3) and near(cur(r).S, 0) and near(cur(r).V, 1), "white keeps H")
	q.dispose(r.root)
	H.assertNoDebugOutput("hue drag")
end)

H.section("text boxes: live commit, invalid/empty revert, clamp, hex, no quantizing echo", function()
	local r = rig({ H = 0.4812, S = 0.4, V = 1 })
	local hb = box(r, "HBox")
	assert(hb.Text == "123")
	-- unfocused echo of the rounded display must not quantize the draft
	hb.Text = "123"
	assert(near(cur(r).H, 0.4812), "echo is not parsed back")
	typeInto(hb, "100")
	assert(near(cur(r).H, 100 / 255) and #r.updates == 1, "valid text commits live")
	lose(hb)
	assert(hb.Text == "100")
	typeInto(hb, "abc")
	assert(near(cur(r).H, 100 / 255), "invalid not committed")
	lose(hb)
	assert(hb.Text == "100", "invalid reverts on focus loss: " .. hb.Text)
	typeInto(hb, "")
	lose(hb)
	assert(hb.Text == "100", "empty reverts")
	local sb = box(r, "SBox")
	typeInto(sb, "300")
	assert(near(cur(r).S, 1), "out of range clamps")
	lose(sb)
	assert(sb.Text == "255")
	-- RGB: one channel, the others keep the bytes the user sees
	local gb = box(r, "GBox")
	typeInto(gb, "10")
	lose(gb)
	local _, g = ColorModel.toBytes(cur(r))
	assert(g == 10 and gb.Text == "10", `G byte {g}`)
	-- hex, live only at 6 digits
	local xb = box(r, "HEXBox")
	local before = cur(r)
	typeInto(xb, "ff8")
	assert(ColorModel.equalsHSV(cur(r), before), "3 digits are not committed live")
	lose(xb)
	assert(box(r, "RBox").Text == "255" and box(r, "BBox").Text == "136" and xb.Text == "FFFF88", `shorthand on focus loss: {xb.Text}`)
	typeInto(xb, "#00ff00")
	assert(box(r, "GBox").Text == "255" and box(r, "RBox").Text == "0", "6 digits (with #) commit live")
	lose(xb)
	q.dispose(r.root)
	H.assertNoDebugOutput("text boxes")
end)

H.section("keys: tab cycles H>S>V>H, wheel is +/-1 even on an empty box", function()
	local r = rig()
	local calls: { string } = {}
	for _, n in { "HBox", "SBox", "VBox" } do
		local b = box(r, n)
		b.CaptureFocus = function()
			table.insert(calls, "capture " .. n)
		end
		b.ReleaseFocus = function()
			table.insert(calls, "release " .. n)
			H.fire(b, "FocusLost", false)
		end
	end
	local hb = box(r, "HBox")
	typeInto(hb, "12\t")
	assert(calls[1] == "release HBox" and calls[2] == "capture SBox", table.concat(calls, ","))
	assert(hb.Text == "12", "tab character removed from the box: " .. hb.Text)
	typeInto(box(r, "VBox"), "5\t")
	assert(calls[4] == "capture HBox", table.concat(calls, ","))
	typeInto(box(r, "HEXBox"), "804020")
	lose(box(r, "HEXBox"))
	local rb = box(r, "RBox")
	local before = tonumber(rb.Text) :: number
	H.fire(rb, "MouseWheelBackward", 0, 0)
	assert(tonumber(rb.Text) == before - 1)
	lose(box(r, "HEXBox"))
	typeInto(rb, "")
	H.fire(rb, "MouseWheelForward", 0, 0)
	lose(rb)
	assert(rb.Text ~= "", "wheel on an empty box does not error")
	q.dispose(r.root)
	H.assertNoDebugOutput("keys")
end)

H.section("confirm / cancel / close", function()
	local r = rig({ H = 0.8, S = 0.4, V = 1 }, Color3.fromRGB(222, 0, 222))
	local preview = H.find(r.root, "Preview")
	local grad = H.findAll(preview, function(c: any)
		return c.ClassName == "UIGradient"
	end)[1]
	local function halves(): (Color3, Color3)
		local kp = grad.Color.Keypoints
		return kp[1].Value, kp[#kp].Value
	end
	local l, c = halves()
	assert(l == Color3.fromRGB(222, 0, 222) and c == ColorModel.toColor3(cur(r)), "left = last, right = draft")
	typeInto(box(r, "HEXBox"), "00FF00")
	lose(box(r, "HEXBox"))
	local _, c2 = halves()
	assert(c2 == Color3.fromRGB(0, 255, 0), "preview follows the draft (no update call)")
	H.fire(H.find(r.root, "SelectButton"), "Activated", H.input({}), 1)
	assert(#r.confirms == 1)
	local l2 = halves()
	assert(l2 == Color3.fromRGB(0, 255, 0), "confirm: last := draft")
	typeInto(box(r, "HEXBox"), "0000FF")
	lose(box(r, "HEXBox"))
	local updates = #r.updates
	H.fire(H.find(r.root, "CancelButton"), "Activated", H.input({}), 1)
	assert(#r.cancels == 1 and #r.updates == updates, "cancel fires OnCancel, not OnUpdate")
	assert(cur(r).H > 0.3 and cur(r).H < 0.4 and box(r, "HEXBox").Text == "00FF00", "draft restored: " .. box(r, "HEXBox").Text)
	assert(box(r, "HBox").Text == tostring(math.floor(cur(r).H * 255 + 0.5)), "boxes show the restored HSV (original showed the old one)")
	-- close = cancel
	typeInto(box(r, "HEXBox"), "FF0000")
	lose(box(r, "HEXBox"))
	H.fire(H.find(r.root, "CloseButton"), "Activated", H.input({}), 1)
	assert(#r.cancels == 2 and box(r, "HEXBox").Text == "00FF00")
	q.dispose(r.root)
	H.assertNoDebugOutput("confirm cancel")
end)

H.section("button dim and close icon follow hover/press", function()
	local r = rig()
	local sel = H.find(r.root, "SelectButton")
	local base = sel.BackgroundColor3
	H.fire(sel, "MouseEnter")
	H.finishTweens()
	local hover = sel.BackgroundColor3
	assert(near(hover.R, base.R * 0.8) or hover ~= base, "hover dims")
	H.fire(sel, "InputBegan", H.input({ Position = pos(1, 1) }))
	H.finishTweens()
	local pressed = sel.BackgroundColor3
	assert(pressed.R < hover.R or pressed.B < hover.B, "pressed dims more")
	H.fire(sel, "MouseLeave")
	H.finishTweens()
	assert(sel.BackgroundColor3 == base, "leave restores")
	local close = H.find(r.root, "CloseButton")
	assert((H.find(close, "CloseIcon").Visible :: any) == false)
	H.fire(close, "MouseEnter")
	assert((H.find(close, "CloseIcon").Visible :: any) == true, "x appears on hover")
	q.dispose(r.root)
	H.assertNoDebugOutput("dim")
end)

H.section("focus loss and destroy mid-drag close everything and restore the cursor", function()
	local r = rig()
	drag(r.field, pos(600, 200), {})
	UIS.WindowFocusReleased:Fire()
	assert(uisConns() == baseConns and (UIS.MouseIconEnabled :: any) == true, "focus loss ends the drag (no error)")
	H.fire(r.hue, "InputBegan", H.input({ Position = pos(600, 357) }))
	assert(uisConns() == baseConns + 3 and (UIS.MouseIconEnabled :: any) == false)
	q.dispose(r.root)
	assert(uisConns() == baseConns and (UIS.MouseIconEnabled :: any) == true, "destroyed mid-drag")
	H.advance(2)
	assert(H.pendingTimers() == 0)
	H.assertNoDebugOutput("focus loss")
end)

H.section("demo: two windows, original initial state, logging", function()
	local lines: { string } = {}
	local root = Demo.build({
		Log = function(s: string)
			table.insert(lines, s)
		end,
	})
	local wins = H.findAll(root, function(c: any)
		return c.Name == "ClassicColorPicker"
	end)
	assert(#wins == 2 and wins[1].BackgroundColor3 == Color3.fromRGB(255, 255, 255) and wins[2].BackgroundColor3 == Color3.fromRGB(41, 41, 41))
	local layout = H.findAll(root, function(c: any)
		return c.ClassName == "UIListLayout" and c.Padding == UDim.new(0, 32)
	end)
	assert(#layout == 1)
	local sel = H.findAll(wins[1], function(c: any)
		return c.Name == "SelectButton"
	end)[1]
	H.fire(sel, "Activated", H.input({}), 1)
	assert(lines[1] == "[confirm] rgb(235, 153, 255), hsv(204, 102, 255)", lines[1])
	local cancel = H.findAll(wins[2], function(c: any)
		return c.Name == "CancelButton"
	end)[1]
	H.fire(cancel, "Activated", H.input({}), 1)
	assert(lines[2] == "[cancel] last = rgb(222, 0, 222), draft = rgb(235, 153, 255)", lines[2])
	local n = H.countDescendants(root)
	print(`demo descendants: {n}`)
	H.resetOutput()
	q.dispose(root)
	assert(uisConns() == baseConns)
	H.assertNoDebugOutput("demo")
end)

H.section("A-M2 a cursor the game had already hidden stays hidden after the drag", function()
	local r = rig()
	;(UIS :: any).MouseIconEnabled = false
	drag(r.field, pos(520, 146), {}, nil)
	assert((UIS.MouseIconEnabled :: any) == false)
	UIS.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = pos(520, 336) }))
	H.finishTweens()
	assert((UIS.MouseIconEnabled :: any) == false, "restored to the value found (hidden), not forced visible")
	;(UIS :: any).MouseIconEnabled = true
	drag(r.field, pos(520, 146), {}, nil)
	assert((UIS.MouseIconEnabled :: any) == false)
	UIS.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = pos(520, 336) }))
	H.finishTweens()
	assert((UIS.MouseIconEnabled :: any) == true, "visible before, visible after")
	q.dispose(r.root)
	assert(uisConns() == baseConns)
	H.assertNoDebugOutput("a-m2")
end)

H.done()
