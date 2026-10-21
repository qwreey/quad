--!strict
-- Window edge docking (docking stage 2): drag to an edge with a preview, the strip and its press rule, the strip as a
-- wall for floating windows, the width handle, undocking, the flags, close / reopen, the top bar inset.
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Devui = require("../src")
local Compositor = require("../src/Window/Compositor")

type WindowLayout = Devui.WindowLayout
type WindowState = Devui.WindowState

local UIS = H.UserInputService
local M1 = Enum.UserInputType.MouseButton1

local function mouse(t: Enum.UserInputType, x: number, y: number, state: Enum.UserInputState?): any
	return H.input({ UserInputType = t, Position = Vector3.new(x, y, 0), UserInputState = state })
end
-- a global press (UserInputService.InputBegan) at x, y, as the engine sends it
local function press(x: number, y: number)
	UIS.InputBegan:Fire(mouse(M1, x, y), true)
end
local function part(win: Instance, name: string): any
	for _, p: any in Compositor.partsOf(win) do
		if p.Name == name then
			return p
		end
	end
	return nil
end
local function get(win: Instance, name: string): any
	local found = H.find(win, name)
	if found ~= nil then
		return found
	end
	for _, p: any in Compositor.partsOf(win) do
		if p.Name == name then
			return p
		end
		local hit = H.find(p, name)
		if hit ~= nil then
			return hit
		end
	end
	error(`missing {name}`)
end
-- drag the title bar: press at (x0, y0), move through `path`, release at the last point
local function dragTitle(win: Instance, x0: number, y0: number, path: { { number } }, keepDown: boolean?)
	H.fire(get(win, "TitleBar"), "InputBegan", mouse(M1, x0, y0))
	local last = { x0, y0 }
	for _, p in path do
		UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, p[1], p[2]), false)
		last = p
	end
	if not keepDown then
		UIS.InputEnded:Fire(mouse(M1, last[1], last[2], Enum.UserInputState.End), false)
	end
end

-- the window's edge-dock preview while it shows (a decoration part in the container — no Overlay layer is mounted
-- in this spec), else nil
local function previewOf(win: Instance): any
	local p = part(win, "WindowDockPreview")
	return if p ~= nil and p.Visible then p else nil
end

-- a placed container (a LayerCollector holds it: press-to-front needs windows on screen)
local function newContainer(w: number, h: number): any
	local screen = Instance.new("ScreenGui")
	screen.Parent = Instance.new("Folder")
	local container = Instance.new("Frame")
	container.Parent = screen
	H.setAbs(container, 0, 0, w, h)
	return container
end

H.section("drag the title bar to the left edge: a preview of strip + panel, release docks; Position keeps the floating rectangle", function()
	local container = newContainer(800, 600)
	local m = Devui.WindowManager.new()
	local pos, size = q.Source(UDim2.fromOffset(200, 100)), q.Source(Vector2.new(300, 200))
	local win = Devui.Window({ Title = "Explorer", Key = "explorer", Manager = m, Position = pos, Size = size })
	win.Parent = container
	local frame = part(win, "WindowDecoration")
	local strip = part(win, "WindowDockStrip")
	assert(strip ~= nil and strip.Visible == false and part(win, "WindowDockResize").Visible == false, "floating: no strip, no dock handle")

	dragTitle(win, 250, 110, { { 10, 110 } }, true)
	assert(pos:Get() == UDim2.fromOffset(-40, 100), `still a plain move while dragging ({pos:Get()})`)
	local preview = previewOf(win)
	assert(preview ~= nil and preview.Size == UDim2.new(0, 19 + 300, 1, 0), "preview = strip (19) + panel (Size.X) over the full height")
	assert(preview.Parent == container and preview.AnchorPoint == Vector2.zero and preview.Position == UDim2.fromScale(0, 0), "in the container, at its left edge")
	assert(preview.ZIndex == frame.ZIndex + 3, "above the dragged window's chunk (frame, surface, grip)")
	UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, 300, 110), false)
	assert(previewOf(win) == nil, "off the edge: no preview")
	UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, 5, 110), false)
	assert(previewOf(win) ~= nil, "back at the edge")
	UIS.InputEnded:Fire(mouse(M1, 5, 110, Enum.UserInputState.End), false)
	assert(previewOf(win) == nil, "released: the preview closes")

	assert(pos:Get() == UDim2.fromOffset(200, 100), "Position goes back to where the drag began (the floating rectangle)")
	assert(frame.Position == UDim2.fromOffset(19, 0) and frame.Size == UDim2.new(0, 300, 1, 0), "the panel right inside the strip, full height")
	local root: any = win
	assert(root.Position == UDim2.fromOffset(19, 19) and root.Size == UDim2.new(0, 300, 1, -19), "the surface under the title bar")
	assert(strip.Visible == true and strip.Position == UDim2.fromScale(0, 0) and strip.Size == UDim2.new(0, 19, 1, 0), "the strip at the edge")
	assert(part(win, "WindowResizeGrip").Visible == false and part(win, "WindowDockResize").Visible == true, "the dock handle replaces the grip")
	assert(get(win, "Arrow").Rotation == 180, "expanded left dock: `<`")

	-- the layout and the window state
	local layout = m:ExportLayout()
	local left = layout.Left :: any
	assert(#layout.Floating == 0 and left ~= nil and layout.Right == nil, "on the Left edge, not floating")
	assert(left.Width == 300 and left.Collapsed == false and left.Node.Tabs[1] == "explorer" and left.Node.Selected == "explorer")
	assert(left.Position[2] == 200 and left.Position[4] == 100 and left.Size[1] == 300 and left.Size[2] == 200, "the floating rectangle")
	local st = m:ExportWindow("explorer") :: WindowState
	assert(st.Dock == "Left" and st.DockWidth == 300 and (st.Position :: { number })[2] == 200)

	-- the app writing Position / Size while docked moves nothing
	pos:Set(UDim2.fromOffset(5, 5))
	size:Set(Vector2.new(100, 100))
	assert(frame.Position == UDim2.fromOffset(19, 0) and frame.Size == UDim2.new(0, 300, 1, 0), "docked: the Sources are only kept")
	q.dispose(win)
	q.dispose(container)
	H.assertNoDebugOutput("dock left")
end)

H.section("strip press: collapsed -> expand + focus, expanded without focus -> focus, focused -> collapse; gamepad uses the current focus", function()
	local container = newContainer(800, 600)
	local m = Devui.WindowManager.new()
	local collapsed = q.Source(false)
	local a = Devui.Window({ Title = "A", Manager = m, Collapsed = collapsed })
	local b = Devui.Window({ Title = "B", Manager = m, Position = q.Source(UDim2.fromOffset(300, 100)) })
	a.Parent = container
	b.Parent = container
	dragTitle(a, 100, 70, { { 3, 70 } })
	local strip = part(a, "WindowDockStrip")
	local arrow = get(a, "Arrow")
	assert(strip.Visible == true, "A docked")
	H.setAbs(strip, 0, 0, 19, 600)
	H.setAbs(part(a, "WindowDecoration"), 19, 0, 300, 600)
	H.setAbs(part(b, "WindowDecoration"), 300, 100, 300, 200)
	H.setAbs(b, 300, 119, 300, 181)

	press(400, 150) -- B takes the focus
	assert(m.Focused:Get() ~= 0 and (b :: any).ZIndex > (a :: any).ZIndex, "B on top, focused")
	local function pressStrip()
		press(5, 300)
		H.fire(strip, "Activated", mouse(M1, 5, 300), 1)
	end
	pressStrip() -- expanded, not focused: raise + focus
	assert(collapsed:Get() == false and (a :: any).ZIndex > (b :: any).ZIndex, "A raised")
	local aId = m.Focused:Get()
	pressStrip() -- expanded and focused (before the press): collapse
	assert(collapsed:Get() == true and m.Focused:Get() == aId, "collapsed, the focus kept (collapsing is not closing)")
	assert(part(a, "WindowDecoration").Visible == false and (a :: any).Visible == false and strip.Visible == true, "only the strip")
	assert(get(a, "WindowIcon").Visible == false, "a docked window has no icon")
	assert(arrow.Rotation == 0, "collapsed left dock: `>`")
	press(400, 150) -- B again
	pressStrip() -- collapsed: expand + raise + focus
	assert(collapsed:Get() == false and m.Focused:Get() == aId and (a :: any).ZIndex > (b :: any).ZIndex, "expanded, raised, focused")
	assert(arrow.Rotation == 180)

	-- gamepad / keyboard: no global press, the current focus decides
	H.fire(strip, "Activated", H.input({ UserInputType = Enum.UserInputType.Gamepad1 }), 1)
	assert(collapsed:Get() == true, "focused: collapse")
	H.fire(strip, "Activated", H.input({ UserInputType = Enum.UserInputType.Gamepad1 }), 1)
	assert(collapsed:Get() == false, "collapsed: expand")
	-- the title bar's collapse button is the same Collapsed
	H.fire(get(a, "CollapseButton"), "Activated", H.input({}), 1)
	assert(collapsed:Get() == true and strip.Visible == true)
	q.dispose(a)
	q.dispose(b)
	q.dispose(container)
	H.assertNoDebugOutput("strip press")
end)

H.section("the strip is a wall: floating windows of the container stop at it; a strip that appears pushes them out", function()
	local container = newContainer(800, 600)
	local other = newContainer(800, 600)
	local m = Devui.WindowManager.new()
	local pb = q.Source(UDim2.fromOffset(5, 50))
	local pc = q.Source(UDim2.fromOffset(700, 50))
	local pd = q.Source(UDim2.fromOffset(2, 50))
	local a = Devui.Window({ Title = "A", Key = "a", Manager = m })
	local b = Devui.Window({ Title = "B", Manager = m, Position = pb, Size = q.Source(Vector2.new(200, 100)) })
	local c = Devui.Window({ Title = "C", Manager = m, Position = pc, Size = q.Source(Vector2.new(200, 100)) })
	local d = Devui.Window({ Title = "D", Manager = m, Position = pd }) -- another container: not walled
	a.Parent = container
	b.Parent = container
	c.Parent = container
	d.Parent = other
	m:ImportWindow("a", { Kind = "a", Open = true, Collapsed = false, Dock = "Left", DockWidth = 250 })
	assert(part(a, "WindowDockStrip").Visible == true, "docked by import")
	assert(pb:Get() == UDim2.fromOffset(19, 50), `B pushed out of the strip ({pb:Get()})`)
	assert(pc:Get() == UDim2.fromOffset(700, 50), "the panel itself is no wall (C is over the free right side)")
	assert(pd:Get() == UDim2.fromOffset(2, 50), "a window of another container is not walled")
	-- dragging B left stops at the strip (its whole edge, not only the title-bar padding)
	dragTitle(b, 100, 60, { { -1000, 60 } })
	assert(pb:Get() == UDim2.fromOffset(19, 50), `dragged: stops at the strip ({pb:Get()})`)
	-- a right dock walls the right side the same way
	local e = Devui.Window({ Title = "E", Manager = m })
	e.Parent = container
	m:ImportWindow("a", { Kind = "a", Open = true, Collapsed = true, Dock = "Left", DockWidth = 250 }) -- collapsed: still a wall
	dragTitle(c, 750, 60, { { 400, 60 } })
	assert(pc:Get() == UDim2.fromOffset(350, 50))
	dragTitle(e, 100, 70, { { 795, 70 } }) -- E docks right
	assert(part(e, "WindowDockStrip").Visible == true)
	dragTitle(c, 400, 60, { { 5000, 60 } })
	assert(pc:Get() == UDim2.fromOffset(800 - 19 - 200, 50), `stops at the right strip ({pc:Get()})`)
	-- placed by an import, or moved into the container: brought out of the strip as well
	local pf = q.Source(UDim2.fromOffset(300, 50))
	local f = Devui.Window({ Title = "F", Key = "f", Manager = m, Position = pf, Size = q.Source(Vector2.new(200, 100)) })
	f.Parent = container
	m:ImportWindow("f", { Kind = "f", Open = true, Collapsed = false, Position = { 0, 2, 0, 50 }, Size = { 200, 100 } })
	assert(pf:Get() == UDim2.fromOffset(19, 50), `imported into the strip: brought out ({pf:Get()})`)
	d.Parent = container
	assert(pd:Get() == UDim2.fromOffset(19, 50), `moved into the container: brought out ({pd:Get()})`)
	-- a closed docked window is no wall
	m:ImportWindow("a", { Kind = "a", Open = false, Collapsed = false, Dock = "Left", DockWidth = 250 })
	dragTitle(b, 100, 60, { { -1000, 60 } })
	assert(pb:Get() == UDim2.fromOffset(19 - 200, 50), `the old title-bar rule again ({pb:Get()})`)
	for _, w in { a, b, c, d, e, f } do
		q.dispose(w)
	end
	q.dispose(container)
	q.dispose(other)
	H.resetOutput() -- (the key-less notice: the import used the layout API)
end)

H.section("the dock width handle: [MinSize.X or 2 x FrameHeight, half the container]; NoResize has none; a shrinking container clamps", function()
	local container = newContainer(800, 600)
	local m = Devui.WindowManager.new()
	local a = Devui.Window({ Title = "A", Manager = m })
	a.Parent = container
	dragTitle(a, 100, 70, { { 3, 70 } })
	local frame = part(a, "WindowDecoration")
	local handle = part(a, "WindowDockResize")
	assert(handle.Position == UDim2.fromOffset(19 + 300, 0) and handle.Size == UDim2.new(0, 6, 1, 0), "just outside the panel's inner edge")
	H.fire(handle, "InputBegan", mouse(M1, 320, 300))
	UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, 370, 300), false)
	assert(frame.Size == UDim2.new(0, 350, 1, 0) and handle.Position == UDim2.fromOffset(19 + 350, 0), "wider")
	UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, 2000, 300), false)
	assert(frame.Size == UDim2.new(0, 400, 1, 0), "at most half the container")
	UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, -2000, 300), false)
	assert(frame.Size == UDim2.new(0, 38, 1, 0), "at least 2 x FrameHeight")
	UIS.InputEnded:Fire(mouse(M1, 0, 300, Enum.UserInputState.End), false)
	-- the container shrinks below twice the width: clamped to half
	H.fire(handle, "InputBegan", mouse(M1, 0, 0))
	UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, 300, 0), false)
	UIS.InputEnded:Fire(mouse(M1, 300, 0, Enum.UserInputState.End), false)
	assert(frame.Size == UDim2.new(0, 338, 1, 0))
	H.setAbs(container, 0, 0, 500, 600)
	assert(frame.Size == UDim2.new(0, 250, 1, 0), "half of the narrower container")
	q.dispose(a)

	-- right dock: dragging left widens; MinSize.X is the floor
	local b = Devui.Window({ Title = "B", Manager = m, MinSize = Vector2.new(120, 50), Size = q.Source(Vector2.new(200, 150)) })
	b.Parent = container
	dragTitle(b, 100, 70, { { 495, 70 } })
	local bFrame = part(b, "WindowDecoration")
	local bHandle = part(b, "WindowDockResize")
	assert(bFrame.Position == UDim2.new(1, -(19 + 200), 0, 0) and bHandle.AnchorPoint == Vector2.new(1, 0))
	H.fire(bHandle, "InputBegan", mouse(M1, 280, 0))
	UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, 250, 0), false)
	assert(bFrame.Size == UDim2.new(0, 230, 1, 0), "dragging toward the middle widens a right dock")
	UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, 1000, 0), false)
	assert(bFrame.Size == UDim2.new(0, 120, 1, 0), "MinSize.X")
	UIS.InputEnded:Fire(mouse(M1, 1000, 0, Enum.UserInputState.End), false)
	q.dispose(b)

	local fixed = Devui.Window({ Title = "F", Manager = m, NoResize = true })
	fixed.Parent = container
	dragTitle(fixed, 100, 70, { { 3, 70 } })
	assert(part(fixed, "WindowDockStrip").Visible == true and part(fixed, "WindowDockResize") == nil, "NoResize: docks, no width handle")
	q.dispose(fixed)
	q.dispose(container)
	H.assertNoDebugOutput("dock width")
end)

H.section("undock: dragging a docked title bar past 6 px floats it at its kept Size under the pointer, and the drag goes on", function()
	local container = newContainer(800, 600)
	local m = Devui.WindowManager.new()
	local pos = q.Source(UDim2.fromOffset(200, 100))
	local a = Devui.Window({ Title = "A", Key = "a", Manager = m, Position = pos })
	a.Parent = container
	dragTitle(a, 250, 110, { { 3, 110 } })
	local frame = part(a, "WindowDecoration")
	H.setAbs(frame, 19, 0, 300, 600) -- the panel on screen
	dragTitle(a, 169, 10, { { 172, 12 } }, true)
	assert(part(a, "WindowDockStrip").Visible == true and pos:Get() == UDim2.fromOffset(200, 100), "within the threshold: still docked")
	UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, 269, 60), false)
	-- grabbed at half the panel's width, 10 px down: the floating window (300 wide) puts that spot under the pointer
	assert(part(a, "WindowDockStrip").Visible == false, "floating")
	assert(pos:Get() == UDim2.fromOffset(119, 50), `under the pointer ({pos:Get()})`)
	assert(frame.Position == UDim2.fromOffset(119, 50) and frame.Size == UDim2.fromOffset(300, 200), "the kept Size")
	UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, 369, 160), false)
	assert(pos:Get() == UDim2.fromOffset(219, 150), "the drag goes on")
	UIS.InputEnded:Fire(mouse(M1, 369, 160, Enum.UserInputState.End), false)
	assert(m:ExportLayout().Left == nil and #m:ExportLayout().Floating == 1)
	-- docking again uses the dock width it keeps (300), not its floating width now
	m:ImportWindow("a", { Kind = "a", Open = true, Collapsed = false, Size = { 350, 200 } })
	dragTitle(a, 300, 160, { { 3, 160 } })
	local again = m:ExportLayout().Left
	assert(again ~= nil and again.Width == 300, `the kept dock width ({again and again.Width})`)
	q.dispose(a)

	-- NoMove: no undock (and no dock) by drag; a layout docks it
	local fixed = Devui.Window({ Title = "F", Key = "f", Manager = m, NoMove = true })
	fixed.Parent = container
	m:ImportWindow("f", { Kind = "f", Open = true, Collapsed = false, Dock = "Right", DockWidth = 200 })
	dragTitle(fixed, 700, 10, { { 300, 300 } })
	assert(part(fixed, "WindowDockStrip").Visible == true, "NoMove: stays docked")
	q.dispose(fixed)
	q.dispose(container)
	H.assertNoDebugOutput("undock")
end)

H.section("not offered: NoDock (a layout still docks it), an edge held by an open window, the icon, outside the container", function()
	local container = newContainer(800, 600)
	local m = Devui.WindowManager.new()
	local nd = Devui.Window({ Title = "N", Key = "n", Manager = m, NoDock = true })
	nd.Parent = container
	dragTitle(nd, 100, 70, { { 3, 70 } }, true)
	assert(part(nd, "WindowDockPreview") == nil, "NoDock: no preview part")
	UIS.InputEnded:Fire(mouse(M1, 3, 70, Enum.UserInputState.End), false)
	assert(part(nd, "WindowDockStrip").Visible == false, "NoDock: not docked")
	m:ImportWindow("n", { Kind = "n", Open = true, Collapsed = false, Dock = "Left", DockWidth = 200 })
	assert(part(nd, "WindowDockStrip").Visible == true, "a layout docks a NoDock window")
	local other = Devui.Window({ Title = "O", Manager = m })
	other.Parent = container
	dragTitle(other, 300, 70, { { 3, 70 } }, true)
	assert(previewOf(other) == nil, "the edge is held: no preview")
	UIS.InputEnded:Fire(mouse(M1, 3, 70, Enum.UserInputState.End), false)
	assert(part(other, "WindowDockStrip").Visible == false, "and no dock")
	-- the collapsed icon never docks
	local iconWin = Devui.Window({ Title = "I", Manager = m, Collapsed = q.Source(true) })
	iconWin.Parent = container
	local icon = get(iconWin, "WindowIcon")
	H.fire(icon, "InputBegan", mouse(M1, 300, 300))
	UIS.InputChanged:Fire(mouse(Enum.UserInputType.MouseMovement, 795, 300), false)
	assert(previewOf(iconWin) == nil)
	UIS.InputEnded:Fire(mouse(M1, 795, 300, Enum.UserInputState.End), false)
	assert(part(iconWin, "WindowDockStrip").Visible == false, "the icon only moves")
	-- the pointer outside the container (a Frame smaller than the screen) docks nothing
	dragTitle(other, 300, 70, { { 900, 70 } })
	assert(part(other, "WindowDockStrip").Visible == false)
	for _, w in { nd, other, iconWin } do
		q.dispose(w)
	end
	q.dispose(container)
	assert(#H.output() == 1, "only the key-less notice")
	H.resetOutput()
end)

H.section("close and reopen: the edge is kept; taken meanwhile -> opens floating; the saved layout holds one window per edge", function()
	local container = newContainer(800, 600)
	local m = Devui.WindowManager.new()
	local oa = q.Source(true)
	local pa = q.Source(UDim2.fromOffset(200, 100))
	local a = Devui.Window({ Title = "A", Key = "a", Manager = m, Open = oa, Position = pa })
	local b = Devui.Window({ Title = "B", Key = "b", Manager = m, Position = q.Source(UDim2.fromOffset(400, 100)) })
	a.Parent = container
	b.Parent = container
	dragTitle(a, 250, 110, { { 3, 110 } })
	local strip = part(a, "WindowDockStrip")
	oa:Set(false)
	assert(strip.Visible == false and part(a, "WindowDecoration").Visible == false, "closed: panel and strip hidden")
	assert((m:ExportWindow("a") :: WindowState).Dock == "Left", "the edge is remembered")
	assert(m:ExportLayout().Left ~= nil, "a closed docked window keeps its edge in the layout")
	oa:Set(true)
	assert(strip.Visible == true and m.Focused:Get() ~= 0, "reopened docked, with the focus")

	oa:Set(false)
	dragTitle(b, 450, 110, { { 3, 110 } }, true)
	assert(previewOf(b) ~= nil, "the closed window freed the edge")
	UIS.InputEnded:Fire(mouse(M1, 3, 110, Enum.UserInputState.End), false)
	assert(part(b, "WindowDockStrip").Visible == true, "B docked left")
	-- saved: B holds the edge, closed A is saved floating
	local layout = m:ExportLayout()
	assert((layout.Left :: any).Node.Tabs[1] == "b" and #layout.Floating == 1 and layout.Floating[1].Node.Tabs[1] == "a", "one window per edge")
	assert(layout.Floating[1].Position[2] == 200, "A's floating rectangle")
	local ok = pcall(function()
		m:ImportLayout(layout)
	end)
	assert(ok, "the saved layout reads back")
	-- A opened again: its edge is taken, it floats at its kept Position
	oa:Set(true)
	assert(strip.Visible == false and part(a, "WindowDecoration").Position == UDim2.fromOffset(200, 100), "opens floating")
	assert((m:ExportWindow("a") :: WindowState).Dock == nil)
	q.dispose(a)
	q.dispose(b)
	q.dispose(container)
	H.assertNoDebugOutput("close reopen")
end)

H.section("a window without a Key docks the same and is left out of the layout; the right edge mirrors the left", function()
	local container = newContainer(800, 600)
	local m = Devui.WindowManager.new()
	local loose = Devui.Window({ Title = "loose", Manager = m })
	loose.Parent = container
	dragTitle(loose, 100, 70, { { 795, 70 } }, true)
	local preview = previewOf(loose)
	assert(preview ~= nil and preview.AnchorPoint == Vector2.new(1, 0) and preview.Position == UDim2.fromScale(1, 0), "the preview at the right edge")
	UIS.InputEnded:Fire(mouse(M1, 795, 70, Enum.UserInputState.End), false)
	local frame = part(loose, "WindowDecoration")
	local strip = part(loose, "WindowDockStrip")
	assert(frame.Position == UDim2.new(1, -(19 + 300), 0, 0) and frame.Size == UDim2.new(0, 300, 1, 0))
	assert(strip.Visible == true and strip.AnchorPoint == Vector2.new(1, 0) and strip.Position == UDim2.fromScale(1, 0))
	assert(get(loose, "Arrow").Rotation == 0, "expanded right dock: `>`")
	assert((loose :: any).Size == UDim2.new(0, 300, 1, -19), "the surface")
	local layout = m:ExportLayout()
	assert(layout.Right == nil and layout.Left == nil and #layout.Floating == 0, "not in the layout")
	H.resetOutput() -- (the key-less notice)
	-- AvailableSize follows the docked surface's content area (the engine sizes it)
	local avail = q.Source(Vector2.zero)
	local w2 = Devui.Window({ Title = "w2", Manager = m, AvailableSize = avail })
	w2.Parent = container
	dragTitle(w2, 100, 70, { { 3, 70 } })
	get(w2, "Content").AbsoluteWindowSize = Vector2.new(300, 581)
	assert(avail:Get() == Vector2.new(284, 565), `AvailableSize ({avail:Get()})`)
	q.dispose(loose)
	q.dispose(w2)
	q.dispose(container)
	H.resetOutput()
end)

H.section("the Roblox top bar: a docked panel starts below it when its container reaches under it; the strip keeps the full height", function()
	local G = H.GuiService :: any
	local changed = H.mock.newSignal()
	G.TopbarInset = Rect.new(0, 0, 800, 58)
	G.GetPropertyChangedSignal = function(_self: any, name: string): any
		assert(name == "TopbarInset")
		return changed
	end
	local container = newContainer(800, 600) -- at y 0 (and GetGuiInset 0 in the mock): under the bar, like IgnoreGuiInset
	local m = Devui.WindowManager.new()
	local a = Devui.Window({ Title = "A", Manager = m })
	a.Parent = container
	dragTitle(a, 100, 70, { { 3, 70 } })
	local frame = part(a, "WindowDecoration")
	local handle = part(a, "WindowDockResize")
	assert(frame.Position == UDim2.fromOffset(19, 58) and frame.Size == UDim2.new(0, 300, 1, -58), `below the bar ({frame.Position})`)
	assert((a :: any).Position == UDim2.fromOffset(19, 58 + 19) and (a :: any).Size == UDim2.new(0, 300, 1, -58 - 19), "the surface")
	assert(handle.Position == UDim2.fromOffset(319, 58) and handle.Size == UDim2.new(0, 6, 1, -58), "the width handle too")
	assert(part(a, "WindowDockStrip").Size == UDim2.new(0, 19, 1, 0), "the strip: full height")
	G.TopbarInset = Rect.new(0, 0, 800, 36)
	changed:Fire()
	assert(frame.Position == UDim2.fromOffset(19, 36), "follows TopbarInset")
	H.setAbs(container, 0, 40, 800, 560) -- the container moved below the bar
	assert(frame.Position == UDim2.fromOffset(19, 0) and frame.Size == UDim2.new(0, 300, 1, 0), "already under the bar: 0")
	q.dispose(a)
	q.dispose(container)
	G.TopbarInset = nil
	G.GetPropertyChangedSignal = nil
	assert(#(changed :: any).connections == 0, "the TopbarInset connection goes with the window")
	H.assertNoDebugOutput("top bar")
end)

H.done()
