--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Devui = require("../src")
local Style = Devui.Style
local Kids = Devui.Kids

local function nameOf(inst: any): string
	return inst.Name
end

H.section("Text family binds style tokens and State text", function()
	local msg = q.Source("hello")
	local t = Devui.Text({ Text = msg })
	assert(t.Text == "hello" and t.TextColor3 == Color3.fromRGB(255, 255, 255))
	assert(t.TextSize == 13 and t.BackgroundTransparency == 1)
	msg:Set("bye")
	assert(t.Text == "bye", "State text follows")

	local w = Devui.TextWrapped({ Text = "long" })
	assert(w.TextWrapped == true and w.Size == UDim2.new(1, 0, 0, 0))

	local color = q.Source(Color3.new(1, 0, 0))
	local c = Devui.TextColored({ Text = "red", Color = color })
	assert(c.TextColor3 == Color3.new(1, 0, 0))
	color:Set(Color3.new(0, 1, 0))
	assert(c.TextColor3 == Color3.new(0, 1, 0))

	local d = Devui.TextDisabled({ Text = "dim" })
	assert(d.TextColor3 == Color3.fromRGB(128, 128, 128))

	local l = Devui.LabelText({ Label = "Name", Text = "Value" })
	local kids = l:GetChildren()
	local labels = H.findAll(l, function(i)
		return i.Name == "Text"
	end)
	assert(#labels == 2 and (labels[1] :: any).Text == "Value" and (labels[2] :: any).Text == "Name", "value then label")
	assert(#kids >= 3)

	for _, i in { t, w, c, d, l } do
		q.dispose(i)
	end
	H.assertNoDebugOutput("text")
end)

H.section("Theme switch repaints text live", function()
	local s = Style.new()
	local t = Devui.Text({ Text = "x", Style = s })
	assert(t.TextColor3 == Color3.fromRGB(255, 255, 255))
	s:SetScheme("Light")
	assert(t.TextColor3 == Color3.fromRGB(0, 0, 0))
	s:SetDensity("Clear")
	assert(t.TextSize == 15)
	q.dispose(t)
	H.assertNoDebugOutput("theme")
end)

H.section("Button: click, hover/pressed colours, theme", function()
	local clicks = 0
	local s = Style.new()
	local b = Devui.Button({
		Text = "Go",
		Style = s,
		OnClick = function()
			clicks += 1
		end,
	})
	assert(b.Text == "Go" and b.AutoButtonColor == false)
	assert(b.BackgroundColor3 == Color3.fromRGB(66, 150, 250) and b.BackgroundTransparency == 0.6, "idle")
	H.fire(b, "Activated", H.input({}), 1)
	assert(clicks == 1)
	H.fire(b, "MouseEnter", 1, 1)
	assert(b.BackgroundTransparency == 0, "hover")
	H.fire(b, "InputBegan", H.input({}))
	assert(b.BackgroundColor3 == Color3.fromRGB(15, 135, 250), "pressed")
	H.fire(b, "InputEnded", H.input({ UserInputState = Enum.UserInputState.End }))
	assert(b.BackgroundColor3 == Color3.fromRGB(66, 150, 250) and b.BackgroundTransparency == 0, "back to hover")
	H.fire(b, "MouseLeave")
	assert(b.BackgroundTransparency == 0.6)

	local sb = Devui.SmallButton({ Text = "s", Style = s })
	local pad = H.find(sb, "UIPadding") or H.findAll(sb, function(i: any)
		return i.ClassName == "UIPadding"
	end)[1]
	assert(pad ~= nil and (pad :: any).PaddingTop == UDim.new(0, 0), "small button: no vertical padding")

	local fixed = Devui.Button({ Text = "f", Size = UDim2.fromOffset(80, 20), Style = s })
	assert(fixed.Size == UDim2.fromOffset(80, 20) and fixed.AutomaticSize == Enum.AutomaticSize.None)
	s:SetDensity("Clear")
	local stroke = H.findAll(b, function(i: any)
		return i.ClassName == "UIStroke"
	end)[1] :: any
	assert(stroke.Thickness == 1, "density switch reaches the stroke")
	for _, i in { b, sb, fixed } do
		q.dispose(i)
	end
	H.assertNoDebugOutput("button")
end)

H.section("Button Toggled: the pressed look while on, follows a State; hover still works; never written", function()
	local s = Style.new()
	local on = q.Source(false)
	local b = Devui.Button({ Text = "chip", Style = s, Toggled = on })
	assert(b.BackgroundColor3 == Color3.fromRGB(66, 150, 250) and b.BackgroundTransparency == 0.6, "off: resting")
	on:Set(true)
	assert(b.BackgroundColor3 == Color3.fromRGB(15, 135, 250), "on: the ButtonActive look")
	H.fire(b, "MouseEnter", 1, 1)
	H.fire(b, "MouseLeave")
	assert(b.BackgroundColor3 == Color3.fromRGB(15, 135, 250), "hover in and out keeps the on look")
	H.fire(b, "Activated", H.input({}), 1)
	assert(on:Get() == true, "the button never writes Toggled")
	on:Set(false)
	assert(b.BackgroundColor3 == Color3.fromRGB(66, 150, 250))
	local fixed = Devui.Button({ Text = "c", Style = s, Toggled = true })
	assert(fixed.BackgroundColor3 == Color3.fromRGB(15, 135, 250), "a plain true")
	q.dispose(b)
	q.dispose(fixed)
	H.assertNoDebugOutput("toggled")
end)

H.section("Layout containers take Slot children", function()
	local a, b = Devui.Text({ Text = "a" }), Devui.Text({ Text = "b" })
	local row = Devui.SameLine({ Children = Kids(a, b) })
	assert(a.Parent == row and b.Parent == row)
	local layout = H.findAll(row, function(i: any)
		return i.ClassName == "UIListLayout"
	end)[1] :: any
	assert(layout.FillDirection == Enum.FillDirection.Horizontal and layout.Padding == UDim.new(0, 8))

	local explicit = Devui.SameLine({ Spacing = 3 })
	local l2 = H.findAll(explicit, function(i: any)
		return i.ClassName == "UIListLayout"
	end)[1] :: any
	assert(l2.Padding == UDim.new(0, 3))

	local c3 = Devui.Text({ Text = "c" })
	local group = Devui.Group({ Children = Kids(c3) })
	assert(c3.Parent == group and nameOf(group) == "Group")
	local gl = H.findAll(group, function(i: any)
		return i.ClassName == "UIListLayout"
	end)[1] :: any
	assert(gl.FillDirection == Enum.FillDirection.Vertical and gl.Padding == UDim.new(0, 4))

	local e = Devui.Text({ Text = "e" })
	local indent = Devui.Indent({ Children = Kids(e) })
	local ip = H.findAll(indent, function(i: any)
		return i.ClassName == "UIPadding"
	end)[1] :: any
	assert(ip.PaddingLeft == UDim.new(0, 21))
	local sty = Style.new()
	local ind2 = Devui.Indent({ Style = sty })
	local ip2 = H.findAll(ind2, function(i: any)
		return i.ClassName == "UIPadding"
	end)[1] :: any
	sty:SetDensity("Clear")
	assert(ip2.PaddingLeft == UDim.new(0, 25), "indent follows density")

	local sep = Devui.Separator({})
	assert(sep.Size == UDim2.new(1, 0, 0, 1) and sep.BackgroundColor3 == Color3.fromRGB(110, 110, 128))
	local st = Devui.SeparatorText({ Text = "Section" })
	local order = {}
	for _, ch in st:GetChildren() do
		local c: any = ch
		if c.ClassName == "TextLabel" or c.ClassName == "Frame" then
			order[c.LayoutOrder] = c.Name
		end
	end
	assert(order[1] == "Left" and order[2] == "Text" and order[3] == "Right", "rule - text - rule")

	-- Slot children can be added later
	local dyn = q.Slot({} :: { Instance })
	local g2 = Devui.Group({ Children = dyn })
	local late = Devui.Text({ Text = "late" })
	dyn:Add(late)
	assert(late.Parent == g2)

	for _, i in { row, explicit, group, indent, ind2, sep, st, g2 } do
		q.dispose(i)
	end
	H.assertNoDebugOutput("layout")
end)

H.section("Button Disabled: no OnClick, resting colours under hover, dim text; LabelText Modifier targets the row Frame", function()
	local clicks = 0
	local off = q.Source(true)
	local b = Devui.Button({ Text = "x", Disabled = off, OnClick = function()
		clicks += 1
	end })
	local rest = b.BackgroundTransparency
	H.fire(b, "MouseEnter", 1, 1)
	assert(b.BackgroundTransparency == rest, "hover look suppressed")
	H.fire(b, "Activated", H.input({}), 1)
	assert(clicks == 0)
	assert(b.TextColor3 == Style.default.Color.TextDisabled:Get())
	off:Set(false)
	assert(b.BackgroundTransparency ~= rest, "enabled again: the live hover look shows")
	H.fire(b, "Activated", H.input({}), 1)
	assert(clicks == 1)
	q.dispose(b)

	local l = Devui.LabelText({ Label = "k", Text = "v", Modifier = q.Declaration.Modifier.Frame():Visible(false) })
	assert((l :: any).Visible == false and (l :: any).Name == "LabelText", "the Modifier lands on the row Frame")
	q.dispose(l)
	H.assertNoDebugOutput("button disabled")
end)


H.done()
