--!strict
-- Navigation bar (ShortNavigationBar) and navigation rail (WideNavigationRail + WideNavigationRailState) + Badge — Compose
-- tokens and layout, the shared destination model and the Tabs selection rule, the indicator progress, the rail's
-- collapse / expand geometry, ripple BOUNDED to the pill, dispose.
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Tokens = require("../src/Tokens")
local ShortNavigationBar = require("../src/NavigationBar")
local Rail = require("../src/NavigationRail")
local BadgeModule = require("../src/Badge")
local IconButton = require("../src/Button/IconButton")
local Bounded = require("./support/bounded")
local Destination = require("../src/Navigation/Destination")

local L = Tokens.Color.Light
local Heartbeat = H.RunService.Heartbeat :: any
local baseBeats = #Heartbeat.connections

local ITEMS: { Destination.Destination<string> } = {
	{ Key = "home", Label = "Home", Icon = "rbxassetid://1" },
	{ Key = "inbox", Label = "Inbox", Icon = "rbxassetid://2", Badge = "8" },
	{ Key = "alerts", Label = "Alerts", Icon = "rbxassetid://3", Badge = "" },
}

local function items(root: any): { any }
	local out = H.findAll(root, function(c: any)
		return c.Name == "NavigationItem"
	end)
	table.sort(out, function(a: any, b: any)
		return a.LayoutOrder < b.LayoutOrder
	end)
	return out
end
local function own(inst: any, className: string): any
	for _, c in inst:GetChildren() do
		if c.ClassName == className then
			return c
		end
	end
	return nil
end
local function settle()
	for _ = 1, 20 do
		H.advance(0.02)
	end
end

-- ── badge ───────────────────────────────────────────────────────────────────

H.section("Badge: small 6 px error dot; large 16 high LabelSmall onError, 4 px padding, min 16 wide; BadgedBox offsets", function()
	local small: any = BadgeModule.Badge()
	assert(small.Size == UDim2.fromOffset(6, 6) and small.BackgroundColor3 == L.Error)
	assert(own(small, "UICorner").CornerRadius == UDim.new(0.5, 0))
	local large: any = BadgeModule.Badge({ Text = "8" })
	assert(large.Size == UDim2.fromOffset(0, 16) and large.AutomaticSize == Enum.AutomaticSize.X)
	local label = H.find(large, "Text")
	assert(label.Text == "8" and label.TextSize == 11 and label.TextColor3 == L.OnError)
	assert(own(large, "UIPadding").PaddingLeft == UDim.new(0, 4) and own(label, "UISizeConstraint").MinSize == Vector2.new(8, 0))
	assert(BadgeModule.position(false) == UDim2.fromOffset(18, 0), "small: end-aligned, 6 px overlap")
	assert(BadgeModule.position(true) == UDim2.fromOffset(12, -2), "large: 12 from the end, 2 above")
	local ns, nl = H.countDescendants(small) + 1, H.countDescendants(large) + 1
	print(`[nav] badge: small {ns}, large {nl}`)
	H.resetOutput()
	assert(ns == 2 and nl == 5)
	q.dispose(small)
	q.dispose(large)
	H.assertNoDebugOutput("badge")
end)

-- ── navigation bar ──────────────────────────────────────────────────────────

H.section("ShortNavigationBar: 64 tall surfaceContainer, equal cells, top-icon item geometry and colors, counts", function()
	local page = q.Source("home")
	local bar: any = ShortNavigationBar<<string>>({ Items = ITEMS, Selected = page })
	assert(bar.Name == "ShortNavigationBar" and bar.Size == UDim2.new(1, 0, 0, 64) and bar.BackgroundColor3 == L.SurfaceContainer)
	assert(own(bar, "UIShadow") == nil, "no shadow")
	local list = items(bar)
	assert(#list == 3)
	local first = list[1]
	assert(first.Size == UDim2.new(1 / 3, 0, 1, 0), "EqualWeight: 1/n each")
	local indicator = H.find(first, "Indicator")
	assert(indicator.AnchorPoint == Vector2.new(0.5, 0) and indicator.Position == UDim2.new(0.5, 0, 0, 6))
	assert(indicator.Size == UDim2.fromOffset(56, 32) and indicator.BackgroundTransparency == 0, "selected at mount: full pill, no animation")
	assert(indicator.BackgroundColor3 == L.SecondaryContainer and own(indicator, "UICorner").CornerRadius == UDim.new(0.5, 0))
	local icon = H.find(first, "Icon")
	assert(icon.Size == UDim2.fromOffset(24, 24) and icon.Position == UDim2.new(0.5, 0, 0, 10), "icon in the pill, 4 below its top")
	assert(icon.ImageColor3 == L.OnSecondaryContainer)
	local label = H.find(first, "Label")
	assert(label.Position == UDim2.new(0.5, 0, 0, 42) and label.TextSize == 12, "LabelMedium 4 below the pill")
	assert(label.TextColor3 == L.Secondary, "selected label secondary")
	local second = list[2]
	assert(H.find(second, "Indicator").Size == UDim2.fromOffset(0, 32) and H.find(second, "Indicator").BackgroundTransparency == 1)
	assert(H.find(second, "Label").TextColor3 == L.OnSurfaceVariant and H.find(second, "Icon").ImageColor3 == L.OnSurfaceVariant)
	local target = H.find(first, "Target")
	assert(target.Size == UDim2.fromOffset(56, 32) and H.find(target, "StateLayer") ~= nil, "the state layer covers the pill")
	-- badges on the icon
	local box = H.find(second, "IconBox")
	assert(box ~= nil and box.Size == UDim2.fromOffset(24, 24) and H.find(box, "Badge").Position == UDim2.fromOffset(12, -2))
	assert(H.find(H.find(list[3], "IconBox"), "Badge").Size == UDim2.fromOffset(6, 6), "Badge = '' is the small dot")
	local nItem = H.countDescendants(first) + 1
	local nBar = H.countDescendants(bar) + 1
	print(`[nav] bar: {nBar} instances (3 items: plain {nItem}, large badge +6, small badge +3)`)
	H.resetOutput()
	assert(nItem == 9, `item {nItem}`)
	assert(nBar == 3 + 9 * 3 + 6 + 3, `bar {nBar}`)
	q.dispose(bar)
	H.assertNoDebugOutput("bar")
end)

H.section("bar selection: Tabs rule (OnChange only on a user change, OnClick always), snapped colors, animated indicator", function()
	local page = q.Source("home")
	local changes, clicks = {}, {}
	local bar: any = ShortNavigationBar<<string>>({
		Items = ITEMS,
		Selected = page,
		OnChange = function(k: string)
			table.insert(changes, k)
		end,
		OnClick = function(k: string)
			table.insert(clicks, k)
		end,
	})
	local list = items(bar)
	H.fire(list[2], "Activated", H.input({}), 1)
	assert(page:Get() == "inbox" and changes[1] == "inbox" and clicks[1] == "inbox")
	assert(H.find(list[2], "Label").TextColor3 == L.Secondary and H.find(list[1], "Label").TextColor3 == L.OnSurfaceVariant, "colors switch at once")
	assert(#Heartbeat.connections == baseBeats + 2, "two indicators animate")
	H.advance(0.05)
	local w = H.find(list[2], "Indicator").Size.X.Offset
	assert(w > 0 and w < 56, `grows from the center: {w}`)
	assert(H.find(list[2], "Indicator").AnchorPoint == Vector2.new(0.5, 0))
	settle()
	assert(H.find(list[2], "Indicator").Size == UDim2.fromOffset(56, 32) and H.find(list[2], "Indicator").BackgroundTransparency == 0)
	assert(H.find(list[1], "Indicator").Size == UDim2.fromOffset(0, 32) and H.find(list[1], "Indicator").BackgroundTransparency == 1)
	assert(#Heartbeat.connections == baseBeats, "no Heartbeat at rest")
	H.fire(list[2], "Activated", H.input({}), 1)
	assert(#changes == 1 and #clicks == 2, "the selected one: OnClick only")
	page:Set("alerts")
	assert(#changes == 1, "a programmatic write does not report")
	settle()
	assert(H.find(list[3], "Indicator").Size == UDim2.fromOffset(56, 32))
	q.dispose(bar)
	H.assertNoDebugOutput("bar selection")
end)

H.section("bar Start icons + Centered: 40 high pill = 16 + icon + 4 + label + 16, centered group, min width from the content", function()
	local page = q.Source("home")
	local bar: any = ShortNavigationBar<<string>>({ Items = ITEMS, Selected = page, IconPosition = "Start", Arrangement = "Centered" })
	local list = items(bar)
	local first = list[1]
	assert(first.Size == UDim2.new(0.6 / 3, 0, 1, 0), "3 items share 60 %")
	assert(own(H.find(bar, "Row"), "UIListLayout").HorizontalAlignment == Enum.HorizontalAlignment.Center)
	H.setAbs(H.find(first, "Label"), 0, 0, 40, 16)
	local indicator = H.find(first, "Indicator")
	assert(indicator.Size == UDim2.fromOffset(16 + 24 + 4 + 40 + 16, 40), tostring(indicator.Size))
	assert(indicator.AnchorPoint == Vector2.new(0.5, 0.5) and indicator.Position == UDim2.fromScale(0.5, 0.5))
	assert(H.find(first, "Icon").Position == UDim2.new(0.5, -34, 0.5, 0) and H.find(first, "Label").Position == UDim2.new(0.5, -6, 0.5, 0))
	assert(own(first, "UISizeConstraint").MinSize == Vector2.new(100, 0), "Centered min = the pill")
	assert(H.find(first, "Label").TextColor3 == L.OnSecondaryContainer, "Start: selected label onSecondaryContainer")
	assert(H.find(first, "Target").Size == UDim2.fromOffset(100, 40))
	q.dispose(bar)
	H.assertNoDebugOutput("bar start")
end)

H.section("bar item ripple stays inside the pill (BOUNDED)", function()
	local bar: any = ShortNavigationBar<<string>>({ Items = ITEMS, Selected = q.Source("home") })
	Bounded.pressBounded(items(bar)[1], 56, 32, "bar pill")
	q.dispose(bar)
	H.advance(1)
	H.assertNoDebugOutput("bar ripple")
end)

-- ── navigation rail ─────────────────────────────────────────────────────────

local function rail(state: any, props: any?): any
	local p: any = props or {}
	return Rail.WideNavigationRail<<string>>({
		Items = ITEMS,
		Selected = p.Selected or q.Source("home"),
		State = state,
		Header = p.Header,
		Arrangement = p.Arrangement,
		OnChange = p.OnChange,
	})
end

H.section("WideNavigationRail collapsed: 96 wide surface, 44 top, 64 high items 4 apart, the 56 x 32 pill at 20, label centered", function()
	local state = Rail.WideNavigationRailState()
	local r = rail(state)
	assert(r.Name == "WideNavigationRail" and r.Size == UDim2.new(0, 96, 1, 0) and r.BackgroundColor3 == L.Surface and r.ClipsDescendants)
	local list = items(r)
	assert(list[1].Position == UDim2.fromOffset(0, 44) and list[1].Size == UDim2.fromOffset(96, 64))
	assert(list[2].Position == UDim2.fromOffset(0, 44 + 68) and list[3].Position == UDim2.fromOffset(0, 44 + 136))
	local indicator = H.find(list[1], "Indicator")
	assert(indicator.Position == UDim2.fromOffset(20, 6) and indicator.Size == UDim2.fromOffset(56, 32), tostring(indicator.Position))
	assert(H.find(list[1], "Icon").Position == UDim2.fromOffset(36, 10))
	local label = H.find(list[1], "Label")
	H.setAbs(label, 0, 0, 30, 16)
	assert(label.Position == UDim2.fromOffset(33, 42) and label.TextSize == 12 and label.TextTransparency == 0, tostring(label.Position))
	assert(label.TextColor3 == L.Secondary and H.find(list[2], "Label").TextColor3 == L.OnSurfaceVariant)
	assert(H.find(list[1], "Target").Size == UDim2.fromOffset(56, 32))
	local n = H.countDescendants(r) + 1
	print(`[nav] rail (3 items, collapsed): {n} instances`)
	H.resetOutput()
	assert(n == 1 + 9 * 3 + 6 + 3, `rail {n}`)
	q.dispose(r)
	H.assertNoDebugOutput("rail collapsed")
end)

H.section("rail expand: width to the widest item + 20 (220..360), items 56 high 0 apart, pill = 16 + icon + 8 + label + 16, label cross-fade", function()
	local state = Rail.WideNavigationRailState()
	local r = rail(state)
	local list = items(r)
	for i, it in list do
		H.setAbs(H.find(it, "Label"), 0, 0, 30 + i * 10, 16)
	end
	state.Expand()
	assert(state.TargetValue:Get() == "Expanded" and state.CurrentValue:Get() == "Collapsed", "target at once, settled later")
	H.advance(0.05)
	local mid = H.find(list[1], "Label")
	assert(mid.TextTransparency > 0, "the label fades during the move")
	settle()
	assert(state.CurrentValue:Get() == "Expanded", "settled")
	-- LabelLarge widths after the style switch
	for i, it in list do
		H.setAbs(H.find(it, "Label"), 0, 0, 50 + i * 10, 20)
	end
	local widest = 20 + 16 + 24 + 8 + 80 + 16
	assert(r.Size == UDim2.new(0, math.max(220, widest + 20), 1, 0), tostring(r.Size))
	assert(list[1].Position == UDim2.fromOffset(0, 44) and list[1].Size.Y.Offset == 56 and list[2].Position == UDim2.fromOffset(0, 100))
	local indicator = H.find(list[1], "Indicator")
	assert(indicator.Position == UDim2.fromOffset(20, 0) and indicator.Size == UDim2.fromOffset(16 + 24 + 8 + 60 + 16, 56), tostring(indicator.Size))
	assert(list[1].Size.X.Offset == 20 + 124, "the item box ends with its pill")
	assert(H.find(list[1], "Icon").Position == UDim2.fromOffset(36, 16))
	local label = H.find(list[1], "Label")
	assert(label.Position == UDim2.fromOffset(68, 18) and label.TextSize == 14 and label.TextTransparency == 0, tostring(label.Position))
	H.finishTweens()
	assert(label.TextColor3 == L.OnSecondaryContainer, "start-icon selected label onSecondaryContainer")
	-- collapse back; SnapTo jumps
	state.Toggle()
	assert(state.TargetValue:Get() == "Collapsed")
	settle()
	assert(r.Size == UDim2.new(0, 96, 1, 0) and state.CurrentValue:Get() == "Collapsed")
	state.SnapTo("Expanded")
	assert(state.CurrentValue:Get() == "Expanded" and list[1].Size.Y.Offset == 56, "snapped, no animation")
	assert(#Heartbeat.connections == baseBeats)
	q.dispose(r)
	H.assertNoDebugOutput("rail expand")
end)

H.section("rail header: placed at 44, the items 40 below it; Center / Bottom arrangements; selection rule; ripple bounded", function()
	local state = Rail.WideNavigationRailState()
	local header = IconButton({ Icon = "rbxassetid://9", TouchTarget = true })
	local page = q.Source("home")
	local changes = {}
	local r = rail(state, {
		Header = header,
		Selected = page,
		OnChange = function(k: string)
			table.insert(changes, k)
		end,
	})
	local holder = H.find(r, "Header")
	assert(holder.Position == UDim2.fromOffset(0, 44) and holder.Size == UDim2.new(1, 0, 0, 48))
	local list = items(r)
	assert(list[1].Position == UDim2.fromOffset(0, 44 + 48 + 40))
	H.fire(list[3], "Activated", H.input({}), 1)
	assert(page:Get() == "alerts" and changes[1] == "alerts")
	page:Set("home")
	assert(#changes == 1)
	settle()
	Bounded.pressBounded(list[1], 56, 32, "rail pill")
	q.dispose(r)
	local c = rail(Rail.WideNavigationRailState(), { Arrangement = "Center" })
	local cl = items(c)
	assert(cl[1].Position == UDim2.new(0, 0, 0.5, -(3 * 64 + 2 * 4) / 2), tostring(cl[1].Position))
	q.dispose(c)
	local b = rail(Rail.WideNavigationRailState({ InitialValue = "Expanded" }), { Arrangement = "Bottom" })
	local bl = items(b)
	assert(bl[3].Position == UDim2.new(0, 0, 1, -56), tostring(bl[3].Position))
	q.dispose(b)
	H.advance(1)
	assert(#Heartbeat.connections == baseBeats)
	H.assertNoDebugOutput("rail header")
end)

H.section("WideNavigationRailState: values checked, Toggle goes to the opposite target, settles at once with no rail", function()
	local s = Rail.WideNavigationRailState({ InitialValue = "Expanded" })
	assert(s.CurrentValue:Get() == "Expanded")
	s.Toggle()
	assert(s.TargetValue:Get() == "Collapsed" and s.CurrentValue:Get() == "Collapsed")
	local ok = pcall(function()
		Rail.WideNavigationRailState({ InitialValue = "Open" :: any })
	end)
	assert(not ok, "bad value rejected")
	H.resetOutput()
	H.assertNoDebugOutput("rail state")
end)

H.done()
