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
	assert(s3.Size == UDim2.new(1, 0, 0, 40) and s3.TextWrapped == true, "supporting may wrap to two lines")
	assert(class(three, "UIListLayout")[1].VerticalAlignment == Enum.VerticalAlignment.Top, "three-line is top aligned")
	local forced: any = ListItem({ Headline = "H", Supporting = "S", Lines = 3 })
	assert(forced.Size == UDim2.new(1, 0, 0, 88))
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
