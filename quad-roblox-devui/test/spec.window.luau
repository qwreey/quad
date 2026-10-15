--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Devui = require("../src")
local Style = Devui.Style
local Kids = Devui.Kids

local UIS = H.UserInputService
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
local function get(root: Instance, name: string): any
	local found = H.find(root, name)
	assert(found ~= nil, `missing {name}`)
	return found
end

H.section("mount: structure, bindings, small instance count", function()
	local label = q.Source("Debug")
	local win = Devui.Window({
		Title = label,
		Children = Kids(Devui.Text({ Text = "body" }), Devui.Button({ Text = "ok" })),
	})
	local win2: any = win
	assert(win2.Name == "Window" and win2.Position == UDim2.fromOffset(60, 60) and win2.Size == UDim2.fromOffset(300, 200))
	assert(win2.BackgroundColor3 == Color3.fromRGB(15, 15, 15) and win2.Visible == true and win2.Active == true)
	local title = get(win, "Title")
	assert(title.Text == "Debug")
	label:Set("Renamed")
	assert(title.Text == "Renamed", "title follows a State")
	local bar = get(win, "TitleBar")
	assert(bar.Size == UDim2.new(1, 0, 0, 19), "title bar = frame height")
	local content = get(win, "Content")
	assert(content.ClassName == "ScrollingFrame" and content.Position == UDim2.fromOffset(0, 19))
	assert(content.Size == UDim2.new(1, 0, 1, -19) and content.AutomaticCanvasSize == Enum.AutomaticSize.Y)
	local body = H.findAll(content, function(i: any)
		return i.Name == "Text"
	end)[1] :: any
	assert(body.Text == "body" and body.Parent == content, "children live in the scrolling content")
	assert(get(win, "ResizeGrip").Visible == true)

	-- window chrome = 17 instances (9 GuiObjects incl. the ClickSink + corner/stroke/padding/list helpers); the 2 widgets add 6 more
	assert(H.countDescendants(win) == 23, `unexpected instance count {H.countDescendants(win)}`)

	q.dispose(win)
	H.assertNoDebugOutput("mount")
end)

H.section("title-bar drag writes the Position Source; connections closed after", function()
	local base = conns()
	local pos = q.Source(UDim2.new(0.5, 10, 0, 20))
	local win = Devui.Window({ Title = "w", Position = pos })
	local bar = get(win, "TitleBar")
	H.fire(bar, "InputBegan", mouse(Enum.UserInputType.MouseButton1, 100, 100))
	assert(conns() == base + 3)
	UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, 130, 90), false)
	assert(pos:Get() == UDim2.new(0.5, 40, 0, 10), "scale kept, offsets moved by the delta")
	assert((win :: any).Position == UDim2.new(0.5, 40, 0, 10), "UI follows the Source")
	UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, 70, 160), false)
	assert(pos:Get() == UDim2.new(0.5, -20, 0, 80), "delta is from the press point, not cumulative")
	UIS.InputEnded:Fire(mouse(Enum.UserInputType.MouseButton1, 70, 160, Enum.UserInputState.End), false)
	assert(conns() == base)
	-- external writes move the window too (two-way)
	pos:Set(UDim2.fromOffset(5, 5))
	assert((win :: any).Position == UDim2.fromOffset(5, 5))
	q.dispose(win)
	assert(conns() == base)
	H.assertNoDebugOutput("drag")
end)

H.section("resize grip: grows, respects the minimum, writes the Size Source", function()
	local size = q.Source(Vector2.new(300, 200))
	local win = Devui.Window({ Title = "w", Size = size })
	local grip = get(win, "ResizeGrip")
	H.fire(grip, "InputBegan", mouse(Enum.UserInputType.MouseButton1, 300, 200))
	UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, 340, 260), false)
	assert(size:Get() == Vector2.new(340, 260) and (win :: any).Size == UDim2.fromOffset(340, 260))
	UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, 0, 0), false)
	assert(size:Get() == Vector2.new(38, 38), "min = 2 x frame height (19)")
	UIS.InputEnded:Fire(mouse(Enum.UserInputType.MouseButton1, 0, 0, Enum.UserInputState.End), false)
	q.dispose(win)

	local custom = Devui.Window({ Title = "c", Size = q.Source(Vector2.new(200, 100)), MinSize = Vector2.new(150, 90) })
	local g2 = get(custom, "ResizeGrip")
	H.fire(g2, "InputBegan", mouse(Enum.UserInputType.MouseButton1, 0, 0))
	UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, -500, -500), false)
	assert((custom :: any).Size == UDim2.fromOffset(150, 90))
	UIS.InputEnded:Fire(mouse(Enum.UserInputType.MouseButton1, 0, 0, Enum.UserInputState.End), false)
	q.dispose(custom)
end)

H.section("collapse and close", function()
	local collapsed = q.Source(false)
	local open = q.Source(true)
	local win = Devui.Window({ Title = "w", Collapsed = collapsed, Open = open })
	local arrow = get(win, "CollapseButton")
	local content = get(win, "Content")
	local grip = get(win, "ResizeGrip")
	local icon = get(arrow, "Icon")
	local expandedIcon = icon.Image
	H.fire(arrow, "Activated", H.input({}), 1)
	assert(collapsed:Get() == true)
	assert((win :: any).Size == UDim2.fromOffset(300, 19), "collapsed = title bar only")
	assert(content.Visible == false and grip.Visible == false and (win :: any).BackgroundTransparency == 1)
	assert(icon.Image ~= expandedIcon, "arrow flips")
	assert(get(win, "TitleBar").BackgroundColor3 == Color3.new(0, 0, 0), "collapsed title colour")
	collapsed:Set(false) -- external control
	assert((win :: any).Size == UDim2.fromOffset(300, 200) and content.Visible == true and grip.Visible == true)

	H.fire(get(win, "CloseButton"), "Activated", H.input({}), 1)
	assert(open:Get() == false and (win :: any).Visible == false)
	open:Set(true)
	assert((win :: any).Visible == true, "re-open brings it back")

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

H.section("focus on press: z-order, active title colour", function()
	local manager = Devui.WindowManager.new()
	local a = Devui.Window({ Title = "A", Manager = manager })
	local b = Devui.Window({ Title = "B", Manager = manager })
	-- the mock has no layout: A at (0,0) 300x200, B overlapping it at (100,100) 300x200
	H.setAbs(a, 0, 0, 300, 200)
	H.setAbs(b, 100, 100, 300, 200)
	local za, zb = (a :: any).ZIndex, (b :: any).ZIndex
	assert(zb > za, "later window starts on top")
	local idle = get(a, "TitleBar").BackgroundColor3
	assert(idle == Color3.fromRGB(10, 10, 10))

	press(5, 5)
	assert((a :: any).ZIndex > (b :: any).ZIndex and manager.Focused:Get() ~= 0)
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
	H.setAbs(wa, 0, 0, 100, 100)
	press(5, 5)
	local wb = Devui.Window({ Title = "B", Manager = m2 })
	H.setAbs(wb, 500, 500, 100, 100)
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
	assert(#(UIS.InputBegan :: any).connections == began0 + 1, "one global press listener")
	local openB = q.Source(true)
	local b2 = Devui.Window({ Title = "B", Open = openB, Manager = manager })
	assert(#(UIS.InputBegan :: any).connections == began0 + 1, "still one for two windows")
	H.setAbs(a, 0, 0, 300, 200)
	H.setAbs(b2, 0, 0, 300, 200)
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
	H.setAbs(container, 0, 0, 1000, 1000)
	a.Parent = container
	b2.Parent = container
	press(5, 5)
	local top = if (a :: any).ZIndex > (b2 :: any).ZIndex then a else b2
	local other = if top == a then b2 else a
	H.setAbs(other, 600, 600, 300, 200) -- only `other` under (650, 650)
	container.Visible = false
	local before = manager.Focused:Get()
	press(650, 650)
	assert(manager.Focused:Get() == before and (top :: any).ZIndex > (other :: any).ZIndex, "hidden container: no hit")
	container.Visible = true
	press(650, 650)
	assert((other :: any).ZIndex > (top :: any).ZIndex, "shown again: hit")

	-- a press on an open popup (or its click-outside catcher) does not change focus
	local OverlayModule = require("../src/Overlay")
	OverlayModule.warnUnmounted = false
	local overlay = OverlayModule.new()
	H.setAbs(overlay.Layer, 0, 0, 1000, 1000)
	local tip = overlay:Open({ Content = q.Declaration.Frame({}), Position = Vector2.new(400, 400), CloseOnClickOutside = false })
	H.setAbs(tip.Holder, 400, 400, 50, 20)
	press(5, 5) -- not on the tooltip: focus moves as usual
	local focusedNow = manager.Focused:Get()
	local under = if (a :: any).ZIndex > (b2 :: any).ZIndex then b2 else a
	H.setAbs(under, 380, 380, 100, 100)
	press(410, 405) -- on the tooltip holder, which lies over `under`
	assert(manager.Focused:Get() == focusedNow, "press on a popup: no focus change")
	press(470, 470) -- `under` outside the tooltip: focused
	assert(manager.Focused:Get() ~= focusedNow, "outside the popup: focus moves")
	tip:Close()
	local modal = overlay:Open({ Content = q.Declaration.Frame({}), Position = Vector2.new(0, 0) })
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
		H.setAbs(w[i], i * 400, 0, 300, 200)
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
	H.setAbs(win, 100, 100, 300, 200)
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
	assert(H.find(fixed, "ResizeGrip") == nil and H.find(fixed, "CloseButton") == nil and H.find(fixed, "CollapseButton") == nil)
	H.fire(get(fixed, "TitleBar"), "InputBegan", mouse(Enum.UserInputType.MouseButton1, 0, 0))
	assert(conns() == base and pos:Get() == UDim2.fromOffset(0, 0), "NoMove: no drag starts")
	q.dispose(fixed)

	local bare = Devui.Window({ Title = "b", NoTitleBar = true })
	assert(H.find(bare, "TitleBar") == nil)
	assert(get(bare, "Content").Position == UDim2.fromOffset(0, 0) and get(bare, "Content").Size == UDim2.new(1, 0, 1, 0))
	q.dispose(bare)
	H.assertNoDebugOutput("flags")
end)

H.section("theme and density follow live; dispose destroys everything", function()
	local s = Style.new()
	local win = Devui.Window({ Title = "t", Style = s, Children = Kids(Devui.Text({ Text = "x", Style = s })) })
	local n = H.countDescendants(win)
	s:SetScheme("Light")
	assert((win :: any).BackgroundColor3 == Color3.fromRGB(240, 240, 240))
	assert(get(win, "Title").TextColor3 == Color3.fromRGB(0, 0, 0))
	s:SetDensity("Clear")
	assert(get(win, "TitleBar").Size == UDim2.new(1, 0, 0, 23))
	assert(H.countDescendants(win) == n, "switching never adds or removes instances")
	local kids = H.findAll(win, function()
		return true
	end)
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
		H.setAbs(wins[i], i * 400, 0, 300, 200)
	end
	local last = 0
	for i = 1, 2000 do
		last = (i * 7) % 3 + 1
		press(last * 400 + 5, 5)
	end
	local seen: { [number]: boolean } = {}
	for _, w in wins do
		local z = (w :: any).ZIndex
		assert(z >= 1 and z <= 3 and z < layerZ and not seen[z], `rank {z}`)
		seen[z] = true
	end
	assert(wins[last].ZIndex == 3, "the last focused window is on top")
	-- destroying the middle one closes ranks; a new window starts on top again
	local mid = 1
	for i, w in wins do
		if (w :: any).ZIndex == 2 then
			mid = i
		end
	end
	q.dispose(wins[mid])
	for i, w in wins do
		if i ~= mid then
			assert((w :: any).ZIndex <= 2, "ranks closed up")
		end
	end
	local fresh = Devui.Window({ Title = "fresh", Manager = manager })
	assert((fresh :: any).ZIndex == 3)
	for i, w in wins do
		if i ~= mid then
			q.dispose(w)
		end
	end
	q.dispose(fresh)
	assert(manager.Focused:Get() == 0 or manager.Focused:Get() > 0)
	H.assertNoDebugOutput("z rank")
end)


H.section("click sink: the window's empty area is covered by one invisible GuiButton under every other child", function()
	local win = Devui.Window({ Title = "sink" })
	local sink: any = win:FindFirstChild("ClickSink")
	assert(sink ~= nil and sink.ClassName == "TextButton", "a TextButton ClickSink is a direct child of the root")
	assert(sink.ZIndex == 0 and sink.Size == UDim2.fromScale(1, 1), "full cover at ZIndex 0")
	assert(sink.BackgroundTransparency == 1 and sink.Text == "" and sink.AutoButtonColor == false and sink.Selectable == false,
		"invisible, no hover tint, off the gamepad path")
	for _, child: any in win:GetChildren() do
		if child ~= sink and child.ZIndex ~= nil then
			assert(child.ZIndex >= 1, `{child.Name} draws above the sink`)
		end
	end
	q.dispose(win)
end)

H.done()
