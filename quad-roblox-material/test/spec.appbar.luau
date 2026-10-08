--!strict
-- App bars: the six top app bars (Compose AppBar.kt geometry, colors, title placement), the action model (icon buttons in
-- the bar's color, toggles, the overflow menu past MaxItemCount), the scroll behaviors driven by a ScrollingFrame's
-- CanvasPosition (pinned color, enterAlways, exitUntilCollapsed, settle), BottomAppBar and FlexibleBottomAppBar.
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local D = q.Declaration
local Tokens = require("../src/Tokens")
local Overlay = require("../src/Overlay")
local AppBar = require("../src/AppBar")
local Top = require("../src/AppBar/Top")
local Bounded = require("./support/bounded")

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
	local screen = D.Frame { overlay.Layer }
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

local function scroller(behavior: any): any
	return D.ScrollingFrame { Name = "List", behavior.Hook }
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
