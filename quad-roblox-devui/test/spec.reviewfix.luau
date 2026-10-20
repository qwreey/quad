--!strict
-- Review 2026-10-13 (triage): one section per class-A fix. Each section FAILS on the unpatched source.
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Frame = q.Elem "Frame"
local ScreenGui = q.Elem "ScreenGui"
local Devui = require("../src")
local Input = require("../src/Inputs")
local Overlay = require("../src/Overlay")
local UIS = H.UserInputService

local function lost(box: any, enter: boolean)
	H.fire(box, "FocusLost", enter, H.input({}))
end
-- a Drag field: click (press + release in place) opens its editor
local function clickOpen(box: any)
	box.CaptureFocus = function() end
	H.fire(box, "InputBegan", H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(0, 0, 0) }))
	UIS.InputEnded:Fire(
		H.input({
			UserInputType = Enum.UserInputType.MouseButton1,
			UserInputState = Enum.UserInputState.End,
			Position = Vector3.new(0, 0, 0),
		}),
		false
	)
	assert(box.TextEditable == true, "click opened the editor")
end

H.section("R1 number / hex fields: leaving a box without an edit writes nothing and calls no OnChange", function()
	-- InputNum: the value is finer than the "%.3f" text
	local v = q.Source(0.12345)
	local changes = 0
	local row = Input.InputNum({ Value = v, OnChange = function()
		changes += 1
	end })
	local box: any = H.find(row, "InputField")
	assert(box.Text == "0.123", box.Text)
	lost(box, false)
	assert(v:Get() == 0.12345 and changes == 0, `InputNum: value {v:Get()}, OnChange {changes}`)
	lost(box, true)
	assert(v:Get() == 0.12345 and changes == 0, "Enter without an edit")
	-- an edit still commits; invalid text still reverts
	box.Text = "0.5"
	lost(box, true)
	assert(v:Get() == 0.5 and changes == 1 and box.Text == "0.500")
	box.Text = "junk"
	lost(box, false)
	assert(v:Get() == 0.5 and changes == 1 and box.Text == "0.500", "invalid text reverts")
	-- typing the text the box already shows is not an edit either
	v:Set(0.12345)
	box.Text = "0.123"
	lost(box, true)
	assert(v:Get() == 0.12345 and changes == 1)
	-- "%d" shows 3.7 as "4"
	local d = q.Source(3.7)
	local row2 = Input.InputNum({ Value = d, Format = "%d", OnChange = function()
		changes += 1
	end })
	lost(H.find(row2, "InputField"), false)
	assert(d:Get() == 3.7 and changes == 1, `"%d": value {d:Get()}`)
	-- a vector component
	local vec = q.Source(Vector2.new(0.12345, 1))
	local vecChanges = 0
	local row3 = Input.InputVector2({ Value = vec, OnChange = function()
		vecChanges += 1
	end })
	lost(H.find(row3, "X"), false)
	assert(vec:Get() == Vector2.new(0.12345, 1) and vecChanges == 0, "InputVector2 component")
	-- DragNum: click (opens the editor), leave
	local dv = q.Source(0.12345)
	local dragChanges = 0
	local row4 = Input.DragNum({ Value = dv, OnChange = function()
		dragChanges += 1
	end })
	local dbox: any = H.find(row4, "DragField")
	clickOpen(dbox)
	lost(dbox, false)
	assert(dv:Get() == 0.12345 and dragChanges == 0 and dbox.TextEditable == false, `DragNum click + leave: value {dv:Get()}`)
	-- InputColor3: a colour off the 8-bit grid; the hex box and a channel box
	local grey = Color3.new(0.5, 0.5, 0.5)
	local c = q.Source(grey)
	local colorChanges = 0
	local row5 = Input.InputColor3({ Value = c, OnChange = function()
		colorChanges += 1
	end })
	local hex: any = H.find(row5, "Hex")
	assert(hex.Text == "#808080", hex.Text)
	lost(hex, false)
	assert(c:Get() == grey and colorChanges == 0, "hex box: focus alone keeps the colour")
	local r: any = H.find(row5, "R")
	clickOpen(r)
	lost(r, false)
	assert(c:Get() == grey and colorChanges == 0, "R box: click + leave keeps the colour")
	hex.Text = "#ff0000"
	lost(hex, true)
	assert(c:Get() == Color3.fromRGB(255, 0, 0) and colorChanges == 1, "a typed hex commits")
	hex.Text = "zz"
	lost(hex, false)
	assert(hex.Text == "#ff0000" and colorChanges == 1, "invalid hex reverts")
	for _, x in { row, row2, row3, row4, row5 } do
		q.dispose(x)
	end
	H.assertNoDebugOutput("R1")
end)

H.section("R2 Combo: an OnChange that throws does not leave the list (and its click catcher) open", function()
	Overlay.warnUnmounted = false
	local o = Overlay.new()
	local v = q.Source("a")
	local combo = Devui.Combo<<string>>({ Text = "c", Value = v, Options = { "a", "b" }, Overlay = o, OnChange = function(_picked: string)
		error("boom")
	end })
	H.fire(H.find(combo, "Box"), "Activated")
	assert(o.Count:Get() == 1, "list open")
	local options = H.findAll(o.Layer, function(i: any)
		return i.Name == "Option"
	end)
	local ok = pcall(function()
		H.fire(options[2], "Activated")
	end)
	assert(not ok, "the callback's error surfaces")
	assert(v:Get() == "b", "the value was written")
	assert(o.Count:Get() == 0, `the list closed ({o.Count:Get()} popups left)`)
	q.dispose(combo)
	q.dispose(o.Layer)
	Overlay.warnUnmounted = true
	H.resetOutput()
end)

H.section("R3 q.debug: the first Open under a ScreenGui that is not ZIndexBehavior Sibling says so, once", function()
	local function openOnce(overlay: any)
		overlay:Open({ Content = Frame({}), Position = Vector2.new(0, 0) }):Close()
	end
	H.resetOutput()
	local global = Overlay.new()
	local screenGlobal = ScreenGui({ Name = "App", ZIndexBehavior = Enum.ZIndexBehavior.Global, global.Layer })
	openOnce(global)
	local out = H.output()
	assert(
		#out == 1 and string.find(out[1], "ZIndexBehavior = Global", 1, true) ~= nil and string.find(out[1], '"App"', 1, true) ~= nil,
		"one line naming the ScreenGui: " .. table.concat(out, " | ")
	)
	openOnce(global)
	assert(#H.output() == 1, "once per overlay")
	H.resetOutput()
	local sibling = Overlay.new()
	local screenSibling = ScreenGui({ ZIndexBehavior = Enum.ZIndexBehavior.Sibling, sibling.Layer })
	openOnce(sibling)
	H.assertNoDebugOutput("Sibling")
	-- a layer not under a ScreenGui yet keeps the check for later (only the "not mounted" line speaks)
	local late = Overlay.new()
	local holder = Frame({ late.Layer })
	openOnce(late)
	H.assertNoDebugOutput("no ScreenGui yet")
	local screenLate = ScreenGui({ Name = "Late", ZIndexBehavior = Enum.ZIndexBehavior.Global, holder })
	openOnce(late)
	assert(#H.output() == 1, "said once the layer is under a ScreenGui")
	H.resetOutput()
	q.debug = false
	local quiet = Overlay.new()
	local screenQuiet = ScreenGui({ ZIndexBehavior = Enum.ZIndexBehavior.Global, quiet.Layer })
	openOnce(quiet)
	q.debug = true
	H.assertNoDebugOutput("q.debug off")
	for _, s in { screenGlobal, screenSibling, screenLate, screenQuiet } do
		q.dispose(s)
	end
end)

H.section("R4 DragNum: Disabled set during a drag stops the drag's writes", function()
	local v, disabled = q.Source(10), q.Source(false)
	local changes = 0
	local row = Input.DragNum({ Value = v, Disabled = disabled, OnChange = function()
		changes += 1
	end })
	local box: any = H.find(row, "DragField")
	local function move(x: number)
		UIS.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(x, 0, 0) }), false)
	end
	H.fire(box, "InputBegan", H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(0, 0, 0) }))
	move(10)
	assert(v:Get() == 20 and changes == 1, `the drag writes while enabled ({v:Get()})`)
	disabled:Set(true)
	move(30)
	assert(v:Get() == 20 and changes == 1, `disabled mid-drag: value {v:Get()}, OnChange {changes}`)
	UIS.InputEnded:Fire(
		H.input({ UserInputType = Enum.UserInputType.MouseButton1, UserInputState = Enum.UserInputState.End, Position = Vector3.new(30, 0, 0) }),
		false
	)
	assert(v:Get() == 20 and box.TextEditable == false, "the release of a moved drag does not open the editor")
	q.dispose(row)
	H.assertNoDebugOutput("R4")
end)

H.done()
