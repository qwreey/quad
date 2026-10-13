--!strict
local H = require("./support/harness")
local ClickSink = require("./support/clicksink")
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
	ClickSink.assertClickSink(dlg, "the dialog card")
	assert(own(dlg, "UICorner").CornerRadius == UDim.new(0, 28), "corner 28")
	assert(own(H.find(dlg, "Content"), "UIPadding").PaddingLeft == UDim.new(0, 24), "padding 24")
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
	assert(dlg.GroupTransparency == 1 and own(dlg, "UIScale").Scale == 0.92, "fades out and shrinks a little")
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

-- The mock has no layout engine: the specs below play it by hand (`H.setAbs`). `layout(dlg, bodyHeight, k)` is one layout
-- pass of a card that is 252 local px wide under a UIScale product `k`: the card's AbsoluteSize.X, then the body's
-- AbsoluteSize (the body's change is the signal the dialog listens to, so it goes last, as both are already there when the
-- engine's signal arrives).
local function layout(dlg: any, bodyHeight: number, k: number?)
	local scale = k or 1
	H.setAbs(dlg, 0, 0, 252 * scale, 300 * scale)
	H.setAbs(H.find(dlg, "Body"), 0, 0, 204 * scale, bodyHeight * scale)
end

H.section("D3 small layer: width capped, the body in a scroll wrapper the kit sizes, headline/actions pinned", function()
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
	assert(scroll ~= nil and scroll.ClassName == "ScrollingFrame")
	-- Until 2026-10-13 the wrapper was `AutomaticSize = Y` + `AutomaticCanvasSize = Y` + a UISizeConstraint child (asserted
	-- here). The engine does not size that correctly (Dialog.luau "BODY HEIGHT": the card came out 48 short, the cap did not
	-- hold, a long text never scrolled), so the wrapper now has NO automatic size, NO automatic canvas and NO constraint:
	-- the kit writes Size / CanvasSize from the body's laid-out height. One instance more than before nets out: the
	-- UISizeConstraint is gone, the `BodyRoom` frame is new.
	-- (the mock has no property defaults: a property the kit never set reads nil)
	assert(scroll.AutomaticSize == nil, "the wrapper's height is written, not automatic")
	assert(scroll.AutomaticCanvasSize == nil, "the canvas is written too")
	assert(#class(scroll, "UISizeConstraint") == 0, "no size constraint (AutomaticSize ignored it)")
	assert(scroll.VerticalScrollBarInset == Enum.ScrollBarInset.ScrollBar, "the scrollbar does not overlay the body")
	assert(scroll.ScrollingDirection == Enum.ScrollingDirection.Y)
	-- the body is laid out in a very tall frame, so a wrapped label is not bounded by the wrapper's window
	local room = H.find(scroll, "BodyRoom")
	assert(room ~= nil and room.Parent == scroll and room.ClassName == "Frame" and room.BackgroundTransparency == 1)
	assert(room.Size.X == UDim.new(1, 0) and room.Size.Y.Scale == 0 and room.Size.Y.Offset >= 10000, "a fixed, very tall room: " .. tostring(room.Size))
	local body = H.find(scroll, "Body")
	assert(body.Parent == room and body.Text:sub(1, 5) == "lorem" and body.AutomaticSize == Enum.AutomaticSize.Y and body.Size == UDim2.fromScale(1, 0))
	assert(H.find(dlg, "Headline").Parent == H.find(dlg, "Content") and H.find(dlg, "Actions").Parent == H.find(dlg, "Content"), "pinned parts are outside the scroll")
	assert(scroll.Parent == H.find(dlg, "Content") and scroll.LayoutOrder == 3)
	-- before any layout: the 1 px floor (never 0: the engine stops measuring a body under a zero-height window), no canvas
	assert(scroll.Size == UDim2.new(1, 0, 0, 1) and scroll.CanvasSize == UDim2.fromOffset(0, 0), "unmeasured: " .. tostring(scroll.Size))
	-- the cap: layer 400 - 48 margins - 48 card padding - headline 32 - actions 48 - 2 gaps of 16 = 192
	layout(dlg, 794)
	assert(scroll.Size == UDim2.new(1, 0, 0, 192), "a body over the cap stops at the cap: " .. tostring(scroll.Size))
	assert(scroll.CanvasSize == UDim2.fromOffset(0, 794), "and the canvas is the whole body: " .. tostring(scroll.CanvasSize))
	assert(192 <= 400 - 48 - 48 - 32 - 48, "card within the layer height")
	-- an unmeasured layer keeps the plain structure
	h.Close()
	H.advance(0.3)
	local o2, s2 = setup()
	Dialog.open({ Overlay = o2, Headline = "Short", Body = "text", Width = 560 })
	local d2 = H.find(s2, "Dialog")
	assert(d2.Size == UDim2.fromOffset(560, 0) and H.find(d2, "BodyScroll") == nil and H.find(d2, "BodyRoom") == nil, "no caps, no scroll wrapper when the layer is unmeasured")
	assert(H.find(d2, "Body").Parent == H.find(d2, "Content"))
	q.dispose(screen)
	q.dispose(s2)
	H.assertNoDebugOutput("dialog caps")
end)

H.section("body height: the wrapper is min(body, cap) tall, follows a body that grows or shrinks, in local units", function()
	local overlay, screen = setup()
	H.setAbs(overlay.Layer, 0, 0, 300, 400)
	local custom = D.Frame { Name = "Custom" }
	local h = Dialog.open({
		Overlay = overlay,
		Headline = "H",
		Body = custom,
		Width = 560,
		Actions = { { Label = "OK" } },
	})
	local dlg = H.find(screen, "Dialog")
	local scroll = H.find(dlg, "BodyScroll")
	local body = H.find(scroll, "Body")
	assert(body.Parent == H.find(scroll, "BodyRoom") and custom.Parent == body, "an element body: Body wraps it, inside the room")
	local function height(): number
		assert(scroll.Size.X == UDim.new(1, 0) and scroll.Size.Y.Scale == 0, "full width, offset height")
		return scroll.Size.Y.Offset
	end
	local function canvas(): number
		assert(scroll.CanvasSize.X == UDim.new(0, 0) and scroll.CanvasSize.Y.Scale == 0)
		return scroll.CanvasSize.Y.Offset
	end
	-- the body is laid out before the card has a width (cannot happen in one engine pass; the read must not divide by 0)
	H.setAbs(body, 0, 0, 204, 100)
	assert(height() == 1 and canvas() == 0, "no card width yet: nothing written")
	-- below the cap (192): the wrapper is exactly the body, nothing to scroll (canvas 0 = the window)
	layout(dlg, 120)
	assert(height() == 120 and canvas() == 0, "fits the body: " .. height())
	-- the body grows after open (a row was added): the card follows
	layout(dlg, 176)
	assert(height() == 176 and canvas() == 0, "follows growth: " .. height())
	-- exactly the cap: still not scrolling
	layout(dlg, 192)
	assert(height() == 192 and canvas() == 0, "at the cap")
	-- past the cap: the wrapper stops, the canvas takes the body
	layout(dlg, 193)
	assert(height() == 192 and canvas() == 193, "one over the cap scrolls: " .. canvas())
	layout(dlg, 1672)
	assert(height() == 192 and canvas() == 1672, "stays at the cap: " .. canvas())
	-- and back: it shrinks with the body
	layout(dlg, 60)
	assert(height() == 60 and canvas() == 0, "follows shrinking: " .. height())
	-- LOCAL UNITS: under a UIScale (the card's enter scale .8, an ancestor's 1.25 ...) AbsoluteSize is scaled on both
	-- axes; the height written is the unscaled one, and a scale change alone rewrites nothing
	local writes = 0
	scroll:GetPropertyChangedSignal("Size"):Connect(function()
		writes += 1
	end)
	for _, k in { 0.8, 0.8437, 0.92, 1.25, 2.3, 1 } do
		layout(dlg, 60, k)
		assert(height() == 60 and canvas() == 0, "scale " .. k .. ": " .. height())
	end
	assert(writes == 0, "a scale change alone does not rewrite the size: " .. writes)
	-- a fraction of a local pixel (text under a UIScale: two lines = 33 screen px at 1.25 = 26.4) rounds UP, not to the
	-- nearest — a UDim offset is an integer, the body's last row would be clipped otherwise
	H.setAbs(dlg, 0, 0, 252 * 1.25, 300)
	H.setAbs(body, 0, 0, 204 * 1.25, 33)
	assert(height() == 27, "26.4 -> 27: " .. height())
	-- an empty body: the 1 px floor
	layout(dlg, 0)
	assert(height() == 1 and canvas() == 0, "floor: " .. height())
	layout(dlg, 48)
	assert(height() == 48, "and measured again from there")
	-- closing: the body dies with the dialog, nothing is left listening
	h.Close()
	H.advance(0.3)
	assert(H.isDestroyed(custom) and H.find(screen, "Dialog") == nil)
	layerClean(overlay)
	assert(H.pendingTimers() == 0)
	q.dispose(screen)
	H.assertNoDebugOutput("dialog body height")
end)

-- The body's cap comes from what the rest of the card measures: the headline is text that wraps, so its laid-out height
-- is read like the body's (Dialog.luau "CAP"). Layer 300 x 400 -> card 252 wide, at most 400 - 48 = 352 tall.
H.section("cap: the headline's laid-out height comes off the body's cap, the card stays within layer - 48", function()
	local overlay, screen = setup()
	H.setAbs(overlay.Layer, 0, 0, 300, 400)
	local h = Dialog.open({
		Overlay = overlay,
		Headline = "A headline",
		Body = D.Frame { Name = "Custom" },
		Width = 560,
		Actions = { { Label = "Cancel" }, { Label = "OK" } },
	})
	local dlg = H.find(screen, "Dialog")
	local scroll = H.find(dlg, "BodyScroll")
	local headline = H.find(dlg, "Headline")
	local function window(): number
		return scroll.Size.Y.Offset
	end
	local function canvas(): number
		return scroll.CanvasSize.Y.Offset
	end
	-- one layout pass of the headline (`k` = the UIScale product, as `layout`)
	local function layHeadline(height: number, k: number?)
		local scale = k or 1
		H.setAbs(dlg, 0, 0, 252 * scale, 300 * scale)
		H.setAbs(headline, 0, 0, 204 * scale, height * scale)
	end
	-- the card's height as the engine would sum it: padding 48 + headline + window + actions 48 + two 16 px gaps
	local function card(headlineHeight: number): number
		return 48 + headlineHeight + window() + 48 + 2 * 16
	end
	-- the headline is laid out before the card has a width (cannot happen in one engine pass): not read
	H.setAbs(headline, 0, 0, 204, 88)
	-- an overflowing body, the headline not laid out yet: it counts as one 32 px line (the old fixed estimate)
	layout(dlg, 1000)
	assert(window() == 192 and canvas() == 1000, "unmeasured headline = 32: " .. window())
	-- one line measures 24 (not 32): the body gets the 8 px, the card is exactly layer - 48
	layHeadline(24)
	assert(window() == 200 and canvas() == 1000, "one line: " .. window())
	assert(card(24) == 400 - 48, "one-line headline: the 24 px margin exactly, " .. card(24))
	-- two lines (24 + 32): the cap gives the 32 px back, the card does not grow
	layHeadline(56)
	assert(window() == 168, "two lines: the cap shrinks by the extra line, " .. window())
	assert(card(56) == 400 - 48, "two-line headline: still layer - 48, " .. card(56))
	layHeadline(88)
	assert(window() == 136 and card(88) == 400 - 48, "three lines: " .. window())
	-- LOCAL UNITS, as the body: a scale change alone moves nothing
	for _, k in { 0.8, 0.92, 1.25, 1 } do
		layHeadline(88, k)
		assert(window() == 136, "scale " .. k .. ": " .. window())
	end
	-- a height of 0 is "not laid out" (a headline has at least a line): the last measure stays
	layHeadline(0)
	assert(window() == 136, "0 is not a measure: " .. window())
	-- a body between the two caps: fits under a one-line headline, scrolls under a three-line one
	layHeadline(24)
	layout(dlg, 150)
	assert(window() == 150 and canvas() == 0, "150 fits the 200 cap: " .. window())
	layHeadline(88)
	assert(window() == 136 and canvas() == 150, "and scrolls under the 136 cap: " .. window() .. " / " .. canvas())
	-- a body under both caps is not touched by the headline
	layout(dlg, 100)
	layHeadline(24)
	assert(window() == 100 and canvas() == 0)
	layHeadline(88)
	assert(window() == 100 and canvas() == 0, "the cap only caps")
	-- the cap never goes under 72 (ScrollBodyMin): a headline that leaves less overflows the layer instead
	layout(dlg, 1000)
	layHeadline(200)
	assert(window() == 72 and canvas() == 1000, "floor of the cap: " .. window())
	h.Close()
	H.advance(0.3)

	-- the icon (24 + a gap) is a constant; no headline = nothing to read
	local icon = Dialog.open({
		Overlay = overlay,
		Icon = "rbxassetid://7",
		Headline = "H",
		Body = D.Frame { Name = "Custom" },
		Width = 560,
		Actions = { { Label = "OK" } },
	})
	dlg = H.find(screen, "Dialog")
	scroll = H.find(dlg, "BodyScroll")
	headline = H.find(dlg, "Headline")
	layout(dlg, 1000)
	layHeadline(24)
	assert(window() == 160, "icon: " .. window())
	assert(48 + 24 + 24 + window() + 48 + 3 * 16 == 400 - 48, "icon + headline + body + actions = layer - 48")
	icon.Close()
	H.advance(0.3)
	local bare = Dialog.open({ Overlay = overlay, Body = D.Frame { Name = "Custom" }, Width = 560, Actions = { { Label = "OK" } } })
	dlg = H.find(screen, "Dialog")
	scroll = H.find(dlg, "BodyScroll")
	assert(H.find(dlg, "Headline") == nil)
	layout(dlg, 1000)
	assert(window() == 240 and 48 + window() + 48 + 16 == 400 - 48, "no headline: " .. window())
	bare.Close()
	H.advance(0.3)
	layerClean(overlay)
	assert(H.pendingTimers() == 0)
	q.dispose(screen)
	H.assertNoDebugOutput("dialog cap")
end)

H.section("body height: no Body = no wrapper; Fit = true keeps the body in the content list (no wrapper, no room)", function()
	local overlay, screen = setup()
	H.setAbs(overlay.Layer, 0, 0, 300, 400)
	local bare = Dialog.open({ Overlay = overlay, Headline = "no body", Actions = { { Label = "OK" } } })
	local d0 = H.find(screen, "Dialog")
	assert(H.find(d0, "BodyScroll") == nil and H.find(d0, "BodyRoom") == nil and H.find(d0, "Body") == nil)
	bare.Close()
	H.advance(0.3)
	local custom = D.Frame { Name = "Custom" }
	local fit = Dialog.open({ Overlay = overlay, Headline = "fit", Body = custom, Width = 560, Fit = true, Actions = { { Label = "OK" } } })
	local d1 = H.find(screen, "Dialog")
	assert(d1.Size == UDim2.fromOffset(560, 0), "Fit: no width cap")
	assert(H.find(d1, "BodyScroll") == nil and H.find(d1, "BodyRoom") == nil, "Fit: no scroll wrapper")
	local body = H.find(d1, "Body")
	assert(body.Parent == H.find(d1, "Content") and custom.Parent == body and body.AutomaticSize == Enum.AutomaticSize.Y)
	-- laying the body out writes nothing anywhere (the card is auto-sized by the engine; Fit only reads the CARD)
	local scale = own(d1, "UIScale")
	H.finishTweens()
	H.setAbs(body, 0, 0, 512, 100)
	H.finishTweens()
	assert(scale.Scale == 1 and body.Size == UDim2.fromScale(1, 0), "Fit: the body's own layout is not a fit input")
	fit.Close()
	H.advance(0.3)
	local text = Dialog.open({ Overlay = overlay, Headline = "fit", Body = "text", Fit = true })
	local d2 = H.find(screen, "Dialog")
	assert(H.find(d2, "BodyScroll") == nil and H.find(d2, "Body").Parent == H.find(d2, "Content") and H.find(d2, "Body").Text == "text")
	text.Close()
	H.advance(0.3)
	layerClean(overlay)
	q.dispose(screen)
	H.assertNoDebugOutput("dialog body fit")
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
