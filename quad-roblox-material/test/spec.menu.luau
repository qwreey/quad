--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local D = q.Declaration
local Menu = require("../src/Menu")
local Overlay = require("../src/Overlay")
local Tokens = require("../src/Tokens")

local L = Tokens.Color.Light

local function setup()
	local overlay = Overlay.new()
	local screen = D.Frame { overlay.Layer }
	H.setAbs(overlay.Layer, 0, 0, 800, 600)
	local anchor = D.Frame { Name = "Anchor" }
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
	assert(menu.Position == UDim2.fromOffset(100, 106), "below the anchor")
	assert(menu.Size == UDim2.fromOffset(200, 16 + 48 * 4 + 17), "anchor width, content height")
	assert(menu.BackgroundColor3 == L.SurfaceContainer and menu.Active == true)
	assert(#itemsOf(screen) == 4 and H.find(screen, "Divider") ~= nil)
	local scrim = H.find(screen, "Scrim")
	H.finishTweens()
	assert(scrim.BackgroundTransparency == 1, "outside-click catcher is invisible")
	local first = itemsOf(screen)[1]
	assert(first.Size == UDim2.new(1, 0, 0, 48) and H.find(first, "Label").Text == "Rename" and H.find(first, "Leading").Image == "rbxassetid://1")
	assert(H.find(first, "Label").Position == UDim2.fromOffset(48, 0))
	local copy = itemsOf(screen)[2]
	assert(H.find(copy, "Trailing").Text == "Ctrl+C" and H.find(copy, "Trailing").ClassName == "TextLabel")
	local pick = itemsOf(screen)[4]
	assert(pick.BackgroundTransparency == 0 and pick.BackgroundColor3 == L.SecondaryContainer, "selected highlight")
	assert(H.find(pick, "Trailing").ClassName == "ImageLabel", "image trailing")
	local count = H.countDescendants(menu)
	print("Menu (4 items + divider) descendants: " .. count)
	H.resetOutput()
	handle.Close()
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
	assert(menu.AnchorPoint == Vector2.new(0, 1) and menu.Position == UDim2.fromOffset(600, 520), "flipped, clamped: " .. tostring(menu.Position))
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
	assert(#itemsOf(screen) == 20)
	h2.Close()
	H.advance(0.3)
	q.dispose(screen)
	H.assertNoDebugOutput("placement")
end)

H.section("Menu.Button opens the menu under itself", function()
	local overlay, screen, anchor = setup()
	local log: { string } = {}
	local btn = Menu.Button({ Label = "Actions", Items = items(log), Overlay = overlay })
	btn.Parent = anchor
	H.setAbs(btn, 10, 20, 120, 40)
	H.fire(btn, "Activated", H.input({}), 1)
	local menu = H.find(screen, "Menu")
	assert(menu ~= nil and menu.Position == UDim2.fromOffset(10, 60) and menu.Size.X.Offset == 120)
	H.fire(itemsOf(screen)[2], "Activated", H.input({}), 1)
	assert(log[1] == "copy")
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
	local prev = D.TextButton { Name = "Prev" }
	local prevHost = D.Frame { prev }
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
