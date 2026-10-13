--!strict
local H = require("./support/harness")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
local D = q.Declaration
local Tokens = require("../src/Tokens")
local ListModule = require("../src/List")
local List, ListItem, ListData = ListModule.List, ListModule.ListItem, ListModule.ListData

local L = Tokens.Color.Light

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end
local function class(inst: any, name: string): { any }
	return H.findAll(inst, function(c: any)
		return c.ClassName == name
	end)
end

local function assertLayerLayout(host: any, what: string)
	local cc: { [string]: number } = {}
	for _, c in host:GetChildren() do
		cc[c.ClassName] = (cc[c.ClassName] or 0) + 1
	end
	assert(cc.UIPadding == nil and cc.UIListLayout == nil, what .. ": no UIPadding / UIListLayout on the host")
	local layer = H.find(host, "StateLayer")
	assert(layer ~= nil and layer.Parent == host, what .. ": state layer is a direct child of the host")
	local content = H.find(host, "Content")
	assert(content ~= nil and content.Parent == host and content.BackgroundTransparency == 1, what .. ": Content frame under the host")
end

H.section("one-line item: height 56, text column, instance count", function()
	local item: any = ListItem({ Headline = "Inbox" })
	assert(item.ClassName == "Frame" and item.Size == UDim2.new(1, 0, 0, 56))
	local head = H.find(item, "Headline")
	assert(head.Text == "Inbox" and head.TextSize == 16 and head.TextColor3 == L.OnSurface and head.TextTruncate == Enum.TextTruncate.AtEnd)
	assert(H.find(item, "Supporting") == nil and H.find(item, "Overline") == nil)
	assert(item.BackgroundTransparency == 1, "unselected: transparent")
	assert(H.countDescendants(item) == 6, "UIPadding, UIListLayout, Text(Frame+layout+flex), Headline = 6, got " .. H.countDescendants(item))
	local flex = class(item, "UIFlexItem")[1]
	assert(flex.FlexMode == Enum.UIFlexMode.Fill)
	local pad = class(item, "UIPadding")[1]
	assert(pad.PaddingLeft == UDim.new(0, 16) and pad.PaddingRight == UDim.new(0, 24))
	q.dispose(item)
	H.assertNoDebugOutput("one-line")
end)

H.section("two- and three-line heights, inferred and explicit", function()
	local two: any = ListItem({ Headline = "H", Supporting = "S" })
	assert(two.Size == UDim2.new(1, 0, 0, 72))
	local s2 = H.find(two, "Supporting")
	assert(s2.TextColor3 == L.OnSurfaceVariant and s2.TextSize == 14 and s2.Size == UDim2.new(1, 0, 0, 20))
	local three: any = ListItem({ Overline = "O", Headline = "H", Supporting = "S" })
	assert(three.Size == UDim2.new(1, 0, 0, 88))
	assert(H.find(three, "Overline").TextSize == 11)
	local s3 = H.find(three, "Supporting")
	assert(s3.Size == UDim2.new(1, 0, 0, 20) and s3.TextWrapped == false, "with an overline the supporting text is one line")
	assert(class(three, "UIListLayout")[1].VerticalAlignment == Enum.VerticalAlignment.Top, "three-line is top aligned")
	local forced: any = ListItem({ Headline = "H", Supporting = "S", Lines = 3 })
	assert(forced.Size == UDim2.new(1, 0, 0, 88))
	local sf = H.find(forced, "Supporting")
	assert(sf.Size == UDim2.new(1, 0, 0, 40) and sf.TextWrapped == true, "no overline: supporting may wrap to two lines")
	-- the text column fits the 88 px row inside its 12 px top / bottom padding (the column is auto-sized from these)
	for _, i in { three, forced } do
		local sum = 0
		for _, name in { "Overline", "Headline", "Supporting" } do
			local part = H.find(i, name)
			if part ~= nil then
				sum += part.Size.Y.Offset
			end
		end
		assert(sum <= 88 - 2 * 12, "three-line text fits the padded row: " .. sum)
	end
	for _, i in { two, three, forced } do
		q.dispose(i)
	end
	H.assertNoDebugOutput("lines")
end)

H.section("leading/trailing: image ids, State ids, elements, trailing text", function()
	local icon = q.Source("rbxassetid://1")
	local avatar = D.Frame { Name = "Avatar", Size = UDim2.fromOffset(40, 40) }
	local item: any = ListItem({
		Headline = "H",
		Leading = icon,
		Trailing = avatar,
		TrailingText = "100+",
	})
	local lead = H.find(item, "Leading")
	assert(lead.ClassName == "ImageLabel" and lead.Image == "rbxassetid://1" and lead.Size == UDim2.fromOffset(24, 24))
	assert(lead.ImageColor3 == L.OnSurfaceVariant)
	icon:Set("rbxassetid://2")
	assert(lead.Image == "rbxassetid://2", "leading State drives the image")
	local trail = H.find(item, "Trailing")
	assert(trail.ClassName == "Frame" and H.find(trail, "Avatar") ~= nil, "element is wrapped, not re-parented elsewhere")
	assert(H.find(item, "TrailingText").Text == "100+")
	assert(class(item, "UIPadding")[1].PaddingRight == UDim.new(0, 16))
	local big: any = ListItem({ Headline = "H", Leading = "rbxassetid://3", LeadingSize = 40, Trailing = "rbxassetid://4" })
	assert(H.find(big, "Leading").Size == UDim2.fromOffset(40, 40) and H.find(big, "Trailing").Size == UDim2.fromOffset(24, 24))
	q.dispose(item)
	q.dispose(big)
	H.assertNoDebugOutput("sides")
end)

H.section("interactive item: OnClick, state layer, Selected round trip, disabled", function()
	local clicks = 0
	local selected = q.Source(false)
	local disabled = q.Source(false)
	local item: any = ListItem({
		Headline = "Row",
		Supporting = "sub",
		Selected = selected,
		Disabled = disabled,
		OnClick = function()
			clicks += 1
			selected:Set(not selected:Get())
		end,
	})
	assert(item.ClassName == "TextButton" and item.Size == UDim2.new(1, 0, 0, 72) and item.AutoButtonColor == false)
	H.finishTweens()
	assert(item.BackgroundTransparency == 1)
	assertLayerLayout(item, "interactive list item")
	assert(H.find(item, "Content").Parent == item and class(item, "UIPadding")[1].Parent == H.find(item, "Content"), "padding on Content")
	assert(class(item, "UIListLayout")[1].Parent == H.find(item, "Content") and H.find(item, "Headline").Parent.Parent == H.find(item, "Content"))
	assert(H.countDescendants(item) == 11, "two-line interactive: layer 3 + Content + padding + layout + text(3) + Headline + Supporting, got " .. H.countDescendants(item))
	H.fire(item, "Activated", H.input({}), 1)
	H.finishTweens()
	assert(clicks == 1 and selected:Get() == true)
	assert(item.BackgroundTransparency == 0 and item.BackgroundColor3 == L.SecondaryContainer)
	assert(H.find(item, "Headline").TextColor3 == L.OnSecondaryContainer and H.find(item, "Supporting").TextColor3 == L.OnSecondaryContainer)
	H.fire(item, "MouseEnter")
	H.finishTweens()
	assert(near(H.find(item, "StateLayer").BackgroundTransparency, 0.92), "hover layer")
	disabled:Set(true)
	H.finishTweens()
	assert(item.Interactable == false and near(H.find(item, "Headline").TextTransparency, 0.62))
	H.fire(item, "Activated", H.input({}), 1)
	assert(clicks == 1, "disabled swallows the click")
	q.dispose(item)
	H.assertNoDebugOutput("interactive")
end)

H.section("List with a Children Slot; Gap; caller Modifier; Slot CRUD", function()
	local children = q.Slot({ ListItem({ Headline = "A" }), ListItem({ Headline = "B" }) } :: { Instance })
	local list: any = List({ Children = children, Gap = 4, Modifier = D.Modifier.Frame():Size(UDim2.fromOffset(300, 0)) })
	assert(list.Name == "List" and list.Size == UDim2.fromOffset(300, 0) and list.AutomaticSize == Enum.AutomaticSize.Y)
	assert(class(list, "UIListLayout")[1].Padding == UDim.new(0, 4) and class(list, "UIListLayout")[1].FillDirection == Enum.FillDirection.Vertical)
	assert(#class(list, "Frame") >= 2)
	children:Add(ListItem({ Headline = "C" }))
	assert(#H.findAll(list, function(c: any) return c.Name == "Headline" end) == 3)
	local empty: any = List()
	assert(#empty:GetChildren() == 1, "only the layout")
	q.dispose(list)
	q.dispose(empty)
	H.assertNoDebugOutput("list")
end)

type Mail = { Id: number, Title: string }

H.section("ListData: keyed rows are built once, edits update the item State, removal destroys", function()
	local items = q.Source({ { Id = 1, Title = "one" }, { Id = 2, Title = "two" } } :: { Mail })
	local renders = 0
	local list: any = ListData<<Mail>>({
		Items = items,
		Key = function(m: Mail)
			return m.Id
		end,
		Render = function(item: Q.State<Mail>, index: Q.State<number>)
			renders += 1
			local title: Q.State<string> = item:Compute(function(self)
				return self:Get().Title
			end)
			return ListItem({ Headline = title, LayoutOrder = index })
		end,
	})
	local function rows(): { any }
		return H.findAll(list, function(c: any) return c.Name == "ListItem" end)
	end
	assert(renders == 2 and #rows() == 2 and rows()[1].LayoutOrder == 1 and rows()[2].LayoutOrder == 2)
	local firstRow = rows()[1]
	items:Set({ { Id = 1, Title = "ONE" }, { Id = 2, Title = "two" }, { Id = 3, Title = "three" } })
	assert(renders == 3, "only the new key rendered")
	assert(rows()[1] == firstRow and H.find(firstRow, "Headline").Text == "ONE", "recycled row follows the data edit")
	assert(#rows() == 3)
	items:Set({ { Id = 3, Title = "three" }, { Id = 1, Title = "ONE" } })
	assert(#rows() == 2 and renders == 3)
	local byTitle: { [string]: any } = {}
	for _, r in rows() do
		byTitle[H.find(r, "Headline").Text] = r
	end
	assert(byTitle["three"].LayoutOrder == 1 and byTitle["ONE"].LayoutOrder == 2, "index State follows the reorder")
	assert(byTitle["ONE"] == firstRow)
	q.dispose(list)
	assert(H.isDestroyed(firstRow))
	H.assertNoDebugOutput("data")
end)

-- ── drag-to-reorder (`OnReorder`, src/ListReorder.luau) ─────────────────────────────────────────────────────────────
-- The mock has no layout: `layout` stands in for the engine's UIListLayout (hosts stacked by LayoutOrder, each as tall as
-- the spec says its row is), and a tween only lands when `H.finishTweens()` runs — until then the property still holds
-- the value it had when the tween started, which is what "where the row is on screen right now" means below.
local UIS: any = H.UserInputService
local ListReorder = require("../src/ListReorder")
local Icons = require("../src/Icons")
local Overlay = require("../src/Overlay")

local function dragConns(): number
	return #UIS.InputChanged.connections + #UIS.InputEnded.connections + #UIS.WindowFocusReleased.connections
end
local function beganConns(): number
	return #UIS.InputBegan.connections
end
local function heartbeatConns(): number
	return #(H.RunService :: any).Heartbeat.connections
end

type Reorderable = {
	list: any,
	items: Q.Source<{ Mail }>,
	calls: { { number } },
	layout: (listY: number?) -> (),
	row: (title: string) -> any,
	offset: (title: string) -> number,
	top: (title: string) -> number,
	press: (title: string) -> number,
	move: (y: number) -> (),
	release: (y: number) -> (),
	order: () -> string,
}

-- a reorderable list of `titles` (ids 1..n); `heights[title]` is the row's height (default 56); `apply` = the callback
-- edits `Items` itself (the local flow), else it only records the call (the server flow)
local function reorderable(titles: { string }, heights: { [string]: number }?, apply: boolean?, gap: number?): Reorderable
	local mails: { Mail } = {}
	for i, t in titles do
		mails[i] = { Id = i, Title = t }
	end
	local items = q.Source(mails)
	local calls: { { number } } = {}
	local list: any = ListData<<Mail>>({
		Items = items,
		Gap = gap,
		Key = function(m: Mail)
			return m.Id
		end,
		Render = function(item: Q.State<Mail>, _index: Q.State<number>)
			local title: Q.State<string> = item:Compute(function(self)
				return self:Get().Title
			end)
			return ListItem({ Headline = title })
		end,
		OnReorder = function(from: number, to: number)
			table.insert(calls, { from, to })
			if apply then
				local copy = table.clone(items:Get())
				table.insert(copy, to, table.remove(copy, from) :: Mail)
				items:Set(copy)
			end
		end,
	})
	local function hosts(): { any }
		local found = H.findAll(list, function(c: any)
			return c.Name == "ReorderRow"
		end)
		table.sort(found, function(a: any, b: any)
			return a.LayoutOrder < b.LayoutOrder
		end)
		return found
	end
	local function titleOf(host: any): string
		return (H.find(host, "Headline") :: any).Text
	end
	local listY = 100
	local heightOf: { [string]: number } = heights or {}
	local function layout(y: number?)
		listY = y or listY
		local at = listY
		for _, host in hosts() do
			local h = heightOf[titleOf(host)] or 56
			H.setAbs(host, 0, at, 360, h)
			at += h + (gap or 0)
		end
		H.setAbs(list, 0, listY, 360, at - listY)
	end
	layout()
	local function row(title: string): any
		for _, host in hosts() do
			if titleOf(host) == title then
				return host
			end
		end
		error("no row " .. title)
	end
	local pressed: any = nil
	return {
		list = list,
		items = items,
		calls = calls,
		layout = layout,
		row = row,
		offset = function(title: string): number
			return (H.find(row(title), "Lift") :: any).Position.Y.Offset
		end,
		top = function(title: string): number
			return row(title).AbsolutePosition.Y - listY
		end,
		-- press the row's handle; returns the pointer's y (the sections give their moves relative to it)
		press = function(title: string): number
			local host = row(title)
			local y = host.AbsolutePosition.Y + host.AbsoluteSize.Y / 2
			pressed = H.find(host, "DragHandle")
			H.fire(pressed, "InputBegan", H.input({ Position = Vector3.new(340, y, 0) }))
			return y
		end,
		move = function(y: number)
			UIS.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(340, y, 0) }))
		end,
		-- the engine's order: the pressed element's InputEnded, then the service's
		release = function(y: number)
			local input = H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(340, y, 0) })
			if pressed ~= nil and not H.isDestroyed(pressed) then
				H.fire(pressed, "InputEnded", input)
			end
			pressed = nil
			UIS.InputEnded:Fire(input)
		end,
		order = function(): string
			local names: { string } = {}
			for _, host in hosts() do
				table.insert(names, titleOf(host))
			end
			return table.concat(names, ",")
		end,
	}
end

H.section("OnReorder absent: ListData is what it was (rows are the List's children, no handle, no connection)", function()
	local base, began = dragConns(), beganConns()
	local items = q.Source({ { Id = 1, Title = "one" }, { Id = 2, Title = "two" } } :: { Mail })
	local list: any = ListData<<Mail>>({
		Items = items,
		Key = function(m: Mail)
			return m.Id
		end,
		Render = function(_item: Q.State<Mail>, index: Q.State<number>)
			return ListItem({ Headline = "x", LayoutOrder = index })
		end,
	})
	assert(H.find(list, "ReorderRow") == nil and H.find(list, "DragHandle") == nil and H.find(list, "Lift") == nil)
	assert(H.countDescendants(list) == 1 + 2 * 7, "UIListLayout + two 7-instance rows, got " .. H.countDescendants(list))
	for _, c in list:GetChildren() do
		assert(c.ClassName == "UIListLayout" or c.Name == "ListItem", "rows are direct children: " .. c.Name)
	end
	assert(dragConns() == base and beganConns() == began)
	q.dispose(list)
	H.assertNoDebugOutput("plain")
end)

H.section("reorder: row structure — host / Lift / Body / handle, 12 instances around the row, nothing connected at rest", function()
	local base, began, beat = dragConns(), beganConns(), heartbeatConns()
	local r = reorderable({ "A", "B", "C" })
	assert(r.order() == "A,B,C")
	local host = r.row("B")
	assert(host.ClassName == "Frame" and host.Parent == r.list and host.LayoutOrder == 2 and host.ZIndex == 1)
	assert(host.Size == UDim2.new(1, 0, 0, 0) and host.AutomaticSize == Enum.AutomaticSize.Y, "the engine sizes the host at rest")
	local lift = H.find(host, "Lift")
	assert(lift.Parent == host and lift.Position == UDim2.fromOffset(0, 0) and lift.AutomaticSize == Enum.AutomaticSize.Y)
	assert(lift.Size == UDim2.new(1, 0, 0, 0), "no Scale Y under the automatic height")
	assert(lift.BackgroundTransparency == 1 and lift.BackgroundColor3 == L.TertiaryContainer)
	local shadow = class(lift, "UIShadow")[1]
	assert(shadow.Parent == lift and shadow.Enabled == false, "no shadow at rest")
	assert(class(lift, "UICorner")[1].Parent == lift and class(lift, "UICorner")[1].CornerRadius == UDim.new(0, 0))
	local body = H.find(host, "Body")
	assert(body.Parent == lift and H.find(body, "ListItem").Parent == body, "the rendered row sits in Body")
	assert(class(body, "UIFlexItem")[1].Parent == body and class(body, "UIFlexItem")[1].FlexMode == Enum.UIFlexMode.Fill)
	local handle = H.find(host, "DragHandle")
	assert(handle.Parent == lift and handle.ClassName == "TextButton" and handle.Text == "=", "glyph handle (no image id is built in)")
	assert(handle.Size == UDim2.fromOffset(40, 40) and handle.LayoutOrder == 2 and body.LayoutOrder == 1)
	local rowLayout: any = nil
	for _, c in lift:GetChildren() do
		if c.ClassName == "UIListLayout" then
			rowLayout = c
		end
	end
	assert(rowLayout.FillDirection == Enum.FillDirection.Horizontal and rowLayout.VerticalAlignment == Enum.VerticalAlignment.Center)
	-- nothing from the host down to the row is placed or sized with a Scale Y (Ripple.luau "NOT SCALE"): they are automatic
	for _, inst in { host, lift, body } :: { any } do
		assert(inst.Size.Y.Scale == 0 and (inst.Position == nil or inst.Position.Y.Scale == 0), inst.Name .. ": no Scale Y")
	end
	assert(H.countDescendants(host) == 12 + 6, "12 around the row (1 + 6), got " .. H.countDescendants(host))
	assert(H.countDescendants(r.list) == 1 + 3 * 19)
	assert(dragConns() == base and beganConns() == began and heartbeatConns() == beat, "no connection at rest")
	q.dispose(r.list)
	assert(H.isDestroyed(host) and H.isDestroyed(handle))
	-- a place that registered an image for the handle gets an ImageButton
	Icons.override({ dragHandle = "rbxassetid://1" })
	local withImage = reorderable({ "A" })
	local imageHandle = H.find(withImage.list, "DragHandle")
	assert(imageHandle.ClassName == "ImageButton" and H.find(imageHandle, "Icon").Image == "rbxassetid://1")
	assert(H.countDescendants(withImage.row("A")) == 14 + 6)
	q.dispose(withImage.list)
	Icons.override({ dragHandle = false })
	H.assertNoDebugOutput("structure")
end)

H.section("reorder: pressing the handle lifts the row, it follows the pointer inside the list, the others give way", function()
	local base, began = dragConns(), beganConns()
	local r = reorderable({ "A", "B", "C" })
	local y = r.press("A")
	H.finishTweens()
	local host, lift = r.row("A"), H.find(r.row("A"), "Lift")
	assert(host.ZIndex == 2 and r.row("B").ZIndex == 1, "the lifted row draws above the others")
	assert(lift.BackgroundTransparency == 0 and class(lift, "UICorner")[1].CornerRadius == UDim.new(0, 16), "tertiary container, corner large")
	local shadow = class(lift, "UIShadow")[1]
	assert(shadow.Enabled == true and shadow.BlurRadius == UDim.new(0, Tokens.Elevation.Levels[4].BlurRadius), "elevation level 4")
	for _, t in { "A", "B", "C" } do
		local h = r.row(t)
		assert(h.AutomaticSize == Enum.AutomaticSize.None and h.Size == UDim2.new(1, 0, 0, 56), t .. ": host frozen to its measured height")
	end
	assert(dragConns() == base + 3 and beganConns() == began + 1, "the drag's three connections + the Escape listener")
	r.move(y + 20)
	assert(r.offset("A") == 20 and r.offset("B") == 0, "follows at once (a snap, no tween)")
	r.move(y + 28)
	H.finishTweens()
	assert(r.offset("B") == 0, "half a row exactly: still its own slot")
	r.move(y + 29)
	H.finishTweens()
	assert(r.offset("A") == 29 and r.offset("B") == -56 and r.offset("C") == 0, "past half a row: B gives way by A's height")
	r.move(y + 90)
	H.finishTweens()
	assert(r.offset("B") == -56 and r.offset("C") == -56)
	r.move(y + 40)
	H.finishTweens()
	assert(r.offset("B") == -56 and r.offset("C") == 0, "C goes back when A returns")
	r.move(y + 500)
	assert(r.offset("A") == 112, "kept inside the list (bottom)")
	r.move(y - 500)
	H.finishTweens()
	assert(r.offset("A") == 0 and r.offset("B") == 0 and r.offset("C") == 0, "kept inside the list (top)")
	assert(r.order() == "A,B,C" and #r.calls == 0, "nothing is re-ordered while dragging")
	r.release(y - 500)
	H.finishTweens()
	assert(#r.calls == 0 and dragConns() == base and beganConns() == began, "released on its own place: no callback")
	assert(lift.BackgroundTransparency == 1 and shadow.Enabled == false)
	H.advance(0.25)
	assert(host.ZIndex == 1 and host.AutomaticSize == Enum.AutomaticSize.Y and host.Size == UDim2.new(1, 0, 0, 0), "thawed")
	assert(H.pendingTimers() == 0)
	q.dispose(r.list)
	H.assertNoDebugOutput("follow")
end)

H.section("reorder: release calls OnReorder(from, to) once; Items set in the callback re-seats every row where it is", function()
	local r = reorderable({ "A", "B", "C" }, nil, true)
	local y = r.press("A")
	r.move(y + 100) -- A's top at 100: nearest slot is the third (112)
	-- B's and C's tweens are left running (the mock keeps their start value 0 until finishTweens)
	local seen = { A = r.top("A") + r.offset("A"), B = r.top("B") + r.offset("B"), C = r.top("C") + r.offset("C") }
	assert(seen.A == 100 and seen.B == 56 and seen.C == 112)
	r.release(y + 100)
	assert(#r.calls == 1 and r.calls[1][1] == 1 and r.calls[1][2] == 3, "from 1 to 3 (the place after the move)")
	assert(r.order() == "B,C,A", "the owner's edit: LayoutOrder follows")
	r.layout() -- the engine lays out with the new LayoutOrder in the same frame
	for _, t in { "A", "B", "C" } do
		assert(r.top(t) + r.offset(t) == (seen :: any)[t], `{t}: drawn where it was ({r.top(t)} + {r.offset(t)})`)
	end
	assert(r.offset("A") == -12 and r.offset("B") == 56 and r.offset("C") == 56)
	H.finishTweens()
	assert(r.offset("A") == 0 and r.offset("B") == 0 and r.offset("C") == 0, "then every row glides to its new place")
	assert(r.row("A").ZIndex == 2, "the moved row stays on top while it settles")
	H.advance(0.25)
	assert(r.row("A").ZIndex == 1 and r.row("A").AutomaticSize == Enum.AutomaticSize.Y and H.pendingTimers() == 0)
	-- rows that had finished giving way do not move at all
	y = r.press("B")
	r.move(y + 60)
	H.finishTweens()
	assert(r.offset("C") == -56)
	r.release(y + 60)
	assert(#r.calls == 2 and r.calls[2][1] == 1 and r.calls[2][2] == 2 and r.order() == "C,B,A")
	r.layout()
	assert(r.offset("C") == 0 and r.offset("A") == 0 and r.offset("B") == 4, "C sits exactly on its new place; B is 4 px from its slot")
	H.finishTweens()
	H.advance(0.25)
	-- upwards
	y = r.press("A")
	r.move(y - 80)
	r.release(y - 80)
	assert(r.calls[3][1] == 3 and r.calls[3][2] == 2 and r.order() == "C,A,B")
	H.finishTweens()
	H.advance(0.25)
	assert(H.pendingTimers() == 0)
	q.dispose(r.list)
	H.assertNoDebugOutput("drop")
end)

H.section("reorder: Items left alone — the rows wait, then go back; a later Items change re-seats them; no drag while waiting", function()
	local r = reorderable({ "A", "B", "C" })
	local y = r.press("A")
	r.move(y + 60)
	r.release(y + 60)
	H.finishTweens()
	assert(#r.calls == 1 and r.calls[1][1] == 1 and r.calls[1][2] == 2 and r.order() == "A,B,C", "the list did not edit Items")
	assert(r.offset("A") == 56 and r.offset("B") == -56 and r.offset("C") == 0, "the dropped arrangement is held")
	assert(H.find(r.row("A"), "Lift").BackgroundTransparency == 1, "not lifted any more")
	assert(H.pendingTimers() == 1)
	local base = dragConns()
	r.press("C")
	H.finishTweens()
	assert(H.find(r.row("C"), "Lift").BackgroundTransparency == 1 and r.row("C").ZIndex == 1, "no new drag while waiting")
	r.release(0)
	assert(dragConns() == base and #r.calls == 1)
	H.advance(ListReorder.HOLD - 0.01)
	assert(r.offset("A") == 56, "still waiting")
	H.advance(0.02)
	H.finishTweens()
	assert(r.offset("A") == 0 and r.offset("B") == 0, "no answer: back to the resting places")
	assert(r.row("A").AutomaticSize == Enum.AutomaticSize.None, "frozen until the glide ends")
	H.advance(0.25)
	assert(r.row("A").AutomaticSize == Enum.AutomaticSize.Y and H.pendingTimers() == 0 and #r.calls == 1)

	-- the server answers inside the wait with the order the drop showed: nothing moves
	y = r.press("A")
	r.move(y + 60)
	r.release(y + 60)
	H.finishTweens()
	H.advance(0.3)
	local list = r.items:Get()
	r.items:Set({ list[2], list[1], list[3] })
	r.layout()
	assert(r.order() == "B,A,C" and r.offset("A") == 0 and r.offset("B") == 0 and r.offset("C") == 0, "seamless")
	H.advance(0.25)
	assert(H.pendingTimers() == 0)

	-- the server answers with ANOTHER order: every row glides from where it is to that order
	y = r.press("B")
	r.move(y + 60)
	r.release(y + 60) -- shown: A,B,C
	H.finishTweens()
	local seenB = r.top("B") + r.offset("B")
	list = r.items:Get()
	r.items:Set({ list[3], list[2], list[1] }) -- C,A,B
	r.layout()
	assert(r.order() == "C,A,B" and r.top("B") + r.offset("B") == seenB and r.offset("C") == 112)
	H.finishTweens()
	H.advance(0.25)

	-- refused: the owner sets the unchanged order, the rows go back at once
	y = r.press("C") -- the first row now
	r.move(y + 60)
	r.release(y + 60)
	H.finishTweens()
	assert(r.offset("C") == 56 and r.offset("A") == -56)
	r.items:Set(table.clone(r.items:Get()))
	assert(r.offset("C") == 56 and H.pendingTimers() == 1, "the glide back started (the wait timer became the glide's)")
	H.finishTweens()
	assert(r.offset("C") == 0 and r.offset("A") == 0)
	H.advance(0.25)
	assert(H.pendingTimers() == 0)
	q.dispose(r.list)
	H.assertNoDebugOutput("wait")
end)

H.section("reorder: cancel — Escape, focus loss, Items changing mid-drag; no callback", function()
	local base, began = dragConns(), beganConns()
	local r = reorderable({ "A", "B", "C" })
	local y = r.press("A")
	r.move(y + 60)
	H.finishTweens()
	assert(r.offset("B") == -56)
	UIS.InputBegan:Fire(H.input({ KeyCode = Enum.KeyCode.Escape, UserInputType = Enum.UserInputType.Keyboard }), false)
	assert(dragConns() == base and beganConns() == began, "the drag is over")
	H.finishTweens()
	assert(r.offset("A") == 0 and r.offset("B") == 0 and #r.calls == 0)
	r.move(y + 200)
	r.release(y + 200)
	assert(r.offset("A") == 0 and #r.calls == 0, "the cancelled gesture is dead")
	H.advance(0.3)
	assert(H.pendingTimers() == 0)

	-- a press while the rows are still gliding back: they are put on their places at once and the new drag starts there
	y = r.press("C")
	r.move(y - 60)
	H.finishTweens()
	assert(r.offset("C") == -60 and r.offset("B") == 56)
	UIS.InputBegan:Fire(H.input({ KeyCode = Enum.KeyCode.ButtonB, UserInputType = Enum.UserInputType.Gamepad1 }), false)
	assert(r.offset("B") == 56, "(gliding: the mock tween has not landed)")
	r.release(y - 60)
	y = r.press("A")
	assert(r.offset("B") == 0 and r.offset("C") == 0, "snapped to rest by the new press")
	H.finishTweens()
	assert(H.find(r.row("A"), "Lift").BackgroundTransparency == 0 and r.row("A").ZIndex == 2 and r.row("C").ZIndex == 1)
	r.move(y + 60)
	H.finishTweens()
	assert(r.offset("A") == 60 and r.offset("B") == -56 and r.offset("C") == 0)
	UIS.InputBegan:Fire(H.input({ KeyCode = Enum.KeyCode.Escape, UserInputType = Enum.UserInputType.Keyboard }), false)
	r.release(y + 60)
	H.finishTweens()
	H.advance(0.3)
	assert(#r.calls == 0 and H.pendingTimers() == 0)

	y = r.press("B")
	r.move(y + 60)
	UIS.WindowFocusReleased:Fire()
	H.finishTweens()
	assert(r.offset("B") == 0 and #r.calls == 0 and dragConns() == base)
	r.release(y + 60)
	H.advance(0.3)
	assert(H.pendingTimers() == 0)

	-- another change of the same rows arrives mid-drag: the drag is cancelled and the rows re-seat from where they are
	y = r.press("A")
	r.move(y + 100)
	local seenA = r.top("A") + r.offset("A")
	local list = r.items:Get()
	r.items:Set({ list[2], list[1], list[3] })
	r.layout()
	assert(dragConns() == base and #r.calls == 0 and r.order() == "B,A,C")
	assert(r.top("A") + r.offset("A") == seenA, "A is drawn where the pointer left it")
	H.finishTweens()
	assert(r.offset("A") == 0 and H.find(r.row("A"), "Lift").BackgroundTransparency == 1)
	r.release(y + 100)
	H.advance(0.3)
	assert(H.pendingTimers() == 0 and #r.calls == 0)

	-- a row is added mid-drag: the session ends where the layout is
	y = r.press("A")
	r.move(y + 30)
	H.finishTweens()
	list = table.clone(r.items:Get())
	table.insert(list, { Id = 9, Title = "D" })
	r.items:Set(list)
	assert(dragConns() == base and r.offset("A") == 0 and r.offset("B") == 0 and r.order() == "B,A,C,D")
	assert(r.row("A").AutomaticSize == Enum.AutomaticSize.Y and r.row("A").ZIndex == 1, "thawed at once")
	r.release(y + 30)
	H.advance(0.3)
	assert(H.pendingTimers() == 0)
	-- and removed
	r.layout()
	y = r.press("D")
	r.move(y - 100)
	list = table.clone(r.items:Get())
	table.remove(list, 1)
	r.items:Set(list)
	assert(dragConns() == base and r.order() == "A,C,D" and r.offset("D") == 0 and #r.calls == 0)
	r.release(y - 100)
	H.advance(0.3)
	assert(H.pendingTimers() == 0 and #r.calls == 0)
	q.dispose(r.list)
	H.advance(1)
	H.assertNoDebugOutput("cancel")
end)

H.section("reorder: mixed heights and a gap — measured, not assumed", function()
	-- one-, three- and two-line rows, 8 px apart: tops 0 / 64 / 160
	local r = reorderable({ "A", "B", "C" }, { A = 56, B = 88, C = 72 }, true, 8)
	assert(r.top("B") == 64 and r.top("C") == 160)
	local y = r.press("A")
	H.finishTweens()
	assert(r.row("B").Size == UDim2.new(1, 0, 0, 88) and r.row("C").Size == UDim2.new(1, 0, 0, 72), "each host frozen to its own height")
	-- A's slots: 0, then under B (64 + 88 - 56 = 96), then under C (160 + 72 - 56 = 176)
	r.move(y + 48)
	H.finishTweens()
	assert(r.offset("B") == 0, "48 is as far from 0 as from 96")
	r.move(y + 49)
	H.finishTweens()
	assert(r.offset("B") == -64 and r.offset("C") == 0, "B moves up by A's height + the gap")
	r.move(y + 137)
	H.finishTweens()
	assert(r.offset("C") == -64, "136 = halfway between 96 and 176")
	r.move(y + 500)
	assert(r.offset("A") == 176, "bottom of the list: 232 - 56")
	r.move(y + 49)
	H.finishTweens()
	r.release(y + 49)
	assert(#r.calls == 1 and r.calls[1][1] == 1 and r.calls[1][2] == 2 and r.order() == "B,A,C")
	r.layout()
	assert(r.top("A") == 96 and r.offset("A") == 49 - 96 and r.offset("B") == 0 and r.offset("C") == 0)
	H.finishTweens()
	H.advance(0.25)
	-- upwards with the two-line row: B (88) at 0, A (56) at 96, C (72) at 160; C's slots are 160 / 96 / 0
	y = r.press("C")
	r.move(y - 33)
	H.finishTweens()
	assert(r.offset("A") == 80 and r.offset("B") == 0, "A gives way downwards by C's height + the gap")
	r.move(y - 113)
	H.finishTweens()
	assert(r.offset("B") == 80)
	r.release(y - 113)
	assert(r.calls[2][1] == 3 and r.calls[2][2] == 1 and r.order() == "C,B,A")
	r.layout()
	assert(r.top("B") == 80 and r.top("A") == 176 and r.offset("B") == 0 and r.offset("A") == 0 and r.offset("C") == 47)
	H.finishTweens()
	H.advance(0.25)
	assert(H.pendingTimers() == 0)
	q.dispose(r.list)
	H.assertNoDebugOutput("mixed")
end)

H.section("reorder: under a UIScale the pointer and the measures are divided by it", function()
	local r = reorderable({ "A", "B", "C" }, { A = 112, B = 112, C = 112 }) -- screen pixels of 56-unit rows at scale 2
	local scaled = D.Frame { D.UIScale { Scale = 2 }, r.list }
	local y = r.press("A")
	H.finishTweens()
	assert(r.row("A").Size == UDim2.new(1, 0, 0, 56), "frozen in local units")
	r.move(y + 40)
	assert(r.offset("A") == 20)
	r.move(y + 60)
	H.finishTweens()
	assert(r.offset("A") == 30 and r.offset("B") == -56)
	r.release(y + 60)
	H.finishTweens()
	assert(r.offset("A") == 56 and r.calls[1][2] == 2)
	q.dispose(scaled)
	H.advance(2)
	assert(H.pendingTimers() == 0)
	H.assertNoDebugOutput("scale")
end)

H.section("reorder: edge scroll — the ancestor ScrollingFrame scrolls while the lifted row sticks out, the row stays under the pointer", function()
	local beat = heartbeatConns()
	local titles: { string } = {}
	for i = 1, 10 do
		titles[i] = "R" .. i
	end
	local r = reorderable(titles)
	local scroll: any = D.ScrollingFrame { r.list }
	H.setAbs(scroll, 0, 100, 360, 200)
	scroll.AbsoluteWindowSize = Vector2.new(360, 200)
	scroll.AbsoluteCanvasSize = Vector2.new(360, 560)
	scroll.CanvasPosition = Vector2.new(0, 0)
	scroll.ScrollingEnabled = true
	local y = r.press("R1")
	assert(heartbeatConns() == beat + 1 and scroll.ScrollingEnabled == false, "one frame connection; the finger does not scroll the frame")
	r.move(y + 100)
	H.advance(1 / 60)
	assert(scroll.CanvasPosition.Y == 0, "the row (100 .. 156 of 200) is inside the window")
	r.move(y + 160)
	H.advance(1 / 60)
	local first = scroll.CanvasPosition.Y
	assert(first >= 1 and first < 2, "16 px out: starts at the slowest step, got " .. first)
	-- the engine moves the list by the scroll; the row keeps its place under the pointer
	r.layout(100 - 40)
	H.advance(1 / 60)
	assert(r.offset("R1") == 200, "160 of pointer travel + 40 of scroll")
	for _ = 1, 105 do
		H.advance(1 / 60)
	end
	local late = scroll.CanvasPosition.Y
	H.advance(1 / 60)
	local oneFrame = scroll.CanvasPosition.Y - late
	assert(late < 360 and oneFrame > 5 and oneFrame <= 20, "accelerates with the time out of bounds, at most 20 a frame: " .. oneFrame)
	for _ = 1, 200 do
		H.advance(1 / 60)
	end
	assert(scroll.CanvasPosition.Y == 360, "stops at the end of the canvas (560 - 200)")
	-- upwards only when dragged upwards: the row sticking out at the top after a downward drag does not scroll back
	r.layout(100 - 360)
	H.advance(1 / 60)
	assert(scroll.CanvasPosition.Y == 360)
	r.move(y - 20)
	H.advance(1 / 60)
	assert(scroll.CanvasPosition.Y < 360, "dragged above its start and out at the top: scrolls up")
	r.release(y - 20)
	assert(heartbeatConns() == beat and scroll.ScrollingEnabled == true)
	q.dispose(scroll)
	H.advance(2)
	assert(H.pendingTimers() == 0)
	H.assertNoDebugOutput("scroll")
end)

H.section("reorder: keys — the handle engages with Return / ButtonA, Up / Down move the row one place at once", function()
	local began = beganConns()
	local r = reorderable({ "A", "B", "C" }, nil, true)
	local handle = H.find(r.row("B"), "DragHandle")
	local function key(code: Enum.KeyCode)
		UIS.InputBegan:Fire(H.input({ KeyCode = code, UserInputType = Enum.UserInputType.Keyboard }), false)
	end
	H.fire(handle, "SelectionGained")
	assert(beganConns() == began + 1 and handle.NextSelectionUp == nil, "selected: the D-pad still walks on")
	key(Enum.KeyCode.Down)
	assert(#r.calls == 0, "not engaged: the arrows are the engine's")
	key(Enum.KeyCode.Return)
	H.finishTweens()
	assert(handle.NextSelectionUp == handle and handle.NextSelectionDown == handle, "engaged: the arrows are the row's")
	assert(H.find(r.row("B"), "Lift").BackgroundTransparency == 0, "engaged looks lifted")
	key(Enum.KeyCode.Down)
	assert(#r.calls == 1 and r.calls[1][1] == 2 and r.calls[1][2] == 3 and r.order() == "A,C,B")
	r.layout()
	assert(r.offset("B") == -56 and r.offset("C") == 56, "drawn where they were, then gliding")
	assert(r.row("B").ZIndex == 2)
	H.finishTweens()
	assert(r.offset("B") == 0 and r.offset("C") == 0)
	H.advance(0.25)
	key(Enum.KeyCode.Down)
	assert(#r.calls == 1, "already last")
	key(Enum.KeyCode.DPadUp)
	r.layout()
	H.advance(0.25)
	key(Enum.KeyCode.Up)
	assert(#r.calls == 3 and r.calls[3][1] == 2 and r.calls[3][2] == 1 and r.order() == "B,A,C")
	key(Enum.KeyCode.Up)
	assert(#r.calls == 3, "already first")
	key(Enum.KeyCode.Escape)
	H.flushDeferred()
	H.finishTweens()
	assert(handle.NextSelectionUp == nil and H.find(r.row("B"), "Lift").BackgroundTransparency == 1, "disengaged")
	H.fire(handle, "SelectionLost")
	assert(beganConns() == began)
	H.advance(0.25)
	assert(H.pendingTimers() == 0)
	q.dispose(r.list)
	H.assertNoDebugOutput("keys")
end)

H.section("reorder: Escape during a drag does not dismiss an overlay around the list; dispose mid-drag leaves nothing", function()
	local base, began, beat = dragConns(), beganConns(), heartbeatConns()
	local overlay = Overlay.new()
	local screen = D.Frame { overlay.Layer }
	local r = reorderable({ "A", "B" })
	local entry = overlay:Open({ Content = r.list, DismissOnEscape = true })
	r.layout()
	local y = r.press("A")
	r.move(y + 40)
	UIS.InputBegan:Fire(H.input({ KeyCode = Enum.KeyCode.Escape, UserInputType = Enum.UserInputType.Keyboard }), false)
	assert(entry.IsOpen:Get() == true, "the Escape cancelled the drag only")
	H.advance(0.3)
	UIS.InputBegan:Fire(H.input({ KeyCode = Enum.KeyCode.Escape, UserInputType = Enum.UserInputType.Keyboard }), false)
	assert(entry.IsOpen:Get() == false, "the next one closes the overlay")
	H.advance(1)
	q.dispose(screen)
	assert(dragConns() == base and beganConns() == began)

	local d = reorderable({ "A", "B", "C" })
	local all = H.findAll(d.list, function()
		return true
	end)
	y = d.press("B")
	d.move(y + 60)
	q.dispose(d.list)
	for _, c in all do
		assert(H.isDestroyed(c), "undestroyed: " .. c.Name)
	end
	assert(dragConns() == base and beganConns() == began and heartbeatConns() == beat and H.pendingTimers() == 0)
	d.move(y + 90)
	d.release(y + 90)
	assert(#d.calls == 0)
	-- destroyed while waiting for Items
	local w = reorderable({ "A", "B", "C" })
	y = w.press("A")
	w.move(y + 60)
	w.release(y + 60)
	assert(#w.calls == 1 and H.pendingTimers() == 1)
	q.dispose(w.list)
	assert(H.pendingTimers() == 0)
	H.advance(2)
	H.assertNoDebugOutput("dispose mid-drag")
end)

H.section("dispose: full tree of items destroyed, no timers", function()
	local root = D.Frame {
		List({ Children = q.Slot({ ListItem({ Headline = "x", OnClick = function() end, Leading = "rbxassetid://1" }) } :: { Instance }) }),
	}
	local all = H.findAll(root, function()
		return true
	end)
	H.fire(H.find(root, "ListItem"), "InputBegan", H.input({ Position = Vector3.new(1, 1, 0) }))
	q.dispose(root)
	for _, c in all do
		assert(H.isDestroyed(c), "undestroyed: " .. c.Name)
	end
	H.advance(2)
	assert(H.pendingTimers() == 0)
	H.assertNoDebugOutput("dispose")
end)

H.done()
