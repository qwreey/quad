--!strict
-- Window tab groups (docking stage 3): joining by the title row / the centre (bands reserved), the drop preview, tab
-- select / reorder / tear-off, the strip only with two open windows, close-hide-reopen, a group of one, group-level
-- collapse, one z lump, joining a held edge, a docked group dragged off, eligibility, the layout of tab groups.
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Devui = require("../src")
local Compositor = require("../src/Window/Compositor")

local lune = require :: any
local serde = lune("@lune/serde")

type WindowLayout = Devui.WindowLayout
type WindowState = Devui.WindowState

local UIS = H.UserInputService
local M1 = Enum.UserInputType.MouseButton1
local MOVE = Enum.UserInputType.MouseMovement

local function mouse(t: Enum.UserInputType, x: number, y: number, state: Enum.UserInputState?): any
	return H.input({ UserInputType = t, Position = Vector3.new(x, y, 0), UserInputState = state })
end
local relay: () -> ()
local function press(x: number, y: number)
	relay()
	UIS.InputBegan:Fire(mouse(M1, x, y), true)
end
local function moveTo(x: number, y: number)
	UIS.InputChanged:Fire(mouse(MOVE, x, y), false)
end
local function release(x: number, y: number)
	UIS.InputEnded:Fire(mouse(M1, x, y, Enum.UserInputState.End), false)
end
local function json(v: any): any
	return serde.decode("json", serde.encode("json", v))
end
local function err(fn: () -> ()): string
	local ok, e = pcall(fn)
	assert(not ok, "expected an error")
	return tostring(e)
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
local function frameOf(win: Instance): any
	return part(win, "WindowDecoration")
end
local function tabOf(win: Instance): any
	return part(win, "WindowTab")
end
local function previewOf(win: Instance): any
	local p = part(win, "WindowDockPreview")
	return if p ~= nil and p.Visible then p else nil
end

local function newContainer(w: number, h: number): any
	local screen = Instance.new("ScreenGui")
	screen.Parent = Instance.new("Folder")
	local container = Instance.new("Frame")
	container.Parent = screen
	H.setAbs(container, 0, 0, w, h)
	return container
end

-- a layout-engine stand-in: every window's frame / tab / icon and surface get the on-screen rectangle their UDim2s
-- say in the container (remembered: `relay` lays every window laid so far again, before each gesture)
local laid: { [any]: { Instance } } = {}
local function lay(container: any, wins: { Instance })
	local list = laid[container] or {}
	laid[container] = list
	for _, w in wins do
		if table.find(list, w) == nil then
			table.insert(list, w)
		end
	end
	local cp, cs = container.AbsolutePosition, container.AbsoluteSize
	local function place(p: any)
		local pos, size = p.Position, p.Size
		local anchor = p.AnchorPoint or Vector2.zero
		local w = size.X.Scale * cs.X + size.X.Offset
		local h = size.Y.Scale * cs.Y + size.Y.Offset
		H.setAbs(p, cp.X + pos.X.Scale * cs.X + pos.X.Offset - anchor.X * w, cp.Y + pos.Y.Scale * cs.Y + pos.Y.Offset - anchor.Y * h, w, h)
	end
	for _, win in wins do
		if H.isDestroyed(win) then
			continue
		end
		place(win)
		for _, p: any in Compositor.partsOf(win) do
			if p.Name == "WindowDecoration" or p.Name == "WindowTab" or p.Name == "WindowIcon" or p.Name == "WindowDockStrip" then
				place(p)
			end
		end
	end
end

function relay()
	for container, wins in laid do
		if H.isDestroyed(container) then
			laid[container] = nil
		else
			lay(container, wins)
		end
	end
end

-- drag `win`'s title bar from (x0, y0) through `path`; release at the last point unless keepDown
local function dragTitle(win: Instance, x0: number, y0: number, path: { { number } }, keepDown: boolean?)
	relay()
	press(x0, y0)
	H.fire(get(win, "TitleBar"), "InputBegan", mouse(M1, x0, y0))
	local last = { x0, y0 }
	for _, p in path do
		moveTo(p[1], p[2])
		last = p
	end
	if not keepDown then
		release(last[1], last[2])
	end
end
-- the same on a window's tab (press = select, drag = reorder / tear off)
local function dragTab(win: Instance, x0: number, y0: number, path: { { number } }, keepDown: boolean?)
	relay()
	press(x0, y0)
	H.fire(tabOf(win), "InputBegan", mouse(M1, x0, y0))
	local last = { x0, y0 }
	for _, p in path do
		moveTo(p[1], p[2])
		last = p
	end
	if not keepDown then
		release(last[1], last[2])
	end
end
local function clickTab(win: Instance)
	relay()
	local t = tabOf(win)
	local p = t.AbsolutePosition + t.AbsoluteSize / 2
	dragTab(win, p.X, p.Y, {})
end

local function zOf(win: Instance): number
	return (win :: any).ZIndex
end
local function shownTabs(wins: { Instance }): { Instance }
	local out = {}
	for _, w in wins do
		if tabOf(w).Visible then
			table.insert(out, w)
		end
	end
	table.sort(out, function(a, b)
		return tabOf(a).Position.X.Offset < tabOf(b).Position.X.Offset
	end)
	return out
end
local function names(wins: { Instance }): string
	local out = {}
	for _, w in wins do
		table.insert(out, get(w, "Title").Text)
	end
	return table.concat(out, ",")
end

-- A at (100, 100) 300 x 200 and B at (500, 300) 200 x 150, both keyed, in an 1000 x 700 container
local function pair(m: any, container: any, extra: { [string]: any }?): (any, any, any)
	local s = {
		pa = q.Source(UDim2.fromOffset(100, 100)),
		sa = q.Source(Vector2.new(300, 200)),
		pb = q.Source(UDim2.fromOffset(500, 300)),
		sb = q.Source(Vector2.new(200, 150)),
		oa = q.Source(true),
		ob = q.Source(true),
		ca = q.Source(false),
		cb = q.Source(false),
	}
	local propsB: { [string]: any } = { Title = "B", Key = "b", Manager = m, Position = s.pb, Size = s.sb, Open = s.ob, Collapsed = s.cb }
	for k, v in extra or {} do
		propsB[k] = v
	end
	local a = Devui.Window({ Title = "A", Key = "a", Manager = m, Position = s.pa, Size = s.sa, Open = s.oa, Collapsed = s.ca })
	local b = Devui.Window(propsB :: any)
	a.Parent = container
	b.Parent = container
	lay(container, { a, b })
	return a, b, s
end

H.section("join by the title row: the preview covers the target, release makes one group (one rectangle, one decoration)", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a, b, s = pair(m, container)
	dragTitle(b, 510, 310, { { 300, 250 }, { 200, 108 } }, true)
	local preview = previewOf(b)
	assert(preview ~= nil, "a preview over A's title row")
	assert(preview.Position == frameOf(a).Position and preview.Size == frameOf(a).Size, "covering A's outer rectangle")
	assert(preview.ZIndex > frameOf(b).ZIndex and preview.ZIndex > tabOf(a).ZIndex, "above everything")
	release(200, 108)
	assert(previewOf(b) == nil, "released: the preview closes")
	-- one rectangle: A's; B draws (it was dragged in: selected), A's decoration and surface hide
	assert(frameOf(b).Visible and not frameOf(a).Visible, "B draws the group")
	assert(frameOf(b).Position == UDim2.fromOffset(100, 100) and frameOf(b).Size == UDim2.fromOffset(300, 200), "at A's rectangle")
	assert((b :: any).Visible and not (a :: any).Visible, "only the selected surface shows")
	assert((b :: any).Position == UDim2.fromOffset(100, 119), "B's surface under the strip")
	-- the Position / Size Sources keep their pre-group values (B's back to where its drag began)
	assert(s.pa:Get() == UDim2.fromOffset(100, 100) and s.pb:Get() == UDim2.fromOffset(500, 300) and s.sb:Get() == Vector2.new(200, 150))
	-- the strip: the title and close button hide, the collapse arrow stays; two tabs, B before A (pointer left of A's middle)
	assert(get(b, "Title").Visible == false and get(b, "CloseButton").Visible == false and get(b, "CollapseButton").Visible == true)
	lay(container, { a, b })
	local tabs = shownTabs({ a, b })
	assert(#tabs == 2 and tabs[1] == b and tabs[2] == a, `tab order {#tabs}`)
	local tb, ta = tabOf(b), tabOf(a)
	assert(tb.Position.Y == UDim2.fromOffset(0, 100).Y and tb.Size.Y.Offset == 19, "the tabs sit in the strip row")
	assert(tb.Size == ta.Size and tb.Position.X.Offset + tb.Size.X.Offset == ta.Position.X.Offset, "side by side, even widths")
	assert(tb.Position.X.Offset > 100, "after the collapse arrow")
	assert(ta.Position.X.Offset + ta.Size.X.Offset <= 100 + 300 - 4 - 2 * 19, "the strip's right end stays free to drag the group")
	assert(tb.BackgroundColor3 ~= ta.BackgroundColor3, "the selected tab looks active")
	assert(tb.ZIndex == ta.ZIndex and tb.ZIndex >= frameOf(b).ZIndex + 2, "the tabs over the strip")
	-- the selected tab shows its close button
	assert(H.find(tb, "CloseButton").Visible == true and H.find(ta, "CloseButton").Visible == false)
	q.dispose(a)
	q.dispose(b)
	q.dispose(container)
	H.assertNoDebugOutput("title row")
end)

H.section("join by the centre (last tab); the four bands preview a split of the target (docking stage 4)", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a, b = pair(m, container)
	-- (stage 3 kept these bands empty; since stage 4 they split the target — the split itself is spec.windowsplit's,
	-- here only the half previews, and a release away from A)
	local function previewIs(x: number, y: number, w: number, h: number): boolean
		local p = previewOf(b)
		return p ~= nil and p.Position == UDim2.fromOffset(x, y) and p.Size == UDim2.fromOffset(w, h)
	end
	dragTitle(b, 510, 310, { { 120, 200 } }, true) -- x 0.07: the left band
	assert(previewIs(100, 100, 150, 200), "left band: A's left half")
	moveTo(250, 290) -- y 0.95: the bottom band
	assert(previewIs(100, 200, 300, 100), "bottom band: A's bottom half")
	moveTo(250, 125) -- y 0.125 (below the title row): the top band
	assert(previewIs(100, 100, 300, 100), "top band: A's top half")
	moveTo(390, 200)
	assert(previewIs(250, 100, 150, 200), "right band: A's right half")
	moveTo(800, 600)
	assert(previewOf(b) == nil, "away from A: no preview")
	release(800, 600)
	assert(frameOf(a).Visible and frameOf(b).Visible and tabOf(a).Visible == false, "released away: nothing joined")
	lay(container, { a, b })
	dragTitle(b, 400, 260, { { 250, 200 } }, true) -- the centre
	assert(previewOf(b) ~= nil and previewOf(b).Position == frameOf(a).Position)
	release(250, 200)
	lay(container, { a, b })
	local tabs = shownTabs({ a, b })
	assert(#tabs == 2 and tabs[1] == a and tabs[2] == b, "the centre appends")
	local c = Devui.Window({ Title = "C", Key = "c", Manager = m, Position = q.Source(UDim2.fromOffset(600, 50)) })
	c.Parent = container
	lay(container, { a, b, c })
	-- a group's strip row inserts where the pointer is among the tabs: between A and B
	local ta = tabOf(a)
	local between = ta.AbsolutePosition.X + ta.AbsoluteSize.X + 2
	dragTitle(c, 650, 60, { { between, 108 } })
	lay(container, { a, b, c })
	assert(names(shownTabs({ a, b, c })) == "A,C,B", names(shownTabs({ a, b, c })))
	for _, w in { a, b, c } do
		q.dispose(w)
	end
	q.dispose(container)
	H.assertNoDebugOutput("centre")
end)

H.section("tabs: press selects; dragging inside the row reorders; dragging out tears off at the kept size, the drag goes on", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a, b, s = pair(m, container)
	local pc, sc = q.Source(UDim2.fromOffset(700, 400)), q.Source(Vector2.new(250, 120))
	local c = Devui.Window({ Title = "C", Key = "c", Manager = m, Position = pc, Size = sc })
	c.Parent = container
	lay(container, { a, b, c })
	dragTitle(b, 510, 310, { { 250, 200 } })
	lay(container, { a, b, c })
	dragTitle(c, 710, 410, { { 250, 200 } })
	lay(container, { a, b, c })
	assert(names(shownTabs({ a, b, c })) == "A,B,C" and frameOf(c).Visible, "C joined and is selected")
	clickTab(a)
	assert(frameOf(a).Visible and not frameOf(c).Visible and (a :: any).Visible and not (c :: any).Visible, "pressing A's tab selects it")
	-- reorder: drag A's tab to the right inside the row
	lay(container, { a, b, c })
	local t = tabOf(a)
	local y = t.AbsolutePosition.Y + 5
	local x0 = t.AbsolutePosition.X + 10
	local lastX = tabOf(c).AbsolutePosition.X + 10
	dragTab(a, x0, y, { { x0 + 20, y }, { lastX, y } })
	lay(container, { a, b, c })
	assert(names(shownTabs({ a, b, c })) == "B,C,A", `reordered {names(shownTabs({ a, b, c }))}`)
	-- tear C off: down out of the row; it floats at its kept Size, the pointer on the same spot of its title bar
	local tc = tabOf(c)
	local cx, cy = tc.AbsolutePosition.X + 10, tc.AbsolutePosition.Y + 5
	dragTab(c, cx, cy, { { cx, cy + 3 }, { cx, cy + 60 } }, true)
	assert(tabOf(c).Visible == false and frameOf(c).Visible, "C is a plain window again")
	assert(sc:Get() == Vector2.new(250, 120) and frameOf(c).Size == UDim2.fromOffset(250, 120), "at its kept Size")
	local gx = (cx - 100) / 300 -- where on the group's width C was grabbed
	local expectX = math.round(cx - gx * 250)
	assert(pc:Get() == UDim2.fromOffset(expectX, 100 + 60), `under the pointer ({pc:Get()})`)
	assert(get(c, "Title").Visible == true, "its own title bar")
	moveTo(cx + 40, cy + 100)
	assert(pc:Get() == UDim2.fromOffset(expectX + 40, 100 + 100), "the drag goes on")
	release(cx + 40, cy + 100)
	lay(container, { a, b, c })
	assert(names(shownTabs({ a, b })) == "B,A" and zOf(c) > zOf(a), "the others stay a group; C on top")
	assert(s.pa:Get() == UDim2.fromOffset(100, 100), "A's own rectangle untouched")
	for _, w in { a, b, c } do
		q.dispose(w)
	end
	q.dispose(container)
	H.assertNoDebugOutput("tabs")
end)

H.section("the strip shows only with two open windows; close hides the tab, Open:Set(true) brings it back at its place, selected and raised", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a, b, s = pair(m, container)
	local oc, fc = q.Source(true), q.Source(false)
	local c = Devui.Window({ Title = "C", Key = "c", Manager = m, Open = oc, Focused = fc, Position = q.Source(UDim2.fromOffset(700, 50)) })
	local d = Devui.Window({ Title = "D", Key = "d", Manager = m, Position = q.Source(UDim2.fromOffset(600, 400)) })
	c.Parent = container
	d.Parent = container
	lay(container, { a, b, c, d })
	dragTitle(b, 510, 310, { { 250, 200 } })
	dragTitle(c, 710, 60, { { 250, 200 } })
	lay(container, { a, b, c, d })
	assert(names(shownTabs({ a, b, c })) == "A,B,C")
	-- close C (selected): the neighbour (previous, no next) is selected
	oc:Set(false)
	assert(tabOf(c).Visible == false and frameOf(b).Visible, "C's tab hides; B (its neighbour) is selected")
	-- close B through its tab's close button: only A is open -> a plain-looking window
	H.fire(H.find(tabOf(b), "CloseButton"), "Activated", H.input({}), 1)
	assert(s.ob:Get() == false, "the tab's × closes B")
	assert(frameOf(a).Visible and get(a, "Title").Visible == true and get(a, "CloseButton").Visible == true, "one open: the title bar")
	assert(tabOf(a).Visible == false, "no strip")
	-- D on top, then reopen C: back at its place (last), selected, the group raised and focused
	press(650, 410)
	assert(zOf(d) > zOf(a))
	oc:Set(true)
	lay(container, { a, b, c, d })
	assert(names(shownTabs({ a, b, c })) == "A,C", "C back after A (B closed keeps its slot)")
	assert(frameOf(c).Visible and (c :: any).Visible and fc:Get() == true, "selected and focused")
	assert(zOf(a) > zOf(d) and zOf(c) > zOf(d), "raised over D")
	s.ob:Set(true)
	lay(container, { a, b, c, d })
	assert(names(shownTabs({ a, b, c })) == "A,B,C", "B back at its own slot")
	-- every window closed: the group hides as a whole; one reopened shows it again
	s.oa:Set(false)
	s.ob:Set(false)
	oc:Set(false)
	for _, w in { a, b, c } do
		local surface: any = w
		local hidden = not frameOf(w).Visible and not tabOf(w).Visible and not get(w, "WindowIcon").Visible
		assert(hidden and not surface.Visible, "all closed: hidden")
	end
	s.oa:Set(true)
	assert(frameOf(a).Visible and frameOf(a).Position == UDim2.fromOffset(100, 100), "shown again at the group's rectangle")
	for _, w in { a, b, c, d } do
		q.dispose(w)
	end
	q.dispose(container)
	H.assertNoDebugOutput("strip / close")
end)

H.section("OnCloseRequest on a tab's ×; NoClose has none", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local asked = 0
	local a, b, s = pair(m, container, { OnCloseRequest = function()
		asked += 1
	end })
	local c = Devui.Window({ Title = "C", Key = "c", Manager = m, NoClose = true })
	c.Parent = container
	lay(container, { a, b, c })
	dragTitle(b, 510, 310, { { 250, 200 } })
	dragTitle(c, 70, 70, { { 250, 200 } })
	H.fire(H.find(tabOf(b), "CloseButton"), "Activated", H.input({}), 1)
	assert(asked == 1 and s.ob:Get() == true, "the request, Open untouched")
	assert(H.find(tabOf(c), "CloseButton") == nil, "NoClose: no × on its tab")
	for _, w in { a, b, c } do
		q.dispose(w)
	end
	q.dispose(container)
	H.assertNoDebugOutput("close request")
end)

H.section("a group shrinking to one window: it takes the group's rectangle and is a plain window again", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a, b, s = pair(m, container)
	dragTitle(b, 510, 310, { { 250, 200 } })
	lay(container, { a, b })
	-- move the group by the strip's empty area (right of the tabs): only the group's rectangle moves
	dragTitle(b, 390, 108, { { 440, 158 } })
	assert(frameOf(b).Position == UDim2.fromOffset(150, 150) and s.pa:Get() == UDim2.fromOffset(100, 100) and s.pb:Get() == UDim2.fromOffset(500, 300))
	-- resize the group by the drawn window's grip
	local grip = part(b, "WindowResizeGrip")
	assert(grip.Visible and grip.Position == UDim2.fromOffset(450, 350))
	H.fire(grip, "InputBegan", mouse(M1, 445, 345))
	moveTo(475, 365)
	release(475, 365)
	assert(frameOf(b).Size == UDim2.fromOffset(330, 220) and s.sa:Get() == Vector2.new(300, 200) and s.sb:Get() == Vector2.new(200, 150))
	lay(container, { a, b })
	-- tear B off: A alone takes the group's rectangle into its own Sources
	local tb = tabOf(b)
	local x, y = tb.AbsolutePosition.X + 5, tb.AbsolutePosition.Y + 5
	dragTab(b, x, y, { { x, y + 300 } }) -- (out of A too: dropped over A's centre it would join again)
	assert(s.pa:Get() == UDim2.fromOffset(150, 150) and s.sa:Get() == Vector2.new(330, 220), "A stays where the group was")
	assert(frameOf(a).Visible and get(a, "Title").Visible and tabOf(a).Visible == false and frameOf(a).Position == UDim2.fromOffset(150, 150))
	assert(s.sb:Get() == Vector2.new(200, 150), "B at its own size")
	local layout = m:ExportLayout()
	assert(#layout.Floating == 2 and #(layout.Floating[1].Node :: any).Tabs == 1 and layout.Windows.a.Position == nil, "two plain windows")
	q.dispose(a)
	q.dispose(b)
	q.dispose(container)
	H.assertNoDebugOutput("group of one")
end)

H.section("collapse is the group's: one icon (the selected window's); an app writing one window's Collapsed moves the group", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a, b, s = pair(m, container, { Icon = "rbxassetid://7" })
	dragTitle(b, 510, 310, { { 250, 200 } })
	H.fire(get(b, "CollapseButton"), "Activated", H.input({}), 1)
	assert(s.ca:Get() == true and s.cb:Get() == true, "every window collapsed")
	local ib, ia = get(b, "WindowIcon"), get(a, "WindowIcon")
	assert(ib.Visible and not ia.Visible and ib.Position == UDim2.fromOffset(100, 100), "the selected window's icon, at the group")
	assert(H.find(ib, "Image") ~= nil, "its Icon image")
	assert(not frameOf(a).Visible and not frameOf(b).Visible and not tabOf(a).Visible)
	s.ca:Set(false) -- the app expands A (not the selected one)
	assert(s.cb:Get() == false and frameOf(b).Visible, "the whole group expands")
	-- a member's NoCollapse hides the group's arrow
	local c = Devui.Window({ Title = "C", Key = "c", Manager = m, NoCollapse = true })
	c.Parent = container
	lay(container, { a, b, c })
	dragTitle(c, 70, 70, { { 250, 200 } })
	clickTab(b)
	assert(frameOf(b).Visible and get(b, "CollapseButton").Visible == false, "NoCollapse in the group: no arrow")
	for _, w in { a, b, c } do
		q.dispose(w)
	end
	q.dispose(container)
	H.assertNoDebugOutput("collapse")
end)

H.section("the group stacks as one lump: nothing interleaves; pressing any part raises it; the focused window is the selected one", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a, b = pair(m, container)
	local fe = q.Source(false)
	local d = Devui.Window({ Title = "D", Key = "d", Manager = m, Position = q.Source(UDim2.fromOffset(600, 400)) })
	local e = Devui.Window({ Title = "E", Key = "e", Manager = m, Position = q.Source(UDim2.fromOffset(50, 500)), Focused = fe })
	d.Parent = container
	e.Parent = container
	lay(container, { a, b, d, e })
	dragTitle(b, 510, 310, { { 250, 200 } })
	local function lumpOk(): boolean
		local lo, hi = math.min(zOf(a), zOf(b)), math.max(zOf(a), zOf(b))
		for _, w in { d, e } do
			if zOf(w) > lo and zOf(w) < hi then
				return false
			end
		end
		return hi - lo == 3
	end
	assert(lumpOk() and zOf(a) > zOf(d) and zOf(a) > zOf(e), "the group on top as one lump")
	press(650, 410) -- D
	assert(lumpOk() and zOf(d) > zOf(a) and zOf(d) > zOf(b), "D over the whole group")
	assert(tabOf(a).ZIndex < frameOf(d).ZIndex, "the tabs too")
	press(250, 250) -- the group's surface (B shows)
	assert(lumpOk() and zOf(a) > zOf(d))
	assert(m.Focused:Get() ~= 0)
	local focusedB = m.Focused:Get()
	clickTab(a)
	assert(m.Focused:Get() ~= focusedB, "selecting A moves the focus to A")
	press(80, 510) -- E focused
	assert(fe:Get() == true and zOf(e) > zOf(a))
	for _, w in { a, b, d, e } do
		q.dispose(w)
	end
	q.dispose(container)
	H.assertNoDebugOutput("lump")
end)

H.section("Focused:Set(true) on a hidden open tab selects it; the group's flags: NoResize hides the grip, MinSize is the largest", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local fa = q.Source(false)
	local a2 = Devui.Window({ Title = "A", Key = "a", Manager = m, Focused = fa, MinSize = Vector2.new(250, 50) })
	local b2 = Devui.Window({ Title = "B", Key = "b", Manager = m, Position = q.Source(UDim2.fromOffset(500, 300)), MinSize = Vector2.new(100, 180) })
	a2.Parent = container
	b2.Parent = container
	lay(container, { a2, b2 })
	dragTitle(b2, 510, 310, { { 200, 150 } })
	assert(frameOf(b2).Visible and not frameOf(a2).Visible)
	fa:Set(true)
	assert(frameOf(a2).Visible and not frameOf(b2).Visible and fa:Get() == true, "A selected and focused")
	-- the grip floors at the largest MinSize per axis
	local grip = part(a2, "WindowResizeGrip")
	H.fire(grip, "InputBegan", mouse(M1, 350, 250))
	moveTo(-1000, -1000)
	release(-1000, -1000)
	assert(frameOf(a2).Size == UDim2.fromOffset(250, 180), `group floor ({frameOf(a2).Size})`)
	-- an open NoResize window hides the group's grip; closed, it does not count
	local oc = q.Source(true)
	local c = Devui.Window({ Title = "C", Key = "c", Manager = m, NoResize = true, Open = oc, Position = q.Source(UDim2.fromOffset(700, 450)) })
	c.Parent = container
	lay(container, { a2, b2, c })
	dragTitle(c, 710, 460, { { 175, 110 } })
	clickTab(a2)
	assert(frameOf(a2).Visible and part(a2, "WindowResizeGrip").Visible == false, "no grip")
	oc:Set(false)
	assert(part(a2, "WindowResizeGrip").Visible == true, "the closed NoResize window does not count")
	for _, w in { a2, b2, c } do
		q.dispose(w)
	end
	q.dispose(container)
	H.assertNoDebugOutput("flags")
end)

H.section("a held edge joins its group; a docked group's strip dragged off the edge floats the whole group", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a, b, s = pair(m, container)
	dragTitle(a, 150, 110, { { 3, 110 } }) -- A docks left
	assert(part(a, "WindowDockStrip").Visible)
	lay(container, { a, b })
	dragTitle(b, 510, 310, { { 5, 300 } }, true)
	local preview = previewOf(b)
	assert(preview ~= nil and preview.Position == frameOf(a).Position and preview.Size == frameOf(a).Size, "the preview covers A's panel")
	release(5, 300)
	assert(frameOf(b).Visible and frameOf(b).Position == UDim2.fromOffset(19, 0) and frameOf(b).Size == UDim2.new(0, 300, 1, 0), "B draws the docked group")
	assert(part(b, "WindowDockStrip").Visible and not part(a, "WindowDockStrip").Visible, "one strip")
	local layout = m:ExportLayout()
	local left = layout.Left :: any
	assert(left ~= nil and #left.Node.Tabs == 2 and left.Node.Tabs[1] == "a" and left.Node.Selected == "b" and #layout.Floating == 0)
	assert((m:ExportWindow("b") :: WindowState).Dock == "Left", "B is on the edge with its group")
	-- the dock width handle moves the group's width (every window follows)
	local handle = part(b, "WindowDockResize")
	relay()
	H.fire(handle, "InputBegan", mouse(M1, 320, 300))
	moveTo(360, 300)
	release(360, 300)
	assert((m:ExportWindow("a") :: WindowState).DockWidth == 340 and (m:ExportWindow("b") :: WindowState).DockWidth == 340)
	-- over the docked panel's centre: joins too (a free window C)
	local c = Devui.Window({ Title = "C", Key = "c", Manager = m, Position = q.Source(UDim2.fromOffset(600, 50)) })
	c.Parent = container
	lay(container, { a, b, c })
	dragTitle(c, 650, 60, { { 190, 350 } })
	assert((m:ExportLayout().Left :: any).Node.Tabs[3] == "c")
	-- the strip's empty area dragged off the edge: the whole group floats at the group's floating rectangle
	lay(container, { a, b, c })
	dragTitle(c, 340, 8, { { 345, 12 }, { 500, 200 } })
	for _, w in { a, b, c } do
		assert((m:ExportWindow(get(w, "Title").Text:lower()) :: WindowState).Dock == nil, "undocked")
	end
	assert(frameOf(c).Visible and frameOf(c).Size == UDim2.fromOffset(300, 200), "at the group's floating size (A's rectangle when it formed)")
	assert(#m:ExportLayout().Floating == 1 and m:ExportLayout().Left == nil)
	assert(s.pa:Get() == UDim2.fromOffset(100, 100), "A's own Sources untouched")
	for _, w in { a, b, c } do
		q.dispose(w)
	end
	q.dispose(container)
	H.assertNoDebugOutput("edge join")
end)

H.section("not eligible: a NoTitleBar window, an icon, another container, a dragged icon; NoMove in a group stops the group", function()
	local container = newContainer(1000, 700)
	local other = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a, b = pair(m, container)
	local bare = Devui.Window({ Title = "N", Key = "n", Manager = m, NoTitleBar = true, Position = q.Source(UDim2.fromOffset(600, 50)) })
	local iconWin = Devui.Window({ Title = "I", Key = "i", Manager = m, Collapsed = q.Source(true), Position = q.Source(UDim2.fromOffset(50, 500)) })
	local far = Devui.Window({ Title = "F", Key = "f", Manager = m, Position = q.Source(UDim2.fromOffset(100, 100)) })
	bare.Parent = container
	iconWin.Parent = container
	far.Parent = other
	lay(container, { a, b, bare, iconWin })
	lay(other, { far })
	dragTitle(b, 510, 310, { { 750, 150 } }, true)
	assert(previewOf(b) == nil, "a NoTitleBar window is no target")
	moveTo(60, 510)
	assert(previewOf(b) == nil, "an icon is no target")
	release(60, 510)
	-- the far window (another container) is at A's place on its screen: A is the one judged
	dragTitle(far, 150, 110, { { 250, 200 } })
	assert(tabOf(a).Visible == false and frameOf(far).Visible, "another container: no join")
	-- a dragged icon never joins
	local icon = get(iconWin, "WindowIcon")
	H.fire(icon, "InputBegan", mouse(M1, 60, 510))
	moveTo(250, 200)
	release(250, 200)
	assert(get(iconWin, "WindowIcon").Visible and tabOf(a).Visible == false, "the icon only moved")
	-- a NoTitleBar window cannot be dragged at all; NoMove: a group with one does not move
	local fixed = Devui.Window({ Title = "X", Key = "x", Manager = m, NoMove = true, Position = q.Source(UDim2.fromOffset(600, 400)) })
	fixed.Parent = container
	lay(container, { a, b, fixed })
	dragTitle(b, 400, 260, { { 750, 500 } }) -- B onto the fixed window's centre
	assert(frameOf(b).Visible and frameOf(b).Position == UDim2.fromOffset(600, 400), "a NoMove window can be joined")
	dragTitle(b, 790, 408, { { 300, 300 } })
	assert(frameOf(b).Position == UDim2.fromOffset(600, 400), "a group with a NoMove window does not move")
	-- the NoMove window's tab only reorders (it is not torn off)
	relay()
	local tf = tabOf(fixed)
	local fx, fy = tf.AbsolutePosition.X + 5, tf.AbsolutePosition.Y + 5
	dragTab(fixed, fx, fy, { { fx, fy + 300 } })
	assert(tabOf(fixed).Visible and frameOf(fixed).Visible, "still a tab of the group")
	for _, w in { a, b, bare, iconWin, far, fixed } do
		q.dispose(w)
	end
	q.dispose(container)
	q.dispose(other)
	H.assertNoDebugOutput("eligibility")
end)

H.section("NoDock only stops edge docking: a NoDock window joins and is joined; a group with one shows no edge preview", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a, b = pair(m, container, { NoDock = true })
	assert(part(b, "WindowDockPreview") ~= nil, "a NoDock window has the preview part")
	dragTitle(b, 510, 310, { { 250, 200 } })
	assert(frameOf(b).Visible and frameOf(b).Position == UDim2.fromOffset(100, 100), "NoDock B joined A")
	lay(container, { a, b })
	dragTitle(b, 390, 108, { { 5, 108 } }, true)
	assert(previewOf(b) == nil, "the group holds a NoDock window: no edge preview")
	release(5, 108)
	assert(not part(b, "WindowDockStrip").Visible)
	local c = Devui.Window({ Title = "C", Key = "c", Manager = m, Position = q.Source(UDim2.fromOffset(600, 400)) })
	c.Parent = container
	lay(container, { a, b, c })
	-- C onto the group that holds NoDock B
	local fp = frameOf(b).AbsolutePosition
	dragTitle(c, 650, 410, { { fp.X + 150, fp.Y + 100 } })
	assert(frameOf(c).Visible and not frameOf(b).Visible, "joined")
	for _, w in { a, b, c } do
		q.dispose(w)
	end
	q.dispose(container)
	H.assertNoDebugOutput("nodock")
end)

H.section("a whole group joins another with all its tabs in order", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a, b = pair(m, container)
	local c = Devui.Window({ Title = "C", Key = "c", Manager = m, Position = q.Source(UDim2.fromOffset(600, 50)) })
	local d = Devui.Window({ Title = "D", Key = "d", Manager = m, Position = q.Source(UDim2.fromOffset(600, 450)) })
	c.Parent = container
	d.Parent = container
	lay(container, { a, b, c, d })
	dragTitle(b, 510, 310, { { 250, 200 } }) -- A, B
	dragTitle(d, 650, 460, { { 700, 150 } }) -- C, D
	lay(container, { a, b, c, d })
	assert(names(shownTabs({ c, d })) == "C,D" and frameOf(d).Visible)
	-- the C+D group by its strip's empty area onto the A+B group's centre
	dragTitle(d, 880, 58, { { 250, 200 } })
	lay(container, { a, b, c, d })
	assert(names(shownTabs({ a, b, c, d })) == "A,B,C,D", names(shownTabs({ a, b, c, d })))
	assert(frameOf(d).Visible and frameOf(d).Position == UDim2.fromOffset(100, 100), "D (the dragged group's selected) draws")
	assert(#m:ExportLayout().Floating == 1)
	for _, w in { a, b, c, d } do
		q.dispose(w)
	end
	q.dispose(container)
	H.assertNoDebugOutput("group joins group")
end)

H.section("layout: a tab group round-trips (closed tab, kept rectangles, keyless left out); pending keys join at their index", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a, b, s = pair(m, container)
	local c = Devui.Window({ Title = "C", Key = "c", Manager = m, Position = q.Source(UDim2.fromOffset(600, 50)), Size = q.Source(Vector2.new(220, 140)) })
	local k = Devui.Window({ Title = "K", Manager = m, Position = q.Source(UDim2.fromOffset(600, 450)) })
	c.Parent = container
	k.Parent = container
	lay(container, { a, b, c, k })
	dragTitle(b, 510, 310, { { 250, 200 } })
	dragTitle(c, 650, 60, { { 250, 200 } })
	dragTitle(k, 650, 460, { { 250, 200 } })
	s.ob:Set(false) -- a closed tab
	clickTab(c)
	H.resetOutput()
	local layout = m:ExportLayout()
	H.resetOutput() -- (the key-less notice)
	assert(#layout.Floating == 1, "one group")
	local g = layout.Floating[1]
	local gn: any = g.Node
	assert(table.concat(gn.Tabs, ",") == "a,b,c" and gn.Selected == "c", `tabs {table.concat(gn.Tabs, ",")}`)
	assert(g.Position[2] == 100 and g.Position[4] == 100 and g.Size[1] == 300 and g.Size[2] == 200, "the group's rectangle")
	assert(layout.Windows.b.Open == false and layout.Windows.k == nil, "the closed tab is kept; the keyless one is left out")
	local wb, wc = layout.Windows.b :: any, layout.Windows.c :: any
	assert(wb.Position[2] == 500 and wb.Position[4] == 300 and wb.Size[1] == 200, "B's kept rectangle")
	assert(wc.Position[2] == 600 and wc.Size[1] == 220 and wc.Size[2] == 140, "C's kept rectangle")
	local saved = json(layout)
	for _, w in { a, b, c, k } do
		q.dispose(w)
	end
	-- a fresh manager, the layout first, the windows afterwards in another order: each joins at its index
	local m2 = Devui.WindowManager.new()
	m2:ImportLayout(saved)
	assert(serde.encode("json", m2:ExportLayout()) == serde.encode("json", saved), "pending: exported again unchanged")
	local pc2, sc2 = q.Source(UDim2.fromOffset(1, 1)), q.Source(Vector2.new(50, 50))
	local c2 = Devui.Window({ Title = "C", Key = "c", Manager = m2, Position = pc2, Size = sc2 })
	c2.Parent = container
	assert(pc2:Get() == UDim2.fromOffset(600, 50) and sc2:Get() == Vector2.new(220, 140), "its kept rectangle written into its Sources")
	assert(frameOf(c2).Position == UDim2.fromOffset(100, 100), "drawn at the group's rectangle (the others still pending)")
	local a2 = Devui.Window({ Title = "A", Key = "a", Manager = m2 })
	local b2 = Devui.Window({ Title = "B", Key = "b", Manager = m2 })
	a2.Parent = container
	b2.Parent = container
	lay(container, { a2, b2, c2 })
	assert(names(shownTabs({ a2, b2, c2 })) == "A,C", "A before C; B closed")
	assert(frameOf(c2).Visible and not frameOf(a2).Visible, "C selected as saved")
	assert(serde.encode("json", m2:ExportLayout()) == serde.encode("json", saved), "live: the same layout")
	-- tear C off: it goes back to its saved rectangle's size
	local tc = tabOf(c2)
	local x, y = tc.AbsolutePosition.X + 5, tc.AbsolutePosition.Y + 5
	dragTab(c2, x, y, { { x, y + 420 } })
	assert(sc2:Get() == Vector2.new(220, 140) and frameOf(c2).Size == UDim2.fromOffset(220, 140), "the saved own rectangle")
	for _, w in { a2, b2, c2 } do
		q.dispose(w)
	end
	q.dispose(container)
	H.assertNoDebugOutput("tab layout")
end)

H.section("layout: a group the keyless windows leave with one saved tab is saved as a plain window (no own rectangle)", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local pa = q.Source(UDim2.fromOffset(100, 100))
	local a = Devui.Window({ Title = "A", Key = "a", Manager = m, Position = pa, Size = q.Source(Vector2.new(300, 200)) })
	local k = Devui.Window({ Title = "K", Manager = m, Position = q.Source(UDim2.fromOffset(600, 450)) })
	a.Parent = container
	k.Parent = container
	lay(container, { a, k })
	dragTitle(a, 150, 110, { { 500, 210 } }) -- A moves (its kept rectangle is where it lands)
	dragTitle(k, 650, 460, { { 550, 300 } }) -- K joins A by the centre
	assert(names(shownTabs({ a, k })) == "A,K", "one group of two")
	H.resetOutput()
	local layout = m:ExportLayout()
	H.resetOutput() -- (the key-less notice)
	local g = layout.Floating[1]
	local gn: any = g.Node
	assert(#layout.Floating == 1 and #gn.Tabs == 1 and gn.Tabs[1] == "a", "only the keyed window is saved")
	assert((layout.Windows.a :: any).Position == nil and (layout.Windows.a :: any).Size == nil, "a one-tab node carries no own rectangle")
	for _, w in { a, k } do
		q.dispose(w)
	end
	q.dispose(container)
	H.assertNoDebugOutput("one saved tab")
end)

H.section("layout: a member without a saved own rectangle is torn off at the group's Size; ImportWindow takes a window out", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	m:ImportLayout({
		Version = 1,
		Windows = { a = { Kind = "a", Open = true }, b = { Kind = "b", Open = true }, c = { Kind = "c", Open = true } },
		Floating = { { Position = { 0, 100, 0, 100 }, Size = { 400, 250 }, Collapsed = false, Node = { Tabs = { "a", "b", "c" }, Selected = "a" } } },
	})
	local sb = q.Source(Vector2.new(50, 50))
	local pa = q.Source(UDim2.fromOffset(9, 9))
	local a = Devui.Window({ Title = "A", Key = "a", Manager = m, Position = pa })
	local b = Devui.Window({ Title = "B", Key = "b", Manager = m, Size = sb })
	local c = Devui.Window({ Title = "C", Key = "c", Manager = m })
	for _, w in { a, b, c } do
		w.Parent = container
	end
	lay(container, { a, b, c })
	assert(pa:Get() == UDim2.fromOffset(9, 9), "no own rectangle saved: the Sources are left alone")
	assert(m:ExportLayout().Windows.a.Position == nil, "and none is exported")
	local tb = tabOf(b)
	local x, y = tb.AbsolutePosition.X + 5, tb.AbsolutePosition.Y + 5
	dragTab(b, x, y, { { x, y + 420 } })
	assert(sb:Get() == Vector2.new(400, 250), "torn off at the group's Size")
	-- ImportWindow on a grouped window: it leaves the group first, then takes the state
	-- (a position the mock's stale on-screen size keeps inside the container)
	m:ImportWindow("c", { Kind = "c", Open = true, Collapsed = false, Position = { 0, 300, 0, 200 }, Size = { 200, 120 } })
	assert(frameOf(c).Visible and frameOf(c).Position == UDim2.fromOffset(300, 200) and tabOf(c).Visible == false, "a plain window at its state")
	assert(frameOf(a).Visible and frameOf(a).Position == UDim2.fromOffset(100, 100), "A, left alone, keeps the group's place")
	assert(pa:Get() == UDim2.fromOffset(100, 100), "and takes it into its Sources")
	-- ExportWindow carries no group: one window's own state
	local layout = m:ExportLayout()
	assert(#layout.Floating == 3)
	for _, w in { a, b, c } do
		q.dispose(w)
	end
	q.dispose(container)
	H.assertNoDebugOutput("no own rect")
end)

H.section("ExportWindow of a grouped window: its own state (kept rectangle, no group fields)", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a, b = pair(m, container)
	dragTitle(b, 510, 310, { { 250, 200 } })
	local st = m:ExportWindow("b") :: any
	assert(st.Position[2] == 500 and st.Position[4] == 300 and st.Size[1] == 200 and st.Dock == nil, "its own rectangle")
	local count = 0
	for key in st do
		assert(key == "Kind" or key == "Open" or key == "Collapsed" or key == "Position" or key == "Size", `field {key}`)
		count += 1
	end
	assert(count == 5)
	q.dispose(a)
	q.dispose(b)
	q.dispose(container)
	H.assertNoDebugOutput("export window")
end)

H.section("rebuilding the UI: a destroyed keyed tab waits in its group and comes back to its tab; a keyless one leaves", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a, b = pair(m, container)
	local k = Devui.Window({ Title = "K", Manager = m, Position = q.Source(UDim2.fromOffset(700, 450)) })
	k.Parent = container
	lay(container, { a, b, k })
	dragTitle(b, 510, 310, { { 250, 200 } })
	dragTitle(k, 710, 460, { { 250, 200 } })
	q.dispose(k)
	H.resetOutput()
	assert(#((m:ExportLayout().Floating[1].Node :: any).Tabs) == 2)
	H.resetOutput()
	q.dispose(b)
	assert(frameOf(a).Visible and get(a, "Title").Visible, "A alone open: a plain look (B waits in the group)")
	assert(#((m:ExportLayout().Floating[1].Node :: any).Tabs) == 2, "B still a tab of the saved group")
	local b2 = Devui.Window({ Title = "B", Key = "b", Manager = m })
	b2.Parent = container
	lay(container, { a, b2 })
	assert(names(shownTabs({ a, b2 })) == "A,B" and frameOf(b2).Visible, "B back at its tab, selected as before")
	q.dispose(a)
	q.dispose(b2)
	q.dispose(container)
	H.resetOutput()
end)

-- ── review fixes (each section fails without its fix) ───────────────────────────────────────────────────────────

local function floatNode(tabs: { string }, x: number, w: number): any
	return { Position = { 0, x, 0, 50 }, Size = { w, 150 }, Collapsed = false, Node = { Tabs = tabs, Selected = tabs[1] } }
end
local function windowsOf(keys: { string }, open: boolean?): any
	local out = {}
	for _, k in keys do
		out[k] = { Kind = k, Open = if open == nil then true else open }
	end
	return out
end

H.section("an import never writes a state it hands in: a pending group dissolved by the import keeps the new rectangles", function()
	local m = Devui.WindowManager.new()
	m:ImportLayout({ Version = 1, Windows = windowsOf({ "a", "b" }), Floating = { floatNode({ "a", "b" }, 10, 400) } })
	m:ImportLayout({ Version = 1, Windows = windowsOf({ "a", "b" }), Floating = { floatNode({ "a" }, 111, 200), floatNode({ "b" }, 222, 210) } })
	local layout = m:ExportLayout()
	assert(#layout.Floating == 2, "two plain windows")
	local byKey: { [string]: any } = {}
	for _, g in layout.Floating do
		byKey[(g.Node :: any).Tabs[1]] = g
	end
	assert(byKey.a.Position[2] == 111 and byKey.a.Size[1] == 200, `a ({byKey.a.Position[2]}, {byKey.a.Size[1]})`)
	assert(byKey.b.Position[2] == 222 and byKey.b.Size[1] == 210, `b ({byKey.b.Position[2]}, {byKey.b.Size[1]})`)
	H.assertNoDebugOutput("import aliasing")
end)

H.section("a pending tab registering on an edge an open window holds: its group opens floating (one panel per edge)", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local w = Devui.Window({ Title = "W", Key = "w", Manager = m })
	w.Parent = container
	m:ImportWindow("w", { Kind = "w", Open = true, Collapsed = false, Dock = "Left", DockWidth = 250 })
	m:ImportLayout({ Version = 1, Windows = windowsOf({ "a", "b" }), Floating = {}, Left = { Width = 200, Collapsed = false, Node = { Tabs = { "a", "b" }, Selected = "a" } } })
	local a = Devui.Window({ Title = "A", Key = "a", Manager = m })
	local b = Devui.Window({ Title = "B", Key = "b", Manager = m })
	a.Parent = container
	b.Parent = container
	assert((m:ExportWindow("a") :: WindowState).Dock == nil and (m:ExportWindow("b") :: WindowState).Dock == nil, "the group floats")
	assert(part(w, "WindowDockStrip").Visible and not part(a, "WindowDockStrip").Visible and not part(b, "WindowDockStrip").Visible, "one strip")
	local layout = m:ExportLayout()
	assert((layout.Left :: any).Node.Tabs[1] == "w" and #layout.Floating == 1 and #(layout.Floating[1].Node :: any).Tabs == 2)
	for _, x in { w, a, b } do
		q.dispose(x)
	end
	q.dispose(container)
	H.assertNoDebugOutput("pending edge")
end)

H.section("an import that opens a tab neither selects nor focuses it: the focus stays where it was", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local ob, fb, fd = q.Source(false), q.Source(false), q.Source(false)
	local a = Devui.Window({ Title = "A", Key = "a", Manager = m })
	local b = Devui.Window({ Title = "B", Key = "b", Manager = m, Open = ob, Focused = fb })
	local d = Devui.Window({ Title = "D", Key = "d", Manager = m, Position = q.Source(UDim2.fromOffset(600, 400)), Focused = fd })
	for _, x in { a, b, d } do
		x.Parent = container
	end
	lay(container, { a, b, d })
	press(650, 410)
	assert(fd:Get() == true)
	m:ImportLayout({ Version = 1, Windows = windowsOf({ "a", "b" }), Floating = { floatNode({ "a", "b" }, 100, 300) } })
	assert(ob:Get() == true and frameOf(a).Visible and not frameOf(b).Visible, "B opened, A selected as saved")
	assert(fb:Get() == false and fd:Get() == true, "the focus did not move")
	for _, x in { a, b, d } do
		q.dispose(x)
	end
	q.dispose(container)
	H.assertNoDebugOutput("import focus")
end)

H.section("ImportWindow takes a window out of its group's lump too (its ZIndex no longer between the group's)", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a, b = pair(m, container)
	local c = Devui.Window({ Title = "C", Key = "c", Manager = m, Position = q.Source(UDim2.fromOffset(700, 450)) })
	c.Parent = container
	lay(container, { a, b, c })
	dragTitle(b, 510, 310, { { 250, 200 } })
	dragTitle(c, 710, 460, { { 250, 200 } })
	lay(container, { a, b, c })
	assert(names(shownTabs({ a, b, c })) == "A,B,C")
	m:ImportWindow("b", { Kind = "b", Open = true, Collapsed = false, Position = { 0, 300, 0, 200 }, Size = { 200, 120 } })
	local lo, hi = math.min(zOf(a), zOf(c)), math.max(zOf(a), zOf(c))
	assert(hi - lo == 3, "A and C one lump")
	assert(zOf(b) < lo or zOf(b) > hi, `B out of the lump ({zOf(a)}, {zOf(b)}, {zOf(c)})`)
	for _, x in { a, b, c } do
		q.dispose(x)
	end
	q.dispose(container)
	H.assertNoDebugOutput("import window lump")
end)

H.section("a layout cannot make a tab of a NoTitleBar window or of one in another container: placed as plain windows", function()
	local container = newContainer(1000, 700)
	local other = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a = Devui.Window({ Title = "A", Key = "a", Manager = m })
	local n = Devui.Window({ Title = "N", Key = "n", Manager = m, NoTitleBar = true })
	local c = Devui.Window({ Title = "C", Key = "c", Manager = m })
	local far = Devui.Window({ Title = "F", Key = "f", Manager = m })
	a.Parent = container
	n.Parent = container
	c.Parent = container
	far.Parent = other
	m:ImportLayout({ Version = 1, Windows = windowsOf({ "a", "n", "c", "f" }), Floating = { floatNode({ "a", "n", "c", "f" }, 100, 300) } })
	local layout = m:ExportLayout()
	local tabsOf = {}
	for _, g in layout.Floating do
		table.insert(tabsOf, table.concat((g.Node :: any).Tabs, ","))
	end
	table.sort(tabsOf)
	assert(table.concat(tabsOf, " ") == "a,c f n", table.concat(tabsOf, " "))
	assert(frameOf(n).Visible and frameOf(n).Position == UDim2.fromOffset(100, 50), "N plain at the node's rectangle")
	assert(frameOf(far).Visible and frameOf(far).Position == UDim2.fromOffset(100, 50), "F plain at the node's rectangle")
	-- the same for pending tabs when their windows come: a NoTitleBar one at once, another container's when parented
	m:ImportLayout({ Version = 1, Windows = windowsOf({ "p", "r", "s", "t" }), Floating = { floatNode({ "p", "r" }, 300, 250), floatNode({ "s", "t" }, 500, 260) } })
	local p = Devui.Window({ Title = "P", Key = "p", Manager = m })
	local r = Devui.Window({ Title = "R", Key = "r", Manager = m, NoTitleBar = true })
	local s2 = Devui.Window({ Title = "S", Key = "s", Manager = m })
	local t = Devui.Window({ Title = "T", Key = "t", Manager = m })
	p.Parent = container
	r.Parent = container
	s2.Parent = container
	t.Parent = other
	local counts = {}
	for _, g in m:ExportLayout().Floating do
		local gn: any = g.Node
		counts[gn.Tabs[1]] = #gn.Tabs
	end
	assert(counts.p == 1 and counts.r == 1 and counts.s == 1 and counts.t == 1, "no group left")
	assert(frameOf(r).Position == UDim2.fromOffset(300, 50) and frameOf(t).Position == UDim2.fromOffset(500, 50), "at their node's rectangle")
	for _, x in { a, n, c, far, p, r, s2, t } do
		q.dispose(x)
	end
	q.dispose(container)
	q.dispose(other)
	H.assertNoDebugOutput("import eligibility")
end)

H.section("dock widths: a floating group leaves each window its own; a docked group's width is shared; an import stores the fitted width", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a, b = pair(m, container)
	m:ImportWindow("a", { Kind = "a", Open = true, Collapsed = false, Dock = "Left", DockWidth = 250 })
	m:ImportWindow("a", { Kind = "a", Open = true, Collapsed = false, Position = { 0, 100, 0, 100 }, Size = { 300, 200 } })
	lay(container, { a, b })
	dragTitle(a, 150, 110, { { 600, 380 } }) -- A onto B's centre (B was never docked)
	assert(frameOf(a).Visible and frameOf(a).Position == UDim2.fromOffset(500, 300), "A joined B")
	-- the floating group docks with the drawn window's own dock width; every window follows
	lay(container, { a, b })
	dragTitle(a, 690, 308, { { 4, 308 } })
	assert((m:ExportWindow("a") :: WindowState).DockWidth == 250 and (m:ExportWindow("b") :: WindowState).DockWidth == 250, "A's kept width")
	-- torn off a docked group, a window keeps the group's width
	lay(container, { a, b })
	local tb = tabOf(b)
	local x, y = tb.AbsolutePosition.X + 5, tb.AbsolutePosition.Y + 5
	dragTab(b, x, y, { { x + 600, y + 400 } })
	assert(frameOf(b).Visible and not part(b, "WindowDockStrip").Visible, "B floats")
	lay(container, { a, b })
	dragTitle(b, 650, 410, { { 995, 300 } }) -- B docks right with the width it keeps
	assert((m:ExportLayout().Right :: any).Width == 250, `B docks at 250 ({(m:ExportLayout().Right :: any).Width})`)
	q.dispose(a)
	q.dispose(b)
	q.dispose(container)
	-- an import docking a live group into a narrow container stores the width that fits (half the container)
	local narrow = newContainer(400, 600)
	local m2 = Devui.WindowManager.new()
	local c = Devui.Window({ Title = "C", Key = "c", Manager = m2 })
	local d = Devui.Window({ Title = "D", Key = "d", Manager = m2 })
	c.Parent = narrow
	d.Parent = narrow
	m2:ImportLayout({ Version = 1, Windows = windowsOf({ "c", "d" }), Floating = {}, Left = { Width = 300, Collapsed = false, Node = { Tabs = { "c", "d" }, Selected = "c" }, Position = { 0, 10, 0, 10 }, Size = { 200, 150 } } })
	local left = m2:ExportLayout().Left :: any
	assert(left ~= nil and left.Width == 200, `the fitted width ({left and left.Width})`)
	q.dispose(c)
	q.dispose(d)
	q.dispose(narrow)
	H.assertNoDebugOutput("dock widths")
end)

H.section("drop occlusion: the window on top under the pointer decides — a NoTitleBar window or an icon over a target covers it", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a, b = pair(m, container)
	local bare = Devui.Window({ Title = "N", Key = "n", Manager = m, NoTitleBar = true, Position = q.Source(UDim2.fromOffset(200, 170)), Size = q.Source(Vector2.new(100, 60)) })
	local iconWin = Devui.Window({ Title = "I", Key = "i", Manager = m, Collapsed = q.Source(true), Position = q.Source(UDim2.fromOffset(300, 250)) })
	bare.Parent = container
	iconWin.Parent = container
	lay(container, { a, b, bare, iconWin })
	dragTitle(b, 510, 310, { { 250, 200 } }, true) -- over the NoTitleBar window over A's centre
	assert(previewOf(b) == nil, "covered by the NoTitleBar window")
	moveTo(310, 260) -- over the icon over A's centre
	assert(previewOf(b) == nil, "covered by the icon")
	moveTo(180, 150) -- A's centre, uncovered
	assert(previewOf(b) ~= nil, "A itself")
	moveTo(250, 200)
	release(250, 200)
	assert(tabOf(a).Visible == false and frameOf(a).Visible, "released over the cover: nothing joined")
	for _, x in { a, b, bare, iconWin } do
		q.dispose(x)
	end
	q.dispose(container)
	H.assertNoDebugOutput("occlusion")
end)

H.section("a group drag rebuilds the layout once per move (not once per window)", function()
	local LayoutModule = require("../src/Window/Layout") :: any
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a, b = pair(m, container)
	local c = Devui.Window({ Title = "C", Key = "c", Manager = m, Position = q.Source(UDim2.fromOffset(700, 450)) })
	c.Parent = container
	lay(container, { a, b, c })
	dragTitle(b, 510, 310, { { 250, 200 } })
	dragTitle(c, 710, 460, { { 250, 200 } })
	local builds = 0
	local original = LayoutModule.build
	LayoutModule.build = function(...)
		builds += 1
		return original(...)
	end
	dragTitle(c, 390, 108, { { 395, 108 } }, true)
	local before = builds
	moveTo(420, 140)
	local perMove = builds - before
	release(420, 140)
	LayoutModule.build = original
	assert(perMove == 1, `one layout build per move ({perMove})`)
	for _, x in { a, b, c } do
		q.dispose(x)
	end
	q.dispose(container)
	H.assertNoDebugOutput("one refresh")
end)

H.section("layout validation for tab groups", function()
	local m = Devui.WindowManager.new()
	local function bad(layout: any, expect: string)
		local e = err(function()
			m:ImportLayout(layout)
		end)
		assert(string.find(e, "Devui.WindowManager:ImportLayout: " .. expect, 1, true) ~= nil, `{expect}: {e}`)
	end
	local function node(tabs: { string }, selected: string): any
		return { Position = { 0, 0, 0, 0 }, Size = { 100, 100 }, Collapsed = false, Node = { Tabs = tabs, Selected = selected } }
	end
	local wab = { a = { Kind = "a", Open = true }, b = { Kind = "b", Open = true } }
	bad({ Version = 1, Windows = wab, Floating = { node({ "a", "b", "a" }, "a") } }, 'layout.Floating[1].Node.Tabs lists "a" twice')
	bad({ Version = 1, Windows = wab, Floating = { node({ "a", "b" }, "c") } }, "layout.Floating[1].Node: Selected must be one of its Tabs")
	bad({ Version = 1, Windows = wab, Floating = { node({}, "a") } }, "layout.Floating[1].Node.Tabs must be a non-empty array")
	bad({ Version = 1, Windows = wab, Floating = { node({ "a", 5 :: any }, "a") } }, "layout.Floating[1].Node.Tabs[2] must be a string key")
	bad({ Version = 1, Windows = wab, Floating = { node({ "a", "b" }, "a"), node({ "b" }, "b") } }, 'window "b" is placed twice in the layout (layout.Floating[1] and layout.Floating[2])')
	bad({ Version = 1, Windows = wab, Floating = { node({ "a" }, "a") }, Left = { Width = 100, Collapsed = false, Node = { Tabs = { "b", "a" }, Selected = "b" } } }, 'window "a" is placed twice in the layout (layout.Left and layout.Floating[1])')
	bad({ Version = 1, Windows = { a = { Kind = "a", Open = true, Position = { 0, 0 } }, b = wab.b }, Floating = { node({ "a", "b" }, "a") } }, 'layout.Windows["a"].Position must be an array of 4 numbers')
	bad({ Version = 1, Windows = { a = { Kind = "a", Open = true, Size = { 1, 0 / 0 } }, b = wab.b }, Floating = { node({ "a", "b" }, "a") } }, 'layout.Windows["a"].Size must be an array of 2 numbers')
	-- a docked tab group reads back; one key per node across Floating / Left / Right
	m:ImportLayout({ Version = 1, Windows = wab, Floating = {}, Right = { Width = 200, Collapsed = true, Node = { Tabs = { "b", "a" }, Selected = "a" } } })
	local right = m:ExportLayout().Right :: any
	assert(right ~= nil and right.Node.Tabs[1] == "b" and right.Node.Selected == "a" and right.Collapsed == true, "pending docked group exported")
	assert((m:ExportWindow("a") :: WindowState).Dock == "Right" and (m:ExportWindow("a") :: WindowState).Collapsed == true, "its windows' states")
	H.assertNoDebugOutput("validation")
end)

H.done()
