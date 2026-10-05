--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Input = require("../src/Input")

local UIS = H.UserInputService
local function conns(): number
	local function n(sig: any): number
		return #sig.connections
	end
	return n(UIS.InputChanged) + n(UIS.InputEnded) + n(UIS.WindowFocusReleased)
end

local function lost(box: any, enter: boolean)
	H.fire(box, "FocusLost", enter, H.input({}))
end
local function buttons(row: any): (any, any)
	local list = H.findAll(row, function(i)
		return i.ClassName == "TextButton"
	end)
	return list[1], list[2]
end
local function mouseDown(x: number): any
	return H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(x, 0, 0) })
end
local function mouseMove(x: number): any
	return H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(x, 0, 0) })
end
local function mouseUp(x: number): any
	return H.input({
		UserInputType = Enum.UserInputType.MouseButton1,
		UserInputState = Enum.UserInputState.End,
		Position = Vector3.new(x, 0, 0),
	})
end

H.section("InputNum mount: default format, label, +/- buttons, budget", function()
	local v = q.Source(1.5)
	local row = Input.InputNum({ Text = "Speed", Value = v })
	local box = H.find(row, "InputField") :: any
	assert(box.Text == "1.500", box.Text)
	local minus, plus = buttons(row)
	assert(minus.Text == "-" and plus.Text == "+")
	assert((H.find(row, "Label") :: any).Text == "Speed")
	-- row + layout + box(+UICorner/UIPadding/UIStroke/UIFlex) + 2 buttons(+UICorner/UIPadding/UIStroke) + label
	assert(H.countDescendants(row) <= 16, `instances: {H.countDescendants(row)}`)
	local int = Input.InputNum({ Value = q.Source(4), Step = 1 })
	assert((H.find(int, "InputField") :: any).Text == "4", "integral step -> %d")
	local custom = Input.InputNum({ Value = q.Source(2), Format = "%.1f px" })
	assert((H.find(custom, "InputField") :: any).Text == "2.0 px")
	for _, r in { row, int, custom } do
		q.dispose(r)
	end
	H.assertNoDebugOutput("mount")
end)

H.section("typing commits on FocusLost; Source round trip both ways", function()
	local v = q.Source(1)
	local log: { number } = {}
	local row = Input.InputNum({
		Value = v,
		Min = 0,
		Max = 10,
		OnChange = function(n)
			table.insert(log, n)
		end,
	})
	local box = H.find(row, "InputField") :: any
	box.Text = "7.25"
	assert(v:Get() == 1, "nothing written while typing")
	lost(box, true)
	assert(v:Get() == 7.25 and log[1] == 7.25 and box.Text == "7.250", box.Text)
	-- external write updates the box
	v:Set(3)
	assert(box.Text == "3.000" and #log == 1, "external :Set: no OnChange")
	q.dispose(row)
	H.assertNoDebugOutput("typing")
end)

H.section("Min/Max clamp typed text, buttons, and step snapping", function()
	local v = q.Source(5)
	local row = Input.InputNum({ Value = v, Min = 0, Max = 10, Step = 2 })
	local box = H.find(row, "InputField") :: any
	local minus, plus = buttons(row)
	box.Text = "99"
	lost(box, false)
	assert(v:Get() == 10 and box.Text == "10")
	box.Text = "-5"
	lost(box, false)
	assert(v:Get() == 0)
	box.Text = "5"
	lost(box, false)
	assert(v:Get() == 6, "snapped to a multiple of the step from Min")
	H.fire(plus, "Activated", H.input({}), 1)
	assert(v:Get() == 8)
	H.fire(plus, "Activated", H.input({}), 1)
	H.fire(plus, "Activated", H.input({}), 1)
	assert(v:Get() == 10, "+ clamps at Max")
	H.fire(minus, "Activated", H.input({}), 1)
	assert(v:Get() == 8 and box.Text == "8")
	v:Set(0)
	H.fire(minus, "Activated", H.input({}), 1)
	assert(v:Get() == 0, "- clamps at Min")
	q.dispose(row)
	H.assertNoDebugOutput("clamp")
end)

H.section("invalid text reverts to the current value", function()
	local v = q.Source(2.5)
	local row = Input.InputNum({ Value = v })
	local box = H.find(row, "InputField") :: any
	box.Text = "abc"
	lost(box, true)
	assert(v:Get() == 2.5 and box.Text == "2.500", "reverted: " .. box.Text)
	box.Text = ""
	lost(box, false)
	assert(v:Get() == 2.5 and box.Text == "2.500")
	-- unchanged-but-reformatted text is canonicalised too
	box.Text = "2.5000001"
	lost(box, false)
	assert(box.Text == "2.500" or v:Get() ~= 2.5)
	q.dispose(row)
	H.assertNoDebugOutput("revert")
end)

H.section("Disabled: not editable, buttons inert", function()
	local v = q.Source(1)
	local dis = q.Source(true)
	local row = Input.InputNum({ Value = v, Disabled = dis })
	local box = H.find(row, "InputField") :: any
	local _, plus = buttons(row)
	assert(box.TextEditable == false)
	H.fire(plus, "Activated", H.input({}), 1)
	assert(v:Get() == 1)
	dis:Set(false)
	assert(box.TextEditable == true)
	H.fire(plus, "Activated", H.input({}), 1)
	assert(v:Get() == 2)
	q.dispose(row)
	H.assertNoDebugOutput("disabled")
end)

H.section("DragNum: horizontal drag changes the value (Speed, Min/Max, Step)", function()
	local base = conns()
	local v = q.Source(10)
	local log: { number } = {}
	local row = Input.DragNum({
		Value = v,
		Speed = 0.5,
		Min = 0,
		Max = 20,
		OnChange = function(n)
			table.insert(log, n)
		end,
	})
	local box = H.find(row, "DragField") :: any
	assert(box.TextEditable == false and box.TextXAlignment == Enum.TextXAlignment.Center)
	assert(box.Text == "10.000")
	H.fire(box, "InputBegan", mouseDown(100))
	assert(conns() == base + 3, "global tracking only while dragging")
	UIS.InputChanged:Fire(mouseMove(102), false)
	assert(v:Get() == 10, "dead zone")
	UIS.InputChanged:Fire(mouseMove(110), false)
	assert(v:Get() == 15 and box.Text == "15.000")
	UIS.InputChanged:Fire(mouseMove(400), false)
	assert(v:Get() == 20, "clamped to Max")
	UIS.InputChanged:Fire(mouseMove(-400), false)
	assert(v:Get() == 0, "clamped to Min")
	UIS.InputEnded:Fire(mouseUp(-400), false)
	assert(conns() == base, "closed on release")
	assert(box.TextEditable == false, "a real drag does not open the editor")
	assert(log[#log] == 0)
	-- external write follows
	v:Set(7)
	assert(box.Text == "7.000")
	q.dispose(row)
	H.assertNoDebugOutput("drag")
end)

H.section("DragNum with Step snaps; default Speed is the Step", function()
	local v = q.Source(0)
	local row = Input.DragNum({ Value = v, Step = 5 })
	local box = H.find(row, "DragField") :: any
	assert(box.Text == "0", "integral step -> %d")
	H.fire(box, "InputBegan", mouseDown(0))
	UIS.InputChanged:Fire(mouseMove(7), false)
	assert(v:Get() == 35, "7px * speed 5 = 35")
	UIS.InputChanged:Fire(mouseMove(10), false)
	assert(v:Get() == 50)
	UIS.InputEnded:Fire(mouseUp(10), false)
	q.dispose(row)
	H.assertNoDebugOutput("drag step")
end)

H.section("DragNum: click without drag edits the text; Enter commits; invalid reverts", function()
	local v = q.Source(3)
	local row = Input.DragNum({ Value = v, Min = 0, Max = 100 })
	local box = H.find(row, "DragField") :: any
	local focused = 0
	box.CaptureFocus = function()
		focused += 1
	end
	H.fire(box, "InputBegan", mouseDown(50))
	UIS.InputEnded:Fire(mouseUp(51), false)
	assert(box.TextEditable == true and focused == 1, "click opens the editor and takes focus")
	box.Text = "42"
	lost(box, true)
	assert(v:Get() == 42 and box.TextEditable == false and box.Text == "42.000")
	-- a second click re-opens the editor; invalid text reverts on focus loss
	H.fire(box, "InputBegan", mouseDown(0))
	UIS.InputEnded:Fire(mouseUp(0), false)
	assert(box.TextEditable == true and focused == 2)
	box.Text = "junk"
	lost(box, false)
	assert(v:Get() == 42 and box.Text == "42.000" and box.TextEditable == false)
	-- a dragged press while editing (selecting text) must not change the value
	H.fire(box, "InputBegan", mouseDown(0))
	UIS.InputEnded:Fire(mouseUp(0), false)
	assert(box.TextEditable == true)
	H.fire(box, "InputBegan", mouseDown(0))
	UIS.InputChanged:Fire(mouseMove(30), false)
	assert(v:Get() == 42, "no value drag while the editor is open")
	UIS.InputEnded:Fire(mouseUp(30), false)
	assert(box.TextEditable == true, "still editing")
	lost(box, true)
	q.dispose(row)
	H.assertNoDebugOutput("click edit")
end)

H.section("DragNum Disabled ignores drag and click; dispose mid-drag closes connections", function()
	local base = conns()
	local v = q.Source(1)
	local dis = q.Source(true)
	local row = Input.DragNum({ Value = v, Disabled = dis })
	local box = H.find(row, "DragField") :: any
	H.fire(box, "InputBegan", mouseDown(0))
	UIS.InputChanged:Fire(mouseMove(50), false)
	UIS.InputEnded:Fire(mouseUp(50), false)
	assert(v:Get() == 1 and box.TextEditable == false)
	dis:Set(false)
	H.fire(box, "InputBegan", mouseDown(0))
	UIS.InputChanged:Fire(mouseMove(50), false)
	assert(v:Get() == 51)
	q.dispose(row)
	assert(conns() == base, "dispose mid-drag leaks nothing")
	H.assertNoDebugOutput("drag disabled")
end)

H.section("dispose baseline for InputNum", function()
	local base = conns()
	local row = Input.InputNum({ Value = q.Source(1) })
	q.dispose(row)
	assert(conns() == base and H.isDestroyed(row))
	H.assertNoDebugOutput("dispose")
end)

H.done()
