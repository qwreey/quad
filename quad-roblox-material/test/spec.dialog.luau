--!strict
local H = require("./support/harness")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
local D = q.Declaration
local Tokens = require("../src/Tokens")
local Overlay = require("../src/Overlay")
local Dialog = require("../src/Dialog")

local L = Tokens.Color.Light
local UIS = H.UserInputService
local function inputBeganConns(): number
	local u = UIS :: any
	return #u.InputBegan.connections
end
local baseConns = inputBeganConns()

local function class(inst: any, name: string): { any }
	return H.findAll(inst, function(c: any)
		return c.ClassName == name
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

local function setup()
	local overlay = Overlay.new()
	local screen = D.Frame { overlay.Layer }
	return overlay, screen
end

local function layerClean(overlay: Overlay.Overlay)
	assert(overlay.Count:Get() == 0 and #overlay.Layer:GetChildren() == 0, "overlay layer back to baseline")
end

H.section("open: structure, snapped mount then animated enter", function()
	local overlay, screen = setup()
	local closedWith: { any } = {}
	local handle = Dialog.open({
		Overlay = overlay,
		Icon = "rbxassetid://7",
		Headline = "Discard draft?",
		Body = "Your changes will be lost.",
		Actions = { { Label = "Cancel", Result = false }, { Label = "Discard", Result = true } },
		OnClose = function(r: any?)
			table.insert(closedWith, r)
		end,
	})
	local dlg: any = H.find(screen, "Dialog")
	assert(dlg.ClassName == "CanvasGroup" and dlg.BackgroundColor3 == L.SurfaceContainerHigh)
	assert(dlg.Size == UDim2.fromOffset(312, 0) and dlg.AutomaticSize == Enum.AutomaticSize.Y and dlg.Active == true)
	assert(own(dlg, "UICorner").CornerRadius == UDim.new(0, 28), "corner 28")
	assert(own(dlg, "UIPadding").PaddingLeft == UDim.new(0, 24), "padding 24")
	assert(H.find(dlg, "Headline").Text == "Discard draft?" and H.find(dlg, "Headline").TextSize == 24)
	assert(H.find(dlg, "Headline").TextXAlignment == Enum.TextXAlignment.Center, "icon centers the headline")
	assert(H.find(dlg, "Body").Text == "Your changes will be lost." and H.find(dlg, "Body").TextColor3 == L.OnSurfaceVariant)
	assert(H.find(dlg, "Icon").Image == "rbxassetid://7" and H.find(dlg, "Icon").ImageColor3 == L.Secondary)
	assert(#class(H.find(dlg, "Actions"), "TextButton") == 2)
	assert(H.find(screen, "Scrim") ~= nil)
	-- enter: mounted snapped (transparent, scale .8) then tweened in by the PostRef hook
	assert(dlg.GroupTransparency == 1, "mounted snapped transparent")
	assert(own(dlg, "UIScale").Scale == 0.8)
	H.finishTweens()
	assert(dlg.GroupTransparency == 0 and own(dlg, "UIScale").Scale == 1, "animated in")
	assert(handle.IsOpen:Get() and not handle.Closing:Get() and handle.Result:Get() == nil)
	-- a click on Discard closes with true
	local discard = class(H.find(dlg, "Actions"), "TextButton")[2]
	assert(H.find(discard, "Label").Text == "Discard")
	H.fire(discard, "Activated", H.input({}), 1)
	assert(not handle.IsOpen:Get() and handle.Closing:Get() and handle.Result:Get() == true and #closedWith == 1 and closedWith[1] == true)
	assert(H.find(screen, "Dialog") ~= nil, "still mounted during the exit")
	H.finishTweens()
	assert(dlg.GroupTransparency == 1, "fades out")
	H.advance(0.3)
	assert(H.find(screen, "Dialog") == nil)
	layerClean(overlay)
	assert(H.pendingTimers() == 0 and inputBeganConns() == baseConns, "no timers, Escape connection closed")
	handle.Close(false)
	assert(#closedWith == 1 and handle.Result:Get() == true, "Close after close is ignored")
	q.dispose(screen)
	H.assertNoDebugOutput("open")
end)

H.section("action OnClick runs before the close; disabled action; width clamp", function()
	local overlay, screen = setup()
	local order: { string } = {}
	local handle = Dialog.open({
		Overlay = overlay,
		Headline = "H",
		Width = 9999,
		Actions = {
			{
				Label = "Go",
				Result = "go",
				OnClick = function()
					table.insert(order, "click")
				end,
			},
		},
		OnClose = function()
			table.insert(order, "close")
		end,
	})
	assert((H.find(screen, "Dialog") :: any).Size == UDim2.fromOffset(560, 0), "max width 560")
	H.fire(class(H.find(screen, "Actions"), "TextButton")[1], "Activated", H.input({}), 1)
	assert(order[1] == "click" and order[2] == "close" and handle.Result:Get() == "go")
	H.advance(0.3)
	layerClean(overlay)
	local narrow = Dialog.open({ Overlay = overlay, Headline = "n", Width = 10 })
	assert((H.find(screen, "Dialog") :: any).Size == UDim2.fromOffset(280, 0), "min width 280")
	narrow.Close()
	H.advance(0.3)
	local blocked = false
	local dis = Dialog.open({ Overlay = overlay, Actions = { { Label = "No", Disabled = true, OnClick = function() blocked = true end } } })
	local btn: any = class(H.find(screen, "Actions"), "TextButton")[1]
	H.fire(btn, "Activated", H.input({}), 1)
	assert(not blocked and dis.IsOpen:Get(), "disabled action does nothing")
	dis.Close()
	H.advance(0.3)
	layerClean(overlay)
	q.dispose(screen)
	H.assertNoDebugOutput("actions")
end)

H.section("scrim click dismisses with DismissResult; DismissOnScrim = false ignores it", function()
	local overlay, screen = setup()
	local got: { any } = {}
	local a = Dialog.open({
		Overlay = overlay,
		Headline = "A",
		DismissResult = "dismissed",
		OnClose = function(r: any?)
			table.insert(got, r)
		end,
	})
	H.fire(H.find(screen, "Scrim"), "Activated", H.input({}), 1)
	assert(not a.IsOpen:Get() and a.Result:Get() == "dismissed" and got[1] == "dismissed")
	H.advance(0.3)
	local b = Dialog.open({ Overlay = overlay, Headline = "B", DismissOnScrim = false })
	H.fire(H.find(screen, "Scrim"), "Activated", H.input({}), 1)
	assert(b.IsOpen:Get(), "scrim click ignored")
	b.Close(1)
	H.advance(0.3)
	assert(b.Result:Get() == 1)
	layerClean(overlay)
	q.dispose(screen)
	H.assertNoDebugOutput("scrim")
end)

H.section("Escape / gamepad B close only the top dialog; DismissOnEscape = false", function()
	local overlay, screen = setup()
	local first = Dialog.open({ Overlay = overlay, Headline = "first", DismissResult = "esc1" })
	local second = Dialog.open({ Overlay = overlay, Headline = "second", DismissResult = "esc2" })
	assert(inputBeganConns() == baseConns + 1, "one shared connection for both")
	local u = UIS :: any
	u.InputBegan:Fire(H.input({ KeyCode = Enum.KeyCode.Escape, UserInputType = Enum.UserInputType.Keyboard }), false)
	assert(not second.IsOpen:Get() and first.IsOpen:Get() and second.Result:Get() == "esc2", "top only")
	H.advance(0.3)
	u.InputBegan:Fire(H.input({ KeyCode = Enum.KeyCode.ButtonB, UserInputType = Enum.UserInputType.Gamepad1 }), false)
	assert(not first.IsOpen:Get() and first.Result:Get() == "esc1", "gamepad B")
	H.advance(0.3)
	assert(inputBeganConns() == baseConns)
	local sticky = Dialog.open({ Overlay = overlay, Headline = "sticky", DismissOnEscape = false })
	assert(inputBeganConns() == baseConns + 1, "shared connection while a dialog is open (it ignores Escape)")
	u.InputBegan:Fire(H.input({ KeyCode = Enum.KeyCode.Escape, UserInputType = Enum.UserInputType.Keyboard }), false)
	assert(sticky.IsOpen:Get())
	sticky.Close()
	H.advance(0.3)
	layerClean(overlay)
	q.dispose(screen)
	H.assertNoDebugOutput("escape")
end)

H.section("Body can be an element; confirm and alert results", function()
	local overlay, screen = setup()
	local custom = D.TextLabel { Name = "Custom", Text = "custom body" }
	local h = Dialog.open({ Overlay = overlay, Headline = "x", Body = custom })
	assert(H.find(H.find(screen, "Body"), "Custom") == custom)
	h.Close()
	H.advance(0.3)
	assert(H.isDestroyed(custom), "the element dies with the dialog")

	local confirmed: { boolean } = {}
	local c = Dialog.confirm({
		Overlay = overlay,
		Headline = "Delete?",
		Body = "gone",
		OnClose = function(ok: boolean)
			table.insert(confirmed, ok)
		end,
	})
	local buttons = class(H.find(screen, "Actions"), "TextButton")
	assert(H.find(buttons[1], "Label").Text == "Cancel" and H.find(buttons[2], "Label").Text == "OK")
	H.fire(buttons[2], "Activated", H.input({}), 1)
	assert(c.Result:Get() == true and confirmed[1] == true)
	H.advance(0.3)
	local c2 = Dialog.confirm({ Overlay = overlay, Headline = "Delete?", ConfirmLabel = "Delete", CancelLabel = "Keep", OnClose = function(ok: boolean) table.insert(confirmed, ok) end })
	local b2 = class(H.find(screen, "Actions"), "TextButton")
	assert(H.find(b2[2], "Label").Text == "Delete")
	H.fire(H.find(screen, "Scrim"), "Activated", H.input({}), 1)
	assert(c2.Result:Get() == false and confirmed[2] == false, "scrim dismiss = cancel")
	H.advance(0.3)
	local seen = 0
	local a = Dialog.alert({ Overlay = overlay, Headline = "Saved", OnClose = function() seen += 1 end })
	assert(#class(H.find(screen, "Actions"), "TextButton") == 1)
	H.fire(class(H.find(screen, "Actions"), "TextButton")[1], "Activated", H.input({}), 1)
	assert(a.Result:Get() == true and seen == 1)
	H.advance(0.3)
	layerClean(overlay)
	q.dispose(screen)
	H.assertNoDebugOutput("confirm")
end)

H.section("destroying the overlay layer while open: no leaked connection or timer", function()
	local overlay, screen = setup()
	local h = Dialog.open({ Overlay = overlay, Headline = "x", Actions = { { Label = "ok" } } })
	assert(inputBeganConns() == baseConns + 1)
	H.fire(class(H.find(screen, "Actions"), "TextButton")[1], "InputBegan", H.input({ Position = Vector3.new(1, 1, 0) }))
	q.dispose(screen)
	assert(inputBeganConns() == baseConns, "Escape connection closed on destroy")
	H.advance(2)
	assert(H.pendingTimers() == 0)
	assert(h.IsOpen:Get() == false and h.Result:Get() == nil, "the layer died: the handle is finalized (DismissResult = nil)")
	H.assertNoDebugOutput("dispose")
end)

H.section("default overlay: open + close leaves the layer empty; theme dark", function()
	local screen = D.Frame { Overlay.default().Layer }
	local h = Dialog.open({ Headline = "default" })
	assert(H.find(screen, "Dialog") ~= nil)
	h.Close()
	H.advance(0.3)
	layerClean(Overlay.default())
	local Theme = require("../src/Theme")
	local dark = Theme.new({ Scheme = "dark" })
	local o2, s2 = setup()
	local d2 = Dialog.open({ Overlay = o2, Theme = dark, Headline = "dark" })
	assert((H.find(s2, "Dialog") :: any).BackgroundColor3 == Tokens.Color.Dark.SurfaceContainerHigh)
	d2.Close()
	H.advance(0.3)
	q.dispose(screen)
	q.dispose(s2)
	H.assertNoDebugOutput("default")
end)

local GS = H.GuiService

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

H.section("D2 gamepad: selection starts on the first enabled action, is trapped, and returns on close", function()
	local overlay, screen = setup()
	;(UIS :: any).GetLastInputType = function() return Enum.UserInputType.Gamepad1 end
	local prev = D.TextButton { Name = "Prev" }
	local prevHost = D.Frame { prev }
	GS.SelectedObject = prev
	local h = Dialog.open({
		Overlay = overlay,
		Headline = "x",
		Actions = {
			{ Label = "Off", Disabled = true },
			{ Label = "Cancel" },
			{ Label = "OK" },
		},
	})
	local buttons = class(H.find(screen, "Actions"), "TextButton")
	assert(GS.SelectedObject == buttons[2], "first ENABLED action")
	assert(trapped(screen) and H.find(screen, "Scrim").Selectable == false)
	h.Close(true)
	assert(GS.SelectedObject == prev and not trapped(screen))
	H.advance(0.3)
	;(UIS :: any).GetLastInputType = nil
	GS.SelectedObject = nil
	q.dispose(screen)
	q.dispose(prevHost)
	H.assertNoDebugOutput("dialog selection")
end)

H.section("D4 Escape is ignored while a TextBox is focused (and when the engine processed it), ButtonB is not", function()
	local overlay, screen = setup()
	local box = D.TextBox { Name = "Typing" }
	local h = Dialog.open({ Overlay = overlay, Headline = "x", Actions = { { Label = "ok" } } })
	;(UIS :: any).FocusedTextBox = box
	UIS.InputBegan:Fire(H.input({ KeyCode = Enum.KeyCode.Escape, UserInputType = Enum.UserInputType.Keyboard }), false)
	assert(h.IsOpen:Get(), "typing keeps Escape")
	;(UIS :: any).FocusedTextBox = nil
	UIS.InputBegan:Fire(H.input({ KeyCode = Enum.KeyCode.Escape, UserInputType = Enum.UserInputType.Keyboard }), true)
	assert(h.IsOpen:Get(), "processed Escape ignored")
	UIS.InputBegan:Fire(H.input({ KeyCode = Enum.KeyCode.ButtonB, UserInputType = Enum.UserInputType.Gamepad1 }), true)
	assert(not h.IsOpen:Get(), "B dismisses")
	H.advance(0.3)
	q.dispose(screen)
	H.assertNoDebugOutput("dialog escape guards")
end)

H.section("D3 small layer: width capped, body scrolls with the card capped to the layer, headline/actions pinned", function()
	local overlay, screen = setup()
	H.setAbs(overlay.Layer, 0, 0, 300, 400)
	local h = Dialog.open({
		Overlay = overlay,
		Headline = "Long",
		Body = string.rep("lorem ipsum ", 100),
		Width = 560,
		Actions = { { Label = "Cancel" }, { Label = "OK" } },
	})
	local dlg = H.find(screen, "Dialog")
	assert(dlg.Size == UDim2.fromOffset(252, 0), "width capped at layer - 48: " .. tostring(dlg.Size))
	local scroll = H.find(dlg, "BodyScroll")
	assert(scroll ~= nil and scroll.ClassName == "ScrollingFrame" and scroll.AutomaticCanvasSize == Enum.AutomaticSize.Y)
	assert(scroll.VerticalScrollBarInset == Enum.ScrollBarInset.ScrollBar, "the scrollbar does not overlay the body")
	local limit = class(scroll, "UISizeConstraint")[1]
	assert(limit ~= nil, "the scroll body is height-capped")
	local maxBody = limit.MaxSize.Y
	assert(maxBody > 0 and maxBody <= 400 - 48 - 48 - 32 - 48, "card within layer height: body max " .. maxBody)
	assert(H.find(scroll, "Body").Text:sub(1, 5) == "lorem" and H.find(dlg, "Headline").Parent == dlg and H.find(dlg, "Actions").Parent == dlg, "pinned parts are outside the scroll")
	-- an unmeasured layer keeps the plain structure
	h.Close()
	H.advance(0.3)
	local o2, s2 = setup()
	Dialog.open({ Overlay = o2, Headline = "Short", Body = "text", Width = 560 })
	local d2 = H.find(s2, "Dialog")
	assert(d2.Size == UDim2.fromOffset(560, 0) and H.find(d2, "BodyScroll") == nil, "no caps, no scroll wrapper when the layer is unmeasured")
	q.dispose(screen)
	q.dispose(s2)
	H.assertNoDebugOutput("dialog caps")
end)

H.section("A-H2 dialog: layer death reports DismissResult through OnClose and clears the Escape connection", function()
	local overlay, screen = setup()
	local got: { any } = {}
	local h = Dialog.open({
		Overlay = overlay,
		Headline = "x",
		DismissResult = "gone",
		OnClose = function(r: any)
			table.insert(got, r)
		end,
	})
	q.dispose(screen)
	assert(got[1] == "gone" and #got == 1 and h.Result:Get() == "gone")
	assert(inputBeganConns() == baseConns)
	H.assertNoDebugOutput("dialog death")
end)

H.done()
