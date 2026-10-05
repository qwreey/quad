--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local D = q.Declaration
local Overlay = require("../src/Overlay")
Overlay.warnUnmounted = false -- these specs open popups on a bare layer (no ScreenGui); the debug line has its own spec in spec.overlay
local Tooltip = require("../src/Tooltip")

local function get(root: Instance, name: string): any
	local found = H.find(root, name)
	assert(found ~= nil, `missing {name}`)
	return found
end

H.section("hover delay shows it at the mouse; leaving hides; no pending timer afterwards", function()
	local o = Overlay.new()
	local tip = Tooltip.hook({ Text = "Saves the file", Overlay = o })
	local target = D.TextButton({ tip.Hook, Text = "Save" })
	assert(tip.Visible:Get() == false and o.Count:Get() == 0 and H.pendingTimers() == 0)

	H.setMouse(100, 50)
	H.fire(target, "MouseEnter", 100, 50)
	assert(H.pendingTimers() == 1 and o.Count:Get() == 0)
	H.advance(0.4)
	assert(o.Count:Get() == 0, "not yet")
	H.advance(0.2)
	assert(o.Count:Get() == 1 and tip.Visible:Get() == true and H.pendingTimers() == 0)
	local label = get(o.Layer, "Tooltip")
	assert(label.Text == "Saves the file")
	assert(get(o.Layer, "PopupHolder").Position == UDim2.fromOffset(112, 66), "near the mouse (+12,+16)")
	assert(H.find(o.Layer, "Catcher") == nil, "no click-outside catcher")

	H.fire(target, "MouseLeave")
	assert(o.Count:Get() == 0 and tip.Visible:Get() == false and #o.Layer:GetChildren() == 0)
	assert(H.pendingTimers() == 0)
	q.dispose(target)
	q.dispose(o.Layer)
	H.assertNoDebugOutput("show/hide")
end)

H.section("the GUI inset is subtracted from the mouse position", function()
	local gs: any = H.GuiService
	local orig = gs.GetGuiInset
	gs.GetGuiInset = function(_self: any): (any, any)
		return Vector2.new(0, 36), Vector2.new(0, 0)
	end
	local o = Overlay.new()
	local tip = Tooltip.hook({ Text = "hint", Overlay = o })
	local target = D.TextButton({ tip.Hook, Text = "t" })
	H.setMouse(100, 86)
	H.fire(target, "MouseEnter", 100, 86)
	H.advance(0.6)
	assert(get(o.Layer, "PopupHolder").Position == UDim2.fromOffset(112, 66), "(100,86) - (0,36) + (12,16)")
	H.fire(target, "MouseLeave")
	gs.GetGuiInset = orig
	q.dispose(target)
	q.dispose(o.Layer)
	H.assertNoDebugOutput("inset")
end)

H.section("leaving before the delay cancels the timer; repeat cycles stay clean", function()
	local o = Overlay.new()
	local tip = Tooltip.hook({ Text = "t", Delay = 1, Overlay = o })
	local target = D.TextButton({ tip.Hook, Text = "x" })
	for _ = 1, 3 do
		H.fire(target, "MouseEnter", 0, 0)
		assert(H.pendingTimers() == 1)
		H.advance(0.5)
		H.fire(target, "MouseLeave")
		assert(H.pendingTimers() == 0)
		H.advance(2)
		assert(o.Count:Get() == 0)
	end
	-- a second enter while one is pending does not stack timers
	H.fire(target, "MouseEnter", 0, 0)
	H.fire(target, "MouseEnter", 0, 0)
	assert(H.pendingTimers() == 1)
	H.advance(1.1)
	assert(o.Count:Get() == 1)
	H.fire(target, "MouseEnter", 0, 0) -- already showing: nothing scheduled
	assert(H.pendingTimers() == 0)
	H.fire(target, "MouseLeave")
	q.dispose(target)
	q.dispose(o.Layer)
	H.assertNoDebugOutput("cancel")
end)

H.section("Text as a State: the open tooltip follows it", function()
	local o = Overlay.new()
	local text = q.Source("one")
	local tip = Tooltip.hook({ Text = text, Delay = 0, Overlay = o })
	local target = D.Frame({ tip.Hook })
	H.fire(target, "MouseEnter", 0, 0)
	H.advance(0.01)
	local label = get(o.Layer, "Tooltip")
	assert(label.Text == "one")
	text:Set("two")
	assert(label.Text == "two")
	H.fire(target, "MouseLeave")
	q.dispose(target)
	q.dispose(o.Layer)
	H.assertNoDebugOutput("state text")
end)

H.section("Content factory: a fresh element per show, destroyed by the Overlay on hide", function()
	local o = Overlay.new()
	local made: { any } = {}
	local tip = Tooltip.hook({
		Overlay = o,
		Delay = 0.1,
		Content = function()
			local f = D.Frame({ Name = "Rich", D.TextLabel({ Text = "rich" }) })
			table.insert(made, f)
			return f
		end,
	})
	local target = D.Frame({ tip.Hook })
	for cycle = 1, 2 do
		H.fire(target, "MouseEnter", 0, 0)
		H.advance(0.2)
		assert(#made == cycle and made[cycle].Parent ~= nil and o.Count:Get() == 1)
		H.fire(target, "MouseLeave")
		assert(H.isDestroyed(made[cycle]) and o.Count:Get() == 0)
	end
	q.dispose(target)
	q.dispose(o.Layer)
	H.assertNoDebugOutput("content")
end)

H.section("pressing the target hides it; destroying the target cancels / closes with no leak", function()
	local o = Overlay.new()
	local tip = Tooltip.hook({ Text = "t", Delay = 0.5, Overlay = o })
	local target = D.TextButton({ tip.Hook, Text = "x" })
	H.fire(target, "MouseEnter", 0, 0)
	H.advance(0.6)
	assert(o.Count:Get() == 1)
	H.fire(target, "InputBegan", H.input({}))
	assert(o.Count:Get() == 0)
	-- a keyboard input is not a press
	H.fire(target, "MouseEnter", 0, 0)
	H.advance(0.6)
	assert(o.Count:Get() == 1)
	H.fire(target, "InputBegan", H.input({ UserInputType = Enum.UserInputType.Keyboard }))
	assert(o.Count:Get() == 1)

	q.dispose(target)
	assert(o.Count:Get() == 0 and tip.Visible:Get() == false and #o.Layer:GetChildren() == 0)

	-- destroyed while the delay is pending
	local tip2 = Tooltip.hook({ Text = "t", Delay = 0.5, Overlay = o })
	local target2 = D.TextButton({ tip2.Hook, Text = "y" })
	H.fire(target2, "MouseEnter", 0, 0)
	assert(H.pendingTimers() == 1)
	q.dispose(target2)
	assert(H.pendingTimers() == 0)
	H.advance(2)
	assert(o.Count:Get() == 0)
	q.dispose(o.Layer)
	H.assertNoDebugOutput("dispose")
end)

H.section("giving neither Text nor Content raises", function()
	local ok, err = pcall(function()
		Tooltip.hook({})
	end)
	assert(not ok and string.find(tostring(err), "Text or Content", 1, true))
end)

H.section("a tooltip whose overlay died shows nothing and does not throw from the timer thread", function()
	local o = Overlay.new()
	local tip = Tooltip.hook({ Text = "t", Overlay = o })
	local target = D.TextButton({ tip.Hook, Text = "x" })
	local gui = D.ScreenGui({ o.Layer })
	H.fire(target, "MouseEnter", 0, 0)
	assert(H.pendingTimers() == 1)
	q.dispose(gui) -- the layer dies while the timer is pending
	H.advance(1) -- the delayed show runs: it must bail quietly
	assert(tip.Visible:Get() == false and not o.Alive:Get() and H.pendingTimers() == 0)
	-- a fresh enter / leave cycle on the dead overlay is quiet too
	H.fire(target, "MouseLeave")
	H.fire(target, "MouseEnter", 0, 0)
	H.advance(1)
	assert(tip.Visible:Get() == false)
	q.dispose(target)
	H.assertNoDebugOutput("dead overlay")
end)

H.section("Hooks prop: a tooltip hook rides on a Button, a Text and a Selectable", function()
	local Devui = require("../src")
	local o = Overlay.new()
	local tip = Tooltip.hook({ Text = "hint", Overlay = o, Delay = 0.1 })
	local btn = Devui.Button({ Text = "Save", Hooks = { tip.Hook } })
	H.fire(btn, "MouseEnter", 0, 0)
	H.advance(0.2)
	assert(tip.Visible:Get() and o.Count:Get() == 1, "tooltip shown from a Hooks-attached hook")
	H.fire(btn, "MouseLeave")
	assert(not tip.Visible:Get())
	local tip2 = Tooltip.hook({ Text = "hint2", Overlay = o, Delay = 0.1 })
	local label = Devui.Text({ Text = "x", Hooks = { tip2.Hook } })
	H.fire(label, "MouseEnter", 0, 0)
	H.advance(0.2)
	assert(tip2.Visible:Get(), "Text takes Hooks")
	H.fire(label, "MouseLeave")
	local fired = 0
	local sel = Devui.Selectable({ Text = "s", Hooks = { Devui.Interaction.pointerDown(function()
		fired += 1
	end) } })
	H.fire(sel, "InputBegan", H.input({ UserInputType = Enum.UserInputType.MouseButton1 }))
	assert(fired == 1, "Selectable takes Hooks")
	q.dispose(btn)
	q.dispose(label)
	q.dispose(sel)
	q.dispose(o.Layer)
	H.assertNoDebugOutput("hooks")
end)


H.done()
