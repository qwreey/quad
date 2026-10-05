--!strict
local H = require("./support/harness")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
local D = q.Declaration
local Interaction = require("../src/Interaction")

local UIS = H.UserInputService
local function uisConns(): number
	local u = UIS :: any
	return #u.InputChanged.connections + #u.InputEnded.connections + #u.WindowFocusReleased.connections
end
local base = uisConns()

H.section("hover / press / focus states follow the element events", function()
	local presses: { any } = {}
	local ends: { boolean } = {}
	local ix = Interaction.new({
		OnPressBegan = function(p: Vector2?)
			table.insert(presses, if p then p else false)
		end,
		OnPressEnded = function(cancelled: boolean)
			table.insert(ends, cancelled)
		end,
	})
	local btn = D.TextButton { ix.Hook }
	assert(not ix.Hovered:Get() and not ix.Pressed:Get() and not ix.Focused:Get())
	H.fire(btn, "MouseEnter")
	assert(ix.Hovered:Get())
	H.fire(btn, "InputBegan", H.input({ Position = Vector3.new(7, 9, 0) }))
	assert(ix.Pressed:Get() and #presses == 1 and presses[1] == Vector2.new(7, 9), "press position")
	H.fire(btn, "InputEnded", H.input({}))
	assert(not ix.Pressed:Get() and ends[1] == false, "released")
	-- touch press
	H.fire(btn, "InputBegan", H.input({ UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(1, 2, 0) }))
	assert(ix.Pressed:Get())
	-- pointer leaves while pressed -> cancelled press + hover off
	H.fire(btn, "MouseLeave")
	assert(not ix.Hovered:Get() and not ix.Pressed:Get() and ends[2] == true, "leave cancels the press")
	-- gamepad A: pressed with no position
	H.fire(btn, "InputBegan", H.input({ UserInputType = Enum.UserInputType.Gamepad1, KeyCode = Enum.KeyCode.ButtonA }))
	assert(ix.Pressed:Get() and presses[3] == false, "gamepad press has no pointer position")
	H.fire(btn, "InputEnded", H.input({ UserInputType = Enum.UserInputType.Gamepad1, KeyCode = Enum.KeyCode.ButtonA }))
	-- other inputs are not presses
	H.fire(btn, "InputBegan", H.input({ UserInputType = Enum.UserInputType.MouseButton2 }))
	assert(not ix.Pressed:Get(), "right click is not a press")
	H.fire(btn, "SelectionGained")
	assert(ix.Focused:Get())
	H.fire(btn, "SelectionLost")
	assert(not ix.Focused:Get())
	q.dispose(btn)
	H.assertNoDebugOutput("interaction states")
end)

H.section("disabled: nothing turns on, everything can turn off", function()
	local disabled = q.Source(false)
	local ix = Interaction.new({ Disabled = disabled })
	local btn = D.TextButton { ix.Hook }
	H.fire(btn, "MouseEnter")
	assert(ix.Hovered:Get())
	disabled:Set(true)
	H.fire(btn, "MouseLeave")
	assert(not ix.Hovered:Get(), "off still works")
	H.fire(btn, "MouseEnter")
	H.fire(btn, "InputBegan", H.input({}))
	H.fire(btn, "SelectionGained")
	assert(not ix.Hovered:Get() and not ix.Pressed:Get() and not ix.Focused:Get(), "disabled blocks on")
	q.dispose(btn)
	H.assertNoDebugOutput("interaction disabled")
end)

H.section("derived States update (hover -> computed value)", function()
	local ix = Interaction.new()
	local label: Q.State<string> = ix.Hovered:Compute(function(self)
		return if self:Get() then "hot" else "cold"
	end)
	local t = D.TextButton { ix.Hook, Text = label }
	assert(t.Text == "cold")
	H.fire(t, "MouseEnter")
	assert(t.Text == "hot")
	q.dispose(t)
end)

H.section("drag: global connections only while dragging, closed at end / focus loss / destroy", function()
	local log: { string } = {}
	local drag = Interaction.drag({
		OnBegan = function(x: number, y: number)
			table.insert(log, `began {x},{y}`)
		end,
		OnMoved = function(x: number, y: number, dx: number, dy: number)
			table.insert(log, `moved {x},{y},{dx},{dy}`)
		end,
		OnEnded = function(x: number, y: number, cancelled: boolean)
			table.insert(log, `ended {x},{y},{cancelled}`)
		end,
	})
	local el = D.Frame { drag.Hook }
	assert(uisConns() == base, "no global connection while idle")
	assert(not drag.Dragging:Get())

	-- mouse drag: begin on element, move anywhere, release anywhere
	H.fire(el, "InputBegan", H.input({ Position = Vector3.new(10, 20, 0) }))
	assert(drag.Dragging:Get() and uisConns() == base + 3, "3 connections while dragging")
	UIS.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(15, 22, 0), Delta = Vector3.new(5, 2, 0) }))
	UIS.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.Keyboard, Position = Vector3.new(99, 99, 0) }))
	UIS.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton2 }))
	assert(drag.Dragging:Get(), "unrelated end does not stop")
	UIS.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(18, 25, 0) }))
	assert(not drag.Dragging:Get() and uisConns() == base, "closed at drag end")
	assert(table.concat(log, "|") == "began 10,20|moved 15,22,5,2|ended 18,25,false", table.concat(log, "|"))

	-- window focus lost cancels
	table.clear(log)
	H.fire(el, "InputBegan", H.input({ Position = Vector3.new(1, 1, 0) }))
	UIS.WindowFocusReleased:Fire()
	assert(not drag.Dragging:Get() and uisConns() == base and log[2] == "ended 1,1,true", "focus loss cancels: " .. tostring(log[2]))

	-- touch drag follows its own InputObject
	table.clear(log)
	local touch = H.input({ UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(5, 5, 0) })
	H.fire(el, "InputBegan", touch)
	UIS.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(50, 50, 0) })) -- another finger
	UIS.InputChanged:Fire(touch)
	assert(#log == 2, "only the owning touch moves it: " .. table.concat(log, "|"))
	UIS.InputEnded:Fire(touch)
	assert(not drag.Dragging:Get() and uisConns() == base)

	-- destroyed mid-drag: connections closed, end reported as cancelled
	table.clear(log)
	H.fire(el, "InputBegan", H.input({ Position = Vector3.new(3, 3, 0) }))
	assert(uisConns() == base + 3)
	q.dispose(el)
	assert(uisConns() == base, "closed on element death")
	assert(log[#log] == "ended 3,3,true" and not drag.Dragging:Get())

	-- Cancel() and a second drag works after a cancelled one
	local drag2 = Interaction.drag({}) -- a tracker serves ONE element (its Hook is a one-shot PreRef)
	local el2 = D.Frame { drag2.Hook }
	H.fire(el2, "InputBegan", H.input({ Position = Vector3.new(0, 0, 0) }))
	assert(drag2.Dragging:Get())
	drag2:Cancel()
	assert(uisConns() == base and not drag2.Dragging:Get())
	drag2:Cancel() -- idempotent
	q.dispose(el2)
	H.assertNoDebugOutput("drag")
end)

H.section("drag disabled ignores begin", function()
	local drag = Interaction.drag({ Disabled = true })
	local el = D.Frame { drag.Hook }
	H.fire(el, "InputBegan", H.input({}))
	assert(not drag.Dragging:Get() and uisConns() == base)
	q.dispose(el)
end)

assert(uisConns() == base, "no leaked global connections at the end")
H.assertNoDebugOutput("interaction")
H.done()
