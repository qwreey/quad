--!strict
local H = require("./support/harness")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
local D = q.Declaration
local Theme = require("../src/Theme")
local Tokens = require("../src/Tokens")
local Card = require("../src/Card")
local Divider = require("../src/Divider")

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

H.section("Elevated card at rest: Frame + corner 12 + shadow level 1, no interaction layer", function()
	local card = Card({})
	assert(card.ClassName == "Frame" and card.Name == "Card")
	assert(card.BackgroundColor3 == L.SurfaceContainerLow and card.BackgroundTransparency == 0)
	assert(H.find(card, "_quad_round").CornerRadius == UDim.new(0, 12), "corner 12")
	assert(#class(card, "UIShadow") == 1 and #class(card, "UIStroke") == 0)
	assert(H.countDescendants(card) == 3, "UICorner + UIShadow + Content, got " .. H.countDescendants(card))
	assert(card.AutomaticSize == Enum.AutomaticSize.XY)
	q.dispose(card)
	H.assertNoDebugOutput("elevated")
end)

H.section("Filled and Outlined variants", function()
	local filled = Card({ Variant = "Filled" })
	assert(filled.BackgroundColor3 == L.SurfaceContainerHighest and #class(filled, "UIShadow") == 0)
	assert(H.countDescendants(filled) == 2, "UICorner + Content")
	local outlined = Card({ Variant = "Outlined" })
	local stroke = H.find(outlined, "Outline")
	assert(outlined.BackgroundColor3 == L.Surface and stroke.Thickness == 1 and stroke.Color == L.OutlineVariant)
	assert(H.countDescendants(outlined) == 3)
	q.dispose(filled)
	q.dispose(outlined)
	H.assertNoDebugOutput("variants")
end)

H.section("children Slot, padding, gap, caller Modifier overrides the base size", function()
	local children = q.Slot({ D.TextLabel { Name = "A", Text = "a" }, D.TextLabel { Name = "B", Text = "b" } } :: { Instance })
	local card = Card({
		Children = children,
		Padding = 16,
		Gap = 8,
		LayoutOrder = 3,
		Modifier = D.Modifier.GuiObject():Size(UDim2.fromOffset(200, 100)),
	})
	assert(H.find(card, "A") ~= nil and H.find(card, "B") ~= nil, "children mounted")
	assert(card.Size == UDim2.fromOffset(200, 100) and card.LayoutOrder == 3, "caller Modifier wins over the base")
	local pad = class(card, "UIPadding")[1]
	assert(pad.PaddingLeft == UDim.new(0, 16) and pad.PaddingBottom == UDim.new(0, 16), "padding")
	assert(class(card, "UIListLayout")[1].Padding == UDim.new(0, 8))
	local content = H.find(card, "Content")
	assert(pad.Parent == content and class(card, "UIListLayout")[1].Parent == content, "padding + layout on Content")
	assert(H.find(card, "A").Parent == content, "children under Content")
	assert(#class(card, "UIPadding") == 1 and pad.Parent ~= card)
	children:Add(D.TextLabel { Name = "C", Text = "c" })
	assert(H.find(card, "C") ~= nil, "Slot CRUD reaches the card")
	q.dispose(card)
	H.assertNoDebugOutput("children")
end)

H.section("interactive card: OnClick, state layer, hover raises the shadow, disabled", function()
	local clicks = 0
	local disabled = q.Source(false)
	local card: any = Card({
		Variant = "Elevated",
		Disabled = disabled,
		OnClick = function()
			clicks += 1
		end,
	})
	assert(card.ClassName == "TextButton" and card.AutoButtonColor == false and card.Text == "")
	assertLayerLayout(card, "interactive card")
	assert(H.countDescendants(card) == 6, "corner + shadow + layer(3) + Content, got " .. H.countDescendants(card))
	H.fire(card, "Activated", H.input({}), 1)
	assert(clicks == 1)
	local shadow = class(card, "UIShadow")[1]
	H.finishTweens()
	local lv = Tokens.Elevation.Levels
	assert(shadow.BlurRadius == UDim.new(0, lv[1].BlurRadius))
	H.fire(card, "MouseEnter")
	H.finishTweens()
	assert(shadow.BlurRadius == UDim.new(0, lv[2].BlurRadius), "hover level 2")
	assert(near(H.find(card, "StateLayer").BackgroundTransparency, 0.92), "hover layer .08")
	disabled:Set(true)
	H.finishTweens()
	assert(card.Interactable == false and shadow.Enabled == false)
	assert(near(card.BackgroundTransparency, 0.88) and card.BackgroundColor3 == L.OnSurface)
	H.fire(card, "Activated", H.input({}), 1)
	assert(clicks == 1, "disabled swallows the click")
	disabled:Set(false)
	H.finishTweens()
	assert(card.BackgroundColor3 == L.SurfaceContainerLow and card.Interactable == true)
	q.dispose(card)
	H.assertNoDebugOutput("interactive")
end)

H.section("outlined interactive: disabled outline, theme switch", function()
	local theme = Theme.new({ Scheme = "light" })
	local card = Card({ Variant = "Outlined", Theme = theme, OnClick = function() end, Disabled = true })
	H.finishTweens()
	local stroke = H.find(card, "Outline")
	assert(near(stroke.Transparency, 0.88) and stroke.Color == L.OnSurface)
	local plain = Card({ Variant = "Filled", Theme = theme })
	theme:SetScheme("dark")
	H.finishTweens()
	assert(plain.BackgroundColor3 == Tokens.Color.Dark.SurfaceContainerHighest)
	q.dispose(card)
	q.dispose(plain)
	H.assertNoDebugOutput("theme")
end)

H.section("dispose destroys everything (card tree with a pressed ripple)", function()
	local root = D.Frame {
		Card({ OnClick = function() end, Children = q.Slot({ D.TextLabel { Text = "x" } } :: { Instance }) }),
		Card({ Variant = "Outlined" }),
	}
	local all = H.findAll(root, function()
		return true
	end)
	H.fire(H.find(root, "Card"), "InputBegan", H.input({ Position = Vector3.new(1, 1, 0) }))
	q.dispose(root)
	for _, c in all do
		assert(H.isDestroyed(c), "undestroyed: " .. c.Name)
	end
	H.advance(2)
	assert(H.pendingTimers() == 0)
	H.assertNoDebugOutput("dispose")
end)

H.section("Divider: full, inset, middle inset, vertical", function()
	local full = Divider()
	assert(full.Size == UDim2.new(1, 0, 0, 1) and full.BackgroundColor3 == L.OutlineVariant and H.countDescendants(full) == 0)
	local inset = Divider({ Inset = "Start" })
	local line = H.find(inset, "Line")
	assert(inset.BackgroundTransparency == 1 and line.BackgroundColor3 == L.OutlineVariant and H.countDescendants(inset) == 2)
	local pad = class(inset, "UIPadding")[1]
	assert(pad.PaddingLeft == UDim.new(0, 16) and pad.PaddingRight == UDim.new(0, 0))
	local mid = Divider({ Inset = "Both" })
	local mp = class(mid, "UIPadding")[1]
	assert(mp.PaddingLeft == UDim.new(0, 16) and mp.PaddingRight == UDim.new(0, 16))
	local vert = Divider({ Orientation = "Vertical", Inset = "Both", LayoutOrder = 2, Modifier = D.Modifier.Frame():Size(UDim2.new(0, 2, 1, 0)) })
	local vp = class(vert, "UIPadding")[1]
	assert(vert.Size == UDim2.new(0, 2, 1, 0) and vert.LayoutOrder == 2, "caller Modifier wins")
	assert(vp.PaddingTop == UDim.new(0, 16) and vp.PaddingBottom == UDim.new(0, 16) and vp.PaddingLeft == UDim.new(0, 0))
	local v2 = Divider({ Orientation = "Vertical" })
	assert(v2.Size == UDim2.new(0, 1, 1, 0))
	for _, d in { full, inset, mid, vert, v2 } do
		q.dispose(d)
	end
	H.assertNoDebugOutput("divider")
end)

H.done()
