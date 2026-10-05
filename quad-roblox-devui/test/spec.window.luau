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

	-- window chrome = 16 instances (8 GuiObjects + corner/stroke/padding/list helpers); the 2 widgets add 6 more
	assert(H.countDescendants(win) == 22, `unexpected instance count {H.countDescendants(win)}`)

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

H.section("focus on click: z-order, active title colour", function()
	local manager = Devui.WindowManager.new()
	local a = Devui.Window({ Title = "A", Manager = manager })
	local b = Devui.Window({ Title = "B", Manager = manager })
	local za, zb = (a :: any).ZIndex, (b :: any).ZIndex
	assert(zb > za, "later window starts on top")
	local idle = get(a, "TitleBar").BackgroundColor3
	assert(idle == Color3.fromRGB(10, 10, 10))

	H.fire(a, "InputBegan", mouse(Enum.UserInputType.MouseButton1, 5, 5))
	assert((a :: any).ZIndex > (b :: any).ZIndex and manager.Focused:Get() ~= 0)
	assert(get(a, "TitleBar").BackgroundColor3 == Color3.fromRGB(41, 74, 122), "active colour")
	assert(get(b, "TitleBar").BackgroundColor3 == idle)

	-- pressing in the content area also focuses
	H.fire(get(b, "Content"), "InputBegan", mouse(Enum.UserInputType.MouseButton1, 5, 50))
	assert((b :: any).ZIndex > (a :: any).ZIndex)
	assert(get(b, "TitleBar").BackgroundColor3 == Color3.fromRGB(41, 74, 122) and get(a, "TitleBar").BackgroundColor3 == idle)

	-- starting a title drag focuses too
	H.fire(get(a, "TitleBar"), "InputBegan", mouse(Enum.UserInputType.MouseButton1, 5, 5))
	assert((a :: any).ZIndex > (b :: any).ZIndex)
	UIS.InputEnded:Fire(mouse(Enum.UserInputType.MouseButton1, 5, 5, Enum.UserInputState.End), false)
	q.dispose(a)
	q.dispose(b)

	-- a focused window covered by a newly registered one rises on click
	local m2 = Devui.WindowManager.new()
	local wa = Devui.Window({ Title = "A", Manager = m2 })
	H.fire(wa, "InputBegan", mouse(Enum.UserInputType.MouseButton1, 5, 5))
	local wb = Devui.Window({ Title = "B", Manager = m2 })
	assert((wb :: any).ZIndex > (wa :: any).ZIndex, "B registered on top")
	H.fire(wa, "InputBegan", mouse(Enum.UserInputType.MouseButton1, 5, 5))
	assert((wa :: any).ZIndex > (wb :: any).ZIndex, "click on the focused-but-covered A raises it")
	q.dispose(wa)
	q.dispose(wb)
	H.assertNoDebugOutput("focus")
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
	end
	local last = 0
	for i = 1, 2000 do
		last = (i * 7) % 3 + 1
		H.fire(wins[last], "InputBegan", mouse(Enum.UserInputType.MouseButton1, 5, 5))
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


H.done()
