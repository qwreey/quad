--!strict
-- Window splits (docking stage 4): a leaf's band splits it in half (the preview covers that half; a corner goes to the
-- deeper side), a split unit's outer band splits its root (the long preview), the strip row wins over the outer band,
-- nested splits, the splitter and its floors (one layout build per move), folding a leaf on both axes, the fold rule
-- (a lone leaf and a second folded side unfold, a refused fold is written back, a pending key counts only when saved
-- open), the window Collapsed Sources (a collapsed docked panel records an app's fold), tab strips in every leaf, the
-- whole unit moved by a strip's empty area (undocked: the pointer keeps its share of the width and its place in the
-- pressed leaf), a whole split dragged in as tabs or as one side, tearing a tab out (the leaf goes, the split
-- dissolves), a closed leaf keeps its slot, joining a docked split by the held edge (its last-focused leaf, else its
-- first), a docked top / bottom split, drop judging (an unselected tab, a splitter), a forgotten key destroyed, the
-- parts a NoTitleBar / NoResize window has, the layout of splits (and README's example), validation, eligibility on
-- import, ImportWindow out of a split.
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Devui = require("../src")
local Compositor = require("../src/Window/Compositor")

local lune = require :: any
local serde = lune("@lune/serde")

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
local function splitterOf(win: Instance): any
	return part(win, "WindowSplitter")
end
local function previewOf(win: Instance): any
	local p = part(win, "WindowDockPreview")
	return if p ~= nil and p.Visible then p else nil
end
local function rect(x: number, y: number, w: number, h: number): (UDim2, UDim2)
	return UDim2.fromOffset(x, y), UDim2.fromOffset(w, h)
end
-- the frame of `win` is at that rectangle
local function at(win: Instance, x: number, y: number, w: number, h: number): boolean
	local f = frameOf(win)
	local p, s = rect(x, y, w, h)
	return f.Visible == true and f.Position == p and f.Size == s
end
local function where(win: Instance): string
	local f = frameOf(win)
	return `{f.Position} {f.Size} visible={f.Visible}`
end
local function previewIs(win: Instance, x: number, y: number, w: number, h: number): boolean
	local pv = previewOf(win)
	local p, s = rect(x, y, w, h)
	return pv ~= nil and pv.Position == p and pv.Size == s
end

local function newContainer(w: number, h: number): any
	local screen = Instance.new("ScreenGui")
	screen.Parent = Instance.new("Folder")
	local container = Instance.new("Frame")
	container.Parent = screen
	H.setAbs(container, 0, 0, w, h)
	return container
end

-- a layout-engine stand-in: every window's frame / tab / icon / strip / splitter / fold bar and surface get the
-- on-screen rectangle their UDim2s say in the container (remembered: `relay` lays every window laid so far again,
-- before each gesture)
local laid: { [any]: { Instance } } = {}
local LAID = { WindowDecoration = true, WindowTab = true, WindowIcon = true, WindowDockStrip = true, WindowSplitter = true, WindowFoldBar = true }
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
	for _, win in list do
		if H.isDestroyed(win) then
			continue
		end
		place(win)
		for _, p: any in Compositor.partsOf(win) do
			if LAID[p.Name] then
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

-- drag `win`'s title bar (or its strip's empty area) from (x0, y0) through `path`; release at the last point unless
-- keepDown
local function dragTitle(win: Instance, x0: number, y0: number, path: { { number } }, keepDown: boolean?)
	relay()
	press(x0, y0)
	H.fire(get(win, "TitleBar"), "InputBegan", mouse(M1, x0, y0))
	local last = { x0, y0 }
	for _, p in path do
		moveTo(p[1], p[2])
		relay()
		last = p
	end
	if not keepDown then
		release(last[1], last[2])
	end
	relay()
end
-- the same on a window's tab (press = select, drag = reorder / tear off)
local function dragTab(win: Instance, path: { { number } }, keepDown: boolean?)
	relay()
	local t = tabOf(win)
	local x0, y0 = t.AbsolutePosition.X + 5, t.AbsolutePosition.Y + 5
	press(x0, y0)
	H.fire(t, "InputBegan", mouse(M1, x0, y0))
	local last = { x0, y0 }
	for _, p in path do
		local x, y = x0 + p[1], y0 + p[2]
		moveTo(x, y)
		relay()
		last = { x, y }
	end
	if not keepDown then
		release(last[1], last[2])
	end
	relay()
end
-- drag `win`'s splitter by (dx, dy)
local function dragSplitter(win: Instance, dx: number, dy: number)
	relay()
	local sp = splitterOf(win)
	assert(sp.Visible, "the splitter shows")
	local x0, y0 = sp.AbsolutePosition.X + 2, sp.AbsolutePosition.Y + 2
	press(x0, y0)
	H.fire(sp, "InputBegan", mouse(M1, x0, y0))
	moveTo(x0 + dx, y0 + dy)
	release(x0 + dx, y0 + dy)
	relay()
end
local function clickArrow(win: Instance)
	H.fire(get(win, "CollapseButton"), "Activated", H.input({}), 1)
	relay()
end

local function zOf(win: Instance): number
	return (win :: any).ZIndex
end

type Win = { win: Instance, pos: any, size: any, open: any, collapsed: any }
local function window(m: any, container: any, key: string, x: number, y: number, w: number, h: number, extra: { [string]: any }?): Win
	local s: Win = {
		win = nil :: any,
		pos = q.Source(UDim2.fromOffset(x, y)),
		size = q.Source(Vector2.new(w, h)),
		open = q.Source(true),
		collapsed = q.Source(false),
	}
	local props: { [string]: any } = {
		Title = string.upper(key),
		Key = key,
		Manager = m,
		Position = s.pos,
		Size = s.size,
		Open = s.open,
		Collapsed = s.collapsed,
	}
	for k, v in extra or {} do
		props[k] = v
	end
	s.win = Devui.Window(props :: any)
	s.win.Parent = container
	lay(container, { s.win })
	return s
end
local function disposeAll(container: any, wins: { Win })
	for _, w in wins do
		q.dispose(w.win)
	end
	q.dispose(container)
end
local function nodeOf(layout: any, i: number?): any
	return layout.Floating[i or 1].Node
end

H.section("a leaf's band splits it in half: the preview covers that half; one unit, the target keeps its rectangle (all four sides)", function()
	-- side, pointer, the preview (B's half), A's half after the drop, the saved children order
	local cases = {
		{ "Right", 390, 200, { 250, 100, 150, 200 }, { 100, 100, 150, 200 }, "LeftRight", "a,b" },
		{ "Left", 120, 200, { 100, 100, 150, 200 }, { 250, 100, 150, 200 }, "LeftRight", "b,a" },
		{ "Top", 250, 125, { 100, 100, 300, 100 }, { 100, 200, 300, 100 }, "TopBottom", "b,a" },
		{ "Bottom", 250, 290, { 100, 200, 300, 100 }, { 100, 100, 300, 100 }, "TopBottom", "a,b" },
	}
	for _, c in cases do
		local container = newContainer(1000, 700)
		local m = Devui.WindowManager.new()
		local a = window(m, container, "a", 100, 100, 300, 200)
		local b = window(m, container, "b", 500, 300, 200, 150)
		local px, py = c[2] :: number, c[3] :: number
		local pv, ah = c[4] :: { number }, c[5] :: { number }
		dragTitle(b.win, 510, 310, { { 300, 250 }, { px, py } }, true)
		assert(previewIs(b.win, pv[1], pv[2], pv[3], pv[4]), `{c[1]}: the preview covers the half B takes`)
		release(px, py)
		relay()
		assert(previewOf(b.win) == nil, "released: the preview closes")
		assert(at(a.win, ah[1], ah[2], ah[3], ah[4]), `{c[1]}: A keeps its half ({where(a.win)})`)
		assert(at(b.win, pv[1], pv[2], pv[3], pv[4]), `{c[1]}: B in the other half ({where(b.win)})`)
		assert((a.win :: any).Visible and (b.win :: any).Visible, "both surfaces show")
		assert((b.win :: any).Position == UDim2.fromOffset(pv[1], pv[2] + 19), "B's surface under its strip")
		-- the Position / Size Sources keep their own rectangles
		assert(a.pos:Get() == UDim2.fromOffset(100, 100) and b.pos:Get() == UDim2.fromOffset(500, 300) and b.size:Get() == Vector2.new(200, 150))
		local layout = m:ExportLayout()
		assert(#layout.Floating == 1, "one unit")
		local node = nodeOf(layout)
		assert(node.Split == c[6] and node.Ratio == 0.5, `{c[1]}: {node.Split} {node.Ratio}`)
		assert(node.Children[1].Tabs[1] .. "," .. node.Children[2].Tabs[1] == c[7], `{c[1]}: children order`)
		local g = layout.Floating[1]
		assert(g.Position[2] == 100 and g.Position[4] == 100 and g.Size[1] == 300 and g.Size[2] == 200 and g.Collapsed == false, "A's rectangle is the unit's")
		assert(layout.Windows.b.Position ~= nil and layout.Windows.b.Position[2] == 500, "B's own rectangle saved")
		disposeAll(container, { a, b })
	end
	H.assertNoDebugOutput("leaf bands")
end)

H.section("every leaf of a split shows its tab strip, even with one window; one z lump; the focused leaf's strip is active", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a = window(m, container, "a", 100, 100, 300, 200)
	local b = window(m, container, "b", 500, 300, 200, 150)
	local d = window(m, container, "d", 600, 450, 200, 150)
	dragTitle(b.win, 510, 310, { { 390, 200 } })
	for _, w in { a, b } do
		assert(tabOf(w.win).Visible and get(w.win, "Title").Visible == false, "a tab, the title hidden")
	end
	local tax = tabOf(a.win).Position.X.Offset
	assert(tabOf(a.win).Position.Y == UDim.new(0, 100) and tax > 100 and tax + tabOf(a.win).Size.X.Offset <= 250, "A's tab in A's strip row")
	assert(tabOf(b.win).Position.X.Offset > 250 and tabOf(b.win).Position.Y.Offset == 100, "B's tab in B's strip row")
	-- one lump: D pressed goes over both; the unit pressed goes over D
	press(650, 500)
	assert(zOf(d.win) > zOf(a.win) and zOf(d.win) > zOf(b.win))
	assert(tabOf(a.win).ZIndex < frameOf(d.win).ZIndex and splitterOf(b.win).ZIndex < frameOf(d.win).ZIndex, "its tabs and splitter too")
	press(150, 250) -- A's surface
	assert(zOf(a.win) > zOf(d.win) and zOf(b.win) > zOf(d.win) and math.abs(zOf(a.win) - zOf(b.win)) == 3, "raised as one lump")
	assert(splitterOf(b.win).ZIndex >= frameOf(a.win).ZIndex + 2 and splitterOf(b.win).ZIndex >= frameOf(b.win).ZIndex + 2, "the splitter over both sides")
	-- the focused window is the pressed leaf's; only its strip has the active colour
	local style = Devui.Style.default
	assert(get(a.win, "TitleBar").BackgroundColor3 == style.Color.TitleBgActive:Get(), "A's strip active")
	assert(get(b.win, "TitleBar").BackgroundColor3 == style.Color.TitleBg:Get(), "B's not")
	press(300, 250) -- B's surface
	assert(get(b.win, "TitleBar").BackgroundColor3 == style.Color.TitleBgActive:Get() and get(a.win, "TitleBar").BackgroundColor3 == style.Color.TitleBg:Get())
	-- only the corner leaf (B) draws the unit's grip, at the unit's corner
	assert(part(b.win, "WindowResizeGrip").Visible and not part(a.win, "WindowResizeGrip").Visible)
	assert(part(b.win, "WindowResizeGrip").Position == UDim2.fromOffset(400, 300))
	disposeAll(container, { a, b, d })
	H.assertNoDebugOutput("strips")
end)

H.section("the outer band splits the root (the long preview): explorer / props top-bottom, then output on the right", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local e = window(m, container, "explorer", 100, 100, 300, 400)
	local p = window(m, container, "props", 500, 100, 200, 150)
	local o = window(m, container, "output", 600, 450, 250, 150)
	dragTitle(p.win, 510, 110, { { 250, 470 } }) -- E's bottom band
	assert(at(e.win, 100, 100, 300, 200) and at(p.win, 100, 300, 300, 200), `explorer over props ({where(e.win)} / {where(p.win)})`)
	-- inside P's leaf (past the outer band): P's own left band splits P — its left half
	dragTitle(o.win, 610, 460, { { 300, 300 }, { 150, 400 } }, true)
	assert(previewIs(o.win, 100, 300, 150, 200), "a leaf band inside the split: half of P")
	-- the unit's right outer band (2 x 19 inside its right edge), over P's body: half of the WHOLE unit
	moveTo(390, 420)
	assert(previewIs(o.win, 250, 100, 150, 400), "the outer band: the long preview")
	-- the strip row wins over the outer band: E's strip row at the right end joins as a tab (preview = E's leaf)
	moveTo(390, 108)
	assert(previewIs(o.win, 100, 100, 300, 200), "strip row over the outer band: joins E's leaf")
	moveTo(390, 200)
	assert(previewIs(o.win, 250, 100, 150, 400), "back in the outer band over E's body")
	release(390, 200)
	relay()
	assert(at(e.win, 100, 100, 150, 200) and at(p.win, 100, 300, 150, 200) and at(o.win, 250, 100, 150, 400), `the root split ({where(e.win)} / {where(p.win)} / {where(o.win)})`)
	local node = nodeOf(m:ExportLayout())
	assert(node.Split == "LeftRight" and node.Children[1].Split == "TopBottom" and node.Children[2].Tabs[1] == "output")
	assert(node.Children[1].Children[1].Tabs[1] == "explorer" and node.Children[1].Children[2].Tabs[1] == "props")
	-- the left outer band
	local d = window(m, container, "d", 600, 550, 200, 120)
	dragTitle(d.win, 610, 560, { { 110, 250 } }, true)
	assert(previewIs(d.win, 100, 100, 150, 400), "the left outer band")
	release(110, 250)
	relay()
	local root = nodeOf(m:ExportLayout())
	assert(root.Split == "LeftRight" and root.Children[1].Tabs[1] == "d" and root.Children[2].Split == "LeftRight", "d split off the root's left")
	disposeAll(container, { e, p, o, d })
	H.assertNoDebugOutput("outer band")
end)

H.section("nested splits: a leaf of a split splits again; ExportLayout keeps the tree", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a = window(m, container, "a", 100, 100, 400, 300)
	local b = window(m, container, "b", 600, 100, 200, 150)
	local c = window(m, container, "c", 600, 400, 200, 150)
	dragTitle(b.win, 610, 110, { { 480, 250 } }) -- A's right band: A | B
	assert(at(a.win, 100, 100, 200, 300) and at(b.win, 300, 100, 200, 300))
	dragTitle(c.win, 610, 410, { { 400, 350 } }) -- B's bottom band (clear of the unit's outer band)
	assert(at(b.win, 300, 100, 200, 150) and at(c.win, 300, 250, 200, 150), `B over C ({where(b.win)} / {where(c.win)})`)
	local node = nodeOf(m:ExportLayout())
	assert(node.Split == "LeftRight" and node.Children[1].Tabs[1] == "a" and node.Children[2].Split == "TopBottom")
	assert(node.Children[2].Children[1].Tabs[1] == "b" and node.Children[2].Children[2].Tabs[1] == "c")
	-- the splitters: B draws the A | (B / C) one, C draws the B / C one
	assert(splitterOf(b.win).Visible and splitterOf(b.win).Position == UDim2.fromOffset(300, 100) and splitterOf(b.win).Size == UDim2.fromOffset(6, 300))
	assert(splitterOf(c.win).Visible and splitterOf(c.win).Position == UDim2.fromOffset(300, 244) and splitterOf(c.win).Size == UDim2.fromOffset(200, 6))
	assert(not splitterOf(a.win).Visible, "A draws none")
	-- the unit's grip floors at the tree: along x A + (B / C), across the larger
	local grip = part(c.win, "WindowResizeGrip")
	assert(grip.Visible and not part(b.win, "WindowResizeGrip").Visible, "the corner leaf (C) draws the grip")
	relay()
	H.fire(grip, "InputBegan", mouse(M1, 495, 395))
	moveTo(-1000, -1000)
	release(-1000, -1000)
	relay()
	assert(frameOf(a.win).Size == UDim2.fromOffset(38, 76), `the floor: 38 + 38 wide, 38 + 38 tall ({frameOf(a.win).Size})`)
	disposeAll(container, { a, b, c })
	H.assertNoDebugOutput("nested")
end)

H.section("the splitter moves the seam, kept above both sides' floors; Ratio is saved", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a = window(m, container, "a", 100, 100, 300, 200, { MinSize = Vector2.new(80, 50) })
	local b = window(m, container, "b", 500, 300, 200, 150, { MinSize = Vector2.new(100, 50) })
	dragTitle(b.win, 510, 310, { { 390, 200 } })
	assert(at(a.win, 100, 100, 150, 200) and at(b.win, 250, 100, 150, 200))
	dragSplitter(b.win, 30, 0)
	assert(at(a.win, 100, 100, 180, 200) and at(b.win, 280, 100, 120, 200), `moved ({where(a.win)})`)
	assert(math.abs(nodeOf(m:ExportLayout()).Ratio - 0.6) < 1e-6, "Ratio = A's share")
	dragSplitter(b.win, 500, 0)
	assert(at(a.win, 100, 100, 200, 200) and at(b.win, 300, 100, 100, 200), `B stops at its floor ({where(b.win)})`)
	dragSplitter(b.win, -1000, 0)
	assert(at(a.win, 100, 100, 80, 200) and at(b.win, 180, 100, 220, 200), `A stops at its floor ({where(a.win)})`)
	-- a top / bottom split: the splitter is over the first side's bottom
	local container2 = newContainer(1000, 700)
	local m2 = Devui.WindowManager.new()
	local c = window(m2, container2, "c", 100, 100, 300, 200)
	local d = window(m2, container2, "d", 500, 300, 200, 150)
	dragTitle(d.win, 510, 310, { { 250, 290 } })
	assert(splitterOf(d.win).Position == UDim2.fromOffset(100, 194) and splitterOf(d.win).Size == UDim2.fromOffset(300, 6))
	dragSplitter(d.win, 0, -40)
	assert(at(c.win, 100, 100, 300, 60) and at(d.win, 100, 160, 300, 140), `top / bottom moved ({where(c.win)})`)
	-- the unit's resize keeps the ratio and the floors
	disposeAll(container, { a, b })
	disposeAll(container2, { c, d })
	H.assertNoDebugOutput("splitter")
end)

H.section("folding a leaf: its strip row (top / bottom) or a bar (left | right); the sibling takes the space; the splitter hides", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a = window(m, container, "a", 100, 100, 300, 200)
	local b = window(m, container, "b", 500, 300, 200, 150)
	dragTitle(b.win, 510, 310, { { 250, 290 } }) -- A over B
	clickArrow(a.win)
	assert(a.collapsed:Get() == true and b.collapsed:Get() == false, "A's Collapsed: its leaf's fold")
	assert(at(a.win, 100, 100, 300, 19) and at(b.win, 100, 119, 300, 181), `A keeps its row ({where(a.win)} / {where(b.win)})`)
	assert(not (a.win :: any).Visible and (b.win :: any).Visible, "A's surface hides")
	assert(tabOf(a.win).Visible and get(a.win, "TitleBar").Visible, "its strip row and tab stay")
	assert(H.find(get(a.win, "CollapseButton"), "Icon").Rotation == -90, "the arrow points right")
	assert(not splitterOf(b.win).Visible, "the splitter hides while a side is folded")
	assert(part(a.win, "WindowIcon").Visible == false and part(b.win, "WindowIcon").Visible == false, "a floating split unit never becomes an icon")
	clickArrow(a.win)
	assert(a.collapsed:Get() == false and at(a.win, 100, 100, 300, 100) and splitterOf(b.win).Visible, "unfolded")
	-- an app writing a window's Collapsed folds its leaf (the other leaf is untouched)
	b.collapsed:Set(true)
	relay()
	assert(at(a.win, 100, 100, 300, 181) and at(b.win, 100, 281, 300, 19), `B folded at the bottom ({where(b.win)})`)
	assert(a.collapsed:Get() == false)
	b.collapsed:Set(false)
	relay()
	assert(at(b.win, 100, 200, 300, 100))
	disposeAll(container, { a, b })

	-- left | right: the folded leaf is a bar FrameHeight wide with the arrow; pressing it unfolds
	local container2 = newContainer(1000, 700)
	local m2 = Devui.WindowManager.new()
	local c = window(m2, container2, "c", 100, 100, 300, 200)
	local d = window(m2, container2, "d", 500, 300, 200, 150)
	dragTitle(d.win, 510, 310, { { 390, 200 } }) -- C | D
	clickArrow(d.win)
	assert(at(c.win, 100, 100, 281, 200) and at(d.win, 381, 100, 19, 200), `D a bar on the right ({where(d.win)})`)
	local bar = part(d.win, "WindowFoldBar")
	assert(bar.Visible and bar.Position == UDim2.fromOffset(381, 100) and bar.Size == UDim2.fromOffset(19, 200))
	assert(H.find(bar, "Arrow").Rotation == 180, "pointing left, where it opens")
	assert(get(d.win, "TitleBar").Visible == false and tabOf(d.win).Visible == false and not (d.win :: any).Visible, "no row, no tab, no surface")
	assert(not splitterOf(d.win).Visible)
	H.fire(bar, "Activated", H.input({}), 1)
	relay()
	assert(d.collapsed:Get() == false and at(d.win, 250, 100, 150, 200) and not part(d.win, "WindowFoldBar").Visible, "the bar unfolds it")
	-- the first side folded: a bar on the left, pointing right
	c.collapsed:Set(true)
	relay()
	assert(at(c.win, 100, 100, 19, 200) and at(d.win, 119, 100, 281, 200) and H.find(part(c.win, "WindowFoldBar"), "Arrow").Rotation == 0)
	-- both sides folded is refused (the fold rule): D's arrow is not offered, an app's true is written back
	assert(get(d.win, "CollapseButton").Visible == false, "no arrow where folding is refused")
	d.collapsed:Set(true)
	relay()
	assert(d.collapsed:Get() == false and at(c.win, 100, 100, 19, 200) and at(d.win, 119, 100, 281, 200), `refused ({where(d.win)})`)
	disposeAll(container2, { c, d })
	H.assertNoDebugOutput("fold")
end)

H.section("a docked split: top / bottom stacking on the side; the panel collapses as a whole and keeps the leaves' folds", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a = window(m, container, "a", 100, 100, 300, 200)
	local b = window(m, container, "b", 500, 300, 200, 150)
	dragTitle(a.win, 150, 110, { { 3, 110 } }) -- A docks left
	assert(part(a.win, "WindowDockStrip").Visible)
	-- B on the docked panel's bottom band: the preview is the panel's bottom half (its height is the container's)
	dragTitle(b.win, 510, 310, { { 150, 650 } }, true)
	local pv = previewOf(b.win)
	assert(pv ~= nil and pv.Position == UDim2.new(0, 19, 0.5, 0) and pv.Size == UDim2.new(0, 300, 0.5, 0), `the panel's bottom half ({pv and pv.Position})`)
	release(150, 650)
	relay()
	assert(frameOf(a.win).Position == UDim2.new(0, 19, 0, 0) and frameOf(a.win).Size == UDim2.new(0, 300, 0.5, 0), `A on top ({where(a.win)})`)
	assert(frameOf(b.win).Position == UDim2.new(0, 19, 0.5, 0) and frameOf(b.win).Size == UDim2.new(0, 300, 0.5, 0), `B under ({where(b.win)})`)
	assert((m:ExportWindow("b") :: WindowState).Dock == "Left", "B docked with the unit")
	local left = m:ExportLayout().Left :: any
	assert(left ~= nil and left.Node.Split == "TopBottom" and left.Node.Children[2].Tabs[1] == "b" and #m:ExportLayout().Floating == 0)
	-- one strip and one width handle (the corner leaf's), the splitter between the leaves
	assert(part(b.win, "WindowDockStrip").Visible and not part(a.win, "WindowDockStrip").Visible)
	assert(part(b.win, "WindowDockResize").Visible and not part(a.win, "WindowDockResize").Visible)
	assert(splitterOf(b.win).Visible and splitterOf(b.win).Position == UDim2.new(0, 19, 0.5, -6) and splitterOf(b.win).Size == UDim2.new(0, 300, 0, 6))
	-- the width handle widens both leaves at once (not only the handle)
	local handle = part(b.win, "WindowDockResize")
	local hx, hy = handle.AbsolutePosition.X + 2, 300
	press(hx, hy)
	H.fire(handle, "InputBegan", mouse(M1, hx, hy))
	moveTo(hx + 80, hy)
	release(hx + 80, hy)
	relay()
	assert(frameOf(a.win).Size == UDim2.new(0, 380, 0.5, 0) and frameOf(b.win).Size == UDim2.new(0, 380, 0.5, 0), `both leaves 380 wide ({where(a.win)} / {where(b.win)})`)
	assert(part(b.win, "WindowDockResize").Position == UDim2.fromOffset(19 + 380, 0) and splitterOf(b.win).Size == UDim2.new(0, 380, 0, 6), "the handle and the splitter follow")
	assert((m:ExportLayout().Left :: any).Width == 380, "saved as shown")
	-- the splitter on the panel: 700 tall, 100 px up = Ratio (350 - 100) / 700
	dragSplitter(b.win, 0, -100)
	assert(math.abs((m:ExportLayout().Left :: any).Node.Ratio - 250 / 700) < 1e-6, "the ratio of the panel's height")
	-- fold A, then collapse the panel by its strip (B focused: a press on the strip collapses)
	clickArrow(a.win)
	assert(a.collapsed:Get() == true and b.collapsed:Get() == false and frameOf(b.win).Position == UDim2.new(0, 19, 0, 19), `A folded ({where(b.win)})`)
	press(300, 500)
	local strip = part(b.win, "WindowDockStrip")
	press(5, 300)
	H.fire(strip, "Activated", mouse(M1, 5, 300), 1)
	relay()
	assert(a.collapsed:Get() and b.collapsed:Get(), "the panel collapsed: every window's Collapsed")
	assert(not frameOf(a.win).Visible and not frameOf(b.win).Visible and strip.Visible, "only the strip stays")
	press(5, 300)
	H.fire(strip, "Activated", mouse(M1, 5, 300), 1)
	relay()
	assert(a.collapsed:Get() == true and b.collapsed:Get() == false and frameOf(b.win).Visible, "expanded: A's fold kept")
	-- an app writing false on a window of a collapsed panel expands the panel and unfolds that window's leaf
	press(300, 500)
	press(5, 300)
	H.fire(strip, "Activated", mouse(M1, 5, 300), 1)
	assert(b.collapsed:Get() == true)
	a.collapsed:Set(false)
	relay()
	assert(a.collapsed:Get() == false and b.collapsed:Get() == false and frameOf(a.win).Visible and frameOf(b.win).Visible, "expanded and unfolded")
	disposeAll(container, { a, b })
	H.assertNoDebugOutput("docked split")
end)

H.section("a strip's empty area moves the whole unit (floating and docked); a tab dragged out leaves its leaf", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a = window(m, container, "a", 100, 100, 300, 200)
	local b = window(m, container, "b", 500, 300, 200, 150)
	dragTitle(b.win, 510, 310, { { 390, 200 } }) -- A | B
	dragTitle(a.win, 245, 108, { { 295, 158 } }) -- A's strip, right of its tab
	assert(at(a.win, 150, 150, 150, 200) and at(b.win, 300, 150, 150, 200), `the whole unit moved ({where(a.win)})`)
	assert(a.pos:Get() == UDim2.fromOffset(100, 100), "A's own Sources untouched")
	-- docked: dragged off the edge, the whole unit floats at its floating rectangle
	dragTitle(b.win, 445, 158, { { 3, 158 } })
	assert((m:ExportWindow("a") :: WindowState).Dock == "Left" and (m:ExportWindow("b") :: WindowState).Dock == "Left", "the unit docked")
	assert(frameOf(a.win).Position == UDim2.new(0, 19, 0, 0) and frameOf(b.win).Position == UDim2.new(0, 169, 0, 0))
	dragTitle(a.win, 140, 8, { { 145, 12 }, { 400, 300 } })
	assert((m:ExportWindow("a") :: WindowState).Dock == nil and (m:ExportWindow("b") :: WindowState).Dock == nil, "undocked as a whole")
	assert(frameOf(a.win).Size == UDim2.fromOffset(150, 200) and frameOf(b.win).Size == UDim2.fromOffset(150, 200), "at the floating size, still split")
	local fa = frameOf(a.win).Position
	-- (the dock width was the floating width here: the share and the pixel spot agree — the section below tells them apart)
	assert(math.abs(fa.X.Offset + 0.4 * 300 - 400) <= 1 and fa.Y.Offset == 300 - 8, `the pointer keeps its place ({fa})`)
	-- a tab dragged out of its row: B floats at its own size; A alone is a plain window at the unit's rectangle
	local unitPos = frameOf(a.win).Position
	dragTab(b.win, { { 0, 3 }, { 0, 300 } }, true)
	assert(b.size:Get() == Vector2.new(200, 150) and at(b.win, frameOf(b.win).Position.X.Offset, frameOf(b.win).Position.Y.Offset, 200, 150), "B at its own size")
	assert(tabOf(b.win).Visible == false and get(b.win, "Title").Visible, "B plain")
	release(0, 0)
	assert(a.pos:Get() == unitPos and a.size:Get() == Vector2.new(300, 200), "A takes the unit's rectangle")
	assert(tabOf(a.win).Visible == false and get(a.win, "Title").Visible and at(a.win, unitPos.X.Offset, unitPos.Y.Offset, 300, 200), "A plain")
	assert(#m:ExportLayout().Floating == 2)
	disposeAll(container, { a, b })
	H.assertNoDebugOutput("move / detach")
end)

H.section("leaving a leaf: its leaf goes and the sibling takes the parent's place; the last split dissolves into a tab group", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local e = window(m, container, "explorer", 100, 100, 300, 400)
	local p = window(m, container, "props", 500, 100, 200, 150)
	local o = window(m, container, "output", 600, 450, 250, 150)
	local t = window(m, container, "tools", 650, 300, 200, 100)
	dragTitle(p.win, 510, 110, { { 250, 470 } }) -- E / P
	dragTitle(o.win, 610, 460, { { 390, 200 } }) -- (E / P) | O
	dragTitle(t.win, 660, 310, { { 200, 108 } }) -- T a tab of E's leaf
	assert(tabOf(t.win).Visible and frameOf(t.win).Visible and not frameOf(e.win).Visible, "T selected in E's leaf")
	-- O out: the root is E / P again, at the unit's rectangle
	dragTab(o.win, { { 0, 3 }, { 0, 500 } })
	assert(at(t.win, 100, 100, 300, 200) and at(p.win, 100, 300, 300, 200), `E / P again ({where(t.win)})`)
	local node = nodeOf(m:ExportLayout(), 1)
	assert(node.Split == "TopBottom", "still split")
	-- P out: E's leaf is the root — a tab group of E and T (no split), at the unit's rectangle
	dragTab(p.win, { { 0, 3 }, { 0, 400 } })
	relay()
	assert(at(t.win, 100, 100, 300, 400), `a tab group again ({where(t.win)})`)
	local after = m:ExportLayout()
	local group: any = nil
	for _, g in after.Floating do
		local n: any = g.Node
		if n.Tabs ~= nil and #n.Tabs == 2 then
			group = n
		end
	end
	assert(group ~= nil and group.Split == nil and group.Collapsed == nil and group.Tabs[1] == "explorer", "the leaf is the node")
	-- T out too (dropped away from E): E alone is a plain window
	dragTab(t.win, { { 0, 3 }, { 550, 480 } })
	assert(tabOf(e.win).Visible == false and get(e.win, "Title").Visible and e.pos:Get() == UDim2.fromOffset(100, 100) and e.size:Get() == Vector2.new(300, 400))
	disposeAll(container, { e, p, o, t })
	H.assertNoDebugOutput("dissolve")
end)

H.section("a leaf whose windows are all closed hides (the sibling takes the space); reopening brings it back to its slot", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a = window(m, container, "a", 100, 100, 300, 200)
	local b = window(m, container, "b", 500, 300, 200, 150)
	local c = window(m, container, "c", 600, 450, 200, 150)
	dragTitle(b.win, 510, 310, { { 390, 200 } }) -- A | B
	dragTitle(c.win, 610, 460, { { 320, 108 } }) -- C a tab of B's leaf
	b.open:Set(false)
	relay()
	assert(at(c.win, 250, 100, 150, 200), "C draws B's leaf")
	c.open:Set(false)
	relay()
	assert(at(a.win, 100, 100, 300, 200), `A takes the space ({where(a.win)})`)
	assert(not frameOf(b.win).Visible and not frameOf(c.win).Visible and not splitterOf(b.win).Visible and not splitterOf(c.win).Visible)
	assert(tabOf(a.win).Visible, "still a split unit: A keeps its strip")
	assert(part(a.win, "WindowResizeGrip").Visible, "A is the corner now")
	local saved = nodeOf(m:ExportLayout())
	assert(saved.Split == "LeftRight" and #saved.Children[2].Tabs == 2, "the closed leaf is saved")
	b.open:Set(true)
	relay()
	assert(at(a.win, 100, 100, 150, 200) and at(b.win, 250, 100, 150, 200) and b.open:Get(), "back at its slot")
	assert(zOf(b.win) >= zOf(a.win), "raised")
	-- every leaf closed: the unit is hidden
	a.open:Set(false)
	b.open:Set(false)
	relay()
	for _, w in { a, b, c } do
		assert(not frameOf(w.win).Visible and not tabOf(w.win).Visible and not (w.win :: any).Visible)
	end
	disposeAll(container, { a, b, c })
	H.assertNoDebugOutput("closed leaf")
end)

H.section("the held edge joins a docked split's leaf of its focused window (else its first)", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a = window(m, container, "a", 100, 100, 300, 200)
	local b = window(m, container, "b", 500, 300, 200, 150)
	local c = window(m, container, "c", 600, 450, 200, 150)
	dragTitle(a.win, 150, 110, { { 3, 110 } })
	dragTitle(b.win, 510, 310, { { 150, 650 } }) -- A / B on the left
	press(150, 500) -- B focused
	dragTitle(c.win, 610, 460, { { 5, 200 } }, true)
	local pv = previewOf(c.win)
	assert(pv ~= nil and pv.Position == frameOf(b.win).Position and pv.Size == frameOf(b.win).Size, "the preview covers B's leaf")
	release(5, 200)
	local left = m:ExportLayout().Left :: any
	assert(left.Node.Children[2].Tabs[1] == "b" and left.Node.Children[2].Tabs[2] == "c" and left.Node.Children[2].Selected == "c", "C joined B's leaf")
	assert((m:ExportWindow("c") :: WindowState).Dock == "Left")
	disposeAll(container, { a, b, c })
	H.assertNoDebugOutput("edge join")
end)

H.section("layout: a split tree round-trips (Ratio, a folded leaf, kept rectangles); pending keys join their leaf at their slot", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local e = window(m, container, "explorer", 100, 100, 300, 400)
	local p = window(m, container, "props", 500, 100, 200, 150)
	local o = window(m, container, "output", 600, 450, 250, 150)
	local t = window(m, container, "tools", 650, 300, 220, 110)
	dragTitle(p.win, 510, 110, { { 250, 470 } }) -- E / P
	dragTitle(o.win, 610, 460, { { 390, 200 } }) -- (E / P) | O
	dragTitle(t.win, 660, 310, { { 240, 308 } }) -- T a tab of P's leaf (its strip row, after P)
	dragSplitter(o.win, 30, 0)
	clickArrow(t.win) -- P's leaf folds (T draws it)
	assert(p.collapsed:Get() and t.collapsed:Get() and not e.collapsed:Get(), "the leaf's windows share its fold")
	local layout = m:ExportLayout()
	local node = nodeOf(layout)
	assert(node.Split == "LeftRight" and math.abs(node.Ratio - 0.6) < 1e-6)
	local leafP = node.Children[1].Children[2]
	assert(table.concat(leafP.Tabs, ",") == "props,tools" and leafP.Selected == "tools" and leafP.Collapsed == true, "the folded leaf")
	assert(node.Children[1].Children[1].Collapsed == nil, "an unfolded leaf has no Collapsed")
	local wt: any = layout.Windows.tools
	assert(wt.Position[2] == 650 and wt.Size[1] == 220, "T's own rectangle")
	assert(layout.Floating[1].Collapsed == false)
	local saved = json(layout)
	disposeAll(container, { e, p, o, t })
	local container2 = newContainer(1000, 700)
	local m2 = Devui.WindowManager.new()
	m2:ImportLayout(saved)
	assert(serde.encode("json", m2:ExportLayout()) == serde.encode("json", saved), "pending: exported again unchanged")
	-- the windows come in another order; each takes its leaf and slot
	local t2 = window(m2, container2, "tools", 1, 1, 50, 50)
	assert(t2.pos:Get() == UDim2.fromOffset(650, 300) and t2.size:Get() == Vector2.new(220, 110), "T's own rectangle written")
	assert(t2.collapsed:Get() == true, "T's Collapsed: its leaf's fold")
	local o2 = window(m2, container2, "output", 1, 1, 50, 50)
	local e2 = window(m2, container2, "explorer", 1, 1, 50, 50)
	local p2 = window(m2, container2, "props", 1, 1, 50, 50)
	relay()
	assert(serde.encode("json", m2:ExportLayout()) == serde.encode("json", saved), "live: the same layout")
	assert(at(e2.win, 100, 100, 180, 381) and at(t2.win, 100, 481, 180, 19) and at(o2.win, 280, 100, 120, 400), `rebuilt ({where(e2.win)} / {where(t2.win)} / {where(o2.win)})`)
	assert(not frameOf(p2.win).Visible and tabOf(p2.win).Visible, "P a tab of the folded leaf")
	disposeAll(container2, { t2, o2, e2, p2 })
	H.assertNoDebugOutput("split layout")
end)

H.section("layout: a docked split reads back; a floating split's group Collapsed is read as false", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local function windows(keys: { string }): any
		local out = {}
		for _, k in keys do
			out[k] = { Kind = k, Open = true }
		end
		return out
	end
	local tree = { Split = "TopBottom", Ratio = 0.25, Children = { { Tabs = { "a" }, Selected = "a" }, { Tabs = { "b" }, Selected = "b", Collapsed = true } } }
	m:ImportLayout({ Version = 1, Windows = windows({ "a", "b" }), Floating = {}, Right = { Width = 250, Collapsed = false, Node = tree, Position = { 0, 10, 0, 10 }, Size = { 300, 300 } } } :: any)
	local a = window(m, container, "a", 1, 1, 50, 50)
	local b = window(m, container, "b", 1, 1, 50, 50)
	relay()
	assert(frameOf(a.win).Position == UDim2.new(1, -269, 0, 0) and frameOf(a.win).Size == UDim2.new(0, 250, 1, -19), `A fills the panel but B's row ({where(a.win)})`)
	assert(frameOf(b.win).Position == UDim2.new(1, -269, 1, -19) and frameOf(b.win).Size == UDim2.new(0, 250, 0, 19), `B folded at the bottom ({where(b.win)})`)
	assert(b.collapsed:Get() and not a.collapsed:Get())
	assert(part(b.win, "WindowDockStrip").Visible, "B (the corner leaf) draws the strip")
	m:ImportLayout({ Version = 1, Windows = windows({ "a", "b" }), Floating = { { Position = { 0, 100, 0, 100 }, Size = { 300, 200 }, Collapsed = true, Node = tree } } } :: any)
	relay()
	assert(not a.collapsed:Get() and b.collapsed:Get() and frameOf(a.win).Visible, "a floating split is never collapsed as a whole")
	assert(nodeOf(m:ExportLayout()).Split == "TopBottom" and m:ExportLayout().Floating[1].Collapsed == false)
	disposeAll(container, { a, b })
	H.assertNoDebugOutput("docked layout")
end)

H.section("layout: what cannot be a tab is placed plainly and the rest of the tree builds; ImportWindow takes a window out of a split", function()
	local container = newContainer(1000, 700)
	local other = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a = window(m, container, "a", 1, 1, 50, 50)
	local n = window(m, container, "n", 1, 1, 50, 50, { NoTitleBar = true })
	local b = window(m, container, "b", 1, 1, 50, 50)
	local f = window(m, other, "f", 1, 1, 50, 50)
	local leaf = function(key: string): any
		return { Tabs = { key }, Selected = key }
	end
	local windows = { a = { Kind = "a", Open = true }, n = { Kind = "n", Open = true, Position = { 0, 700, 0, 10 }, Size = { 120, 90 } }, b = { Kind = "b", Open = true }, f = { Kind = "f", Open = true } }
	-- ((a | n) / (b | f)): n has no title bar, f is in another container — both placed plainly
	local tree = {
		Split = "TopBottom",
		Ratio = 0.5,
		Children = {
			{ Split = "LeftRight", Ratio = 0.5, Children = { leaf("a"), leaf("n") } },
			{ Split = "LeftRight", Ratio = 0.5, Children = { leaf("b"), leaf("f") } },
		},
	}
	m:ImportLayout({ Version = 1, Windows = windows, Floating = { { Position = { 0, 100, 0, 100 }, Size = { 300, 200 }, Collapsed = false, Node = tree } } } :: any)
	relay()
	assert(at(a.win, 100, 100, 300, 100) and at(b.win, 100, 200, 300, 100), `a / b built ({where(a.win)} / {where(b.win)})`)
	assert(n.pos:Get() == UDim2.fromOffset(700, 10) and n.size:Get() == Vector2.new(120, 90) and tabOf(n.win) == nil, "n plain at its own rectangle")
	assert(f.pos:Get() == UDim2.fromOffset(100, 100) and frameOf(f.win).Size == UDim2.fromOffset(300, 200), "f plain at the group's rectangle (it had none)")
	local node: any = nil
	for _, g in m:ExportLayout().Floating do
		local saved: any = g.Node
		if saved.Split ~= nil then
			node = saved
		end
	end
	assert(node ~= nil and node.Split == "TopBottom" and node.Children[1].Tabs[1] == "a" and node.Children[2].Tabs[1] == "b", "the tree without them")
	-- ImportWindow takes b out of the split: a is a plain window at the unit's rectangle
	m:ImportWindow("b", { Kind = "b", Open = true, Collapsed = false, Position = { 0, 600, 0, 400 }, Size = { 200, 100 } })
	relay()
	assert(at(b.win, 600, 400, 200, 100) and tabOf(b.win).Visible == false, "b on its own")
	assert(at(a.win, 100, 100, 300, 200) and tabOf(a.win).Visible == false and a.pos:Get() == UDim2.fromOffset(100, 100), "a plain at the unit's rectangle")
	-- a pending NoTitleBar-less import of a tree whose leaves end with one window: no split
	disposeAll(container, { a, n, b })
	q.dispose(f.win)
	q.dispose(other)
	H.assertNoDebugOutput("eligibility")
end)

H.section("layout validation for splits", function()
	local m = Devui.WindowManager.new()
	local function bad(node: any, expect: string)
		local e = err(function()
			m:ImportLayout({
				Version = 1,
				Windows = { a = { Kind = "a", Open = true }, b = { Kind = "b", Open = true } },
				Floating = { { Position = { 0, 0, 0, 0 }, Size = { 100, 100 }, Collapsed = false, Node = node } },
			} :: any)
		end)
		assert(string.find(e, expect, 1, true) ~= nil, `{expect}: {e}`)
	end
	local a, b = { Tabs = { "a" }, Selected = "a" }, { Tabs = { "b" }, Selected = "b" }
	bad({ Split = "Horizontal", Ratio = 0.5, Children = { a, b } }, 'layout.Floating[1].Node.Split must be "LeftRight" or "TopBottom", got Horizontal')
	bad({ Split = "LeftRight", Ratio = 0, Children = { a, b } }, "layout.Floating[1].Node.Ratio must be a number strictly between 0 and 1")
	bad({ Split = "LeftRight", Ratio = 1, Children = { a, b } }, "Ratio must be a number strictly between 0 and 1")
	bad({ Split = "LeftRight", Ratio = "half", Children = { a, b } }, "Ratio must be a number strictly between 0 and 1")
	bad({ Split = "LeftRight", Ratio = 0.5, Children = { a } }, "layout.Floating[1].Node.Children must be an array of exactly two nodes")
	bad({ Split = "LeftRight", Ratio = 0.5, Children = { a, b, a } }, "Children must be an array of exactly two nodes")
	bad({ Split = "LeftRight", Ratio = 0.5 }, "Children must be an array of exactly two nodes")
	bad({ Split = "LeftRight", Ratio = 0.5, Children = { a, { Tabs = { "a" }, Selected = "a" } } }, 'layout.Floating[1].Node.Children[2].Tabs lists "a" twice')
	bad({ Split = "LeftRight", Ratio = 0.5, Children = { a, { Tabs = { "b" }, Selected = "b", Collapsed = "yes" } } }, "layout.Floating[1].Node.Children[2].Collapsed must be a boolean or nil")
	bad({ Split = "LeftRight", Ratio = 0.5, Children = { a, 7 } }, "layout.Floating[1].Node.Children[2] must be a tab set")
	bad({ Split = "LeftRight", Ratio = 0.5, Children = { a, { Split = "TopBottom", Ratio = 0.5, Children = { b, { Tabs = {}, Selected = "x" } } } } }, "layout.Floating[1].Node.Children[2].Children[2].Tabs must be a non-empty array")
	bad({ Tabs = { "a", "b" }, Selected = "a", Split = "LeftRight" }, "a node is either a tab set (Tabs) or a split (Split), not both")
	H.assertNoDebugOutput("validation")
end)

H.section("the fold rule: a leaf folds only while its sibling has a visible unfolded leaf; otherwise the fold clears or is refused", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a = window(m, container, "a", 100, 100, 300, 200)
	local b = window(m, container, "b", 500, 300, 200, 150)
	dragTitle(b.win, 510, 310, { { 250, 290 } }) -- A over B
	clickArrow(a.win)
	assert(a.collapsed:Get() and at(a.win, 100, 100, 300, 19))
	-- B closes: A has nothing to fold against — its fold clears (its Collapsed false), it is drawn whole, no arrow
	b.open:Set(false)
	relay()
	assert(a.collapsed:Get() == false and at(a.win, 100, 100, 300, 200) and (a.win :: any).Visible, `A unfolded ({where(a.win)})`)
	assert(get(a.win, "CollapseButton").Visible == false, "a lone leaf offers no arrow")
	a.collapsed:Set(true) -- refused: written back
	relay()
	assert(a.collapsed:Get() == false and at(a.win, 100, 100, 300, 200), "an app's fold of a lone leaf is refused")
	b.open:Set(true)
	relay()
	assert(at(a.win, 100, 100, 300, 100) and at(b.win, 100, 200, 300, 100) and get(a.win, "CollapseButton").Visible, "both back unfolded")
	-- a load that folds both sides: the second side unfolds
	local tree = { Split = "TopBottom", Ratio = 0.5, Children = { { Tabs = { "a" }, Selected = "a", Collapsed = true }, { Tabs = { "b" }, Selected = "b", Collapsed = true } } }
	m:ImportLayout({ Version = 1, Windows = { a = { Kind = "a", Open = true }, b = { Kind = "b", Open = true } }, Floating = { { Position = { 0, 100, 0, 100 }, Size = { 300, 200 }, Collapsed = false, Node = tree } } } :: any)
	relay()
	assert(a.collapsed:Get() == true and b.collapsed:Get() == false and at(a.win, 100, 100, 300, 19) and at(b.win, 100, 119, 300, 181), `the second side unfolds ({where(b.win)})`)
	local saved = nodeOf(m:ExportLayout())
	assert(saved.Children[1].Collapsed == true and saved.Children[2].Collapsed == nil)
	disposeAll(container, { a, b })
	H.assertNoDebugOutput("fold rule")
end)

H.section("a docked split panel collapsed: an app's true on a window is recorded as its leaf's fold", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a = window(m, container, "a", 100, 100, 300, 200)
	local b = window(m, container, "b", 500, 300, 200, 150)
	dragTitle(a.win, 150, 110, { { 3, 110 } })
	dragTitle(b.win, 510, 310, { { 150, 650 } }) -- A / B on the left
	local strip = part(b.win, "WindowDockStrip")
	press(150, 500)
	press(5, 300)
	H.fire(strip, "Activated", mouse(M1, 5, 300), 1)
	relay()
	assert(a.collapsed:Get() and b.collapsed:Get() and not frameOf(a.win).Visible, "the panel collapsed")
	a.collapsed:Set(true) -- (equal value: still the app asking for A's fold)
	press(5, 300)
	H.fire(strip, "Activated", mouse(M1, 5, 300), 1)
	relay()
	assert(a.collapsed:Get() == true and b.collapsed:Get() == false, "expanded: A folded, B not")
	assert(frameOf(a.win).Size == UDim2.new(0, 300, 0, 19) and frameOf(b.win).Position == UDim2.new(0, 19, 0, 19), `A keeps its row ({where(a.win)})`)
	disposeAll(container, { a, b })
	H.assertNoDebugOutput("docked fold record")
end)

H.section("drop judging: an unselected tab and a top / bottom splitter are judged by the leaf under the pointer", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a = window(m, container, "a", 100, 100, 300, 200)
	local b = window(m, container, "b", 500, 300, 200, 150)
	local c = window(m, container, "c", 600, 500, 200, 120)
	dragTitle(b.win, 510, 310, { { 250, 200 } }) -- A, B tabs
	-- select A: B is now an unselected tab that sits above A in the stacking
	relay()
	local ta = tabOf(a.win)
	press(ta.AbsolutePosition.X + 5, ta.AbsolutePosition.Y + 5)
	H.fire(ta, "InputBegan", mouse(M1, ta.AbsolutePosition.X + 5, ta.AbsolutePosition.Y + 5))
	release(ta.AbsolutePosition.X + 5, ta.AbsolutePosition.Y + 5)
	relay()
	assert(frameOf(a.win).Visible and not frameOf(b.win).Visible and zOf(b.win) > zOf(a.win), "A selected, B above it")
	local tb = tabOf(b.win)
	local bx, by = tb.AbsolutePosition.X + 5, tb.AbsolutePosition.Y + 5
	dragTitle(c.win, 610, 510, { { bx, by } }, true)
	assert(previewIs(c.win, 100, 100, 300, 200), "dropping on B's tab joins the group")
	release(bx, by)
	relay()
	assert(tabOf(c.win).Visible and frameOf(c.win).Visible, "C joined")
	disposeAll(container, { a, b, c })

	-- a top / bottom splitter sits over the first side's bottom: just above the seam is the first side's bottom band
	local container2 = newContainer(1000, 700)
	local m2 = Devui.WindowManager.new()
	local d = window(m2, container2, "d", 100, 100, 300, 200)
	local e = window(m2, container2, "e", 500, 300, 200, 150)
	local f = window(m2, container2, "f", 600, 500, 200, 120)
	dragTitle(e.win, 510, 310, { { 250, 290 } }) -- D over E, the seam at y 200, E's splitter [194, 200]
	assert(splitterOf(e.win).Visible and zOf(e.win) > zOf(d.win))
	dragTitle(f.win, 610, 510, { { 250, 197 } }, true)
	assert(previewIs(f.win, 100, 150, 300, 50), "over the splitter: D's bottom half")
	release(250, 197)
	relay()
	disposeAll(container2, { d, e, f })
	H.assertNoDebugOutput("drop judging")
end)

H.section("a forgotten key of a split or a tab group destroyed: no stale state is read; the layout drops it", function()
	for _, splitIt in { true, false } do
		local container = newContainer(1000, 700)
		local m = Devui.WindowManager.new()
		local a = window(m, container, "a", 100, 100, 300, 200)
		local b = window(m, container, "b", 500, 300, 200, 150)
		dragTitle(b.win, 510, 310, { if splitIt then { 390, 200 } else { 250, 200 } })
		m:ForgetWindow("b")
		q.dispose(b.win)
		local layout = m:ExportLayout()
		assert(layout.Windows.b == nil and #layout.Floating == 1 and nodeOf(layout).Tabs[1] == "a", "only a is saved")
		assert(tabOf(a.win).Visible == false and frameOf(a.win).Visible, "a plain window again")
		q.dispose(a.win)
		q.dispose(container)
	end
	H.assertNoDebugOutput("forget")
end)

H.section("a splitter drag rebuilds the layout once per move", function()
	local LayoutModule = require("../src/Window/Layout") :: any
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a = window(m, container, "a", 100, 100, 300, 200)
	local b = window(m, container, "b", 500, 300, 200, 150)
	dragTitle(b.win, 510, 310, { { 390, 200 } })
	relay()
	local sp = splitterOf(b.win)
	local x0, y0 = sp.AbsolutePosition.X + 2, sp.AbsolutePosition.Y + 2
	press(x0, y0)
	H.fire(sp, "InputBegan", mouse(M1, x0, y0))
	moveTo(x0 + 5, y0)
	local builds = 0
	local original = LayoutModule.build
	LayoutModule.build = function(...)
		builds += 1
		return original(...)
	end
	moveTo(x0 + 20, y0)
	local perMove = builds
	LayoutModule.build = original
	release(x0 + 20, y0)
	assert(perMove == 1, `one layout build per move ({perMove})`)
	disposeAll(container, { a, b })
	H.assertNoDebugOutput("splitter builds")
end)

H.section("a corner of a leaf goes to the band the pointer is deeper in", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a = window(m, container, "a", 100, 100, 300, 200)
	local b = window(m, container, "b", 500, 300, 200, 150)
	-- bands: 60 px wide on the left, 40 px tall at the bottom
	dragTitle(b.win, 510, 310, { { 115, 285 } }, true) -- 15 / 60 from the left edge, 15 / 40 from the bottom one: the smaller share (closer to its edge) wins
	assert(previewIs(b.win, 100, 100, 150, 200), "deeper in the left band: the left half")
	moveTo(130, 290) -- 30 / 60 from the left edge, 10 / 40 from the bottom one: bottom wins
	assert(previewIs(b.win, 100, 200, 300, 100), "deeper in the bottom band: the bottom half")
	moveTo(800, 600)
	release(800, 600)
	disposeAll(container, { a, b })
	H.assertNoDebugOutput("corner")
end)

H.section("undocking a docked split as a whole: the pointer keeps its share of the unit's width and its place in the pressed leaf's row", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local tree = { Split = "TopBottom", Ratio = 0.5, Children = { { Tabs = { "a" }, Selected = "a" }, { Tabs = { "b" }, Selected = "b" } } }
	m:ImportLayout({ Version = 1, Windows = { a = { Kind = "a", Open = true }, b = { Kind = "b", Open = true } }, Floating = {}, Left = { Width = 200, Collapsed = false, Node = tree, Position = { 0, 100, 0, 100 }, Size = { 400, 300 } } } :: any)
	local a = window(m, container, "a", 1, 1, 50, 50)
	local b = window(m, container, "b", 1, 1, 50, 50)
	relay()
	assert(frameOf(b.win).Position == UDim2.new(0, 19, 0.5, 0) and frameOf(b.win).Size == UDim2.new(0, 200, 0.5, 0))
	-- B's strip row (y 350..369), right of its tab: 181 / 200 of the panel's width, 8 px into the row
	dragTitle(b.win, 200, 358, { { 205, 362 }, { 600, 400 } })
	assert((m:ExportWindow("a") :: WindowState).Dock == nil, "undocked")
	-- the floating unit is 400 x 300 and B's leaf starts 150 px down it: the unit's top-left = pointer - (181 / 200 x 400,
	-- 150 + 8) — not the same pixel offset (that would be 600 - 181)
	local fa = frameOf(a.win).Position
	assert(math.abs(fa.X.Offset - (600 - 181 / 200 * 400)) <= 1 and fa.Y.Offset == 400 - 158, `the unit placed by share and leaf row ({fa})`)
	assert(frameOf(b.win).Position == UDim2.fromOffset(fa.X.Offset, fa.Y.Offset + 150) and frameOf(b.win).Size == UDim2.fromOffset(400, 150))
	disposeAll(container, { a, b })
	H.assertNoDebugOutput("undock share")
end)

H.section("a whole split dragged by its strip: onto a tab place its windows join flat; onto a band its tree is one side", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local a = window(m, container, "a", 100, 100, 300, 200)
	local b = window(m, container, "b", 500, 50, 200, 150)
	local c = window(m, container, "c", 550, 400, 300, 200)
	dragTitle(b.win, 510, 60, { { 390, 200 } }) -- A | B
	dragTitle(a.win, 245, 108, { { 700, 500 } }) -- the whole unit by A's strip onto C's centre (the pointer moves 455, 392)
	relay()
	local node = nil :: any
	for _, g in m:ExportLayout().Floating do
		node = g.Node
	end
	assert(#m:ExportLayout().Floating == 1 and node.Split == nil and table.concat(node.Tabs, ",") == "c,a,b", "flat tabs of C's leaf, tree gone")
	assert(at(a.win, 550, 400, 300, 200) and not frameOf(c.win).Visible, "A drawn at C's rectangle")
	-- out again: B and A torn off, made A | B, then dropped on D's right band — the tree is that side
	dragTab(b.win, { { 0, 3 }, { -400, -350 } })
	dragTab(a.win, { { 0, 3 }, { -500, -250 } })
	relay()
	local d = window(m, container, "d", 50, 450, 300, 200)
	local fa = frameOf(a.win).Position
	local fb = frameOf(b.win).AbsolutePosition
	dragTitle(b.win, fb.X + 10, fb.Y + 5, { { fa.X.Offset + frameOf(a.win).Size.X.Offset - 10, fa.Y.Offset + 100 } }) -- B on A's right band
	relay()
	local ta = frameOf(a.win)
	dragTitle(a.win, ta.AbsolutePosition.X + ta.AbsoluteSize.X - 8, ta.AbsolutePosition.Y + 8, { { 330, 550 } }) -- the unit onto D's right band
	relay()
	local root: any = nil
	for _, g in m:ExportLayout().Floating do
		local n: any = g.Node
		if n.Split ~= nil then
			root = n
		end
	end
	assert(root ~= nil and root.Split == "LeftRight" and root.Children[1].Tabs[1] == "d", "D keeps the left")
	assert(root.Children[2].Split == "LeftRight" and root.Children[2].Children[1].Tabs[1] == "a" and root.Children[2].Children[2].Tabs[1] == "b", "the A | B tree is the right side")
	assert(at(d.win, 50, 450, 150, 200) and at(a.win, 200, 450, 75, 200) and at(b.win, 275, 450, 75, 200), `inside D's rectangle ({where(a.win)})`)
	disposeAll(container, { a, b, c, d })
	H.assertNoDebugOutput("whole split")
end)

H.section("the held edge with no focus ever in the docked split: its first visible leaf", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local tree = { Split = "TopBottom", Ratio = 0.5, Children = { { Tabs = { "a" }, Selected = "a" }, { Tabs = { "b" }, Selected = "b" } } }
	m:ImportLayout({ Version = 1, Windows = { a = { Kind = "a", Open = true }, b = { Kind = "b", Open = true } }, Floating = {}, Left = { Width = 300, Collapsed = false, Node = tree } } :: any)
	local a = window(m, container, "a", 1, 1, 50, 50)
	local b = window(m, container, "b", 1, 1, 50, 50)
	local c = window(m, container, "c", 600, 450, 200, 150)
	-- (an import focuses nothing: the unit has no leaf its focus was in)
	dragTitle(c.win, 610, 460, { { 5, 600 } })
	local left = m:ExportLayout().Left :: any
	assert(table.concat(left.Node.Children[1].Tabs, ",") == "a,c" and #left.Node.Children[2].Tabs == 1, "C joined the first leaf")
	disposeAll(container, { a, b, c })
	H.assertNoDebugOutput("edge first")
end)

H.section("the fold rule and a load: a pending key counts only when it was saved open", function()
	local container = newContainer(1000, 700)
	local m = Devui.WindowManager.new()
	local tree = { Split = "TopBottom", Ratio = 0.5, Children = { { Tabs = { "a" }, Selected = "a", Collapsed = true }, { Tabs = { "b" }, Selected = "b" } } }
	local function load(bOpen: boolean)
		m:ImportLayout({ Version = 1, Windows = { a = { Kind = "a", Open = true }, b = { Kind = "b", Open = bOpen } }, Floating = { { Position = { 0, 100, 0, 100 }, Size = { 300, 200 }, Collapsed = false, Node = tree } } } :: any)
	end
	load(true)
	local a = window(m, container, "a", 1, 1, 50, 50)
	assert(a.collapsed:Get() == true, "b (pending, saved open) counts: a stays folded")
	q.dispose(a.win)
	m:ForgetWindow("a")
	m:ForgetWindow("b")
	load(false)
	local a2 = window(m, container, "a", 1, 1, 50, 50)
	assert(a2.collapsed:Get() == false, "b saved closed does not count: a's fold clears")
	assert(nodeOf(m:ExportLayout()).Children[1].Collapsed == nil, "and is saved cleared")
	q.dispose(a2.win)
	q.dispose(container)
	H.assertNoDebugOutput("pending fold")
end)

H.section("parts: a NoTitleBar window has no fold bar or splitter; a NoResize one has the fold bar and no splitter", function()
	local m = Devui.WindowManager.new()
	local bare = Devui.Window({ Title = "n", Manager = m, NoTitleBar = true })
	local fixed = Devui.Window({ Title = "r", Manager = m, NoResize = true })
	assert(part(bare, "WindowFoldBar") == nil and part(bare, "WindowSplitter") == nil)
	assert(part(fixed, "WindowFoldBar") ~= nil and part(fixed, "WindowSplitter") == nil)
	q.dispose(bare)
	q.dispose(fixed)
	H.assertNoDebugOutput("parts")
end)

H.section("README's layout example reads (Layout.read) and round-trips", function()
	local fs = lune("@lune/fs")
	local luau = lune("@lune/luau")
	local text: string = fs.readFile("quad-roblox-devui/README.md")
	local start = string.find(text, "```luau\n{\n\tVersion = 1,", 1)
	assert(start ~= nil, "the example block")
	local from = (start :: number) + #"```luau\n"
	local stop = string.find(text, "\n}\n", from, true)
	local example = luau.load("return " .. string.sub(text, from, (stop :: number) + 2))()
	local m = Devui.WindowManager.new()
	m:ImportLayout(example)
	local back = m:ExportLayout() :: any
	assert(back.Left.Node.Split == "LeftRight" and back.Left.Node.Children[1].Children[2].Collapsed == true)
	assert(back.Windows.explorer ~= nil and back.Floating[1].Node.Tabs[2] == "note-1")
	H.assertNoDebugOutput("readme example")
end)

H.done()
