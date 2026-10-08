--!strict
-- Floating toolbars (Compose FloatingToolbar.kt): the no-FAB form (64 thick, padding 8, corner full, leading / trailing
-- shown while expanded) and the FAB form (toolbar + 8 + FAB in an 80 box, FAB 56 expanded / 80 collapsed), standard and
-- vibrant colors, the expanded progress (Short3), vertical forms, dispose.
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Tokens = require("../src/Tokens")
local Toolbar = require("../src/Toolbar")
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
local function settle()
	for _ = 1, 12 do
		H.advance(0.02)
	end
end
local function action(name: string): any
	return { Icon = "rbxassetid://1", Label = name }
end

H.section("HorizontalFloatingToolbar: 8 + leading + content + trailing + 8 by 64, corner full, standard colors; collapse hides leading / trailing", function()
	local expanded = q.Source(true)
	local bar: any = Toolbar.HorizontalFloatingToolbar({
		Expanded = expanded,
		LeadingContent = { action("Bold") },
		Content = { action("A"), action("B") },
		TrailingContent = { action("More") },
	})
	assert(bar.Name == "HorizontalFloatingToolbar" and bar.Size == UDim2.fromOffset(8 + 48 + 96 + 48 + 8, 64), tostring(bar.Size))
	assert(bar.BackgroundColor3 == L.SurfaceContainer and own(bar, "UICorner").CornerRadius == UDim.new(0.5, 0) and own(bar, "UIShadow") == nil)
	local leading, content, trailing = H.find(bar, "Leading"), H.find(bar, "Content"), H.find(bar, "Trailing")
	assert(leading.Position == UDim2.fromOffset(8, 8) and leading.Size == UDim2.fromOffset(48, 48) and leading.ClipsDescendants)
	assert(content.Position == UDim2.fromOffset(56, 8) and trailing.Position == UDim2.fromOffset(152, 8))
	assert(H.find(H.find(content, "IconButton"), "Icon").ImageColor3 == L.OnSurface, "standard: icons onSurface")
	local trailRow = H.find(trailing, "Row")
	assert(trailRow.AnchorPoint == Vector2.new(1, 0) and trailRow.Position == UDim2.fromScale(1, 0), "trailing revealed from its end")
	assert(H.find(leading, "Row").AnchorPoint == Vector2.new(0, 0), "leading revealed from its start")
	local n = H.countDescendants(bar) + 1
	print(`[toolbar] horizontal, 1 + 2 + 1 actions: {n} instances`)
	H.resetOutput()
	assert(n == 2 + 3 * 3 + 4 * 7, `count {n}`)
	expanded:Set(false)
	assert(#Heartbeat.connections == baseBeats + 1, "one progress animates")
	H.advance(0.05)
	local w = bar.Size.X.Offset
	assert(w < 208 and w > 112, `in between: {w}`)
	settle()
	assert(bar.Size == UDim2.fromOffset(112, 64) and leading.Size == UDim2.fromOffset(0, 48) and leading.Visible == false)
	assert(content.Position == UDim2.fromOffset(8, 8) and trailing.Visible == false)
	assert(#Heartbeat.connections == baseBeats)
	q.dispose(bar)
	H.assertNoDebugOutput("horizontal")
end)

H.section("vibrant colors: primaryContainer, icons onPrimaryContainer, FAB tertiaryContainer", function()
	local bar: any = Toolbar.HorizontalFloatingToolbar({ Expanded = true, Colors = "Vibrant", Content = { action("A") } })
	assert(bar.BackgroundColor3 == L.PrimaryContainer and H.find(H.find(bar, "IconButton"), "Icon").ImageColor3 == L.OnPrimaryContainer)
	q.dispose(bar)
	local withFab: any = Toolbar.HorizontalFloatingToolbar({
		Expanded = true,
		Colors = "Vibrant",
		Content = { action("A") },
		FloatingActionButton = { Icon = "rbxassetid://2" },
	})
	assert(H.find(withFab, "FAB").BackgroundColor3 == L.TertiaryContainer)
	q.dispose(withFab)
	H.assertNoDebugOutput("vibrant")
end)

H.section("FAB form: toolbar + 8 + FAB in an 80 box; expanded FAB 56 + Level1 shadow, collapsed FAB 80 and no toolbar", function()
	local expanded = q.Source(true)
	local clicks = 0
	local bar: any = Toolbar.HorizontalFloatingToolbar({
		Expanded = expanded,
		Content = { action("A"), action("B") },
		FloatingActionButton = { Icon = "rbxassetid://2", OnClick = function()
			clicks += 1
		end },
	})
	assert(bar.Size == UDim2.fromOffset(112 + 8 + 56, 80) and bar.BackgroundTransparency == 1)
	local tb, fab = H.find(bar, "Toolbar"), H.find(bar, "FAB")
	assert(tb.Position == UDim2.fromOffset(0, 8) and tb.Size == UDim2.fromOffset(112, 64) and tb.BackgroundColor3 == L.SurfaceContainer)
	assert(own(tb, "UIShadow") ~= nil and H.find(tb, "Clip").ClipsDescendants)
	assert(fab.Size == UDim2.fromOffset(56, 56) and fab.Position == UDim2.fromOffset(120, 12) and fab.BackgroundColor3 == L.PrimaryContainer)
	H.fire(fab, "Activated", H.input({}), 1)
	assert(clicks == 1)
	local n = H.countDescendants(bar) + 1
	print(`[toolbar] FAB form, 2 actions: {n} instances`)
	H.resetOutput()
	expanded:Set(false)
	settle()
	assert(tb.Size == UDim2.fromOffset(0, 64) and tb.Position == UDim2.fromOffset(112, 8), "shrunk toward the FAB")
	assert(fab.Size == UDim2.fromOffset(80, 80) and fab.Position == UDim2.fromOffset(96, 0))
	q.dispose(bar)
	local start: any = Toolbar.HorizontalFloatingToolbar({
		Expanded = true,
		Content = { action("A") },
		FloatingActionButton = { Icon = "rbxassetid://2" },
		FloatingActionButtonPosition = "Start",
	})
	assert(H.find(start, "FAB").Position == UDim2.fromOffset(0, 12) and H.find(start, "Toolbar").Position == UDim2.fromOffset(64, 8))
	q.dispose(start)
	H.advance(0.5)
	H.assertNoDebugOutput("fab form")
end)

H.section("VerticalFloatingToolbar: 64 wide, leading revealed from its bottom; FAB form at the bottom by default", function()
	local bar: any = Toolbar.VerticalFloatingToolbar({ Expanded = true, LeadingContent = { action("L") }, Content = { action("A") } })
	assert(bar.Size == UDim2.fromOffset(64, 8 + 48 + 48 + 8))
	local leading = H.find(bar, "Leading")
	assert(leading.Position == UDim2.fromOffset(8, 8) and leading.Size == UDim2.fromOffset(48, 48))
	assert(H.find(leading, "Row").AnchorPoint == Vector2.new(0, 1))
	assert(H.find(bar, "Content").Position == UDim2.fromOffset(8, 56))
	q.dispose(bar)
	local withFab: any = Toolbar.VerticalFloatingToolbar({
		Expanded = true,
		Content = { action("A"), action("B"), action("C") },
		FloatingActionButton = { Icon = "rbxassetid://2" },
	})
	assert(withFab.Size == UDim2.fromOffset(80, 160 + 8 + 56))
	assert(H.find(withFab, "Toolbar").Position == UDim2.fromOffset(8, 0) and H.find(withFab, "Toolbar").Size == UDim2.fromOffset(64, 160))
	assert(H.find(withFab, "FAB").Position == UDim2.fromOffset(12, 168))
	q.dispose(withFab)
	H.assertNoDebugOutput("vertical")
end)

H.section("toolbar action ripple stays inside the 40 px button (BOUNDED); nothing left after dispose", function()
	local bar: any = Toolbar.HorizontalFloatingToolbar({ Expanded = true, Content = { action("A") } })
	Bounded.pressBounded(H.find(bar, "IconButton"), 40, 40, "toolbar action")
	q.dispose(bar)
	H.advance(1)
	assert(#Heartbeat.connections == baseBeats and H.pendingTimers() == 0)
	H.assertNoDebugOutput("toolbar ripple")
end)

H.done()
