--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local D = q.Declaration
local Gallery = require("../gallery")
local Theme = require("../src/Theme")
local Tokens = require("../src/Tokens")

local UIS = H.UserInputService
local Heartbeat = H.RunService.Heartbeat :: any

local function inputConns(): number
	return #(UIS.InputChanged :: any).connections + #(UIS.InputEnded :: any).connections + #(UIS.InputBegan :: any).connections
end
local function beats(): number
	return #Heartbeat.connections
end
local function click(inst: any)
	H.fire(inst, "Activated", H.input({}), 1)
end
local function named(root: any, name: string): { any }
	return H.findAll(root, function(i: any)
		return i.Name == name
	end)
end
local function byText(root: any, text: string): any
	local hits = H.findAll(root, function(i: any)
		return i.Text == text
	end)
	assert(#hits >= 1, `no instance with Text "{text}"`)
	return hits[1]
end
-- the TextButton that holds (or is) the instance showing `text`
local function button(root: any, text: string): any
	local node: any = byText(root, text)
	while node ~= nil and node.ClassName ~= "TextButton" do
		node = node.Parent
	end
	assert(node ~= nil, `no button around "{text}"`)
	return node
end
local function tabButton(root: any, text: string): any
	for _, b in named(root, "Tab") do
		if H.find(b, "Label").Text == text then
			return b
		end
	end
	error(`no tab "{text}"`)
end
local function visibleSection(gui: any): string
	local page = H.find(gui, "Page") :: any
	local kids = page:GetChildren()
	local out: { string } = {}
	for _, k in kids do
		if (k :: any).ClassName == "Frame" then
			table.insert(out, (k :: any).Name)
		end
	end
	return table.concat(out, ",")
end

local baseInput, baseBeats = inputConns(), beats()
local parent = Instance.new("Folder")
local gui = Gallery.mount(parent) :: any
local layer = H.find(gui, "Overlay") :: any
local counts: { [string]: number } = {}

H.section("mount: ScreenGui settings, own overlay layer, first section only", function()
	assert(gui.Parent == parent and gui.ResetOnSpawn == false and gui.ZIndexBehavior == Enum.ZIndexBehavior.Sibling)
	assert(layer ~= nil and layer.Parent == gui, "overlay layer in the ScreenGui")
	assert(gui.DisplayOrder > 0 and gui.IgnoreGuiInset == false)
	assert(visibleSection(gui) == "Buttons", visibleSection(gui))
	local scroll = H.find(gui, "Scroller") :: any
	assert(scroll.ClassName == "ScrollingFrame" and scroll.AutomaticCanvasSize == Enum.AutomaticSize.Y)
	counts.Buttons = H.countDescendants(gui)
	print(`[gallery] mounted: {counts.Buttons} instances (Buttons section)`)
	H.resetOutput()
	H.assertNoDebugOutput("mount")
end)

H.section("buttons: click counter, disable switch drives the disabled buttons", function()
	click(button(gui, "Filled"))
	click(button(gui, "Tonal"))
	assert(byText(gui, "Clicked 2 times") ~= nil)
	local filled = H.find(gui, "Switch") :: any
	click(filled)
	H.finishTweens()
	local disabledButtons = H.findAll(gui, function(i: any)
		return i.ClassName == "TextButton" and i.Interactable == false
	end)
	local dis = #disabledButtons
	assert(dis >= 15, `disabled buttons after the switch: {dis}`)
	click(filled)
	H.finishTweens()
	H.assertNoDebugOutput("buttons")
end)

local order = { "Selection", "Text", "Surfaces", "Overlays", "Navigation", "Chips", "Pickers", "Theme" }
local sectionNames: { [string]: string } = {
	Selection = "Selection",
	Text = "TextInput",
	Surfaces = "Surfaces",
	Overlays = "Overlays",
	Navigation = "Navigation",
	Chips = "ChipsTabsProgress",
	Pickers = "Pickers",
	Theme = "Theme",
}

H.section("every tab: only the selected section exists; switching destroys the previous one", function()
	for _, tab in order do
		click(tabButton(gui, tab))
		H.finishTweens()
		assert(visibleSection(gui) == sectionNames[tab], `{tab}: {visibleSection(gui)}`)
		counts[tab] = H.countDescendants(gui)
		print(`[gallery] {tab}: {counts[tab]} instances total`)
		H.resetOutput()
		H.assertNoDebugOutput(tab)
	end
	click(tabButton(gui, "Buttons"))
	H.finishTweens()
	assert(visibleSection(gui) == "Buttons")
	assert(H.countDescendants(gui) == counts.Buttons, `back to the first section: {H.countDescendants(gui)} vs {counts.Buttons}`)
	H.assertNoDebugOutput("back")
end)

H.section("section state survives leaving and re-entering (Memo)", function()
	click(tabButton(gui, "Selection"))
	click(button(gui, "Pear"))
	assert(byText(gui, "Fruit: pear") ~= nil)
	click(button(gui, "Apple"))
	assert(byText(gui, "Fruit: apple") ~= nil)
	click(tabButton(gui, "Buttons"))
	click(tabButton(gui, "Selection"))
	assert(byText(gui, "Fruit: apple") ~= nil, "memoized Source kept the choice")
	click(tabButton(gui, "Buttons"))
	H.assertNoDebugOutput("memo")
end)

H.section("surfaces: dragging a row's handle re-orders the list through OnReorder (at once / after the pretend 2 s server round trip)", function()
	click(tabButton(gui, "Surfaces"))
	H.finishTweens()
	local UIS: any = H.UserInputService
	local function rows(): { any }
		local found = named(gui, "ReorderRow")
		table.sort(found, function(a: any, b: any)
			return a.LayoutOrder < b.LayoutOrder
		end)
		return found
	end
	local function titles(): string
		local out: { string } = {}
		for _, r in rows() do
			table.insert(out, H.find(r, "Headline").Text)
		end
		return table.concat(out, ",")
	end
	-- the mock has no layout: stack the rows as the engine would (two-line rows 72, one-line 56)
	local function layout()
		local y = 0
		for _, r in rows() do
			local h = if H.find(r, "Supporting") ~= nil then 72 else 56
			H.setAbs(r, 0, y, 360, h)
			y += h
		end
		H.setAbs(rows()[1].Parent, 0, 0, 360, y)
	end
	local function drag(index: number, dy: number)
		layout()
		local handle = H.find(rows()[index], "DragHandle")
		local y = rows()[index].AbsolutePosition.Y + 20
		local input = H.input({ Position = Vector3.new(340, y, 0) })
		H.fire(handle, "InputBegan", input)
		UIS.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(340, y + dy, 0) }))
		H.fire(handle, "InputEnded", input)
		UIS.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(340, y + dy, 0) }))
	end
	assert(titles() == "Opening,Interlude,Main theme,Bridge,Finale", titles())
	drag(1, 60) -- Opening (72) under Interlude (56): its slots are 0 / 56 / 128 ..., 60 is nearest to the second
	assert(titles() == "Interlude,Opening,Main theme,Bridge,Finale", titles())
	assert(byText(gui, "OnReorder(1, 2) applied at once") ~= nil)
	H.finishTweens()
	H.advance(0.3)
	click(H.find(byText(gui, "Server delay 2 s").Parent, "Switch"))
	H.finishTweens()
	drag(5, -80)
	assert(titles() == "Interlude,Opening,Main theme,Bridge,Finale", "the pretend server has not answered")
	assert(byText(gui, "OnReorder(5, 4) sent: waiting for the server (2 s)") ~= nil)
	H.finishTweens()
	H.advance(1.9)
	H.finishTweens()
	-- longer than the plain 1 s wait: `Reordering` keeps the dropped rows where they are (Finale 56 up, Bridge 72 down)
	assert(H.find(rows()[5], "Lift").Position.Y.Offset == -56 and H.find(rows()[4], "Lift").Position.Y.Offset == 72, "still waiting at 1.9 s")
	H.advance(0.15)
	assert(titles() == "Interlude,Opening,Main theme,Finale,Bridge", titles())
	assert(byText(gui, "OnReorder(5, 4) applied by the server after 2 s") ~= nil)
	assert(H.find(rows()[5], "Lift").Position.Y.Offset == 0 and H.find(rows()[4], "Lift").Position.Y.Offset == 0, "the answer moves nothing")
	H.finishTweens()
	H.advance(0.5)
	-- refused by the server: the rows wait the 2 s, then go back
	click(H.find(byText(gui, "Server refuses").Parent, "Switch"))
	H.finishTweens()
	drag(1, 60)
	H.finishTweens()
	H.advance(1.9)
	assert(H.find(rows()[1], "Lift").Position.Y.Offset == 72, "waiting")
	H.advance(0.15)
	H.finishTweens()
	assert(titles() == "Interlude,Opening,Main theme,Finale,Bridge" and H.find(rows()[1], "Lift").Position.Y.Offset == 0, "back")
	assert(byText(gui, "OnReorder(1, 2): the server refused, the rows go back") ~= nil)
	H.advance(0.5)
	click(H.find(byText(gui, "Server refuses").Parent, "Switch"))
	click(H.find(byText(gui, "Server delay 2 s").Parent, "Switch"))
	click(tabButton(gui, "Buttons"))
	click(tabButton(gui, "Surfaces"))
	assert(titles() == "Interlude,Opening,Main theme,Finale,Bridge", "the order is the owner's data: it survives the tab")
	click(tabButton(gui, "Buttons"))
	H.finishTweens()
	H.advance(0.5)
	H.assertNoDebugOutput("reorder")
end)

H.section("theme switch: the Switch toggles Theme.default and every swatch follows", function()
	click(tabButton(gui, "Theme"))
	H.finishTweens()
	local before = Theme.default.Scheme:Get()
	assert(before == "light")
	local sw = H.find(gui, "Switch") :: any
	click(sw)
	H.finishTweens()
	assert(Theme.default.Scheme:Get() == "dark", "switch wrote the scheme")
	assert(H.find(sw, "Halo").Position == UDim2.fromOffset(36, 16), "controlled form: the handle shows the derived `Checked` (on)")
	assert(H.find(gui, "SchemeBridge") == nil, "no bridge frame / Effect any more")
	local primary = named(gui, "Primary")
	assert(#primary >= 1 and primary[1].BackgroundColor3 == Tokens.Color.Dark.Primary, "swatch follows the scheme")
	assert(H.find(gui, "Page") ~= nil)
	click(button(gui, "Toggle"))
	H.finishTweens()
	assert(Theme.default.Scheme:Get() == "light", "Toggle button flips it back")
	assert(H.find(sw, "Halo").Position == UDim2.fromOffset(16, 16), "...and the Switch follows without any Effect (off)")
	assert(sw.ClassName == "TextButton")
	H.assertNoDebugOutput("theme")
	click(tabButton(gui, "Buttons"))
end)

H.section("overlays: one of each kind opens and closes through the panel's own overlay", function()
	click(tabButton(gui, "Overlays"))
	H.finishTweens()
	local count = function(): number
		return #layer:GetChildren()
	end
	local base = count()
	-- dialog
	click(button(gui, "Confirm"))
	assert(count() > base, "dialog opened in the gallery's overlay layer")
	click(button(gui, "Cancel"))
	H.finishTweens()
	H.advance(0.5)
	assert(count() == base, `dialog closed: {count()} vs {base}`)
	assert(byText(gui, "Last dialog result: cancelled") ~= nil)
	-- snackbar
	click(button(gui, "With action"))
	assert(count() > base, "snackbar shown")
	H.finishTweens()
	click(button(gui, "Undo"))
	H.finishTweens()
	H.advance(0.5)
	assert(count() == base, "snackbar gone after its action")
	assert(byText(gui, "Last snackbar: undo pressed") ~= nil)
	-- the second host, placed at the top of the same layer
	click(button(gui, "Show at top"))
	local topSnack = H.find(layer, "Snackbar") :: any
	assert(topSnack ~= nil and topSnack.AnchorPoint == Vector2.new(0.5, 0), "the top host's snackbar hangs from the layer's top")
	H.finishTweens()
	assert(topSnack.Position == UDim2.new(0.5, 0, 0, 16), "16 under the top edge")
	H.advance(4.1)
	H.finishTweens()
	H.advance(0.5)
	assert(count() == base, "the top snackbar timed out")
	assert(byText(gui, "Last snackbar: Timeout (top)") ~= nil)
	-- menu
	click(button(gui, "Actions"))
	assert(count() > base, "menu opened")
	click(button(gui, "Rename"))
	H.finishTweens()
	H.advance(0.5)
	assert(count() == base, "menu closed by an item")
	assert(byText(gui, "Last menu item: rename") ~= nil)
	-- tooltip: hover shows after the delay
	local target = button(gui, "Hover me")
	H.fire(target, "MouseEnter", 0, 0)
	H.advance(0.6)
	H.finishTweens()
	assert(count() > base, "tooltip shown")
	H.fire(target, "MouseLeave", 0, 0)
	H.finishTweens()
	H.advance(0.5)
	assert(count() == base, "tooltip hidden")
	H.assertNoDebugOutput("overlays")
	click(tabButton(gui, "Buttons"))
end)

H.section("sheets and drawers: the modal sheets open in the panel's layer, the standard ones sit in mock screens", function()
	click(tabButton(gui, "Overlays"))
	H.finishTweens()
	local base = #layer:GetChildren()
	local function escape()
		UIS.InputBegan:Fire(H.input({ KeyCode = Enum.KeyCode.Escape, UserInputType = Enum.UserInputType.Keyboard }), false)
	end
	click(button(gui, "Modal bottom sheet"))
	assert(#layer:GetChildren() == base + 1, "modal bottom sheet opened")
	escape()
	H.advance(0.5)
	assert(#layer:GetChildren() == base, "Escape closed it")
	assert(byText(gui, "Last sheet pick: dismissed") ~= nil)
	click(button(gui, "Modal side sheet"))
	assert(#layer:GetChildren() == base + 1, "modal side sheet opened")
	escape()
	H.advance(0.5)
	assert(#layer:GetChildren() == base)
	click(button(gui, "Detached modal"))
	assert(#layer:GetChildren() == base + 1, "detached modal side sheet opened")
	local detachedModal = H.find(layer, "SideSheet") :: any
	H.finishTweens()
	assert(detachedModal.Position == UDim2.new(1, -16, 0, 16) and H.find(detachedModal, "CornerPatch") == nil, "16 off the edge, no squared corner")
	escape()
	H.advance(0.5)
	assert(#layer:GetChildren() == base)
	local detached = H.find(H.find(gui, "DetachedSideSheetScreen"), "SideSheet") :: any
	assert(detached.Position == UDim2.new(1, -16, 0, 16) and detached.Size == UDim2.new(0, 256, 1, -32), "detached standard sheet expanded")
	click(button(gui, "Toggle detached"))
	H.finishTweens()
	assert(detached.Position == UDim2.new(1, 256, 0, 16), "...and hidden past the edge, margin included")
	H.advance(0.5)
	local detachedStart = H.find(H.find(gui, "DetachedStartSideSheetScreen"), "SideSheet") :: any
	assert(detachedStart.Position == UDim2.new(0, 16, 0, 16), "the start-edge one 16 in from the left")
	local side = H.find(H.find(gui, "SideSheetScreen"), "SideSheet") :: any
	assert(side.Position == UDim2.fromScale(1, 0), "standard side sheet expanded")
	click(button(gui, "Toggle side sheet"))
	H.finishTweens()
	assert(side.Position == UDim2.new(1, 256, 0, 0), "...and hidden by the toggle")
	H.advance(0.5)
	assert(H.find(H.find(gui, "BottomSheetScreen"), "BottomSheet") ~= nil, "the scaffold's sheet")
	click(tabButton(gui, "Navigation"))
	H.finishTweens()
	local screen = H.find(gui, "ModalDrawerScreen") :: any
	local drawer = H.find(screen, "Drawer") :: any
	assert(drawer.Visible == false, "closed")
	local menu = H.findAll(H.find(screen, "TopBar"), function(i: any)
		return i.ClassName == "TextButton"
	end)[1]
	click(menu)
	assert(drawer.Visible == true, "the menu button opened it")
	H.finishTweens()
	click(button(screen, "Outbox"))
	assert(byText(screen, "Page: outbox") ~= nil, "picked")
	H.finishTweens()
	H.advance(0.5)
	assert(drawer.Visible == false, "picking closed it (Compose sample)")
	assert(H.find(gui, "PermanentDrawerScreen") ~= nil and H.find(gui, "DismissibleDrawerScreen") ~= nil)
	click(tabButton(gui, "Buttons"))
	H.advance(0.5)
	H.assertNoDebugOutput("sheets and drawers")
end)

H.section("navigation bar, rail, app bars and toolbars: the Navigation tab's screens work", function()
	click(tabButton(gui, "Navigation"))
	H.finishTweens()
	local phone = H.find(gui, "NavigationBarScreen") :: any
	local bar = H.find(phone, "ShortNavigationBar") :: any
	assert(bar ~= nil and bar.Size == UDim2.new(1, 0, 0, 64))
	click(button(phone, "Saved"))
	assert(byText(phone, "Page: saved") ~= nil and byText(H.find(gui, "NavigationRailScreen"), "Page: saved") ~= nil, "one page Source")
	local railScreen = H.find(gui, "NavigationRailScreen") :: any
	local rail = H.find(railScreen, "WideNavigationRail") :: any
	assert(rail.Size == UDim2.new(0, 96, 1, 0))
	click(H.findAll(H.find(rail, "Header"), function(i: any)
		return i.ClassName == "TextButton"
	end)[1])
	for _ = 1, 15 do
		H.advance(0.02)
	end
	assert(rail.Size.X.Offset >= 220, "the header button expanded the rail")
	local exit = H.find(gui, "ExitUntilCollapsedAppBarScreen") :: any
	local medium = H.find(exit, "MediumFlexibleTopAppBar") :: any
	assert(medium.Size == UDim2.new(1, 0, 0, 136))
	local content = H.find(exit, "Content") :: any
	content.CanvasPosition = Vector2.new(0, 200)
	assert(medium.Size == UDim2.new(1, 0, 0, 64), "collapsed by the list's scroll")
	content.CanvasPosition = Vector2.new(0, 0)
	assert(medium.Size == UDim2.new(1, 0, 0, 136))
	assert(H.find(gui, "BottomAppBarScreen") ~= nil and H.find(gui, "LargeFlexibleAppBar") ~= nil)
	local toolbars = H.find(gui, "ToolbarScreen") :: any
	local horizontal = H.find(toolbars, "HorizontalFloatingToolbar") :: any
	local wide = horizontal.Size.X.Offset
	local labeled = (byText(gui, "Expanded") :: any).Parent
	click(H.findAll(labeled, function(i: any)
		return i.Name == "Switch"
	end)[1])
	for _ = 1, 15 do
		H.advance(0.02)
	end
	assert(horizontal.Size.X.Offset < wide, "the Expanded switch collapsed the toolbars")
	click(tabButton(gui, "Buttons"))
	H.advance(0.5)
	H.assertNoDebugOutput("layout group")
end)

H.section("Scaffold screens: the bars placed, the FAB 16 above the navigation bar, its snackbar in the screen's own layer above the FAB", function()
	click(tabButton(gui, "Navigation"))
	H.finishTweens()
	local phone = H.find(gui, "NavigationBarScreen") :: any
	local scaffold = H.find(phone, "Scaffold") :: any
	local bar = H.find(scaffold, "ShortNavigationBar") :: any
	assert(bar.Parent == scaffold and bar.AnchorPoint == Vector2.new(0, 1) and bar.Position == UDim2.fromScale(0, 1), "bar at the bottom")
	local body = H.find(scaffold, "Body") :: any
	assert(body.Parent == scaffold and body.Position == UDim2.fromOffset(0, 0) and body.Size == UDim2.new(1, 0, 1, -64), "content above the bar")
	local floating = H.find(scaffold, "Floating") :: any
	assert(floating.Size == UDim2.new(1, 0, 1, -64) and floating.ZIndex == 2, "FAB / snackbar frame ends at the bar's top")
	local pad = H.find(floating, "UIPadding") :: any
	assert(pad.PaddingBottom == UDim.new(0, 16) and pad.PaddingRight == UDim.new(0, 16) and pad.PaddingLeft == UDim.new(0, 16), "FabSpacing")
	local list = H.find(floating, "UIListLayout") :: any
	assert(list.HorizontalAlignment == Enum.HorizontalAlignment.Right and list.VerticalAlignment == Enum.VerticalAlignment.Bottom, "End")
	local host = H.find(floating, "SnackbarHost") :: any
	assert(host.LayoutOrder == -1 and H.find(host, "UIFlexItem") ~= nil, "the snackbar host fills above the FAB")
	local fab = H.findAll(floating, function(i: any)
		return i.Parent == floating and i.ClassName == "TextButton"
	end)[1]
	assert(fab ~= nil and (fab.LayoutOrder or 0) == 0, "the FAB below the snackbar host (default LayoutOrder)")
	click(fab)
	H.advance(0.05)
	local own = H.find(host, "Overlay") :: any
	assert(H.find(own, "Snackbar") ~= nil, "the snackbar opened in the screen's layer")
	assert(H.find(layer, "Snackbar") == nil, "not in the panel's overlay")
	H.advance(5)
	assert(H.find(own, "Snackbar") == nil, "timed out")
	for _, name in { "FlexibleBottomAppBarScreen", "BottomAppBarScreen", "WideNavigationBarScreen" } do
		local sc = H.find(H.find(gui, name), "Scaffold") :: any
		assert(sc ~= nil and H.find(sc, "Floating") == nil, name .. ": no FAB / snackbar frame")
		local b = H.find(sc, "Body") :: any
		assert(b.Parent == sc, name)
		local barH = if name == "BottomAppBarScreen" then 80 else 64
		assert(b.Size == UDim2.new(1, 0, 1, -barH), `{name}: region {b.Size}`)
	end
	click(tabButton(gui, "Buttons"))
	H.advance(0.5)
	H.assertNoDebugOutput("scaffold screens")
end)

H.section("app bar screens (Scaffold): the content region and the list's ScrollingFrame start at the bar's bottom edge (scrollbar never under the bar), rows stay where the content-behind-the-bar layout puts them", function()
	click(tabButton(gui, "Navigation"))
	H.finishTweens()
	local function padTop(content: any): number
		for _, c in content:GetChildren() do
			if c.ClassName == "UIPadding" then
				return c.PaddingTop.Offset
			end
		end
		error("no UIPadding")
	end
	local cases: { { Screen: string, Bar: string, Expanded: number } } = {
		{ Screen = "PinnedAppBarScreen", Bar = "TopAppBar", Expanded = 64 },
		{ Screen = "EnterAlwaysAppBarScreen", Bar = "CenterAlignedTopAppBar", Expanded = 64 },
		{ Screen = "ExitUntilCollapsedAppBarScreen", Bar = "MediumFlexibleTopAppBar", Expanded = 136 },
	}
	-- down in small and large steps, up part way (enterAlways brings the bar back), back to the top
	local path = { 0, 5, 30, 64, 71, 72, 100, 400, 2000, 380, 350, 60, 20, 3, 0 }
	for _, case in cases do
		local name = case.Screen
		local screen = H.find(gui, name) :: any
		local bar = H.find(screen, case.Bar) :: any
		local content = H.find(screen, "Content") :: any
		local body = content.Parent :: any
		assert(body.Name == "Body" and body.Parent.Name == "Scaffold", `{name}: the list is the Scaffold's content`)
		assert(content.Size == UDim2.fromScale(1, 1) and (content.Position or UDim2.new()) == UDim2.new(), `{name}: the list fills the region`)
		local expanded = case.Expanded
		-- layout stand-in for the settle's canvas clamp: 24 rows of 48 in a 420 screen, the window below the bar
		content.AbsoluteWindowSize = Vector2.new(360, 420 - expanded)
		content.AbsoluteCanvasSize = Vector2.new(360, 24 * 48)
		local function check(label: string)
			local barBottom = bar.Size.Y.Offset
			assert(bar.Size.Y.Scale == 0, label)
			assert(body.Position == UDim2.fromOffset(0, barBottom), `{name} {label}: region top {body.Position} vs bar bottom {barBottom}`)
			assert(body.Size == UDim2.new(1, 0, 1, -barBottom), `{name} {label}: region fills below the bar`)
			assert(body.Position.Y.Offset + padTop(content) == expanded, `{name} {label}: rows at the full-screen place`)
		end
		check("rest")
		for _, y in path do
			content.CanvasPosition = Vector2.new(0, y)
			check(`y={y}`)
		end
		-- stop part way: the settle animation moves the bar; the frame follows every step
		content.CanvasPosition = Vector2.new(0, 30)
		H.advance(0.15)
		for i = 1, 15 do
			H.advance(0.02)
			check(`settle {i}`)
		end
		-- settled: the first row meets the bar's bottom (the canvas moved with the bar — no gap)
		local rowTop = expanded - content.CanvasPosition.Y
		assert(math.abs(rowTop - bar.Size.Y.Offset) < 1e-3 or name == "PinnedAppBarScreen", `{name}: first row {rowTop} vs bar bottom {bar.Size.Y.Offset}`)
		content.CanvasPosition = Vector2.new(0, 0)
		H.advance(0.5)
		check("back")
	end
	click(tabButton(gui, "Buttons"))
	H.advance(0.5)
	H.assertNoDebugOutput("app bar screens")
end)

local function fireAncestry(root: any)
	local all = H.findAll(root, function(_: any): boolean
		return true
	end)
	for _, d in all do
		local anyD: any = d
		anyD.AncestryChanged:Fire(d, root)
	end
end

H.section("indeterminate progress: Heartbeat connected only while its section is up", function()
	assert(beats() == baseBeats, "no loop while another section is shown")
	click(tabButton(gui, "Chips"))
	-- the mock does not fire AncestryChanged when the section is parented into the ScreenGui; the engine does
	fireAncestry(gui)
	H.advance(0.1)
	-- linear + circular indeterminate, two loading indicators, the wavy bar's travelling wave
	assert(beats() == baseBeats + 5, `five progress loops: {beats() - baseBeats}`)
	click(tabButton(gui, "Buttons"))
	assert(beats() == baseBeats, "loops gone with the section")
	H.assertNoDebugOutput("progress")
end)

H.section("dispose: overlay, connections and timers back to baseline", function()
	click(tabButton(gui, "Pickers"))
	click(button(gui, "Pick a date (en)"))
	assert(#layer:GetChildren() > 0)
	q.dispose(gui)
	H.advance(1)
	assert(inputConns() == baseInput, `input connections: {inputConns()} vs {baseInput}`)
	assert(beats() == baseBeats, "heartbeat connections")
	assert(H.pendingTimers() == 0, `pending timers: {H.pendingTimers()}`)
	H.assertNoDebugOutput("dispose")
end)

H.section("GalleryPanel without an Overlay brings its own layer and works inside a plain host", function()
	local host = D.Frame { Size = UDim2.fromOffset(800, 600), Gallery.GalleryPanel({}) }
	assert(#named(host, "Overlay") == 1, "own overlay layer inside the panel")
	click(tabButton(host, "Overlays"))
	click(button(host, "Alert"))
	assert(byText(host, "Saved") ~= nil, "alert opened in the panel's own layer")
	q.dispose(host)
	H.advance(1)
	assert(inputConns() == baseInput and H.pendingTimers() == 0)
	H.assertNoDebugOutput("panel")
end)

print("[gallery] instance counts:")
for _, k in { "Buttons", "Selection", "Text", "Surfaces", "Overlays", "Navigation", "Chips", "Pickers", "Theme" } do
	print(`  {k}: {counts[k]}`)
end
H.done()
