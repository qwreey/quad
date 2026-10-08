--!strict
-- Scaffold (Compose Scaffold.kt ScaffoldLayout, adapted): the content region between the top bar's CURRENT bottom and the
-- bottom bar's top for every scroll behavior and through the settle, the collapse compensation handed to the content as
-- innerPadding.Top, foreign bars measured by their Size, FAB positions (FabSpacing 16, EndOverlay over the bottom bar),
-- the snackbar host above the FAB / the bottom bar, instance counts, no per-frame work at rest.
local H = require("./support/harness")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
local D = q.Declaration
local Tokens = require("../src/Tokens")
local Overlay = require("../src/Overlay")
local Snackbar = require("../src/Snackbar")
local AppBar = require("../src/AppBar")
local FAB = require("../src/Button/FAB")
local ShortNavigationBar = require("../src/NavigationBar")
local ScaffoldModule = require("../src/Scaffold")
local Scaffold = ScaffoldModule.Scaffold

local L = Tokens.Color.Light
local Heartbeat = H.RunService.Heartbeat :: any
local baseBeats = #Heartbeat.connections

local function own(inst: any, name: string): any
	for _, c in inst:GetChildren() do
		if c.Name == name or c.ClassName == name then
			return c
		end
	end
	return nil
end
local function ownCount(scaffold: any, given: { any }): number
	-- the Scaffold's own instances: everything minus the given instances' subtrees
	local total = H.countDescendants(scaffold) + 1
	for _, g in given do
		total -= H.countDescendants(g) + 1
	end
	return total
end

local function list(rows: number, padding: ScaffoldModule.PaddingValues, hook: any?): ScrollingFrame
	local items: { Instance } = {}
	for i = 1, rows do
		table.insert(items, D.Frame { Name = "Row", Size = UDim2.new(1, 0, 0, 48), LayoutOrder = i })
	end
	return D.ScrollingFrame {
		Name = "List",
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		hook or q.None,
		D.UIPadding { PaddingTop = padding.Top, PaddingLeft = UDim.new(0, 16) },
		D.UIListLayout { SortOrder = Enum.SortOrder.LayoutOrder },
		q.Slot<<Instance>>(items),
	}
end

local function padTop(scroller: any): number
	return (own(scroller, "UIPadding") :: any).PaddingTop.Offset
end

H.section("content only: Scaffold + Body (2), background color, the content fills the whole region; an Instance content is placed as given", function()
	local content = D.Frame { Name = "Page", Size = UDim2.fromScale(1, 1) }
	local s: any = Scaffold({ Content = content })
	assert(s.Name == "Scaffold" and s.Size == UDim2.fromScale(1, 1) and s.BackgroundColor3 == L.Background)
	local body = own(s, "Body")
	assert(body.Position == UDim2.fromOffset(0, 0) and body.Size == UDim2.new(1, 0, 1, 0) and body.BackgroundTransparency == 1)
	assert(content.Parent == body)
	assert(ownCount(s, { content }) == 2, `own instances {ownCount(s, { content })}`)
	assert(own(s, "Floating") == nil)
	local seen: ScaffoldModule.PaddingValues? = nil
	local s2: any = Scaffold({
		ContainerColor = Color3.new(1, 0, 0),
		Content = function(p: ScaffoldModule.PaddingValues): GuiObject
			seen = p
			return D.Frame { Name = "Page" }
		end,
	})
	assert(s2.BackgroundColor3 == Color3.new(1, 0, 0))
	assert(seen ~= nil and (seen :: any).Top:Get() == UDim.new(0, 0), "no top bar: no padding")
	assert(not pcall(Scaffold, { Content = content, FloatingActionButtonPosition = "Middle" :: any }), "unknown FabPosition errors")
	q.dispose(s)
	q.dispose(s2)
	H.assertNoDebugOutput("content only")
end)

-- the three behaviors, each with a bottom bar: the region stays between the bars through scrolls and settles
local cases = {
	{ Name = "pinned", Make = AppBar.TopAppBarDefaults.pinnedScrollBehavior, Bar = AppBar.TopAppBar, Expanded = 64 },
	{ Name = "enterAlways", Make = AppBar.TopAppBarDefaults.enterAlwaysScrollBehavior, Bar = AppBar.CenterAlignedTopAppBar, Expanded = 64 },
	{ Name = "exitUntilCollapsed", Make = AppBar.TopAppBarDefaults.exitUntilCollapsedScrollBehavior, Bar = AppBar.MediumTopAppBar, Expanded = 112 },
}
H.section("content region == between the top bar's current bottom and the bottom bar's top, for pinned / enterAlways / exitUntilCollapsed, through scrolls and settles", function()
	for _, case in cases do
		local behavior = case.Make()
		local bar: any = case.Bar({ Title = case.Name, ScrollBehavior = behavior })
		local bottom: any = AppBar.BottomAppBar({})
		local scroller: any = nil
		local s: any = Scaffold({
			TopBar = bar,
			BottomBar = bottom,
			Content = function(p: ScaffoldModule.PaddingValues): GuiObject
				scroller = list(30, p, behavior.Hook)
				return scroller
			end,
		})
		local body = own(s, "Body")
		assert(scroller.Parent == body)
		assert(bar.Parent == s and bar.AnchorPoint == Vector2.new(0, 0) and bar.Position == UDim2.new(), "top bar at the top")
		assert(bottom.Parent == s and bottom.AnchorPoint == Vector2.new(0, 1) and bottom.Position == UDim2.fromScale(0, 1), "bottom bar at the bottom")
		-- layout stand-in for the settle's canvas clamp: a 480 screen, 30 rows of 48
		scroller.AbsoluteWindowSize = Vector2.new(360, 480 - case.Expanded - 80)
		scroller.AbsoluteCanvasSize = Vector2.new(360, 30 * 48)
		local function check(label: string)
			local barBottom = bar.Size.Y.Offset
			assert(bar.Size.Y.Scale == 0, label)
			assert(body.Position == UDim2.fromOffset(0, barBottom), `{case.Name} {label}: region top {body.Position} vs bar bottom {barBottom}`)
			assert(body.Size == UDim2.new(1, 0, 1, -(barBottom + 80)), `{case.Name} {label}: region ends at the bottom bar's top ({body.Size})`)
			assert(body.Position.Y.Offset + padTop(scroller) == case.Expanded, `{case.Name} {label}: rows at the full-screen place`)
		end
		check("rest")
		for _, y in { 0, 7, 24, 48, 49, 64, 100, 400, 900, 380, 350, 60, 20, 3, 0 } do
			scroller.CanvasPosition = Vector2.new(0, y)
			check(`y={y}`)
		end
		-- stop part way: the settle animation moves the bar (and the canvas); the region follows every step
		for _, stop in { 30, 20 } do
			scroller.CanvasPosition = Vector2.new(0, stop)
			H.advance(0.15)
			for i = 1, 15 do
				H.advance(0.02)
				check(`settle {stop} #{i}`)
			end
			if case.Name ~= "pinned" then
				local rowTop = case.Expanded - scroller.CanvasPosition.Y
				assert(math.abs(rowTop - bar.Size.Y.Offset) < 1e-3, `{case.Name}: settled first row {rowTop} vs bar bottom {bar.Size.Y.Offset}`)
			end
		end
		scroller.CanvasPosition = Vector2.new(0, 0)
		H.advance(0.5)
		check("back")
		assert(#Heartbeat.connections == baseBeats, `{case.Name}: no Heartbeat at rest`)
		q.dispose(s)
	end
	H.assertNoDebugOutput("region")
end)

H.section("a top app bar without a scroll behavior, and a foreign bar measured by its Size (followed through the Size signal): no compensation", function()
	local medium: any = AppBar.LargeTopAppBar({ Title = "Still" })
	local p0: ScaffoldModule.PaddingValues? = nil
	local s: any = Scaffold({
		TopBar = medium,
		Content = function(p: ScaffoldModule.PaddingValues): GuiObject
			p0 = p
			return D.Frame {}
		end,
	})
	assert(own(s, "Body").Position == UDim2.fromOffset(0, 152) and (p0 :: any).Top:Get() == UDim.new(0, 0))
	q.dispose(s)
	local foreign = D.Frame { Name = "MyBar", Size = UDim2.new(1, 0, 0, 50) }
	local foot = D.Frame { Name = "MyFoot", Size = UDim2.new(1, 0, 0, 30) }
	local p1: ScaffoldModule.PaddingValues? = nil
	local s2: any = Scaffold({
		TopBar = foreign,
		BottomBar = foot,
		Content = function(p: ScaffoldModule.PaddingValues): GuiObject
			p1 = p
			return D.Frame {}
		end,
	})
	local body = own(s2, "Body")
	assert(body.Position == UDim2.fromOffset(0, 50) and body.Size == UDim2.new(1, 0, 1, -80), tostring(body.Size))
	foreign.Size = UDim2.new(1, 0, 0, 20)
	foot.Size = UDim2.new(1, 0, 0, 40)
	H.flushDeferred()
	assert(body.Position == UDim2.fromOffset(0, 20) and body.Size == UDim2.new(1, 0, 1, -60), "follows the bars' Size")
	assert((p1 :: any).Top:Get() == UDim.new(0, 0), "no compensation for a foreign bar")
	q.dispose(s2)
	H.assertNoDebugOutput("foreign")
end)

H.section("FAB: 16 from the edge (Start / Center / End), its bottom 16 above the bottom bar; EndOverlay and no bottom bar: 16 above the scaffold's bottom", function()
	local aligns = { Start = Enum.HorizontalAlignment.Left, Center = Enum.HorizontalAlignment.Center, End = Enum.HorizontalAlignment.Right, EndOverlay = Enum.HorizontalAlignment.Right }
	for _, position in { "Start", "Center", "End", "EndOverlay" } do
		for _, withBar in { true, false } do
			local fab: any = FAB({ Icon = "rbxassetid://1" })
			local bar: any? = if withBar then ShortNavigationBar<<string>>({ Items = { { Key = "a", Label = "A" } }, Selected = q.Source("a") }) else nil
			local content = D.Frame {}
			local s: any = Scaffold({
				BottomBar = bar,
				FloatingActionButton = fab,
				FloatingActionButtonPosition = position :: any,
				Content = content,
			})
			local floating = own(s, "Floating")
			assert(floating.ZIndex == 2 and floating.BackgroundTransparency == 1 and fab.Parent == floating)
			local overBar = position == "EndOverlay" or not withBar
			local want = if overBar then UDim2.fromScale(1, 1) else UDim2.new(1, 0, 1, -64)
			assert(floating.Size == want, `{position} bar={withBar}: {floating.Size}`)
			local pad = own(floating, "UIPadding")
			assert(pad.PaddingLeft == UDim.new(0, 16) and pad.PaddingRight == UDim.new(0, 16) and pad.PaddingBottom == UDim.new(0, 16))
			assert(pad.PaddingTop == nil or pad.PaddingTop == UDim.new(0, 0))
			local layout = own(floating, "UIListLayout")
			assert(layout.HorizontalAlignment == aligns[position] and layout.VerticalAlignment == Enum.VerticalAlignment.Bottom)
			-- the content region is not affected by the FAB (Compose pads only for the bars)
			assert(own(s, "Body").Size == UDim2.new(1, 0, 1, if withBar then -64 else 0))
			local mine = if withBar then { content, fab, bar } else { content, fab }
			assert(ownCount(s, mine) == 5, `{position}: own instances {ownCount(s, mine)}`)
			q.dispose(s)
		end
	end
	H.assertNoDebugOutput("fab")
end)

H.section("snackbar host: alone it fills down to the bottom bar's top; with a FAB it fills above the FAB; a shown snackbar opens in it", function()
	local layer = Overlay.new()
	local bar: any = AppBar.BottomAppBar({})
	local s: any = Scaffold({ BottomBar = bar, SnackbarHost = layer.Layer, Content = D.Frame {} })
	local floating = own(s, "Floating")
	assert(layer.Layer.Parent == floating and floating.Size == UDim2.new(1, 0, 1, -80), "alone: ends at the bar's top")
	assert(own(floating, "UIListLayout") == nil and own(floating, "UIPadding") == nil)
	q.dispose(s)

	local layer2 = Overlay.new()
	local host = Snackbar.new({ Overlay = layer2 })
	local fab: any = FAB({ Icon = "rbxassetid://1", Label = "Compose" })
	local nav: any = ShortNavigationBar<<string>>({ Items = { { Key = "a", Label = "A" } }, Selected = q.Source("a") })
	local content = D.Frame {}
	local s2: any = Scaffold({ BottomBar = nav, FloatingActionButton = fab, SnackbarHost = layer2.Layer, Content = content })
	local floating2 = own(s2, "Floating")
	local wrap = own(floating2, "SnackbarHost")
	assert(wrap.LayoutOrder == -1 and wrap.Size == UDim2.fromScale(1, 0) and own(wrap, "UIFlexItem").FlexMode == Enum.UIFlexMode.Fill)
	assert(layer2.Layer.Parent == wrap and (fab.LayoutOrder or 0) > wrap.LayoutOrder, "listed above the FAB")
	assert(floating2.Size == UDim2.new(1, 0, 1, -64))
	assert(ownCount(s2, { content, fab, nav, layer2.Layer }) == 7, `all slots: own instances {ownCount(s2, { content, fab, nav, layer2.Layer })}`)
	local item = host:Show({ Text = "Saved" })
	H.advance(0.05)
	local card = H.find(layer2.Layer, "Snackbar") :: any
	assert(card ~= nil, "in the scaffold's layer")
	assert(card.AnchorPoint == Vector2.new(0.5, 1), "centered at the host's bottom edge")
	item.Close()
	H.advance(1)
	assert(H.find(layer2.Layer, "Snackbar") == nil)
	host:Destroy()
	q.dispose(s2)
	assert(#Heartbeat.connections == baseBeats)
	H.assertNoDebugOutput("snackbar")
end)

H.done()
