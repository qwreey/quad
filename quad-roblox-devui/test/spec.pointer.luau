--!strict
-- The Pointer rule (internal): hover, tooltips and press-to-front agree with where a press would go. The engine sends
-- MouseEnter to covered elements too (Studio 2026-10-20), so these specs fire MouseEnter on a covered row and expect
-- Hovered to stay false. `H.playerGui()` stands in for PlayerGui:GetGuiObjectsAtPosition.
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Frame = q.Elem "Frame"
local TextButton = q.Elem "TextButton"
local TextLabel = q.Elem "TextLabel"
local Devui = require("../src")
local Interaction = require("../src/Interaction")
local Overlay = require("../src/Overlay")
local Tooltip = require("../src/Tooltip")
local Input = require("../src/Input")

local UIS = H.UserInputService
local function mouseAt(x: number, y: number)
	H.setMouse(x, y)
	UIS.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(x, y, 0) }), false)
end
local function pressOn(signal: any, x: number, y: number)
	signal:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(x, y, 0) }), true)
end
local function moveConns(): number
	return #(UIS.InputChanged :: any).connections
end

type Win = { Root: Frame, Row: TextButton, Hover: Interaction.HoverHandle, Slot: any }

-- a window-shaped fixture: root > ClickSink (ZIndex 0, full cover) + Row (a hover-hooked button)
local function fixture()
	local pg = H.playerGui()
	local gui = Instance.new("ScreenGui")
	gui.Parent = pg
	local manager = Devui.WindowManager.new()
	local function win(name: string, x: number, y: number): Win
		local slot = manager:Register()
		local hover = Interaction.hover()
		local row = TextButton({ hover.Hook, Name = name .. "Row", Text = "" })
		local sink = TextButton({ Name = "ClickSink", ZIndex = 0, Text = "" })
		local root = Frame({ slot.Hook, Name = name, ZIndex = slot.ZIndex, sink, row })
		H.setAbs(root, x, y, 200, 100)
		H.setAbs(sink, x, y, 200, 100)
		H.setAbs(row, x + 10, y + 10, 100, 20)
		root.Parent = gui
		return { Root = root, Row = row, Hover = hover, Slot = slot }
	end
	return pg, gui, manager, win
end

H.section("hover: a row covered by another window is not hovered; raising / moving re-judges; leave stops watching", function()
	local moves0 = moveConns()
	local _pg, gui, manager, win = fixture()
	local a = win("A", 0, 0)
	local b = win("B", 50, 0) -- registered later: on top, covers A's row from x = 50
	H.setMouse(60, 20)
	H.fire(a.Row, "MouseEnter", 60, 20)
	assert(a.Hover.Hovered:Get() == false, "covered by B: the engine's MouseEnter is not a hover")
	assert(moveConns() == moves0 + 1, "one global move listener while something is entered")
	a.Slot:Focus()
	H.advance(0)
	assert(a.Hover.Hovered:Get() == true, "A raised under a still mouse: re-judged")
	b.Slot:Focus()
	H.advance(0)
	assert(a.Hover.Hovered:Get() == false)
	mouseAt(20, 20) -- off B
	assert(a.Hover.Hovered:Get() == true, "moved off the cover")
	mouseAt(60, 20)
	assert(a.Hover.Hovered:Get() == false, "moved back under it")
	H.fire(a.Row, "MouseLeave")
	assert(a.Hover.Hovered:Get() == false and moveConns() == moves0, "leave: the move listener is closed")
	-- a hidden cover: B's Visible goes false (Window binds it to Open)
	H.setMouse(60, 20)
	H.fire(a.Row, "MouseEnter", 60, 20)
	assert(a.Hover.Hovered:Get() == false)
	b.Root.Visible = false
	H.advance(0)
	assert(a.Hover.Hovered:Get() == true, "the cover was hidden")
	H.fire(a.Row, "MouseLeave")
	assert(manager.Focused:Get() ~= nil)
	gui:Destroy()
	assert(moveConns() == moves0)
	H.assertNoDebugOutput("hover")
end)

H.section("hover and tooltip: an open popup's click-outside catcher covers everything; closing it re-judges", function()
	local _pg, gui, _manager, win = fixture()
	local o = Overlay.new()
	o.Layer.Parent = gui
	local a = win("A", 0, 0)
	H.setMouse(20, 20)
	H.fire(a.Row, "MouseEnter", 20, 20)
	assert(a.Hover.Hovered:Get() == true)
	local popup = o:Open({ Content = Frame({ Name = "Menu" }), Position = Vector2.new(300, 300) })
	H.setAbs(H.find(o.Layer, "Catcher") :: any, 0, 0, 1000, 1000)
	H.advance(0)
	assert(a.Hover.Hovered:Get() == false, "the catcher takes the click, so it takes the hover")
	popup:Close()
	H.advance(0)
	assert(a.Hover.Hovered:Get() == true)
	H.fire(a.Row, "MouseLeave")

	-- a tooltip waiting on a covered target does not show
	local b = win("B", 50, 0)
	local tip = Tooltip.hook({ Text = "hint", Overlay = o })
	local target = TextButton({ tip.Hook, Name = "Target", Text = "" })
	H.setAbs(target, 60, 10, 20, 20)
	target.Parent = a.Root
	H.setMouse(65, 15)
	H.fire(target, "MouseEnter", 65, 15)
	H.advance(0.6)
	assert(tip.Visible:Get() == false and o.Count:Get() == 0, "covered by B: no hint")
	H.fire(target, "MouseLeave")
	a.Slot:Focus()
	H.fire(target, "MouseEnter", 65, 15)
	H.advance(0.6)
	assert(tip.Visible:Get() == true, "on top: the hint shows")
	H.fire(target, "MouseLeave")
	assert(b.Root ~= nil)
	gui:Destroy()
	H.assertNoDebugOutput("popup and tooltip")
end)

H.section("press-to-front: through a tooltip raises the window; a popup row or another ScreenGui's button does not", function()
	local pg, gui, manager, win = fixture()
	local o = Overlay.new()
	o.Layer.Parent = gui
	local a = win("A", 0, 0)
	local b = win("B", 50, 0)
	b.Slot:Focus()
	-- a tooltip-like popup (no catcher, takes no input) over A only
	local label = TextLabel({ Name = "Hint", Text = "hint" })
	local tipPopup = o:Open({ Content = label, Position = Vector2.new(0, 0), CloseOnClickOutside = false })
	H.setAbs(label, 0, 0, 40, 40)
	pressOn(UIS.InputBegan, 20, 20)
	assert(manager.Focused:Get() == a.Slot.Id, "a press through a tooltip reaches window A")
	tipPopup:Close()

	-- a popup without catcher that holds a button (a submenu) over B: the press is the popup's
	b.Slot:Focus()
	local rowBtn = TextButton({ Name = "Item", Text = "" })
	local sub = o:Open({ Content = Frame({ rowBtn }), Position = Vector2.new(0, 0), CloseOnClickOutside = false })
	H.setAbs(rowBtn, 0, 0, 40, 40)
	pressOn(UIS.InputBegan, 20, 20)
	assert(manager.Focused:Get() == b.Slot.Id, "a press on a popup's button changes nothing")
	sub:Close()

	-- a HUD button in a ScreenGui drawn above
	local hud = Instance.new("ScreenGui")
	hud.DisplayOrder = 10
	hud.Parent = pg
	local hudButton = TextButton({ Name = "Hud", Text = "" })
	H.setAbs(hudButton, 0, 0, 40, 40)
	hudButton.Parent = hud
	pressOn(UIS.InputBegan, 20, 20)
	assert(manager.Focused:Get() == b.Slot.Id, "another ScreenGui's button above takes the press")
	hud:Destroy()

	-- a detached window is never hit
	a.Root.Parent = nil
	pressOn(UIS.InputBegan, 20, 20)
	assert(manager.Focused:Get() == b.Slot.Id, "detached A is not in the engine's list")
	a.Root.Parent = gui
	pressOn(UIS.InputBegan, 20, 20)
	assert(manager.Focused:Get() == a.Slot.Id)
	gui:Destroy()
	H.assertNoDebugOutput("press")
end)

H.section("Input.use moves the press and move listeners to the new service", function()
	local _pg, gui, manager, win = fixture()
	local a = win("A", 0, 0)
	local b = win("B", 50, 0)
	b.Slot:Focus()
	local listener = {
		InputBegan = H.mock.newSignal(),
		InputChanged = H.mock.newSignal(),
		InputEnded = H.mock.newSignal(),
	}
	Input.use(listener :: any)
	pressOn(UIS.InputBegan, 20, 20)
	assert(manager.Focused:Get() == b.Slot.Id, "the engine service is no longer listened to")
	pressOn(listener.InputBegan, 20, 20)
	assert(manager.Focused:Get() == a.Slot.Id, "the story listener is")
	Input.use(nil)
	b.Slot:Focus()
	pressOn(UIS.InputBegan, 60, 20)
	assert(manager.Focused:Get() == b.Slot.Id)
	pressOn(UIS.InputBegan, 20, 20)
	assert(manager.Focused:Get() == a.Slot.Id, "back on the engine service")
	gui:Destroy()
	H.assertNoDebugOutput("Input.use")
end)

H.section("no PlayerGui (story host): hover is the engine's MouseEnter; a tooltip is not a press shield", function()
	local manager = Devui.WindowManager.new()
	local slotA = manager:Register()
	local slotB = manager:Register()
	local hover = Interaction.hover()
	local row = TextButton({ hover.Hook, Text = "" })
	local container = Instance.new("ScreenGui")
	container.Parent = Instance.new("Folder") -- placed, but not in a PlayerGui (a plugin widget stand-in)
	local rootA = Frame({ slotA.Hook, ZIndex = slotA.ZIndex, row })
	local rootB = Frame({ slotB.Hook, ZIndex = slotB.ZIndex })
	rootA.Parent = container
	rootB.Parent = container
	H.setAbs(rootA, 0, 0, 200, 100)
	H.setAbs(rootB, 50, 0, 200, 100)
	H.fire(row, "MouseEnter", 60, 20)
	assert(hover.Hovered:Get() == true, "no engine list to ask: MouseEnter decides")
	H.fire(row, "MouseLeave")
	slotB:Focus()
	local o = Overlay.new()
	o.Layer.Parent = container
	local label = TextLabel({ Text = "hint" })
	local p = o:Open({ Content = label, Position = Vector2.new(0, 0), CloseOnClickOutside = false })
	H.setAbs(o.Layer, 0, 0, 1000, 1000)
	H.setAbs(H.find(o.Layer, "PopupHolder") :: any, 0, 0, 40, 40)
	pressOn(UIS.InputBegan, 20, 20)
	assert(manager.Focused:Get() == slotA.Id, "the tooltip-like popup is not in PopupHits")
	p:Close()
	container:Destroy()
	H.assertNoDebugOutput("story host")
end)

H.done()
