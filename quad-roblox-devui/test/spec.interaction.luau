--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local D = q.Declaration
local Interaction = require("../src/Interaction")

local UIS = H.UserInputService
local function conns(): number
	local function n(sig: any): number
		return #sig.connections
	end
	return n(UIS.InputChanged) + n(UIS.InputEnded) + n(UIS.WindowFocusReleased)
end

local function mouseDown(x: number, y: number): any
	return H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(x, y, 0) })
end
local function mouseMove(x: number, y: number): any
	return H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(x, y, 0) })
end
local function mouseUp(x: number, y: number): any
	return H.input({
		UserInputType = Enum.UserInputType.MouseButton1,
		UserInputState = Enum.UserInputState.End,
		Position = Vector3.new(x, y, 0),
	})
end

H.section("hover / pressed states", function()
	local hover = Interaction.hover()
	local f = D.TextButton({ hover.Hook, Text = "x" })
	assert(hover.Hovered:Get() == false and hover.Pressed:Get() == false)
	H.fire(f, "MouseEnter", 1, 1)
	assert(hover.Hovered:Get() == true)
	H.fire(f, "InputBegan", mouseDown(0, 0))
	assert(hover.Pressed:Get() == true)
	H.fire(f, "InputEnded", mouseUp(0, 0))
	assert(hover.Pressed:Get() == false and hover.Hovered:Get() == true)
	-- a non-primary input does not press
	H.fire(f, "InputBegan", H.input({ UserInputType = Enum.UserInputType.Keyboard }))
	assert(hover.Pressed:Get() == false)
	-- leaving drops hover and a stuck press
	H.fire(f, "InputBegan", mouseDown(0, 0))
	H.fire(f, "MouseLeave")
	assert(hover.Hovered:Get() == false and hover.Pressed:Get() == false)
	-- touch presses too
	H.fire(f, "InputBegan", H.input({ UserInputType = Enum.UserInputType.Touch }))
	assert(hover.Pressed:Get() == true)
	q.dispose(f)
	H.assertNoDebugOutput("hover")
end)

H.section("pointerDown fires for primary input only", function()
	local n = 0
	local f = D.Frame({
		Interaction.pointerDown(function()
			n += 1
		end),
	})
	H.fire(f, "InputBegan", mouseDown(0, 0))
	H.fire(f, "InputBegan", H.input({ UserInputType = Enum.UserInputType.MouseButton2 }))
	H.fire(f, "InputBegan", H.input({ UserInputType = Enum.UserInputType.Touch }))
	assert(n == 2)
	q.dispose(f)
end)

H.section("mouse drag: begin, move deltas, end; connections only while dragging", function()
	local base = conns()
	local log: { string } = {}
	local drag = Interaction.drag({
		OnBegin = function(x, y)
			table.insert(log, `begin {x},{y}`)
		end,
		OnMove = function(x, y, dx, dy)
			table.insert(log, `move {x},{y} d{dx},{dy}`)
		end,
		OnEnd = function(x, y, dx, dy, cancelled)
			table.insert(log, `end {x},{y} d{dx},{dy} {cancelled}`)
		end,
	})
	local f = D.Frame({ drag.Hook })
	assert(conns() == base and drag.Dragging:Get() == false, "nothing global before a drag")

	H.fire(f, "InputBegan", mouseDown(10, 20))
	assert(drag.Dragging:Get() == true and conns() == base + 3)
	UIS.InputChanged:Fire(mouseMove(15, 28), false)
	UIS.InputChanged:Fire(mouseMove(30, 25), false)
	-- unrelated input types are ignored
	UIS.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseWheel, Position = Vector3.new(99, 99, 0) }), false)
	UIS.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.Keyboard }), false)
	assert(drag.Dragging:Get() == true, "keyboard release does not end it")
	UIS.InputEnded:Fire(mouseUp(30, 25), false)
	assert(drag.Dragging:Get() == false and conns() == base, "closed on release")
	assert(log[1] == "begin 10,20" and log[2] == "move 15,28 d5,8" and log[3] == "move 30,25 d20,5", table.concat(log, "|"))
	assert(log[4] == "end 30,25 d20,5 false" and #log == 4, table.concat(log, "|"))

	-- moves after the end are ignored
	UIS.InputChanged:Fire(mouseMove(1, 1), false)
	assert(#log == 4)

	-- a second drag works again
	H.fire(f, "InputBegan", mouseDown(0, 0))
	assert(conns() == base + 3)
	-- a press while dragging does not start a second one
	H.fire(f, "InputBegan", mouseDown(5, 5))
	assert(conns() == base + 3)
	UIS.InputEnded:Fire(mouseUp(0, 0), false)
	assert(conns() == base)
	q.dispose(f)
	H.assertNoDebugOutput("mouse drag")
end)

H.section("touch drag tracks only its own touch", function()
	local base = conns()
	local moves = 0
	local drag = Interaction.drag({
		OnMove = function()
			moves += 1
		end,
	})
	local f = D.Frame({ drag.Hook })
	local touch = H.input({ UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(0, 0, 0) })
	local other = H.input({ UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(50, 50, 0) })
	H.fire(f, "InputBegan", touch)
	UIS.InputChanged:Fire(other, false)
	assert(moves == 0, "another finger is ignored")
	UIS.InputChanged:Fire(touch, false)
	assert(moves == 1)
	UIS.InputEnded:Fire(other, false)
	assert(drag.Dragging:Get() == true)
	UIS.InputEnded:Fire(touch, false)
	assert(drag.Dragging:Get() == false and conns() == base)
	q.dispose(f)
end)

H.section("focus loss and Cancel end the drag as cancelled", function()
	local base = conns()
	local cancelled: { boolean } = {}
	local drag = Interaction.drag({
		OnMove = function() end,
		OnEnd = function(_x, _y, _dx, _dy, c)
			table.insert(cancelled, c)
		end,
	})
	local f = D.Frame({ drag.Hook })
	H.fire(f, "InputBegan", mouseDown(0, 0))
	UIS.WindowFocusReleased:Fire()
	assert(cancelled[1] == true and conns() == base and drag.Dragging:Get() == false)
	H.fire(f, "InputBegan", mouseDown(0, 0))
	drag:Cancel()
	assert(cancelled[2] == true and conns() == base)
	drag:Cancel() -- idempotent
	assert(#cancelled == 2)
	q.dispose(f)
end)

H.section("destroying the element mid-drag closes the connections (no OnEnd)", function()
	local base = conns()
	local ended = false
	local drag = Interaction.drag({
		OnMove = function() end,
		OnEnd = function()
			ended = true
		end,
	})
	local f = D.Frame({ drag.Hook })
	H.fire(f, "InputBegan", mouseDown(0, 0))
	assert(conns() == base + 3)
	q.dispose(f)
	assert(conns() == base, "no leak after dispose")
	assert(drag.Dragging:Get() == false and not ended)
	H.assertNoDebugOutput("destroy mid-drag")
end)

H.section("hover and pressed reset when the element turns invisible (no MouseLeave ever comes)", function()
	local hover = Interaction.hover()
	local f = D.TextButton({ hover.Hook, Text = "x" })
	H.fire(f, "MouseEnter", 1, 1)
	H.fire(f, "InputBegan", mouseDown(0, 0))
	assert(hover.Hovered:Get() and hover.Pressed:Get())
	f.Visible = false
	assert(hover.Hovered:Get() == false and hover.Pressed:Get() == false, "reset on hide")
	f.Visible = true
	assert(hover.Hovered:Get() == false, "it comes back un-hovered")
	q.dispose(f)
	H.assertNoDebugOutput("hover reset")
end)

H.section("drag Enabled = false: a press opens no global connection", function()
	local base = conns()
	local on = q.Source(false)
	local moved = 0
	local drag = Interaction.drag({
		Enabled = on,
		OnMove = function()
			moved += 1
		end,
	})
	local f = D.Frame({ drag.Hook })
	H.fire(f, "InputBegan", mouseDown(0, 0))
	assert(conns() == base and not drag.Dragging:Get(), "disabled: nothing opened")
	on:Set(true)
	H.fire(f, "InputBegan", mouseDown(0, 0))
	assert(conns() > base and drag.Dragging:Get())
	drag:Cancel()
	assert(conns() == base)
	q.dispose(f)
	H.assertNoDebugOutput("drag enabled")
end)


H.done()
