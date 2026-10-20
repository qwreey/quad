--!strict
-- App bars: the six top app bars (Compose AppBar.kt geometry, colors, title placement), the action model (icon buttons in
-- the bar's color, toggles, the overflow menu past MaxItemCount), the scroll behaviors driven by a ScrollingFrame's
-- CanvasPosition (pinned color, enterAlways, exitUntilCollapsed, settle), BottomAppBar and FlexibleBottomAppBar.
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Frame = q.Elem "Frame"
local ScrollingFrame = q.Elem "ScrollingFrame"
local Tokens = require("../src/Tokens")
local Overlay = require("../src/Overlay")
local AppBar = require("../src/AppBar")
local Top = require("../src/AppBar/Top")
local Bounded = require("./support/bounded")
local Input = require("../src/Input")

local L = Tokens.Color.Light
local Heartbeat = H.RunService.Heartbeat :: any
local baseBeats = #Heartbeat.connections

local function own(inst: any, className: string): any
	for _, c in inst:GetChildren() do
		if c.ClassName == className then
			return c
		end
	end
	return nil
end
local function buttons(root: any): { any }
	local out = H.findAll(root, function(c: any)
		return c.Name == "IconButton"
	end)
	table.sort(out, function(a: any, b: any)
		return a.LayoutOrder < b.LayoutOrder
	end)
	return out
end
local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-3
end

local log: { string } = {}
local function act(name: string): () -> ()
	return function()
		table.insert(log, name)
	end
end

H.section("TopAppBar: 64 surface, navigation icon at 4 (48 px button, onSurface), title TitleLarge at 56, actions at the end (onSurfaceVariant)", function()
	local bar: any = AppBar.TopAppBar({
		Title = "Inbox",
		NavigationIcon = { Icon = "menu", Label = "Menu", OnClick = act("menu") },
		Actions = { { Icon = "rbxassetid://1", Label = "Search", OnClick = act("search") }, { Icon = "rbxassetid://2", Label = "More", OnClick = act("more") } },
	})
	assert(bar.Name == "TopAppBar" and bar.Size == UDim2.new(1, 0, 0, 64) and bar.BackgroundColor3 == L.Surface and bar.ClipsDescendants)
	local nav = H.find(bar, "NavigationIcon")
	assert(nav.AnchorPoint == Vector2.new(0, 0.5) and nav.Position == UDim2.new(0, 4, 0.5, 0) and nav.Size == UDim2.fromOffset(48, 48))
	local navButton = buttons(nav)[1]
	assert(navButton.Size == UDim2.fromOffset(48, 48), "TouchTarget 48")
	assert(H.find(navButton, "Icon").ImageColor3 == L.OnSurface and H.find(navButton, "Icon").Image == "rbxassetid://6031097225")
	local title = H.find(bar, "Title")
	assert(title.Position == UDim2.new(0, 56, 0.5, 0) and title.AnchorPoint == Vector2.new(0, 0.5), tostring(title.Position))
	assert(title.TextSize == 22 and title.TextColor3 == L.OnSurface and title.TextXAlignment == Enum.TextXAlignment.Left)
	assert(title.Size == UDim2.new(1, -(56 + 96 + 8), 0, 28), tostring(title.Size))
	local actions = H.find(bar, "Actions")
	assert(actions.AnchorPoint == Vector2.new(1, 0.5) and actions.Position == UDim2.new(1, -4, 0.5, 0) and actions.Size == UDim2.fromOffset(96, 48))
	local list = buttons(actions)
	assert(#list == 2 and H.find(list[1], "Icon").ImageColor3 == L.OnSurfaceVariant)
	H.fire(list[1], "Activated", H.input({}), 1)
	H.fire(navButton, "Activated", H.input({}), 1)
	assert(log[1] == "search" and log[2] == "menu")
	local n = H.countDescendants(bar) + 1
	print(`[appbar] TopAppBar with a navigation icon and two actions: {n} instances`)
	H.resetOutput()
	assert(n == 1 + 1 + 1 + 2 + 3 * 7, `count {n}`)
	q.dispose(bar)
	table.clear(log)
	H.assertNoDebugOutput("top app bar")
end)

H.section("title start without an icon is 16; CenterAligned centers in the room symmetric to the wider side; subtitle column", function()
	local plain: any = AppBar.TopAppBar({ Title = "Plain" })
	assert(H.find(plain, "Title").Position == UDim2.new(0, 16, 0.5, 0))
	q.dispose(plain)
	local centered: any = AppBar.CenterAlignedTopAppBar({ Title = "Center", Actions = { { Icon = "x", Label = "A" }, { Icon = "y", Label = "B" } } })
	local t = H.find(centered, "Title")
	assert(centered.Name == "CenterAlignedTopAppBar" and t.AnchorPoint == Vector2.new(0.5, 0.5) and t.Position == UDim2.new(0.5, 0, 0.5, 0))
	assert(t.Size == UDim2.new(1, -208, 0, 28) and t.TextXAlignment == Enum.TextXAlignment.Center, tostring(t.Size))
	q.dispose(centered)
	local sub: any = AppBar.TopAppBar({ Title = "Title", Subtitle = "Subtitle" })
	local column = H.find(sub, "TitleColumn")
	assert(column.Size.Y.Offset == 44 and H.find(column, "Subtitle").Position == UDim2.fromOffset(0, 28))
	local s = H.find(column, "Subtitle")
	assert(s.TextSize == 12 and s.TextColor3 == L.OnSurfaceVariant, "LabelMedium onSurfaceVariant")
	q.dispose(sub)
	H.assertNoDebugOutput("titles")
end)

H.section("two-row bars: heights, large title roles and the baseline padding (24 / 28 from the last baseline)", function()
	local cases: { any } = {
		{ AppBar.MediumTopAppBar, 112, "HeadlineSmall", nil, 24 },
		{ AppBar.LargeTopAppBar, 152, "HeadlineMedium", nil, 28 },
		{ AppBar.MediumFlexibleTopAppBar, 136, "HeadlineMedium", "LabelLarge", 24 },
		{ AppBar.LargeFlexibleTopAppBar, 120, "DisplaySmall", nil, 28 },
	}
	for _, c: any in cases do
		local make: any, height: number, role: any, subRole: any, pad: number = c[1], c[2], c[3], c[4], c[5]
		local bar: any = make({ Title = "Title", Subtitle = if subRole then "Sub" else nil })
		assert(bar.Size == UDim2.new(1, 0, 0, height), `{bar.Name}: {tostring(bar.Size)}`)
		local bottom = H.find(bar, "BottomRow")
		assert(bottom.Position == UDim2.fromOffset(0, 64) and bottom.Size == UDim2.new(1, 0, 0, height - 64) and bottom.ClipsDescendants)
		local node = H.find(bottom, if subRole then "TitleColumn" else "Title")
		local scale: any = Tokens.Typography.Scale
		local lineH = scale[role].LineHeight + (if subRole then scale[subRole].LineHeight else 0)
		local last = subRole or role
		local expect = pad - Top.descentOf(last :: any)
		if expect + lineH > height - 64 then
			expect -= expect + lineH - (height - 64)
		end
		expect = math.max(0, math.round(expect))
		assert(node.AnchorPoint == Vector2.new(0, 1) and node.Position == UDim2.new(0, 16, 1, -expect), `{bar.Name}: {tostring(node.Position)} vs {expect}`)
		local big = H.find(bottom, "Title")
		assert(big.TextSize == scale[role].Size, `{bar.Name}: {role}`)
		assert(H.find(H.find(bar, "TopRow"), "Title").TextTransparency == 1, "the small title is hidden while expanded")
		assert(big.TextTransparency == 0)
		q.dispose(bar)
	end
	-- Medium: HeadlineSmall's baseline is 7.8 above the line box bottom: 24 - 7.8 = 16.2, over the 48 px row by 0.2 -> 16
	local medium: any = AppBar.MediumTopAppBar({ Title = "M" })
	assert(H.find(H.find(medium, "BottomRow"), "Title").Position == UDim2.new(0, 16, 1, -16))
	q.dispose(medium)
	local bad = pcall(function()
		AppBar.MediumTopAppBar({ Title = "x", ExpandedHeight = 40 })
	end)
	assert(not bad, "expanded below collapsed is an error")
	H.resetOutput()
	H.assertNoDebugOutput("two rows")
end)

H.section("actions: toggles (IconToggleButton look, OnCheckedChange with the new value), overflow menu past MaxItemCount", function()
	local overlay = Overlay.new()
	local screen = Frame { overlay.Layer }
	H.setAbs(overlay.Layer, 0, 0, 800, 600)
	local fav = q.Source(false)
	local bar: any = AppBar.TopAppBar({
		Title = "Edit",
		Overlay = overlay,
		MaxItemCount = 3,
		Actions = {
			{ Icon = "rbxassetid://1", Label = "Favorite", Checked = fav, OnCheckedChange = function(v: boolean)
				fav:Set(v)
			end },
			{ Icon = "rbxassetid://2", Label = "Share", OnClick = act("share") },
			{ Icon = "rbxassetid://3", Label = "Copy", OnClick = act("copy") },
			{ Icon = "rbxassetid://4", Label = "Delete", OnClick = act("delete"), Disabled = true },
		},
	})
	local list = buttons(H.find(bar, "Actions"))
	assert(#list == 3 and list[3].LayoutOrder == 5, "2 + the overflow button (after every entry)")
	assert(H.find(list[3], "Icon").Image == "rbxassetid://6031104648", "moreVert")
	assert(H.find(bar, "Actions").Size == UDim2.fromOffset(144, 48))
	H.fire(list[1], "Activated", H.input({}), 1)
	H.finishTweens()
	assert(fav:Get() == true and H.find(list[1], "Icon").ImageColor3 == L.Primary, "checked: primary")
	H.setAbs(list[3], 700, 10, 48, 48)
	H.fire(list[3], "Activated", H.input({}), 1)
	local copy = H.findAll(overlay.Layer, function(c: any)
		return c.ClassName == "TextLabel" and c.Text == "Copy"
	end)
	assert(#copy == 1, "the menu lists the overflowed actions")
	local row: any = copy[1]
	while row.ClassName ~= "TextButton" do
		row = row.Parent
	end
	H.fire(row, "Activated", H.input({}), 1)
	assert(log[1] == "copy", "a menu entry clicks its action")
	H.advance(0.5)
	H.fire(list[3], "Activated", H.input({}), 1)
	H.fire(list[3], "Activated", H.input({}), 1)
	H.advance(0.5)
	assert(#overlay.Layer:GetChildren() == 0, "the overflow button toggles the menu")
	q.dispose(bar)
	q.dispose(screen)
	table.clear(log)
	H.advance(1)
	H.assertNoDebugOutput("actions")
end)

H.section("action ripple stays inside the 40 px button (BOUNDED)", function()
	local bar: any = AppBar.TopAppBar({ Title = "x", Actions = { { Icon = "rbxassetid://1", Label = "A", OnClick = act("a") } } })
	Bounded.pressBounded(buttons(bar)[1], 40, 40, "app bar action")
	q.dispose(bar)
	table.clear(log)
	H.advance(1)
	H.assertNoDebugOutput("action ripple")
end)

-- ── scrolling ───────────────────────────────────────────────────────────────

local function scroller(behavior: any, maxY: number?): any
	local frame: any = ScrollingFrame { Name = "List", behavior.Hook }
	-- layout stand-in: the furthest scroll (canvas - window) the settle clamps its canvas target to
	frame.AbsoluteWindowSize = Vector2.new(360, 300)
	frame.AbsoluteCanvasSize = Vector2.new(360, 300 + (maxY or 1700))
	return frame
end
-- run the 0.1 s idle wait and the whole 0.2 s settle animation
local function settleOut()
	H.advance(0.15)
	for _ = 1, 15 do
		H.advance(0.02)
	end
end
local function scrollTo(frame: any, y: number)
	frame.CanvasPosition = Vector2.new(0, y)
end

H.section("pinned: the height stays, the container turns surfaceContainer once the content scrolls under it", function()
	local behavior = AppBar.TopAppBarDefaults.pinnedScrollBehavior()
	local bar: any = AppBar.TopAppBar({ Title = "Pinned", ScrollBehavior = behavior })
	local list = scroller(behavior)
	assert(behavior.IsPinned and behavior.State.HeightOffsetLimit:Get() == -64)
	scrollTo(list, 10)
	H.finishTweens()
	assert(bar.Size == UDim2.new(1, 0, 0, 64) and bar.BackgroundColor3 == L.SurfaceContainer, "scrolled color")
	assert(near(behavior.State.OverlappedFraction:Get(), 10 / 64))
	scrollTo(list, 0)
	H.finishTweens()
	assert(bar.BackgroundColor3 == L.Surface)
	H.advance(0.5)
	assert(H.pendingTimers() == 0, "pinned: no settle timer")
	q.dispose(bar)
	q.dispose(list)
	H.assertNoDebugOutput("pinned")
end)

H.section("enterAlways: the bar follows every scroll, up or down; a stop part way settles to the nearer end", function()
	local behavior = AppBar.TopAppBarDefaults.enterAlwaysScrollBehavior()
	local bar: any = AppBar.TopAppBar({ Title = "Enter", ScrollBehavior = behavior })
	local list = scroller(behavior)
	scrollTo(list, 30)
	assert(bar.Size == UDim2.new(1, 0, 0, 34), tostring(bar.Size))
	scrollTo(list, 200)
	assert(bar.Size == UDim2.new(1, 0, 0, 0), "hidden")
	scrollTo(list, 180)
	assert(bar.Size == UDim2.new(1, 0, 0, 20), "any scroll up brings it back")
	H.advance(0.15)
	for _ = 1, 15 do
		H.advance(0.02)
	end
	assert(bar.Size == UDim2.new(1, 0, 0, 0), "20 / 64 shown: collapsed fraction 0.69 -> settles hidden")
	assert(#Heartbeat.connections == baseBeats, "the settle loop ends")
	q.dispose(bar)
	q.dispose(list)
	H.advance(0.5)
	H.assertNoDebugOutput("enter always")
end)

H.section("exitUntilCollapsed (Medium): collapses on scroll down to its 64 px row, expands only near the top; colors and title fades", function()
	local behavior = AppBar.TopAppBarDefaults.exitUntilCollapsedScrollBehavior()
	local bar: any = AppBar.MediumTopAppBar({ Title = "Medium", ScrollBehavior = behavior })
	local list = scroller(behavior)
	assert(behavior.State.HeightOffsetLimit:Get() == -48)
	scrollTo(list, 24)
	assert(bar.Size == UDim2.new(1, 0, 0, 88) and H.find(bar, "BottomRow").Size == UDim2.new(1, 0, 0, 24))
	local fraction = behavior.State.CollapsedFraction:Get()
	assert(near(fraction, 0.5))
	local big = H.find(H.find(bar, "BottomRow"), "Title")
	local small = H.find(H.find(bar, "TopRow"), "Title")
	assert(near(big.TextTransparency, 0.5), "large title alpha 1 - fraction")
	assert(small.TextTransparency > 0.5 and small.TextTransparency < 1, "small title on TopTitleAlphaEasing")
	assert(bar.BackgroundColor3 ~= L.Surface and bar.BackgroundColor3 ~= L.SurfaceContainer, "blending")
	scrollTo(list, 300)
	assert(bar.Size == UDim2.new(1, 0, 0, 64) and bar.BackgroundColor3 == L.SurfaceContainer and small.TextTransparency == 0)
	scrollTo(list, 100)
	assert(bar.Size == UDim2.new(1, 0, 0, 64), "far from the top: stays collapsed")
	scrollTo(list, 20)
	assert(bar.Size == UDim2.new(1, 0, 0, 92), "near the top: expands with the content")
	H.advance(0.15)
	for _ = 1, 15 do
		H.advance(0.02)
	end
	assert(bar.Size == UDim2.new(1, 0, 0, 112), "fraction 20/48 < 0.5: settles expanded")
	q.dispose(bar)
	q.dispose(list)
	H.advance(0.5)
	assert(#Heartbeat.connections == baseBeats)
	H.assertNoDebugOutput("exit until collapsed")
end)

H.section("settle keeps the content under the bar: a stop part way moves the canvas with the bar (no gap, no overlap)", function()
	-- the kit layout (Scroll.luau header): a row sits at `expanded - CanvasPosition.Y`, the bar's bottom at
	-- `expanded + HeightOffset` — the first row meets the bar's bottom iff CanvasPosition.Y + HeightOffset == 0
	local function rowGap(bar: any, list: any, expanded: number): number
		return (expanded - list.CanvasPosition.Y) - bar.Size.Y.Offset
	end
	-- exitUntilCollapsed, Medium (112 -> 64): 30 of 48 collapsed (0.63) collapses; the canvas follows to 48
	local exit = AppBar.TopAppBarDefaults.exitUntilCollapsedScrollBehavior()
	local medium: any = AppBar.MediumTopAppBar({ Title = "Medium", ScrollBehavior = exit })
	local list = scroller(exit)
	scrollTo(list, 30)
	settleOut()
	assert(medium.Size == UDim2.new(1, 0, 0, 64), tostring(medium.Size))
	assert(near(list.CanvasPosition.Y, 48), `exit collapse: canvas {list.CanvasPosition.Y}`)
	assert(near(rowGap(medium, list, 112), 0), `exit collapse: gap {rowGap(medium, list, 112)}`)
	assert(#Heartbeat.connections == baseBeats)
	-- 20 of 48 (0.42) expands; the canvas follows back to the top
	scrollTo(list, 20)
	settleOut()
	assert(medium.Size == UDim2.new(1, 0, 0, 112) and near(list.CanvasPosition.Y, 0), `exit expand: canvas {list.CanvasPosition.Y}`)
	q.dispose(medium)
	q.dispose(list)
	-- enterAlways, TopAppBar 64: near the top, 40 hidden (0.63) hides and scrolls the first row up to the screen top
	local enter = AppBar.TopAppBarDefaults.enterAlwaysScrollBehavior()
	local bar: any = AppBar.TopAppBar({ Title = "Enter", ScrollBehavior = enter })
	list = scroller(enter)
	scrollTo(list, 40)
	settleOut()
	assert(bar.Size == UDim2.new(1, 0, 0, 0) and near(list.CanvasPosition.Y, 64), `enter hide: canvas {list.CanvasPosition.Y}`)
	assert(near(rowGap(bar, list, 64), 0))
	-- 20 hidden (0.31) shows; the canvas follows back to the top
	scrollTo(list, 20)
	assert(near(enter.State.HeightOffset:Get(), -20))
	settleOut()
	assert(bar.Size == UDim2.new(1, 0, 0, 64) and near(list.CanvasPosition.Y, 0), `enter show: canvas {list.CanvasPosition.Y}`)
	-- deep in the list the bar comes back 30 px (0.47 hidden): showing it scrolls the content down with it, as
	-- Compose's padding pushes the list — the content's own scroll (canvas + offset) stays 436
	scrollTo(list, 500)
	scrollTo(list, 470)
	assert(near(enter.State.HeightOffset:Get(), -34))
	settleOut()
	assert(bar.Size == UDim2.new(1, 0, 0, 0) and near(list.CanvasPosition.Y, 500), `enter deep hide: canvas {list.CanvasPosition.Y}`)
	scrollTo(list, 470)
	scrollTo(list, 466)
	assert(near(enter.State.HeightOffset:Get(), -30))
	settleOut()
	assert(bar.Size == UDim2.new(1, 0, 0, 64) and near(list.CanvasPosition.Y, 436), `enter deep show: canvas {list.CanvasPosition.Y}`)
	assert(#Heartbeat.connections == baseBeats)
	q.dispose(bar)
	q.dispose(list)
	-- a list too short to scroll the collapse range (furthest scroll 30 < 48): collapsing would leave a gap, expand
	local short = AppBar.TopAppBarDefaults.exitUntilCollapsedScrollBehavior()
	medium = AppBar.MediumTopAppBar({ Title = "Short", ScrollBehavior = short })
	list = scroller(short, 30)
	scrollTo(list, 30)
	assert(near(short.State.CollapsedFraction:Get(), 30 / 48))
	settleOut()
	assert(medium.Size == UDim2.new(1, 0, 0, 112) and near(list.CanvasPosition.Y, 0), `short: canvas {list.CanvasPosition.Y}`)
	q.dispose(medium)
	q.dispose(list)
	H.advance(0.5)
	H.assertNoDebugOutput("settle gap")
end)

H.section("settle yields to the user: a scroll during it cancels it; a held mouse button (scrollbar thumb) delays it", function()
	local exit = AppBar.TopAppBarDefaults.exitUntilCollapsedScrollBehavior()
	local medium: any = AppBar.MediumTopAppBar({ Title = "Medium", ScrollBehavior = exit })
	local list = scroller(exit)
	scrollTo(list, 30)
	H.advance(0.1) -- the idle timer starts the settle; this Heartbeat (dt 0.1) runs it half way
	local y = list.CanvasPosition.Y
	assert(y > 30 and y < 48, `settling: canvas {y}`)
	assert(#Heartbeat.connections == baseBeats + 1, "the settle loop runs")
	-- the wheel moves the canvas mid-settle: the loop ends at once, the bar follows the wheel, the canvas stays put
	scrollTo(list, y - 10)
	assert(#Heartbeat.connections == baseBeats, "a user scroll cancels the settle")
	local offset = exit.State.HeightOffset:Get()
	assert(near(offset, -(y - 10)), `the bar follows the user's scroll: {offset}`)
	H.advance(0.02)
	H.advance(0.02)
	assert(near(list.CanvasPosition.Y, y - 10) and near(exit.State.HeightOffset:Get(), offset), "nothing fights the scroll")
	-- the user's stop settles afresh
	settleOut()
	assert(near(list.CanvasPosition.Y + exit.State.HeightOffset:Get(), 0), "settled again, no gap")
	-- the scrollbar thumb held still part way: no settle until the button is released
	scrollTo(list, 0)
	settleOut()
	H.UserInputService.MouseButton1Down = true
	scrollTo(list, 30)
	H.advance(0.15)
	for _ = 1, 30 do
		H.advance(0.02)
	end
	assert(near(list.CanvasPosition.Y, 30) and near(exit.State.HeightOffset:Get(), -30), "held: no settle")
	assert(#Heartbeat.connections == baseBeats)
	H.UserInputService.MouseButton1Down = false
	settleOut()
	assert(medium.Size == UDim2.new(1, 0, 0, 64) and near(list.CanvasPosition.Y, 48), `released: settles {list.CanvasPosition.Y}`)
	q.dispose(medium)
	q.dispose(list)
	H.advance(0.5)
	assert(H.pendingTimers() == 0)
	H.assertNoDebugOutput("settle cancel")
end)

H.section("story mode (Input.use): the held button comes from the injected listener, not the engine service", function()
	-- inside a UI Labs widget the engine reports no button held; the held scrollbar thumb is seen only by the listener
	local listener = {
		InputBegan = H.mock.newSignal(),
		InputChanged = H.mock.newSignal(),
		InputEnded = H.mock.newSignal(),
		MouseMoved = H.mock.newSignal(),
	}
	Input.use(listener :: any)
	local exit = AppBar.TopAppBarDefaults.exitUntilCollapsedScrollBehavior()
	local medium: any = AppBar.MediumTopAppBar({ Title = "Medium", ScrollBehavior = exit })
	local list = scroller(exit)
	assert(H.UserInputService.MouseButton1Down == false)
	listener.InputBegan:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1 }), false)
	scrollTo(list, 30)
	H.advance(0.15)
	for _ = 1, 30 do
		H.advance(0.02)
	end
	assert(near(list.CanvasPosition.Y, 30) and near(exit.State.HeightOffset:Get(), -30), "listener-held: no settle")
	assert(#Heartbeat.connections == baseBeats)
	listener.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1 }), false)
	settleOut()
	assert(medium.Size == UDim2.new(1, 0, 0, 64) and near(list.CanvasPosition.Y, 48), `listener-released: settles {list.CanvasPosition.Y}`)
	q.dispose(medium)
	q.dispose(list)
	Input.use(nil)
	assert(#(listener.InputBegan :: any).connections == 0 and #(listener.InputEnded :: any).connections == 0, "tracking dropped")
	assert(#(listener.MouseMoved :: any).connections == 0)
	H.advance(0.5)
	assert(H.pendingTimers() == 0)
	H.assertNoDebugOutput("story settle")
end)

-- ── bottom ──────────────────────────────────────────────────────────────────

H.section("BottomAppBar: 80 surfaceContainer, actions from 4 centered under the 4 top padding, FAB secondaryContainer 12 / 16 in", function()
	local bar: any = AppBar.BottomAppBar({
		Actions = { { Icon = "rbxassetid://1", Label = "Check" }, { Icon = "rbxassetid://2", Label = "Edit" } },
		FloatingActionButton = { Icon = "rbxassetid://3", OnClick = act("fab") },
	})
	assert(bar.Size == UDim2.new(1, 0, 0, 80) and bar.BackgroundColor3 == L.SurfaceContainer and own(bar, "UIShadow") == nil)
	local actions = H.find(bar, "Actions")
	assert(actions.Position == UDim2.fromOffset(4, 42) and actions.AnchorPoint == Vector2.new(0, 0.5) and actions.Size == UDim2.fromOffset(96, 48))
	assert(H.find(buttons(actions)[1], "Icon").ImageColor3 == L.OnSurface, "contentColorFor(surfaceContainer)")
	local fab = H.find(bar, "FAB")
	assert(fab.AnchorPoint == Vector2.new(1, 0) and fab.Position == UDim2.new(1, -16, 0, 12) and fab.Size == UDim2.fromOffset(56, 56))
	assert(fab.BackgroundColor3 == L.SecondaryContainer)
	H.fire(fab, "Activated", H.input({}), 1)
	assert(log[1] == "fab")
	local n = H.countDescendants(bar) + 1
	print(`[appbar] BottomAppBar with two actions and a FAB: {n} instances`)
	H.resetOutput()
	q.dispose(bar)
	table.clear(log)
	local flex: any = AppBar.FlexibleBottomAppBar({ Actions = { { Icon = "a", Label = "A" }, { Icon = "b", Label = "B" }, { Icon = "c", Label = "C" } } })
	assert(flex.Size == UDim2.new(1, 0, 0, 64) and flex.BackgroundColor3 == L.SurfaceContainer)
	local row = H.find(flex, "Row")
	assert(own(row, "UIPadding").PaddingLeft == UDim.new(0, 16) and own(row, "UIListLayout").HorizontalFlex == Enum.UIFlexAlignment.SpaceBetween)
	q.dispose(flex)
	local fixed: any = AppBar.FlexibleBottomAppBar({ HorizontalArrangement = "Fixed", Actions = { { Icon = "a", Label = "A" } } })
	local layout = own(H.find(fixed, "Row"), "UIListLayout")
	assert(layout.HorizontalAlignment == Enum.HorizontalAlignment.Center and layout.Padding == UDim.new(0, 32))
	q.dispose(fixed)
	H.assertNoDebugOutput("bottom")
end)

H.done()
