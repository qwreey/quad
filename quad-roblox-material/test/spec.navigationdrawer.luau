--!strict
-- Navigation drawers: DrawerState, Modal / Dismissible / Permanent drawers, the three sheets, NavigationDrawerItem /
-- Items / Headline / Divider — Compose tokens, the scrim fraction, drag thresholds (half / 400 px/s), Escape on the shared
-- Overlay stack, selection (Tabs rule), ripple BOUNDED, dispose.
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local D = q.Declaration
local Tokens = require("../src/Tokens")
local Overlay = require("../src/Overlay")
local Dialog = require("../src/Dialog")
local Anchored = require("../src/Sheet/Anchored")
local Nav = require("../src/NavigationDrawer")
local Bounded = require("./support/bounded")

local L = Tokens.Color.Light
local UIS = H.UserInputService

Anchored.clock = H.now

local function uisConns(): number
	local u = UIS :: any
	return #u.InputChanged.connections + #u.InputEnded.connections + #u.WindowFocusReleased.connections
end
local function beganConns(): number
	return #(UIS :: any).InputBegan.connections
end
local baseConns, baseBegan = uisConns(), beganConns()

local function own(inst: any, className: string): any
	for _, c in inst:GetChildren() do
		if c.ClassName == className then
			return c
		end
	end
	return nil
end
local function key(code: Enum.KeyCode)
	UIS.InputBegan:Fire(H.input({ KeyCode = code, UserInputType = Enum.UserInputType.Keyboard }), false)
end
local function drag(inst: any, x0: number, xs: { number }, dt: number)
	H.fire(inst, "InputBegan", H.input({ Position = Vector3.new(x0, 300, 0) }))
	for _, x in xs do
		H.advance(dt)
		UIS.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(x, 300, 0) }))
	end
	UIS.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(xs[#xs], 300, 0) }))
end

local ITEMS: { Nav.Entry<string> } = {
	{ Headline = "Mail" },
	{ Key = "inbox", Label = "Inbox", Icon = "rbxassetid://6035067831", Badge = "24" },
	{ Key = "sent", Label = "Sent" },
	"divider",
	{ Key = "trash", Label = "Trash" },
}

-- ── items ───────────────────────────────────────────────────────────────────

H.section("NavigationDrawerItem: 56 tall pill, 12 px margins, 16 / 24 padding, icon 24, LabelLarge, colors, count", function()
	local selected = q.Source(false)
	local clicks = 0
	local item: any = Nav.NavigationDrawerItem({
		Label = "Inbox",
		Icon = "rbxassetid://5",
		Badge = "24",
		Selected = selected,
		OnClick = function()
			clicks += 1
		end,
	})
	assert(item.ClassName == "TextButton" and item.Size == UDim2.new(1, -24, 0, 56))
	assert(own(item, "UICorner").CornerRadius == UDim.new(0.5, 0), "pill indicator")
	assert(item.BackgroundColor3 == L.SecondaryContainer and item.BackgroundTransparency == 1, "unselected: no indicator")
	local content = H.find(item, "Content")
	local pad = own(content, "UIPadding")
	assert(pad.PaddingLeft == UDim.new(0, 16) and pad.PaddingRight == UDim.new(0, 24))
	assert(own(content, "UIListLayout").Padding == UDim.new(0, 12))
	local icon = H.find(item, "Icon")
	local label = H.find(item, "Label")
	local badge = H.find(item, "Badge")
	assert(icon.Size == UDim2.fromOffset(24, 24) and icon.ImageColor3 == L.OnSurfaceVariant)
	assert(label.Text == "Inbox" and label.TextSize == 14 and label.TextColor3 == L.OnSurfaceVariant, "LabelLarge onSurfaceVariant")
	assert(badge.Text == "24" and badge.TextColor3 == L.OnSurfaceVariant)
	selected:Set(true)
	H.finishTweens()
	assert(item.BackgroundTransparency == 0 and label.TextColor3 == L.OnSecondaryContainer and icon.ImageColor3 == L.OnSecondaryContainer)
	H.fire(item, "Activated", H.input({}), 1)
	assert(clicks == 1)
	local n = H.countDescendants(item) + 1
	local plain: any = Nav.NavigationDrawerItem({ Label = "x" })
	local m = H.countDescendants(plain) + 1
	print(`[drawer] item: {n} instances with icon + badge, {m} label only`)
	H.resetOutput()
	assert(n == 12 and m == 10, `counts {n} / {m}`)
	q.dispose(item)
	q.dispose(plain)
	H.assertNoDebugOutput("item")
end)

H.section("item ripple stays inside the 56 px pill row (BOUNDED)", function()
	local item: any = Nav.NavigationDrawerItem({ Label = "Inbox", OnClick = function() end })
	Bounded.pressBounded(item, 336, 56, "drawer item")
	q.dispose(item)
	H.assertNoDebugOutput("item ripple")
end)

H.section("headline (TitleSmall onSurfaceVariant, 48 tall, inset 28) and divider (outline, inset 28, 8 above / below)", function()
	local h: any = Nav.NavigationDrawerHeadline({ Text = "Labels" })
	assert(h.Size == UDim2.new(1, 0, 0, 48) and h.TextSize == 14 and h.TextColor3 == L.OnSurfaceVariant)
	assert(own(h, "UIPadding").PaddingLeft == UDim.new(0, 28) and own(h, "UIPadding").PaddingRight == UDim.new(0, 28))
	local d: any = Nav.NavigationDrawerDivider()
	assert(d.Size == UDim2.new(1, 0, 0, 17))
	local pad = own(d, "UIPadding")
	assert(pad.PaddingLeft == UDim.new(0, 28) and pad.PaddingTop == UDim.new(0, 8) and pad.PaddingBottom == UDim.new(0, 8))
	assert(H.find(d, "Line").BackgroundColor3 == L.Outline)
	q.dispose(h)
	q.dispose(d)
	H.assertNoDebugOutput("headline divider")
end)

H.section("NavigationDrawerItems: entries in order, ONE Selected Source, OnChange only on a user change, OnClick always", function()
	local page = q.Source("inbox")
	local changes: { string } = {}
	local clicks: { string } = {}
	local list: any = Nav.NavigationDrawerItems<<string>>({
		Items = ITEMS,
		Selected = page,
		OnChange = function(k: string)
			table.insert(changes, k)
		end,
		OnClick = function(k: string)
			table.insert(clicks, k)
		end,
	})
	local kids = list:GetChildren()
	local names: { [number]: string } = {}
	for _, k in kids do
		if (k :: any).LayoutOrder ~= nil and (k :: any).ClassName ~= "UIListLayout" then
			names[(k :: any).LayoutOrder] = (k :: any).Name
		end
	end
	assert(names[1] == "NavigationDrawerHeadline" and names[2] == "NavigationDrawerItem" and names[4] == "NavigationDrawerDivider")
	assert(own(list, "UIListLayout").HorizontalAlignment == Enum.HorizontalAlignment.Center)
	local items = H.findAll(list, function(c: any)
		return c.Name == "NavigationDrawerItem"
	end)
	assert(#items == 3)
	H.finishTweens()
	assert(items[1].BackgroundTransparency == 0 and items[2].BackgroundTransparency == 1, "the Source picks the indicator")
	H.fire(items[2], "Activated", H.input({}), 1)
	H.finishTweens()
	assert(page:Get() == "sent" and changes[1] == "sent" and clicks[1] == "sent")
	assert(items[2].BackgroundTransparency == 0 and items[1].BackgroundTransparency == 1)
	H.fire(items[2], "Activated", H.input({}), 1)
	assert(#changes == 1 and #clicks == 2, "the selected one: OnClick only")
	page:Set("trash")
	assert(#changes == 1, "a programmatic write does not report")
	q.dispose(list)
	H.assertNoDebugOutput("items")
end)

-- ── sheets ──────────────────────────────────────────────────────────────────

H.section("sheets: modal surfaceContainerLow + end corners 16, standard surface, width 360 (240..360), scrolling list", function()
	local m: any = Nav.ModalDrawerSheet({ Children = q.Slot<<Instance>>({ D.Frame { Name = "Row" } }) })
	assert(m.Name == "ModalDrawerSheet" and m.Size == UDim2.new(0, 360, 1, 0) and m.BackgroundColor3 == L.SurfaceContainerLow and m.Active)
	assert(own(m, "UICorner").CornerRadius == UDim.new(0, 16) and own(m, "UIShadow") == nil, "end corners 16, no shadow")
	local patch = H.find(m, "CornerPatch")
	assert(patch.AnchorPoint == Vector2.new(0, 0) and patch.Size == UDim2.new(0, 16, 1, 0), "start corners squared")
	local scroll = H.find(m, "Scroll")
	assert(scroll.ClassName == "ScrollingFrame" and scroll.AutomaticCanvasSize == Enum.AutomaticSize.Y and H.find(scroll, "Row") ~= nil)
	assert(own(scroll, "UIPadding").PaddingTop == UDim.new(0, 12) and own(scroll, "UIPadding").PaddingBottom == UDim.new(0, 8))
	local nm = H.countDescendants(m) + 1
	local dsheet: any = Nav.DismissibleDrawerSheet({ Width = 100 })
	assert(dsheet.Size == UDim2.new(0, 240, 1, 0) and dsheet.BackgroundColor3 == L.Surface and own(dsheet, "UICorner") == nil)
	local psheet: any = Nav.PermanentDrawerSheet({ Width = 999 })
	assert(psheet.Size == UDim2.new(0, 360, 1, 0) and psheet.BackgroundColor3 == L.Surface)
	local np = H.countDescendants(psheet) + 1
	print(`[drawer] sheets: modal {nm} (1 row), permanent {np} (empty)`)
	H.resetOutput()
	assert(nm == 7 and np == 4, `counts {nm} / {np}`)
	q.dispose(m)
	q.dispose(dsheet)
	q.dispose(psheet)
	H.assertNoDebugOutput("sheets")
end)

-- ── drawers ─────────────────────────────────────────────────────────────────

local function modalDrawer(state: Nav.DrawerState, props: any?): (any, any, any)
	local p: any = props or {}
	local host: any = Nav.ModalNavigationDrawer({
		DrawerState = state,
		GesturesEnabled = p.GesturesEnabled,
		DrawerContent = Nav.ModalDrawerSheet({ Children = q.Slot<<Instance>>({ Nav.NavigationDrawerItems<<string>>({ Items = ITEMS, Selected = q.Source("inbox") }) }) }),
		Content = q.Slot<<Instance>>({ D.Frame { Name = "Page" } }),
	})
	return host, H.find(host, "Drawer"), H.find(host, "Scrim")
end

H.section("ModalNavigationDrawer: closed and hidden at rest; Open slides in with the scrim fraction; scrim tap closes", function()
	local state = Nav.DrawerState()
	local host, drawer, scrim = modalDrawer(state)
	assert(host.ClipsDescendants == true and host.Size == UDim2.fromScale(1, 1) and H.find(host, "Page") ~= nil)
	assert(drawer.Position == UDim2.fromOffset(-360, 0) and drawer.Visible == false and scrim.Visible == false, "closed: not shown")
	assert(drawer.Active == true and H.find(drawer, "ModalDrawerSheet").Active == true, "the surfaces above the scrim sink presses")
	assert(scrim.BackgroundTransparency == 1)
	state.Open()
	assert(drawer.Visible and scrim.Visible and state.TargetValue:Get() == "Open" and not state.IsOpen:Get())
	H.finishTweens()
	assert(drawer.Position == UDim2.fromOffset(0, 0) and math.abs(scrim.BackgroundTransparency - 0.68) < 1e-6, "scrim 0.32 when open")
	H.advance(0.25)
	assert(state.IsOpen:Get() and state.CurrentValue:Get() == "Open")
	H.fire(scrim, "Activated", H.input({}), 1)
	H.finishTweens()
	assert(drawer.Position == UDim2.fromOffset(-360, 0) and scrim.BackgroundTransparency == 1)
	H.advance(0.15)
	assert(state.CurrentValue:Get() == "Closed" and drawer.Visible == false, "closed again, not shown")
	-- the scrim fraction follows a drag (snapped)
	state.SnapTo("Open")
	assert(drawer.Position == UDim2.fromOffset(0, 0) and state.CurrentValue:Get() == "Open")
	H.fire(drawer, "InputBegan", H.input({ Position = Vector3.new(300, 300, 0) }))
	H.advance(0.1)
	UIS.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(120, 300, 0) }))
	assert(drawer.Position == UDim2.fromOffset(-180, 0), "follows")
	assert(math.abs(scrim.BackgroundTransparency - (1 - 0.32 * 0.5)) < 1e-6, "half open: scrim at half")
	H.advance(0.2)
	UIS.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(120, 300, 0) }))
	H.advance(0.3)
	q.dispose(host)
	H.advance(1)
	H.assertNoDebugOutput("modal drawer")
end)

H.section("modal drag: half the width or 400 px/s; scrim drag; veto; gestures off; the click after a scrim drag", function()
	local state = Nav.DrawerState({ InitialValue = "Open" })
	local host, drawer, scrim = modalDrawer(state)
	assert(drawer.Position == UDim2.fromOffset(0, 0) and drawer.Visible)
	-- slow drag 170 px left (< 180 = half) at 340 px/s: stays open
	drag(drawer, 300, { 266, 232, 198, 164, 130 }, 0.1)
	H.advance(0.3)
	assert(state.CurrentValue:Get() == "Open", "170 < 180 at 340 px/s: stays")
	-- slow drag 190 px: closes
	drag(drawer, 300, { 262, 224, 186, 148, 110 }, 0.1)
	H.advance(0.3)
	assert(state.CurrentValue:Get() == "Closed", "190 >= 180: closes")
	state.Open()
	H.advance(0.3)
	-- fast short fling (40 px in 0.05 s = 800 px/s >= 400): closes
	drag(drawer, 300, { 280, 260 }, 0.025)
	H.advance(0.3)
	assert(state.CurrentValue:Get() == "Closed", "fling closes")
	state.Open()
	H.advance(0.3)
	-- dragging on the scrim works too, and its release is not a tap
	drag(scrim, 600, { 560, 520 }, 0.02)
	H.fire(scrim, "Activated", H.input({}), 1)
	H.advance(0.3)
	assert(state.CurrentValue:Get() == "Closed", "scrim drag flung it closed")
	q.dispose(host)
	H.advance(1)
	-- veto Closed: the scrim and the drag do nothing; Close() still closes (Compose's close() does not ask)
	local stubborn = Nav.DrawerState({
		InitialValue = "Open",
		ConfirmStateChange = function(v)
			return v ~= "Closed"
		end,
	})
	local host2, drawer2, scrim2 = modalDrawer(stubborn)
	H.fire(scrim2, "Activated", H.input({}), 1)
	drag(drawer2, 300, { 260, 220 }, 0.025)
	H.advance(0.3)
	assert(stubborn.CurrentValue:Get() == "Open", "vetoed")
	stubborn.Close()
	H.advance(0.3)
	assert(stubborn.CurrentValue:Get() == "Closed")
	q.dispose(host2)
	-- gestures off: no drag, no scrim tap (Compose onDismissRequest checks gesturesEnabled)
	local still = Nav.DrawerState({ InitialValue = "Open" })
	local host3, drawer3, scrim3 = modalDrawer(still, { GesturesEnabled = false })
	drag(drawer3, 300, { 200, 100 }, 0.02)
	H.fire(scrim3, "Activated", H.input({}), 1)
	H.advance(0.3)
	assert(still.CurrentValue:Get() == "Open" and drawer3.Position == UDim2.fromOffset(0, 0))
	q.dispose(host3)
	H.advance(1)
	assert(uisConns() == baseConns and H.pendingTimers() == 0)
	H.assertNoDebugOutput("modal drag")
end)

H.section("Escape / B close an open drawer through the shared Overlay stack (a dialog above gets the key first)", function()
	local overlay = Overlay.new()
	local state = Nav.DrawerState()
	local host = modalDrawer(state)
	local screen = D.Frame { host, overlay.Layer }
	assert(beganConns() == baseBegan, "nothing registered while closed")
	state.Open()
	assert(beganConns() == baseBegan + 1, "registered once open")
	H.advance(0.3)
	local dlg = Dialog.open({ Headline = "x", Overlay = overlay })
	key(Enum.KeyCode.Escape)
	assert(not dlg.IsOpen:Get() and state.TargetValue:Get() == "Open", "the dialog on top took Escape")
	H.advance(0.5)
	key(Enum.KeyCode.ButtonB)
	assert(state.TargetValue:Get() == "Closed", "then the drawer")
	H.advance(0.3)
	assert(beganConns() == baseBegan, "released when closed")
	state.Open()
	q.dispose(screen)
	H.advance(1)
	assert(beganConns() == baseBegan and H.pendingTimers() == 0, "released on dispose")
	H.assertNoDebugOutput("escape")
end)

H.section("DismissibleNavigationDrawer pushes the content; PermanentNavigationDrawer is a row", function()
	local state = Nav.DrawerState()
	local host: any = Nav.DismissibleNavigationDrawer({
		DrawerState = state,
		DrawerContent = Nav.DismissibleDrawerSheet({}),
		Content = q.Slot<<Instance>>({ D.Frame { Name = "Page" } }),
	})
	assert(H.find(host, "Scrim") == nil, "no scrim")
	local content = H.find(host, "Content")
	local drawer = H.find(host, "Drawer")
	assert(content.Position == UDim2.fromOffset(0, 0) and drawer.Position == UDim2.fromOffset(-360, 0))
	state.Open()
	H.finishTweens()
	assert(content.Position == UDim2.fromOffset(360, 0) and drawer.Position == UDim2.fromOffset(0, 0), "pushed by the width")
	H.advance(0.3)
	key(Enum.KeyCode.Escape)
	H.finishTweens()
	assert(state.TargetValue:Get() == "Closed" and content.Position == UDim2.fromOffset(0, 0))
	H.advance(0.3)
	q.dispose(host)
	local perm: any = Nav.PermanentNavigationDrawer({
		DrawerContent = Nav.PermanentDrawerSheet({ Width = 240 }),
		Content = q.Slot<<Instance>>({ D.Frame { Name = "Page" } }),
	})
	assert(own(perm, "UIListLayout").FillDirection == Enum.FillDirection.Horizontal)
	assert(H.find(perm, "PermanentDrawerSheet").Size == UDim2.new(0, 240, 1, 0))
	assert(own(H.find(perm, "Content"), "UIFlexItem") ~= nil and H.find(perm, "Page") ~= nil)
	q.dispose(perm)
	assert(not pcall(Nav.ModalNavigationDrawer, {} :: any), "DrawerContent required")
	H.advance(1)
	H.assertNoDebugOutput("dismissible permanent")
end)

H.section("DrawerState: checked options; without a drawer requests settle at once; the latest drawer drives it", function()
	assert(not pcall(Nav.DrawerState :: any, { InitialValue = "Half" }))
	local s = Nav.DrawerState()
	s.Open()
	assert(s.IsOpen:Get() and s.CurrentValue:Get() == "Open")
	s.SnapTo("Closed")
	assert(not s.IsOpen:Get())
	local a = modalDrawer(s)
	local b, drawerB = modalDrawer(s)
	q.dispose(a)
	s.Open()
	H.finishTweens()
	assert(drawerB.Position == UDim2.fromOffset(0, 0) and s.CurrentValue:Get() == "Closed", "the latest drawer drives it")
	H.advance(0.3)
	assert(s.IsOpen:Get())
	q.dispose(b)
	H.advance(1)
	H.assertNoDebugOutput("drawer state")
end)

H.done()
