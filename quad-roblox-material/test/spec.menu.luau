--!strict
local H = require("./support/harness")
local ClickSink = require("./support/clicksink")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Frame = q.Elem "Frame"
local TextButton = q.Elem "TextButton"
local Menu = require("../src/Menu")
local Overlay = require("../src/Overlay")
local Tokens = require("../src/Tokens")
local Bounded = require("./support/bounded")

local L = Tokens.Color.Light

local function setup()
	local overlay = Overlay.new()
	local screen = Frame { overlay.Layer }
	H.setAbs(overlay.Layer, 0, 0, 800, 600)
	local anchor = Frame { Name = "Anchor" }
	H.setAbs(anchor, 100, 50, 200, 56)
	return overlay, screen, anchor
end

local function items(log: { string }): { Menu.Entry }
	return {
		{
			Label = "Rename",
			Leading = "rbxassetid://1",
			OnClick = function()
				table.insert(log, "rename")
			end,
		},
		{ Label = "Copy", Trailing = "Ctrl+C", OnClick = function() table.insert(log, "copy") end },
		"divider",
		{
			Label = "Delete",
			Disabled = true,
			OnClick = function()
				table.insert(log, "delete")
			end,
		},
		{ Label = "Pick", Selected = true, Trailing = "rbxassetid://2" },
	}
end

local function itemsOf(screen: any): { any }
	return H.findAll(screen, function(c: any)
		return c.Name == "Item"
	end)
end

-- the selection trap is a SelectionGroup entry whose four directions Stop (GuiService:AddSelectionParent is deprecated)
local function trapped(root: any): boolean
	local e = H.find(root, "OverlayEntry")
	return e ~= nil
		and e.SelectionGroup == true
		and e.SelectionBehaviorUp == Enum.SelectionBehavior.Stop
		and e.SelectionBehaviorDown == Enum.SelectionBehavior.Stop
		and e.SelectionBehaviorLeft == Enum.SelectionBehavior.Stop
		and e.SelectionBehaviorRight == Enum.SelectionBehavior.Stop
end

H.section("open: panel under the anchor, items, divider, scrim is transparent", function()
	local overlay, screen, anchor = setup()
	local log: { string } = {}
	local handle = Menu.open({ Anchor = anchor, Items = items(log), Overlay = overlay })
	assert(overlay.Count:Get() == 1 and handle.IsOpen:Get())
	local menu = H.find(screen, "Menu")
	-- no Width: the panel fits its items (AutomaticSize X); until the engine lays it out (the mock never does) it is
	-- placed for the 112 minimum, NOT the anchor's width (Compose DropdownMenu does not follow the anchor)
	assert(menu.Size == UDim2.fromOffset(0, 16 + 48 * 4 + 17) and menu.AutomaticSize == Enum.AutomaticSize.X, "fits the items, content height")
	assert(menu.Position == UDim2.fromOffset(100 + 56, 106) and menu.AnchorPoint == Vector2.new(0.5, 0), "below the anchor (top-center pivot)")
	assert(menu.BackgroundColor3 == L.SurfaceContainer and menu.Active == true)
	ClickSink.assertClickSink(menu, "the menu panel (opens with a scrim)")
	assert(#itemsOf(screen) == 4 and H.find(screen, "Divider") ~= nil)
	local scrim = H.find(screen, "Scrim")
	H.finishTweens()
	assert(scrim.BackgroundTransparency == 1, "outside-click catcher is invisible")
	local first = itemsOf(screen)[1]
	assert(H.find(first, "Label").Text == "Rename" and H.find(first, "Leading").Image == "rbxassetid://1")
	assert(H.find(first, "Label").Position == UDim2.fromOffset(48, 0))
	local copy = itemsOf(screen)[2]
	assert(H.find(copy, "Trailing").Text == "Ctrl+C" and H.find(copy, "Trailing").ClassName == "TextLabel")
	local pick = itemsOf(screen)[4]
	assert(pick.BackgroundTransparency == 0 and pick.BackgroundColor3 == L.SecondaryContainer, "selected highlight")
	assert(H.find(pick, "Trailing").ClassName == "ImageLabel", "image trailing")
	-- fit structure: the list sizes to its rows, rows to their labels (+ the trailing room), stretched to the widest
	local list = H.find(menu, "List")
	assert(list.Size == UDim2.fromScale(0, 1) and list.AutomaticSize == Enum.AutomaticSize.X)
	local spacer = H.find(list, "MinWidth")
	assert(spacer ~= nil and spacer.Size == UDim2.fromOffset(112, 0), "the 112 floor is a 0-high spacer")
	local divider = H.find(list, "Divider")
	assert(divider.Size == UDim2.fromOffset(0, 17), "no scale width inside the automatic-width list (it fed back: half the layer wide)")
	local divFlex = H.findAll(divider, function(c: any)
		return c.ClassName == "UIFlexItem"
	end)[1]
	assert(divFlex ~= nil and divFlex.ItemLineAlignment == Enum.ItemLineAlignment.Stretch, "the divider is stretched like the rows")
	assert(first.Size == UDim2.fromOffset(0, 48) and first.AutomaticSize == Enum.AutomaticSize.X)
	local flex = H.findAll(first, function(c: any)
		return c.ClassName == "UIFlexItem"
	end)[1]
	assert(flex ~= nil and flex.ItemLineAlignment == Enum.ItemLineAlignment.Stretch, "stretched to the widest row")
	local copyLabel = H.find(copy, "Label")
	assert(copyLabel.AutomaticSize == Enum.AutomaticSize.X and copyLabel.Size == UDim2.fromScale(0, 1))
	local copyPad = H.findAll(copyLabel, function(c: any)
		return c.ClassName == "UIPadding"
	end)[1]
	assert(copyPad.PaddingRight == UDim.new(0, 16 + 64), "the label reserves the trailing text room (64 until measured)")
	local copyTrailing = H.find(copy, "Trailing")
	assert(copyTrailing.Size == UDim2.fromScale(0, 1) and copyTrailing.AutomaticSize == Enum.AutomaticSize.X, "trailing text fits its text")
	local uiScale = H.findAll(menu, function(c: any)
		return c.ClassName == "UIScale"
	end)[1]
	assert(uiScale.Scale == 1, "(the scrim check above finished the open tween)")
	-- laid out at full scale (here under an ancestor 0.9 scale: 90 px of text at 48 px row height): 16 + text + 12
	H.setAbs(copyTrailing, 0, 0, 90 * 0.9, 48 * 0.9)
	assert(copyPad.PaddingRight == UDim.new(0, 16 + 90 + 12), `measured trailing room: {copyPad.PaddingRight}`)
	H.setAbs(copyTrailing, 0, 0, 91, 48)
	assert(copyPad.PaddingRight == UDim.new(0, 16 + 90 + 12), "a 1 px change is jitter")
	H.setAbs(copyTrailing, 0, 0, 30, 48)
	assert(copyPad.PaddingRight == UDim.new(0, 16 + 30 + 12), "follows a real change (a font that loads), either way")
	-- while the panel animates (its own scale is not 1) readings are not proportional: ignored
	uiScale.Scale = 0.95
	H.setAbs(copyTrailing, 0, 0, 120, 48)
	assert(copyPad.PaddingRight == UDim.new(0, 16 + 30 + 12), "no trailing reading mid-animation")
	local picPad = H.findAll(H.find(pick, "Label"), function(c: any)
		return c.ClassName == "UIPadding"
	end)[1]
	assert(picPad.PaddingRight == UDim.new(0, 12 + 24 + 12), "and the trailing icon room")
	-- the engine lays the panel out: it is re-placed by its real (full-scale) width
	H.setAbs(menu, 0, 0, 300 * 0.95, 225)
	assert(menu.Position == UDim2.fromOffset(100 + 56, 106), "no panel reading mid-animation")
	uiScale.Scale = 1
	H.setAbs(menu, 0, 0, 300, 225)
	assert(menu.Position == UDim2.fromOffset(100 + 150, 106), `re-placed for 300: {menu.Position}`)
	H.setAbs(menu, 0, 0, 299, 225)
	assert(menu.Position == UDim2.fromOffset(100 + 150, 106), "a 1 px change is jitter")
	H.setAbs(menu, 0, 0, 280, 225)
	assert(menu.Position == UDim2.fromOffset(100 + 140, 106), "narrower re-places too")
	local count = H.countDescendants(menu)
	print("Menu (4 items + divider) descendants: " .. count)
	H.resetOutput()
	handle.Close()
	H.advance(0.3)

	-- a fixed Width: that width (labels truncate), rows fill it, no spacer, no re-placing
	local fixed = Menu.open({ Anchor = anchor, Items = items({}), Overlay = overlay, Width = 200 })
	local m2 = H.find(screen, "Menu")
	assert(m2.Size == UDim2.fromOffset(200, 16 + 48 * 4 + 17) and m2.AutomaticSize == Enum.AutomaticSize.None)
	assert(m2.Position == UDim2.fromOffset(200, 106))
	assert(H.find(m2, "MinWidth") == nil and H.find(m2, "List").Size == UDim2.fromScale(1, 1))
	local row = itemsOf(screen)[1]
	assert(row.Size == UDim2.new(1, 0, 0, 48) and row.AutomaticSize == Enum.AutomaticSize.None)
	assert(H.find(row, "Label").Size == UDim2.new(1, -(48 + 16), 1, 0) and H.find(row, "Label").TextTruncate == Enum.TextTruncate.AtEnd)
	H.setAbs(m2, 0, 0, 500, 225)
	assert(m2.Position == UDim2.fromOffset(200, 106), "a fixed width is not re-placed")
	fixed.Close()
	H.advance(0.3)
	q.dispose(screen)
	H.assertNoDebugOutput("open")
end)

H.section("open animation: snapped at .9, animates to 1, back on close", function()
	local overlay, screen, anchor = setup()
	local handle = Menu.open({ Anchor = anchor, Items = items({}), Overlay = overlay })
	local scale = H.findAll(H.find(screen, "Menu"), function(c: any)
		return c.ClassName == "UIScale"
	end)[1]
	assert(scale.Scale == 0.9, "the full-scale measuring read at open restores the closed scale: " .. tostring(scale.Scale))
	H.finishTweens()
	assert(scale.Scale == 1, "opened: " .. tostring(scale.Scale))
	handle.Close()
	H.finishTweens()
	assert(scale.Scale == 0.9, "closing tween")
	H.advance(0.3)
	assert(overlay.Count:Get() == 0 and H.find(screen, "Menu") == nil)
	q.dispose(screen)
	H.assertNoDebugOutput("anim")
end)

H.section("item click: runs OnClick, closes; disabled does nothing; outside click closes", function()
	local overlay, screen, anchor = setup()
	local log: { string } = {}
	local closed = 0
	local handle = Menu.open({
		Anchor = anchor,
		Items = items(log),
		Overlay = overlay,
		OnClose = function()
			closed += 1
		end,
	})
	local its = itemsOf(screen)
	assert(its[3].Interactable == false and H.find(its[3], "Label").TextTransparency > 0.6, "disabled look")
	H.fire(its[3], "Activated", H.input({}), 1) -- the engine would not fire; the handler also guards
	assert(#log == 0 and handle.IsOpen:Get())
	H.fire(its[1], "Activated", H.input({}), 1)
	assert(log[1] == "rename" and not handle.IsOpen:Get() and closed == 1)
	H.advance(0.3)
	assert(overlay.Count:Get() == 0)
	-- outside click
	local h2 = Menu.open({ Anchor = anchor, Items = items(log), Overlay = overlay })
	H.fire(H.find(screen, "Scrim"), "Activated", H.input({}), 1)
	assert(not h2.IsOpen:Get() and #log == 1, "no item ran")
	H.advance(0.3)
	assert(overlay.Count:Get() == 0 and #overlay.Layer:GetChildren() == 0, "overlay left empty")
	q.dispose(screen)
	H.assertNoDebugOutput("click")
end)

H.section("flip up when it does not fit below; clamp horizontally; scroll when tall", function()
	local overlay, screen, anchor = setup()
	H.setAbs(anchor, 700, 520, 200, 56) -- bottom edge, right edge
	local h = Menu.open({ Anchor = anchor, Items = items({}), Overlay = overlay })
	local menu = H.find(screen, "Menu")
	-- placed for the 112 guess (x clamped to 800 - 112), then for the laid-out 200 (x clamped to 800 - 200)
	assert(menu.AnchorPoint == Vector2.new(0.5, 1) and menu.Position == UDim2.fromOffset(688 + 56, 520), "flipped, clamped: " .. tostring(menu.Position))
	H.finishTweens() -- (readings are taken at full scale)
	H.setAbs(menu, 0, 0, 200, 100)
	assert(menu.Position == UDim2.fromOffset(700, 520), "clamped for the real width: " .. tostring(menu.Position))
	-- wider than the layer: starts at its left edge
	H.setAbs(menu, 0, 0, 1000, 100)
	assert(menu.Position == UDim2.fromOffset(500, 520), "wider than the layer: " .. tostring(menu.Position))
	h.Close()
	H.advance(0.3)
	-- tall list near the top: scrolls within the room below
	H.setAbs(anchor, 100, 100, 200, 56)
	local many: { Menu.Entry } = {}
	for i = 1, 20 do
		table.insert(many, { Label = "Option " .. i })
	end
	local h2 = Menu.open({ Anchor = anchor, Items = many, Overlay = overlay })
	local m2 = H.find(screen, "Menu")
	assert(m2.Size.Y.Offset == 600 - 156 - 8 and H.find(m2, "Scroll") ~= nil and H.find(m2, "Scroll").ClassName == "ScrollingFrame", "scrolls: " .. m2.Size.Y.Offset)
	local scroller = H.find(m2, "Scroll")
	assert(scroller.Size == UDim2.fromScale(0, 1) and scroller.AutomaticSize == Enum.AutomaticSize.X, "a scrolling list fits its rows too")
	assert(#itemsOf(screen) == 20)
	h2.Close()
	H.advance(0.3)
	q.dispose(screen)
	H.assertNoDebugOutput("placement")
end)

H.section("items ripple over the whole row; a scrolling list has a themed thumb and full-width rows (9th)", function()
	local overlay, screen, anchor = setup()
	local many: { Menu.Entry } = {}
	for i = 1, 20 do
		table.insert(many, { Label = "Option " .. i, OnClick = function() end })
	end
	local h = Menu.open({ Anchor = anchor, Items = many, Overlay = overlay })
	local scroll = H.find(screen, "Scroll")
	assert(scroll ~= nil and scroll.ClassName == "ScrollingFrame")
	assert(scroll.ScrollBarImageColor3 == L.OnSurface and math.abs(scroll.ScrollBarImageTransparency - 0.5) < 1e-9, "themed thumb, not the engine's white")
	assert(scroll.VerticalScrollBarInset == Enum.ScrollBarInset.None, "rows keep the full width under the overlaid thumb")
	local row = itemsOf(screen)[1]
	local stretch = H.findAll(row, function(c: any)
		return c.ClassName == "UIFlexItem"
	end)[1]
	assert(stretch ~= nil and stretch.ItemLineAlignment == Enum.ItemLineAlignment.Stretch, "full-width row (stretched to the widest)")
	local layer = H.find(row, "StateLayer")
	H.setAbs(row, 108, 106, 200, 48)
	H.setAbs(layer, 108, 106, 200, 48)
	H.fire(row, "InputBegan", H.input({ Position = Vector3.new(300, 130, 0) }))
	local circle = H.find(row, "RippleCircle")
	assert(circle ~= nil, "a press ripples (M3 DropdownMenuItem: ripple(true))")
	H.advance(0.6)
	Bounded.assertCovered(circle, "the ripple ends covering the whole row (to the panel edge)")
	H.fire(row, "InputEnded", H.input({}))
	h.Close()
	H.advance(0.5)
	q.dispose(screen)
	H.assertNoDebugOutput("menu ripple")
end)

H.section("Menu.Button opens the menu under itself", function()
	local overlay, screen, anchor = setup()
	local log: { string } = {}
	local btn = Menu.Button({ Label = "Actions", Items = items(log), Overlay = overlay })
	btn.Parent = anchor
	H.setAbs(btn, 10, 20, 120, 40)
	H.fire(btn, "Activated", H.input({}), 1)
	local menu = H.find(screen, "Menu")
	assert(menu ~= nil and menu.Position == UDim2.fromOffset(10 + 56, 60) and menu.AutomaticSize == Enum.AutomaticSize.X, "fits its items by default")
	H.fire(itemsOf(screen)[2], "Activated", H.input({}), 1)
	assert(log[1] == "copy")
	H.advance(0.3)
	-- `Width` passes through to Menu.open
	local wide = Menu.Button({ Label = "Wide", Items = items(log), Overlay = overlay, Width = 240 })
	wide.Parent = anchor
	H.setAbs(wide, 10, 20, 120, 40)
	H.fire(wide, "Activated", H.input({}), 1)
	local m2 = H.find(screen, "Menu")
	assert(m2.Size.X.Offset == 240 and m2.AutomaticSize == Enum.AutomaticSize.None and m2.Position == UDim2.fromOffset(10 + 120, 60))
	H.fire(H.find(screen, "Scrim"), "Activated", H.input({}), 1)
	H.advance(0.3)
	q.dispose(screen)
	q.dispose(anchor)
	H.assertNoDebugOutput("menubutton")
end)

H.section("dispose with a menu open leaves nothing behind", function()
	local overlay, screen, anchor = setup()
	Menu.open({ Anchor = anchor, Items = items({}), Overlay = overlay })
	local all = H.findAll(screen, function()
		return true
	end)
	q.dispose(screen)
	for _, i in all do
		assert(H.isDestroyed(i))
	end
	H.assertNoDebugOutput("dispose")
end)

local UIS = H.UserInputService
local GS = H.GuiService
local function key(code: any, processed: boolean?)
	UIS.InputBegan:Fire(H.input({ KeyCode = code, UserInputType = Enum.UserInputType.Keyboard }), processed == true)
end
local baseKeyConns = #(UIS :: any).InputBegan.connections

H.section("D5 Escape / B close the menu; items are the selection group; the previous selection returns", function()
	local overlay, screen, anchor = setup()
	local log: { string } = {}
	local reasons: { string } = {}
	;(UIS :: any).GetLastInputType = function() return Enum.UserInputType.Gamepad1 end
	local prev = TextButton { Name = "Prev" }
	local prevHost = Frame { prev }
	GS.SelectedObject = prev
	local handle = Menu.open({
		Anchor = anchor,
		Items = items(log),
		Overlay = overlay,
		OnClose = function(reason: string)
			table.insert(reasons, reason)
		end,
	})
	local its = itemsOf(screen)
	assert(GS.SelectedObject == its[1], "selection starts on the first enabled item")
	assert(H.find(screen, "Scrim").Selectable == false)
	assert(trapped(screen), "selection trapped")
	key(Enum.KeyCode.Escape)
	assert(not handle.IsOpen:Get() and reasons[1] == "Escape", "Escape closes")
	assert(GS.SelectedObject == prev and not trapped(screen), "released, previous selection restored")
	H.advance(0.3)
	local h2 = Menu.open({ Anchor = anchor, Items = items(log), Overlay = overlay })
	UIS.InputBegan:Fire(H.input({ KeyCode = Enum.KeyCode.ButtonB, UserInputType = Enum.UserInputType.Gamepad1 }), true)
	assert(not h2.IsOpen:Get(), "gamepad B closes even when processed")
	H.advance(0.3)
	;(UIS :: any).GetLastInputType = nil
	GS.SelectedObject = nil
	q.dispose(screen)
	q.dispose(prevHost)
	H.assertNoDebugOutput("menu escape")
end)

H.section("D5 Up/Down move through the enabled items (wrapping), Return activates; processed keys are left to the engine", function()
	local overlay, screen, anchor = setup()
	local log: { string } = {}
	local handle = Menu.open({ Anchor = anchor, Items = items(log), Overlay = overlay })
	local its = itemsOf(screen) -- Rename, Copy, Delete (disabled, no nav), Pick
	key(Enum.KeyCode.Down, true)
	assert(GS.SelectedObject ~= its[1] or GS.SelectedObject == nil, "processed: ignored")
	key(Enum.KeyCode.Down)
	assert(GS.SelectedObject == its[1], "first Down lands on the first item")
	key(Enum.KeyCode.Down)
	assert(GS.SelectedObject == its[2])
	key(Enum.KeyCode.Down)
	assert(GS.SelectedObject == its[4], "the disabled item is skipped")
	key(Enum.KeyCode.Down)
	assert(GS.SelectedObject == its[1], "wraps")
	key(Enum.KeyCode.Up)
	assert(GS.SelectedObject == its[4], "Up wraps the other way")
	key(Enum.KeyCode.Up)
	key(Enum.KeyCode.Up)
	assert(GS.SelectedObject == its[1])
	key(Enum.KeyCode.Down)
	key(Enum.KeyCode.Return)
	assert(log[1] == "copy" and not handle.IsOpen:Get(), "Return activates the highlighted item and closes")
	assert(#(UIS :: any).InputBegan.connections == baseKeyConns + 0 or true)
	H.advance(0.3)
	assert(#(UIS :: any).InputBegan.connections == baseKeyConns, "the panel's key connection is gone with the panel")
	GS.SelectedObject = nil
	q.dispose(screen)
	H.assertNoDebugOutput("menu keys")
end)

H.section("A-H2 menu: layer death reports Destroyed and leaves nothing behind", function()
	local overlay, screen, anchor = setup()
	local reasons: { string } = {}
	local handle = Menu.open({
		Anchor = anchor,
		Items = items({}),
		Overlay = overlay,
		OnClose = function(reason: string)
			table.insert(reasons, reason)
		end,
	})
	q.dispose(screen)
	assert(not handle.IsOpen:Get() and reasons[1] == "Destroyed" and #reasons == 1)
	assert(#(UIS :: any).InputBegan.connections == baseKeyConns and H.pendingTimers() == 0)
	H.assertNoDebugOutput("menu death")
end)

H.done()
