--!strict
local H = require("./support/harness")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
local D = q.Declaration
local Tokens = require("../src/Tokens")
local Tabs = require("../src/Tabs")

local L = Tokens.Color.Light

local function class(inst: any, name: string): { any }
	return H.findAll(inst, function(c: any)
		return c.ClassName == name
	end)
end
local function tabButtons(root: any): { any }
	return H.findAll(root, function(c: any)
		return c.Name == "Tab"
	end)
end

type Tab = Tabs.Tab<string>
local three: { Tab } = {
	{ Key = "a", Label = "Flights" },
	{ Key = "b", Label = "Trips" },
	{ Key = "c", Label = "Explore" },
}

H.section("Primary: structure, one indicator, geometry for the selected index", function()
	local sel = q.Source("b")
	local tabs = Tabs<<string>>({ Selected = sel, Tabs = three })
	local count = H.countDescendants(tabs)
	print("Primary tabs (3, no icons) instances: " .. (count + 1))
	H.resetOutput()
	assert(tabs.Size == UDim2.new(1, 0, 0, 48) and tabs.BackgroundTransparency == 1)
	assert(#tabButtons(tabs) == 3)
	assert(#H.findAll(tabs, function(c: any)
		return c.Name == "Indicator"
	end) == 1, "ONE indicator instance for all tabs")
	-- Row, Divider, Track, Indicator, UICorner, Row's UIListLayout + 3 x (button, flex, layer(3), content, list, label)
	assert(count == 6 + 3 * 8, "descendants " .. count)
	H.finishTweens()
	local ind = H.find(tabs, "Indicator")
	assert(ind.Visible == true and ind.BackgroundColor3 == L.Primary)
	assert(ind.AnchorPoint == Vector2.new(0.5, 0))
	assert(ind.Position == UDim2.fromScale(0.5, 0), "tab 2 of 3: centered at 1.5/3")
	assert(ind.Size == UDim2.fromOffset(24, 6), "no measurement yet: min 24 px, 6 px high (3 px visible)")
	local track = H.find(tabs, "Track")
	assert(track.Size == UDim2.new(1, 0, 0, 3) and track.ClipsDescendants == true and track.AnchorPoint == Vector2.new(0, 1))
	assert(H.find(ind, "_quad_round").CornerRadius == UDim.new(0, 3) or #class(ind, "UICorner") == 1)
	local div = H.find(tabs, "Divider")
	assert(div.Size == UDim2.new(1, 0, 0, 1) and div.BackgroundColor3 == L.OutlineVariant)
	-- label colors: selected = primary, others = onSurfaceVariant
	local bt = tabButtons(tabs)
	assert(H.find(bt[2], "Label").TextColor3 == L.Primary and H.find(bt[1], "Label").TextColor3 == L.OnSurfaceVariant)
	assert(H.find(bt[1], "Label").Text == "Flights" and H.find(bt[1], "Label").TextSize == 14)
	-- the state layer shows tab states too
	assert(H.find(bt[1], "StateLayer").BackgroundColor3 == L.OnSurface and H.find(bt[2], "StateLayer").BackgroundColor3 == L.Primary)
	q.dispose(tabs)
	H.assertNoDebugOutput("primary structure")
end)

H.section("Primary: indicator width follows the measured label width", function()
	local sel = q.Source("a")
	local tabs = Tabs<<string>>({ Selected = sel, Tabs = three })
	local bt = tabButtons(tabs)
	H.setAbs(H.find(bt[1], "Label"), 0, 0, 52, 20)
	H.setAbs(H.find(bt[3], "Label"), 0, 0, 80, 20)
	H.finishTweens()
	local ind = H.find(tabs, "Indicator")
	assert(ind.Size == UDim2.fromOffset(52, 6) and ind.Position == UDim2.fromScale(0.5 / 3, 0), "tab 1 label width")
	sel:Set("c")
	H.finishTweens()
	assert(ind.Size == UDim2.fromOffset(80, 6) and ind.Position == UDim2.fromScale(2.5 / 3, 0))
	-- re-measuring the selected label (text changed) updates the indicator
	H.setAbs(H.find(bt[3], "Label"), 0, 0, 100, 20)
	H.finishTweens()
	assert(ind.Size == UDim2.fromOffset(100, 6))
	q.dispose(tabs)
	H.assertNoDebugOutput("primary width")
end)

H.section("selection round trip: click -> Source -> UI; external Set -> UI; slide animates", function()
	local sel = q.Source("a")
	local picked: { string } = {}
	local clicked: { string } = {}
	local tabs = Tabs<<string>>({
		Selected = sel,
		Tabs = three,
		OnChange = function(k)
			table.insert(picked, k)
		end,
		OnClick = function(k)
			table.insert(clicked, k)
		end,
	})
	local ind = H.find(tabs, "Indicator")
	H.finishTweens()
	assert(ind.Position == UDim2.fromScale(0.5 / 3, 0))
	local bt = tabButtons(tabs)
	H.fire(bt[3], "Activated", H.input({}), 1)
	assert(sel:Get() == "c" and picked[1] == "c")
	local log = H.tweenLog()
	local sliding = 0
	for _, e in log do
		if e.inst == ind and e.tween.PlaybackState == "Playing" then
			sliding += 1
		end
	end
	assert(sliding >= 1, "the indicator tweens (slides) instead of jumping, got " .. sliding)
	H.finishTweens()
	assert(ind.Position == UDim2.fromScale(2.5 / 3, 0))
	assert(H.find(bt[3], "Label").TextColor3 == L.Primary and H.find(bt[1], "Label").TextColor3 == L.OnSurfaceVariant)
	sel:Set("b")
	H.finishTweens()
	assert(ind.Position == UDim2.fromScale(0.5, 0) and H.find(bt[2], "Label").TextColor3 == L.Primary)
	H.fire(bt[2], "Activated", H.input({}), 1)
	assert(#picked == 1 and #clicked == 2 and clicked[2] == "b", "OnChange only on an actual change; OnClick on every click")
	q.dispose(tabs)
	H.assertNoDebugOutput("selection")
end)

H.section("Secondary: 2 px, full tab width, no rounding", function()
	local sel = q.Source("c")
	local tabs = Tabs<<string>>({ Selected = sel, Tabs = three, Variant = "Secondary" })
	H.finishTweens()
	local ind = H.find(tabs, "Indicator")
	local track = H.find(tabs, "Track")
	assert(track.Size == UDim2.new(1, 0, 0, 2))
	assert(ind.AnchorPoint == Vector2.new(0, 0) and ind.Position == UDim2.fromScale(2 / 3, 0) and ind.Size == UDim2.new(1 / 3, 0, 1, 0))
	assert(#class(ind, "UICorner") == 0, "secondary indicator is square")
	assert(H.find(tabButtons(tabs)[3], "Label").TextColor3 == L.OnSurface, "active secondary label = onSurface")
	sel:Set("a")
	H.finishTweens()
	assert(ind.Position == UDim2.fromScale(0, 0))
	-- Secondary has no label measurement: no OnChange needed, geometry from scale only
	q.dispose(tabs)
	H.assertNoDebugOutput("secondary")
end)

H.section("State tabs: add/remove/rename keep elements; missing key hides the indicator", function()
	local list = q.Source(three)
	local sel = q.Source("b")
	local tabs = Tabs<<string>>({ Selected = sel, TabsState = list })
	local first = tabButtons(tabs)
	H.finishTweens()
	local ind = H.find(tabs, "Indicator")
	list:Set({
		{ Key = "a", Label = "Flights" },
		{ Key = "b", Label = "Trips 2" },
		{ Key = "c", Label = "Explore" },
		{ Key = "d", Label = "Saved" },
	})
	local now = tabButtons(tabs)
	assert(#now == 4 and now[1] == first[1] and now[2] == first[2] and now[3] == first[3], "elements reused")
	assert(H.find(now[2], "Label").Text == "Trips 2")
	H.finishTweens()
	assert(ind.Position == UDim2.fromScale(1.5 / 4, 0), "count 4: tab 2 centered at 1.5/4")
	list:Set({ { Key = "a", Label = "Flights" }, { Key = "c", Label = "Explore" } })
	assert(#tabButtons(tabs) == 2 and H.isDestroyed(first[2]) and H.isDestroyed(now[4]))
	H.finishTweens()
	assert(ind.Visible == false, "selected key gone: indicator hidden")
	sel:Set("c")
	H.finishTweens()
	assert(ind.Visible == true and ind.Position == UDim2.fromScale(1.5 / 2, 0))
	q.dispose(tabs)
	H.assertNoDebugOutput("state tabs")
end)

H.section("icons: Primary stacks icon over label at height 64; Secondary lays them side by side", function()
	local withIcons: { Tab } = {
		{ Key = "a", Label = "One", Icon = "rbxassetid://1" },
		{ Key = "b", Label = "Two", Icon = "rbxassetid://2" },
	}
	local p = Tabs<<string>>({ Selected = q.Source("a"), Tabs = withIcons })
	assert(p.Size == UDim2.new(1, 0, 0, 64))
	local icon = H.find(tabButtons(p)[1], "Icon")
	assert(icon.Size == UDim2.fromOffset(24, 24) and icon.Image == "rbxassetid://1")
	local content = H.find(tabButtons(p)[1], "Content")
	assert(class(content, "UIListLayout")[1].FillDirection == Enum.FillDirection.Vertical)
	H.finishTweens()
	assert(icon.ImageColor3 == L.Primary and H.find(tabButtons(p)[2], "Icon").ImageColor3 == L.OnSurfaceVariant)
	local s = Tabs<<string>>({ Selected = q.Source("a"), Tabs = withIcons, Variant = "Secondary" })
	assert(s.Size == UDim2.new(1, 0, 0, 48))
	assert(class(H.find(tabButtons(s)[1], "Content"), "UIListLayout")[1].FillDirection == Enum.FillDirection.Horizontal)
	q.dispose(p)
	q.dispose(s)
	H.assertNoDebugOutput("icons")
end)

H.section("hover on a tab lights its state layer; Modifier overrides the base size", function()
	local tabs = Tabs<<string>>({
		Selected = q.Source("a"),
		Tabs = three,
		Modifier = D.Modifier.Frame():Size(UDim2.fromOffset(300, 56)),
	})
	assert(tabs.Size == UDim2.fromOffset(300, 56))
	local bt = tabButtons(tabs)
	H.fire(bt[2], "MouseEnter")
	H.finishTweens()
	assert(math.abs(H.find(bt[2], "StateLayer").BackgroundTransparency - 0.92) < 1e-6)
	q.dispose(tabs)
	H.assertNoDebugOutput("hover")
end)

H.section("dispose: nothing leaks", function()
	local list = q.Source(three)
	local root = D.Frame { Tabs<<string>>({ Selected = q.Source("a"), TabsState = list }) }
	local all = H.findAll(root, function()
		return true
	end)
	q.dispose(root)
	for _, c in all do
		assert(H.isDestroyed(c), "undestroyed: " .. c.Name)
	end
	H.advance(2)
	assert(H.pendingTimers() == 0)
	H.assertNoDebugOutput("dispose")
end)

H.done()
