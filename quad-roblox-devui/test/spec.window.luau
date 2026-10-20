--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Devui = require("../src")
local Compositor = require("../src/Window/Compositor")
local Style = Devui.Style
local Kids = Devui.Kids

local UIS = H.UserInputService
-- windows the press-to-front must hit live in a LayerCollector (a detached window is not on screen)
local screen = Instance.new("ScreenGui")
screen.Parent = Instance.new("Folder") -- a placed ScreenGui (not a PlayerGui: the rectangle path)
local function conns(): number
	local function n(sig: any): number
		return #sig.connections
	end
	return n(UIS.InputChanged) + n(UIS.InputEnded) + n(UIS.WindowFocusReleased)
end
local function mouse(t: Enum.UserInputType, x: number, y: number, state: Enum.UserInputState?): any
	return H.input({ UserInputType = t, Position = Vector3.new(x, y, 0), UserInputState = state })
end
-- a global press (UserInputService.InputBegan) at x, y, as the engine sends it for a press on a widget
local function press(x: number, y: number)
	UIS.InputBegan:Fire(mouse(Enum.UserInputType.MouseButton1, x, y), true)
end
-- the window's decoration (made by its manager, siblings of the surface root): the frame and the resize grip
local function deco(win: Instance): (any, any)
	local frame, grip = nil, nil
	for _, part: any in Compositor.partsOf(win) do
		if part.Name == "WindowDecoration" then
			frame = part
		elseif part.Name == "WindowResizeGrip" then
			grip = part
		end
	end
	assert(frame ~= nil, "a window has a decoration frame")
	return frame, grip
end
-- a named instance in the surface or in its decoration (nil when absent)
local function lookup(win: Instance, name: string): any?
	local found = H.find(win, name)
	if found ~= nil then
		return found
	end
	for _, part: any in Compositor.partsOf(win) do
		if part.Name == name then
			return part
		end
		local hit = H.find(part, name)
		if hit ~= nil then
			return hit
		end
	end
	return nil
end
local function get(win: Instance, name: string): any
	local found = lookup(win, name)
	assert(found ~= nil, `missing {name}`)
	return found
end
-- layout stand-in for a window: its outer rectangle at x, y (w x h): the frame, the surface under a title bar of
-- `titleH` (default 19), the grip in the bottom-right corner
local function place(win: Instance, x: number, y: number, w: number, h: number, titleH: number?)
	local bar = titleH or 19
	local frame, grip = deco(win)
	H.setAbs(frame, x, y, w, h)
	H.setAbs(win, x, y + bar, w, h - bar)
	if grip ~= nil then
		H.setAbs(grip, x + w - 15, y + h - 15, 15, 15)
	end
end
-- every instance of a window: the surface root and its descendants, the decoration parts and theirs
local function countAll(win: Instance): number
	local n = 1 + H.countDescendants(win)
	for _, part in Compositor.partsOf(win) do
		n += 1 + H.countDescendants(part)
	end
	return n
end

H.section("mount: structure, bindings, small instance count", function()
	local label = q.Source("Debug")
	local win = Devui.Window({
		Title = label,
		Children = Kids(Devui.Text({ Text = "body" }), Devui.Button({ Text = "ok" })),
	})
	local win2: any = win
	-- the returned root is the content SURFACE, under the title bar; Position / Size stay the outer rectangle
	assert(win2.Name == "Window" and win2.Position == UDim2.fromOffset(60, 79) and win2.Size == UDim2.fromOffset(300, 181))
	assert(win2.BackgroundTransparency == 1 and win2.Visible == true and win2.Active == true)
	assert(H.find(win, "TitleBar") == nil and H.find(win, "ClickSink") == nil, "no title bar or sink inside the surface")
	local frame, grip = deco(win)
	assert(frame.Position == UDim2.fromOffset(60, 60) and frame.Size == UDim2.fromOffset(300, 200), "frame = outer rectangle")
	assert(frame.BackgroundColor3 == Color3.fromRGB(15, 15, 15) and frame.Visible == true)
	assert(grip.Position == UDim2.fromOffset(360, 260) and grip.AnchorPoint == Vector2.new(1, 1), "grip at the outer corner")
	assert(frame.ZIndex < win2.ZIndex and win2.ZIndex < grip.ZIndex, "frame below the surface, grip above it")
	assert(frame.Parent == nil and grip.Parent == nil, "an unplaced surface: the decoration is not placed either")
	assert(get(frame, "TitleBar").Parent == frame)
	local title = get(win, "Title")
	assert(title.Text == "Debug")
	label:Set("Renamed")
	assert(title.Text == "Renamed", "title follows a State")
	local bar = get(win, "TitleBar")
	assert(bar.Size == UDim2.new(1, 0, 0, 19), "title bar = frame height")
	local content = get(win, "Content")
	assert(content.ClassName == "ScrollingFrame" and content.Parent == win)
	assert(content.Size == UDim2.fromScale(1, 1) and content.AutomaticCanvasSize == Enum.AutomaticSize.Y)
	local body = H.findAll(content, function(i: any)
		return i.Name == "Text"
	end)[1] :: any
	assert(body.Text == "body" and body.Parent == content, "children live in the scrolling content")
	assert(grip.Visible == true)

	-- surface = root + Content + padding/list (4); decoration = frame + corner/stroke + ClickSink + title bar (10 with
	-- its buttons and icons) + collapsed icon + its corner/stroke (13) + dock strip + its arrow (15) + grip (16) + dock
	-- width handle (17), hidden while floating (21); the 2 widgets add 6 more
	assert(1 + H.countDescendants(win) == 10, `surface instance count {1 + H.countDescendants(win)}`)
	assert(countAll(win) == 31, `unexpected instance count {countAll(win)}`)

	q.dispose(win)
	assert(H.isDestroyed(frame) and H.isDestroyed(grip), "disposing the surface disposes its decoration")
	H.assertNoDebugOutput("mount")
end)

H.section("title-bar drag writes the Position Source; connections closed after", function()
	local base = conns()
	local pos = q.Source(UDim2.new(0.5, 10, 0, 20))
	local win = Devui.Window({ Title = "w", Position = pos })
	local frame = deco(win)
	local bar = get(win, "TitleBar")
	H.fire(bar, "InputBegan", mouse(Enum.UserInputType.MouseButton1, 100, 100))
	assert(conns() == base + 3)
	UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, 130, 90), false)
	assert(pos:Get() == UDim2.new(0.5, 40, 0, 10), "scale kept, offsets moved by the delta")
	assert(frame.Position == UDim2.new(0.5, 40, 0, 10), "UI follows the Source")
	assert((win :: any).Position == UDim2.new(0.5, 40, 0, 29), "the surface moves with it, under the title bar")
	UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, 70, 160), false)
	assert(pos:Get() == UDim2.new(0.5, -20, 0, 80), "delta is from the press point, not cumulative")
	UIS.InputEnded:Fire(mouse(Enum.UserInputType.MouseButton1, 70, 160, Enum.UserInputState.End), false)
	assert(conns() == base)
	-- external writes move the window too (two-way)
	pos:Set(UDim2.fromOffset(5, 5))
	assert(frame.Position == UDim2.fromOffset(5, 5) and (win :: any).Position == UDim2.fromOffset(5, 24))
	q.dispose(win)
	assert(conns() == base)
	H.assertNoDebugOutput("drag")
end)

H.section("resize grip: grows, respects the minimum, writes the Size Source", function()
	local size = q.Source(Vector2.new(300, 200))
	local win = Devui.Window({ Title = "w", Size = size })
	local frame, grip = deco(win)
	H.fire(grip, "InputBegan", mouse(Enum.UserInputType.MouseButton1, 300, 200))
	UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, 340, 260), false)
	assert(size:Get() == Vector2.new(340, 260) and frame.Size == UDim2.fromOffset(340, 260))
	assert((win :: any).Size == UDim2.fromOffset(340, 241) and grip.Position == UDim2.fromOffset(400, 320), "surface and grip follow")
	UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, 0, 0), false)
	assert(size:Get() == Vector2.new(38, 38), "min = 2 x frame height (19)")
	UIS.InputEnded:Fire(mouse(Enum.UserInputType.MouseButton1, 0, 0, Enum.UserInputState.End), false)
	q.dispose(win)

	local custom = Devui.Window({ Title = "c", Size = q.Source(Vector2.new(200, 100)), MinSize = Vector2.new(150, 90) })
	local f2, g2 = deco(custom)
	H.fire(g2, "InputBegan", mouse(Enum.UserInputType.MouseButton1, 0, 0))
	UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, -500, -500), false)
	assert(f2.Size == UDim2.fromOffset(150, 90))
	UIS.InputEnded:Fire(mouse(Enum.UserInputType.MouseButton1, 0, 0, Enum.UserInputState.End), false)
	q.dispose(custom)
end)

H.section("collapse and close", function()
	local collapsed = q.Source(false)
	local open = q.Source(true)
	local win = Devui.Window({ Title = "w", Collapsed = collapsed, Open = open })
	local arrow = get(win, "CollapseButton")
	local frame, grip = deco(win)
	local winIcon = get(win, "WindowIcon")
	assert(winIcon.Visible == false, "no icon while expanded")
	H.fire(arrow, "Activated", H.input({}), 1)
	assert(collapsed:Get() == true)
	assert(frame.Visible == false and (win :: any).Visible == false and grip.Visible == false, "collapsed: frame, surface and grip hidden")
	assert(winIcon.Visible == true, "collapsed = the icon")
	collapsed:Set(false) -- external control
	assert(frame.Size == UDim2.fromOffset(300, 200) and frame.Visible == true and (win :: any).Visible == true and grip.Visible == true)
	assert(winIcon.Visible == false)

	H.fire(get(win, "CloseButton"), "Activated", H.input({}), 1)
	assert(open:Get() == false and (win :: any).Visible == false and frame.Visible == false and grip.Visible == false)
	open:Set(true)
	assert((win :: any).Visible == true and frame.Visible == true and grip.Visible == true, "re-open brings it back")

	-- closing hides an ANCESTOR of the buttons (no MouseLeave): their hover look must not stay stuck
	local closeBtn = get(win, "CloseButton")
	local idleAlpha, idleColor = closeBtn.BackgroundTransparency, closeBtn.BackgroundColor3
	H.fire(closeBtn, "MouseEnter")
	assert(closeBtn.BackgroundTransparency ~= idleAlpha or closeBtn.BackgroundColor3 ~= idleColor, "hover look applies")
	H.fire(closeBtn, "MouseEnter")
	open:Set(false)
	assert(closeBtn.BackgroundTransparency == idleAlpha and closeBtn.BackgroundColor3 == idleColor, "close drops hover look")
	open:Set(true)
	assert(closeBtn.BackgroundTransparency == idleAlpha and closeBtn.BackgroundColor3 == idleColor, "re-opens not hovered")
	q.dispose(win)
	H.assertNoDebugOutput("collapse/close")
end)

H.section("OnCloseRequest: the close button asks the app and leaves Open alone", function()
	local open = q.Source(true)
	local asked = 0
	local win = Devui.Window({ Title = "w", Open = open, OnCloseRequest = function()
		asked += 1
	end })
	H.fire(get(win, "CloseButton"), "Activated", H.input({}), 1)
	assert(asked == 1 and open:Get() == true and (win :: any).Visible == true, "asked, still open")
	open:Set(false) -- the app decided
	assert((win :: any).Visible == false)
	q.dispose(win)
	local ok, e = pcall(function()
		Devui.Window({ Title = "w", OnCloseRequest = true :: any })
	end)
	assert(not ok and string.find(tostring(e), "Devui.Window: OnCloseRequest must be a function", 1, true) ~= nil, tostring(e))
	H.assertNoDebugOutput("close request")
end)

H.section("focus on press: z-order, active title colour", function()
	local manager = Devui.WindowManager.new()
	local a = Devui.Window({ Title = "A", Manager = manager })
	a.Parent = screen
	local b = Devui.Window({ Title = "B", Manager = manager })
	b.Parent = screen
	-- the mock has no layout: A at (0,0) 300x200, B overlapping it at (100,100) 300x200
	place(a, 0, 0, 300, 200)
	place(b, 100, 100, 300, 200)
	local za, zb = (a :: any).ZIndex, (b :: any).ZIndex
	assert(zb > za, "later window starts on top")
	local idle = get(a, "TitleBar").BackgroundColor3
	assert(idle == Color3.fromRGB(10, 10, 10))

	press(5, 5) -- on A's title bar: a decoration, outside the surface rectangle
	assert((a :: any).ZIndex > (b :: any).ZIndex and manager.Focused:Get() ~= 0, "a press on the decoration raises")
	assert(get(a, "TitleBar").BackgroundColor3 == Color3.fromRGB(41, 74, 122), "active colour")
	assert(get(b, "TitleBar").BackgroundColor3 == idle)

	-- the overlap belongs to the window on top (A now): pressing there keeps A
	press(150, 150)
	assert((a :: any).ZIndex > (b :: any).ZIndex, "overlap: highest rank wins")
	-- B's own part (outside A); the press arrives as gameProcessed (it was on a widget) and still counts
	press(350, 250)
	assert((b :: any).ZIndex > (a :: any).ZIndex)
	assert(get(b, "TitleBar").BackgroundColor3 == Color3.fromRGB(41, 74, 122) and get(a, "TitleBar").BackgroundColor3 == idle)
	-- nowhere near a window: nothing changes; a right click or a key changes nothing either
	press(900, 900)
	UIS.InputBegan:Fire(mouse(Enum.UserInputType.MouseButton2, 5, 5), false)
	UIS.InputBegan:Fire(H.input({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.A }), false)
	assert((b :: any).ZIndex > (a :: any).ZIndex and manager.Focused:Get() ~= 0)
	-- touch counts like the mouse
	UIS.InputBegan:Fire(mouse(Enum.UserInputType.Touch, 5, 5), true)
	assert((a :: any).ZIndex > (b :: any).ZIndex, "touch")

	-- a press on a widget INSIDE the back window (its own InputBegan never reaches the frame) raises it
	local button = Devui.Button({ Text = "in B" })
	button.Parent = get(b, "Content")
	H.setAbs(button, 320, 260, 60, 19)
	H.fire(button, "InputBegan", mouse(Enum.UserInputType.MouseButton1, 330, 265)) -- (stops at the button)
	press(330, 265)
	assert((b :: any).ZIndex > (a :: any).ZIndex, "widget press raises its window")

	-- starting a title drag focuses too (and a hidden window under the pointer is not hit)
	H.fire(get(a, "TitleBar"), "InputBegan", mouse(Enum.UserInputType.MouseButton1, 5, 5))
	assert((a :: any).ZIndex > (b :: any).ZIndex)
	UIS.InputEnded:Fire(mouse(Enum.UserInputType.MouseButton1, 5, 5, Enum.UserInputState.End), false)
	q.dispose(a)
	q.dispose(b)

	-- a focused window covered by a newly registered one rises on press
	local m2 = Devui.WindowManager.new()
	local wa = Devui.Window({ Title = "A", Manager = m2 })
	wa.Parent = screen
	place(wa, 0, 0, 100, 100)
	press(5, 5)
	local wb = Devui.Window({ Title = "B", Manager = m2 })
	wb.Parent = screen
	place(wb, 500, 500, 100, 100)
	assert((wb :: any).ZIndex > (wa :: any).ZIndex, "B registered on top")
	press(5, 5)
	assert((wa :: any).ZIndex > (wb :: any).ZIndex, "press on the focused-but-covered A raises it")
	q.dispose(wa)
	q.dispose(wb)
	H.assertNoDebugOutput("focus")
end)

H.section("press-to-front: hidden windows and popups are not hit; one listener per manager, only while windows exist", function()
	local began0 = #(UIS.InputBegan :: any).connections
	local manager = Devui.WindowManager.new()
	local a = Devui.Window({ Title = "A", Manager = manager })
	a.Parent = screen
	assert(#(UIS.InputBegan :: any).connections == began0 + 1, "one global press listener")
	local openB = q.Source(true)
	local b2 = Devui.Window({ Title = "B", Open = openB, Manager = manager })
	b2.Parent = screen
	assert(#(UIS.InputBegan :: any).connections == began0 + 1, "still one for two windows")
	place(a, 0, 0, 300, 200)
	place(b2, 0, 0, 300, 200)
	press(5, 5)
	assert((b2 :: any).ZIndex > (a :: any).ZIndex)
	-- a closed window is not hit: the press goes to the open one beneath
	openB:Set(false)
	press(5, 5)
	assert((a :: any).ZIndex > (b2 :: any).ZIndex, "a closed window is not hit; the one beneath is")
	openB:Set(true)
	assert((b2 :: any).ZIndex > (a :: any).ZIndex, "reopened B comes to the front (and takes the focus)")
	press(5, 5)
	assert((b2 :: any).ZIndex > (a :: any).ZIndex, "a press on the overlap now hits B, the front one")

	-- a hidden ancestor (the container) hides every window in it
	local container = Instance.new("Frame")
	container.Parent = screen
	H.setAbs(container, 0, 0, 1000, 1000)
	a.Parent = container
	b2.Parent = container
	press(5, 5)
	local top = if (a :: any).ZIndex > (b2 :: any).ZIndex then a else b2
	local other = if top == a then b2 else a
	place(other, 600, 600, 300, 200) -- only `other` under (650, 650)
	container.Visible = false
	local before = manager.Focused:Get()
	press(650, 650)
	assert(manager.Focused:Get() == before and (top :: any).ZIndex > (other :: any).ZIndex, "hidden container: no hit")
	container.Visible = true
	press(650, 650)
	assert((other :: any).ZIndex > (top :: any).ZIndex, "shown again: hit")

	-- a press on an open popup that takes input (or on its click-outside catcher) does not change focus; a popup that
	-- takes no input (a tooltip) does not shield the window under it (no PlayerGui here: the PopupHits fallback)
	local OverlayModule = require("../src/Overlay")
	OverlayModule.warnUnmounted = false
	local overlay = OverlayModule.new()
	H.setAbs(overlay.Layer, 0, 0, 1000, 1000)
	local Frame = q.Elem "Frame"
	local TextButton = q.Elem "TextButton"
	local TextLabel = q.Elem "TextLabel"
	local sub = overlay:Open({ Content = Frame({ TextButton({ Text = "" }) }), Position = Vector2.new(400, 400), CloseOnClickOutside = false })
	H.setAbs(sub.Holder, 400, 400, 50, 20)
	press(5, 5) -- not on the popup: focus moves as usual
	local focusedNow = manager.Focused:Get()
	local under = if (a :: any).ZIndex > (b2 :: any).ZIndex then b2 else a
	place(under, 380, 380, 100, 100)
	press(410, 405) -- on the popup holder, which lies over `under`
	assert(manager.Focused:Get() == focusedNow, "press on a popup with a button: no focus change")
	press(470, 470) -- `under` outside the popup: focused
	assert(manager.Focused:Get() ~= focusedNow, "outside the popup: focus moves")
	sub:Close()
	press(5, 5)
	focusedNow = manager.Focused:Get()
	local tip = overlay:Open({ Content = TextLabel({ Text = "hint" }), Position = Vector2.new(400, 400), CloseOnClickOutside = false })
	H.setAbs(tip.Holder, 400, 400, 50, 20)
	press(410, 405) -- on the tooltip, over `under`
	assert(manager.Focused:Get() ~= focusedNow, "a tooltip takes no input: the window under it is focused")
	tip:Close()
	local modal = overlay:Open({ Content = q.Elem "Frame"({}), Position = Vector2.new(0, 0) })
	local focusedModal = manager.Focused:Get()
	press(5, 5) -- anywhere on the layer = the catcher of a click-outside popup
	assert(manager.Focused:Get() == focusedModal, "press on the catcher: no focus change")
	modal:Close()
	press(5, 5)
	assert(manager.Focused:Get() ~= focusedModal, "popup closed: presses focus again")
	q.dispose(overlay.Layer)
	OverlayModule.warnUnmounted = true

	q.dispose(a)
	assert(#(UIS.InputBegan :: any).connections == began0 + 1, "a window left: listener stays")
	q.dispose(b2)
	assert(#(UIS.InputBegan :: any).connections == began0, "no window left: listener closed")
	q.dispose(container)
	H.assertNoDebugOutput("press-to-front")
end)

H.section("focus succession: closing or destroying the focused window focuses the topmost open one; reopening focuses", function()
	local manager = Devui.WindowManager.new()
	local opens = { q.Source(true), q.Source(true), q.Source(true) }
	local w: { any } = {}
	for i = 1, 3 do
		w[i] = Devui.Window({ Title = `w{i}`, Open = opens[i], Manager = manager })
		w[i].Parent = screen
		place(w[i], i * 400, 0, 300, 200)
	end
	local function focusedIndex(): number?
		for i = 1, 3 do
			if not H.isDestroyed(w[i]) and get(w[i], "TitleBar").BackgroundColor3 == Color3.fromRGB(41, 74, 122) then
				return i
			end
		end
		return nil
	end
	press(405, 5) -- focus w1 (now on top: order w2, w3, w1)
	assert(focusedIndex() == 1)
	opens[1]:Set(false)
	assert(focusedIndex() == 3 and w[3].ZIndex > w[2].ZIndex, "closed: the topmost open window (w3) takes the focus")
	-- closing a window that is NOT focused moves nothing
	opens[2]:Set(false)
	assert(focusedIndex() == 3)
	-- reopening brings the window to the front WITH the focus (Dear ImGui; user decision 2026-10-15)
	opens[2]:Set(true)
	assert(focusedIndex() == 2 and w[2].ZIndex > w[3].ZIndex, "reopened w2: front + focused")
	opens[1]:Set(true)
	assert(focusedIndex() == 1 and w[1].ZIndex > w[2].ZIndex and w[2].ZIndex > w[3].ZIndex, "reopened w1: front + focused")
	-- destroying the focused window: same rule as closing (topmost remaining = w2)
	q.dispose(w[1])
	assert(focusedIndex() == 2, "destroyed: topmost remaining (w2) focused")
	opens[2]:Set(false)
	assert(focusedIndex() == 3, "closed w2: w3 focused")
	-- the last open one closes: nobody is focused
	opens[3]:Set(false)
	assert(manager.Focused:Get() == 0 and focusedIndex() == nil, "no open window: Focused 0")
	q.dispose(w[2])
	q.dispose(w[3])
	H.assertNoDebugOutput("succession")
end)

H.section("staying on screen: dragging keeps the title bar inside; a shrinking container brings windows back", function()
	local container = Instance.new("Frame")
	H.setAbs(container, 0, 0, 800, 600)
	local pos = q.Source(UDim2.fromOffset(100, 100))
	local win = Devui.Window({ Title = "w", Position = pos, Size = q.Source(Vector2.new(300, 200)) })
	win.Parent = container
	place(win, 100, 100, 300, 200)
	local bar = get(win, "TitleBar")
	local function dragBy(dx: number, dy: number)
		H.fire(bar, "InputBegan", mouse(Enum.UserInputType.MouseButton1, 0, 0))
		UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, dx, dy), false)
		UIS.InputEnded:Fire(mouse(Enum.UserInputType.MouseButton1, dx, dy, Enum.UserInputState.End), false)
	end
	-- pad = FrameHeight 19 (DisplaySafeAreaPadding 0); title bar 19
	dragBy(-1000, -1000)
	assert(pos:Get() == UDim2.fromOffset(19 - 300, 0), `top-left clamp: 19 px of the bar, its top at 0 ({pos:Get()})`)
	dragBy(5000, 5000)
	assert(pos:Get() == UDim2.fromOffset(800 - 19, 600 - 19), `bottom-right clamp ({pos:Get()})`)
	-- inside: untouched (offsets move by the plain delta)
	pos:Set(UDim2.fromOffset(100, 100))
	dragBy(10, -20)
	assert(pos:Get() == UDim2.fromOffset(110, 80))
	-- a scale position keeps its scale; the offset absorbs the clamp
	pos:Set(UDim2.new(0.5, 0, 0.5, 0))
	dragBy(10000, 0)
	assert(pos:Get() == UDim2.new(0.5, 800 - 19 - 400, 0.5, 0), `scale kept ({pos:Get()})`)

	-- the program may put the window anywhere: no clamp until the container shrinks
	pos:Set(UDim2.fromOffset(2000, 1500))
	assert(pos:Get() == UDim2.fromOffset(2000, 1500))
	H.setAbs(container, 0, 0, 900, 700) -- grows: nothing (even though the window is outside)
	assert(pos:Get() == UDim2.fromOffset(2000, 1500), "growth clamps nothing")
	H.setAbs(container, 0, 0, 400, 300) -- shrinks: brought back
	assert(pos:Get() == UDim2.fromOffset(400 - 19, 300 - 19), `shrink brings it in ({pos:Get()})`)
	H.setAbs(container, 0, 0, 0, 0) -- zero (minimised): untouched
	assert(pos:Get() == UDim2.fromOffset(400 - 19, 300 - 19))
	pos:Set(UDim2.fromOffset(10, 10))
	H.setAbs(container, 0, 0, 300, 200) -- (from zero: a growth)
	H.setAbs(container, 0, 0, 290, 200) -- shrinks, but the window is inside: no write
	assert(pos:Get() == UDim2.fromOffset(10, 10))

	-- moved to another container: the old one is no longer watched
	local other = Instance.new("Frame")
	H.setAbs(other, 0, 0, 800, 600)
	win.Parent = other
	pos:Set(UDim2.fromOffset(250, 150))
	H.setAbs(container, 0, 0, 100, 100)
	assert(pos:Get() == UDim2.fromOffset(250, 150), "old container ignored")
	H.setAbs(other, 0, 0, 200, 100)
	assert(pos:Get() == UDim2.fromOffset(200 - 19, 100 - 19), "new container watched")

	-- without a title bar the whole window is the band: 19 px of it stays inside on every side
	local bare = q.Source(UDim2.fromOffset(0, 0))
	local nb = Devui.Window({ Title = "n", Position = bare, NoTitleBar = true, Size = q.Source(Vector2.new(100, 50)) })
	nb.Parent = other
	bare:Set(UDim2.fromOffset(-500, -500))
	H.setAbs(other, 0, 0, 150, 90)
	assert(bare:Get() == UDim2.fromOffset(19 - 100, 19 - 50), `no title bar ({bare:Get()})`)

	-- destroyed: the container connection goes with it
	local before = #(other :: any):GetPropertyChangedSignal("AbsoluteSize").connections
	q.dispose(win)
	q.dispose(nb)
	assert(#(other :: any):GetPropertyChangedSignal("AbsoluteSize").connections == before - 2, "container connections closed")
	q.dispose(container)
	q.dispose(other)
	H.assertNoDebugOutput("on screen")
end)

H.section("flags remove parts", function()
	local base = conns()
	local pos = q.Source(UDim2.fromOffset(0, 0))
	local fixed = Devui.Window({ Title = "f", Position = pos, NoMove = true, NoResize = true, NoClose = true, NoCollapse = true })
	assert(lookup(fixed, "WindowResizeGrip") == nil and lookup(fixed, "CloseButton") == nil and lookup(fixed, "CollapseButton") == nil)
	assert(#Compositor.partsOf(fixed) == 3, "NoResize: the frame, the (hidden) icon and the (hidden) dock strip only")
	H.fire(get(fixed, "TitleBar"), "InputBegan", mouse(Enum.UserInputType.MouseButton1, 0, 0))
	assert(conns() == base and pos:Get() == UDim2.fromOffset(0, 0), "NoMove: no drag starts")
	q.dispose(fixed)

	local bare = Devui.Window({ Title = "b", NoTitleBar = true })
	assert(lookup(bare, "TitleBar") == nil)
	assert((bare :: any).Position == UDim2.fromOffset(60, 60) and (bare :: any).Size == UDim2.fromOffset(300, 200), "the surface fills the frame")
	local bareFrame = deco(bare)
	assert(bareFrame.Size == UDim2.fromOffset(300, 200) and get(bareFrame, "ClickSink") ~= nil, "the frame and its sink stay")
	q.dispose(bare)
	H.assertNoDebugOutput("flags")
end)

H.section("theme and density follow live; dispose destroys everything", function()
	local s = Style.new()
	local win = Devui.Window({ Title = "t", Style = s, Children = Kids(Devui.Text({ Text = "x", Style = s })) })
	local n = countAll(win)
	local frame = deco(win)
	s:SetScheme("Light")
	assert(frame.BackgroundColor3 == Color3.fromRGB(240, 240, 240))
	assert(get(win, "Title").TextColor3 == Color3.fromRGB(0, 0, 0))
	s:SetDensity("Clear")
	assert(get(win, "TitleBar").Size == UDim2.new(1, 0, 0, 23))
	assert((win :: any).Position == UDim2.fromOffset(60, 83), "the surface follows the title bar height")
	assert(countAll(win) == n, "switching never adds or removes instances")
	local kids = H.findAll(win, function()
		return true
	end)
	for _, part in Compositor.partsOf(win) do
		table.insert(kids, part)
		H.findAll(part, function()
			return true
		end, kids)
	end
	q.dispose(win)
	for _, k in kids do
		assert(H.isDestroyed(k), "descendant destroyed")
	end
	H.assertNoDebugOutput("theme")
end)

H.section("z-order is a rank: 2000 focus switches never reach the overlay layer; a destroyed window leaves its rank", function()
	local manager = Devui.WindowManager.new()
	local layerZ = require("../src/Overlay").new().Layer.ZIndex
	local wins: { any } = {}
	for i = 1, 3 do
		wins[i] = Devui.Window({ Title = `w{i}`, Manager = manager })
		wins[i].Parent = screen
		place(wins[i], i * 400, 0, 300, 200)
	end
	local last = 0
	for i = 1, 2000 do
		last = (i * 7) % 3 + 1
		press(last * 400 + 5, 5)
	end
	-- rank r owns the chunk 3r-2 (frame), 3r-1 (surface), 3r (grip)
	local seen: { [number]: boolean } = {}
	for _, w in wins do
		local z = (w :: any).ZIndex
		local frame, grip = deco(w)
		assert(z % 3 == 2 and z >= 2 and z <= 8 and not seen[z], `surface z {z}`)
		assert(frame.ZIndex == z - 1 and grip.ZIndex == z + 1 and grip.ZIndex < layerZ, "one contiguous chunk per window")
		seen[z] = true
	end
	assert(wins[last].ZIndex == 8, "the last focused window is on top")
	-- destroying the middle one closes ranks; a new window starts on top again
	local mid = 1
	for i, w in wins do
		if (w :: any).ZIndex == 5 then
			mid = i
		end
	end
	q.dispose(wins[mid])
	for i, w in wins do
		if i ~= mid then
			assert((w :: any).ZIndex <= 5 and select(2, deco(w)).ZIndex <= 6, "ranks closed up")
		end
	end
	local fresh = Devui.Window({ Title = "fresh", Manager = manager })
	fresh.Parent = screen
	assert((fresh :: any).ZIndex == 8 and deco(fresh).ZIndex == 7)
	for i, w in wins do
		if i ~= mid then
			q.dispose(w)
		end
	end
	q.dispose(fresh)
	assert(manager.Focused:Get() == 0 or manager.Focused:Get() > 0)
	H.assertNoDebugOutput("z rank")
end)


H.section("Focused is two-way: true raises and focuses, false drops the focus; a closed window ignores true", function()
	local manager = Devui.WindowManager.new()
	local fa, fb = q.Source(false), q.Source(false)
	local open = q.Source(true)
	local a = Devui.Window({ Title = "A", Manager = manager, Focused = fa, Open = open })
	local b = Devui.Window({ Title = "B", Manager = manager, Focused = fb })
	a.Parent = screen
	b.Parent = screen
	assert(manager.Focused:Get() == 0)
	fa:Set(true)
	assert(fa:Get() and (a :: any).ZIndex > (b :: any).ZIndex and manager.Focused:Get() ~= 0, "true: raised and focused")
	fb:Set(true)
	assert(fb:Get() and not fa:Get(), "the other window took it; A wrote false")
	fb:Set(false)
	assert(manager.Focused:Get() == 0 and not fb:Get() and (b :: any).ZIndex > (a :: any).ZIndex, "false: no window focused, order kept")
	open:Set(false)
	fa:Set(true)
	assert(manager.Focused:Get() == 0, "a closed window ignores true")
	open:Set(true) -- opening focuses (the 2026-10-15 rule) and writes true
	assert(fa:Get() == true)
	q.dispose(a)
	q.dispose(b)
	local pre = q.Source(true)
	local m2 = Devui.WindowManager.new()
	local c = Devui.Window({ Title = "C", Manager = m2, Focused = pre })
	assert(m2.Focused:Get() ~= 0 and pre:Get() == true, "a true held at build time is a request")
	q.dispose(c)
	H.assertNoDebugOutput("Focused two-way")
end)

H.section("AvailableSize: the content area's visible size minus the window padding, written on change", function()
	local out = q.Source(Vector2.new(-1, -1))
	local win = Devui.Window({ Title = "c", AvailableSize = out })
	local content = get(win, "Content")
	content.AbsoluteWindowSize = Vector2.new(300, 281)
	assert(out:Get() == Vector2.new(284, 265), `{out:Get()}`)
	content.AbsoluteWindowSize = Vector2.new(288, 431) -- taller, and a scrollbar took 12 px
	assert(out:Get() == Vector2.new(272, 415))
	content.AbsoluteWindowSize = Vector2.new(10, 10)
	assert(out:Get() == Vector2.new(0, 0), "never negative")
	q.dispose(win)
	H.assertNoDebugOutput("AvailableSize")
end)

H.section("click sink: the window's empty area is covered by one invisible GuiButton in the frame, under the surface", function()
	local win = Devui.Window({ Title = "sink" })
	local frame = deco(win)
	local sink: any = frame:FindFirstChild("ClickSink")
	assert(sink ~= nil and sink.ClassName == "TextButton", "a TextButton ClickSink is a direct child of the decoration frame")
	assert(sink.ZIndex == 0 and sink.Size == UDim2.fromScale(1, 1), "full cover at ZIndex 0")
	assert(sink.BackgroundTransparency == 1 and sink.Text == "" and sink.AutoButtonColor == false and sink.Selectable == false,
		"invisible, no hover tint, off the gamepad path")
	for _, child: any in frame:GetChildren() do
		if child ~= sink and child.ZIndex ~= nil then
			assert(child.ZIndex >= 1, `{child.Name} draws above the sink`)
		end
	end
	assert((win :: any).ZIndex == frame.ZIndex + 1, "the surface sits right above the frame (its empty area falls to the sink)")
	q.dispose(win)
end)

H.section("owner Sources: open:Set(true) raises an open window, SetIfChanged does not; Focused is written out", function()
	local manager = Devui.WindowManager.new()
	local openA, openB = q.Source(true), q.Source(true)
	local focusedA = q.Source(false)
	local a = Devui.Window({ Title = "A", Open = openA, Focused = focusedA, Manager = manager })
	a.Parent = screen
	local b = Devui.Window({ Title = "B", Open = openB, Manager = manager })
	b.Parent = screen
	assert((b :: any).ZIndex > (a :: any).ZIndex and manager.Focused:Get() == 0, "open from the start: no focus stolen")
	assert(focusedA:Get() == false, "Focused written at install")
	openA:SetIfChanged(true)
	assert((b :: any).ZIndex > (a :: any).ZIndex and manager.Focused:Get() == 0, "SetIfChanged(true) syncs only")
	openA:Set(true)
	assert((a :: any).ZIndex > (b :: any).ZIndex, "Set(true) on an open window raises it")
	assert(focusedA:Get() == true, "Focused output follows")
	openB:Set(true)
	assert((b :: any).ZIndex > (a :: any).ZIndex and focusedA:Get() == false, "the other one raised; A's Focused written false")
	q.dispose(a)
	q.dispose(b)
end)
H.section("decoration follows the surface root's parent; the parent's dispose or an engine Destroy takes it along", function()
	local began0 = #(UIS.InputBegan :: any).connections
	local manager = Devui.WindowManager.new()
	local win = Devui.Window({ Title = "f", Manager = manager })
	local frame, grip = deco(win)
	assert(frame.Parent == nil and grip.Parent == nil)
	local c1 = Instance.new("Frame")
	c1.Parent = screen
	win.Parent = c1
	assert(frame.Parent == c1 and grip.Parent == c1, "placed: the decoration joins the surface as its siblings")
	local c2 = Instance.new("Frame")
	c2.Parent = screen
	win.Parent = c2
	assert(frame.Parent == c2 and grip.Parent == c2 and #c1:GetChildren() == 0, "moved: it follows")
	win.Parent = nil
	assert(frame.Parent == nil and grip.Parent == nil, "detached: so is the decoration")
	win.Parent = c2
	assert(win.Parent == c2 and frame.Parent == c2, "the surface root stays where the app put it")
	-- a quad static child: the parent's build places it, the parent's dispose takes everything
	local holder = q.Elem "Frame" ({ Devui.Window({ Title = "static", Manager = manager }) })
	local inner = H.find(holder, "Window") :: any
	local f2, g2 = deco(inner)
	assert(f2.Parent == holder and g2.Parent == holder)
	q.dispose(holder)
	assert(H.isDestroyed(inner) and H.isDestroyed(f2) and H.isDestroyed(g2), "disposed with the parent")
	-- the engine destroying the container (outside quad): no error, the manager lets go
	c2:Destroy()
	assert(H.isDestroyed(win) and H.isDestroyed(frame) and H.isDestroyed(grip))
	assert(#(UIS.InputBegan :: any).connections == began0, "no window left: the press listener closed")
	q.dispose(c1)
	H.assertNoDebugOutput("follow")
end)

H.section("press-to-front through the engine list (PlayerGui): the title bar and the grip count as their window", function()
	local pg = H.playerGui()
	local gui = Instance.new("ScreenGui")
	gui.Parent = pg
	local manager = Devui.WindowManager.new()
	local fa, fb = q.Source(false), q.Source(false)
	local a = Devui.Window({ Title = "A", Manager = manager, Focused = fa })
	a.Parent = gui
	local b = Devui.Window({ Title = "B", Manager = manager, Focused = fb })
	b.Parent = gui
	place(a, 0, 0, 300, 200)
	place(b, 100, 0, 300, 150) -- on top: covers A's title bar from x = 100, not A's grip (285..300 x 185..200)
	assert((b :: any).ZIndex > (a :: any).ZIndex)
	press(290, 190) -- A's resize grip
	assert(fa:Get() and (a :: any).ZIndex > (b :: any).ZIndex, "a press on the back window's grip raises it")
	press(350, 5) -- B's title bar, outside A
	assert(fb:Get() and (b :: any).ZIndex > (a :: any).ZIndex, "a press on the back window's title bar raises it")
	press(150, 10) -- B's title bar over A's
	assert(fb:Get() and not fa:Get(), "the front window's decoration takes the press over the back one")
	press(50, 100) -- A's content, outside B
	assert(fa:Get(), "the surface still counts")
	press(150, 100) -- A (front now) over B's content
	assert(fa:Get() and (a :: any).ZIndex > (b :: any).ZIndex)
	gui:Destroy()
	H.assertNoDebugOutput("engine list")
end)

H.section("focus succession follows Open, not the surface's visibility: collapsing keeps the focus; a collapsed or bare window can take it", function()
	local manager = Devui.WindowManager.new()
	local open1, open2, open3 = q.Source(true), q.Source(true), q.Source(true)
	local col1 = q.Source(false)
	local f1, f2, f3 = q.Source(false), q.Source(false), q.Source(false)
	local w1 = Devui.Window({ Title = "1", Manager = manager, Open = open1, Collapsed = col1, Focused = f1 })
	local w2 = Devui.Window({ Title = "2", Manager = manager, Open = open2, Focused = f2 })
	local w3 = Devui.Window({ Title = "3", Manager = manager, Open = open3, Focused = f3, NoTitleBar = true })
	for i, w in { w1, w2, w3 } do
		w.Parent = screen
		place(w, i * 400, 0, 300, 200, if w == w3 then 0 else nil)
	end
	press(405, 5)
	assert(f1:Get(), "w1 focused")
	col1:Set(true) -- the surface root is hidden; the window is still open
	assert((w1 :: any).Visible == false and f1:Get() and manager.Focused:Get() ~= 0, "collapsing is not a close")
	press(1205, 100) -- the bare window: its surface is the whole rectangle
	assert(f3:Get() and (w3 :: any).ZIndex > (w1 :: any).ZIndex, "a window without a title bar is hit on its surface")
	press(805, 5)
	assert(f2:Get())
	open2:Set(false)
	assert(f3:Get(), "closed: the topmost open window (the bare w3) takes the focus")
	open3:Set(false)
	assert(f1:Get() and (w1 :: any).Visible == false, "then the collapsed w1 (open, its icon on screen)")
	press(405, 5) -- the collapsed window's icon
	assert(f1:Get())
	open1:Set(false)
	assert(manager.Focused:Get() == 0, "no open window left")
	open3:Set(true)
	assert(f3:Get(), "reopening focuses")
	q.dispose(w1)
	q.dispose(w2)
	q.dispose(w3)
	H.assertNoDebugOutput("succession by Open")
end)

H.section("collapsed = icon: the compositor draws a square at Position; press expands, drag moves; first-letter fallback", function()
	local base = conns()
	local title = q.Source("  debug log")
	local pos = q.Source(UDim2.fromOffset(100, 80))
	local collapsed = q.Source(true)
	local win = Devui.Window({ Title = title, Position = pos, Collapsed = collapsed })
	local frame, grip = deco(win)
	local icon = get(win, "WindowIcon")
	assert(table.find(Compositor.partsOf(win), icon) ~= nil and icon.Parent ~= win, "a decoration part, not in the surface")
	assert(icon.Visible == true and frame.Visible == false and (win :: any).Visible == false and grip.Visible == false,
		"collapsed: only the icon")
	assert(icon.Position == UDim2.fromOffset(100, 80) and icon.Size == UDim2.fromOffset(38, 38), "at Position, 2 x FrameHeight")
	assert(icon.ZIndex == grip.ZIndex, "the grip's rank (above the surface)")
	assert(icon.Text == "D" and lookup(win, "Image") == nil, "the title's first letter (spaces skipped, upper-cased)")
	title:Set("évent")
	assert(icon.Text == "é", "one UTF-8 character; non-ASCII kept as is")

	-- a press (released within the threshold) expands
	H.fire(icon, "InputBegan", mouse(Enum.UserInputType.MouseButton1, 110, 90))
	UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, 113, 92), false)
	UIS.InputEnded:Fire(mouse(Enum.UserInputType.MouseButton1, 113, 92, Enum.UserInputState.End), false)
	assert(collapsed:Get() == false and pos:Get() == UDim2.fromOffset(100, 80), "press: expanded in place")
	assert(icon.Visible == false and frame.Visible == true and (win :: any).Visible == true)
	assert(conns() == base, "tracking closed")

	-- a drag (past 6 px) moves the window by the full delta and does not expand
	collapsed:Set(true)
	H.fire(icon, "InputBegan", mouse(Enum.UserInputType.MouseButton1, 110, 90))
	UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, 114, 90), false)
	assert(pos:Get() == UDim2.fromOffset(100, 80), "under the threshold: not moved yet")
	UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, 140, 110), false)
	assert(pos:Get() == UDim2.fromOffset(130, 100) and icon.Position == UDim2.fromOffset(130, 100), "moved by the delta")
	UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, 111, 90), false) -- back near the press point
	UIS.InputEnded:Fire(mouse(Enum.UserInputType.MouseButton1, 111, 90, Enum.UserInputState.End), false)
	assert(collapsed:Get() == true and pos:Get() == UDim2.fromOffset(101, 80), "a drag is never a press")
	assert(conns() == base)

	-- gamepad / keyboard activation expands; a mouse Activated (the gesture's) does nothing on its own
	H.fire(icon, "Activated", H.input({ UserInputType = Enum.UserInputType.MouseButton1 }), 1)
	assert(collapsed:Get() == true)
	H.fire(icon, "Activated", H.input({ UserInputType = Enum.UserInputType.Gamepad1 }), 1)
	assert(collapsed:Get() == false)
	q.dispose(win)
	assert(H.isDestroyed(icon))
	H.assertNoDebugOutput("icon")
end)

H.section("icon: an Icon image instead of the letter; NoMove keeps it in place; kept on screen; a press on it focuses", function()
	local w1 = Devui.Window({ Title = "img", Icon = "rbxassetid://123", Collapsed = q.Source(true) })
	local icon1 = get(w1, "WindowIcon")
	local image = get(icon1, "Image")
	assert(icon1.Text == "" and image.Image == "rbxassetid://123" and image.Parent == icon1)
	q.dispose(w1)

	local pos = q.Source(UDim2.fromOffset(10, 10))
	local fixedCollapsed = q.Source(true)
	local fixed = Devui.Window({ Title = "f", Position = pos, Collapsed = fixedCollapsed, NoMove = true })
	local icon2 = get(fixed, "WindowIcon")
	H.fire(icon2, "InputBegan", mouse(Enum.UserInputType.MouseButton1, 20, 20))
	UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, 80, 80), false)
	UIS.InputEnded:Fire(mouse(Enum.UserInputType.MouseButton1, 80, 80, Enum.UserInputState.End), false)
	assert(pos:Get() == UDim2.fromOffset(10, 10) and fixedCollapsed:Get() == true, "NoMove: no move, and a wandering release is not a press")
	q.dispose(fixed)

	-- on screen: the icon is the window (19 px of it stays inside on every side)
	local container = Instance.new("Frame")
	H.setAbs(container, 0, 0, 400, 300)
	local p3 = q.Source(UDim2.fromOffset(100, 100))
	local w3 = Devui.Window({ Title = "c", Position = p3, Collapsed = q.Source(true) })
	w3.Parent = container
	local icon3 = get(w3, "WindowIcon")
	H.setAbs(icon3, 100, 100, 38, 38)
	H.fire(icon3, "InputBegan", mouse(Enum.UserInputType.MouseButton1, 0, 0))
	UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, -1000, -1000), false)
	assert(p3:Get() == UDim2.fromOffset(19 - 38, 19 - 38), `icon clamp top-left ({p3:Get()})`)
	UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, 5000, 5000), false)
	assert(p3:Get() == UDim2.fromOffset(400 - 19, 300 - 19), `icon clamp bottom-right ({p3:Get()})`)
	UIS.InputEnded:Fire(mouse(Enum.UserInputType.MouseButton1, 0, 0, Enum.UserInputState.End), false)
	q.dispose(w3)
	q.dispose(container)

	-- a press on a collapsed window's icon raises it (it is a decoration part of its window)
	local manager = Devui.WindowManager.new()
	local a = Devui.Window({ Title = "A", Manager = manager, Collapsed = q.Source(true) })
	local b = Devui.Window({ Title = "B", Manager = manager })
	a.Parent = screen
	b.Parent = screen
	place(b, 0, 0, 300, 200)
	H.setAbs(get(a, "WindowIcon"), 500, 500, 38, 38) -- clear of B
	assert((b :: any).ZIndex > (a :: any).ZIndex)
	press(510, 510)
	assert((a :: any).ZIndex > (b :: any).ZIndex and get(a, "WindowIcon").ZIndex > get(b, "WindowResizeGrip").ZIndex, "the icon raised its window")
	q.dispose(a)
	q.dispose(b)
	H.assertNoDebugOutput("icon 2")
end)
H.done()
