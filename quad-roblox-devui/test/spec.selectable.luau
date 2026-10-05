--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local SelectableModule = require("../src/Selectable")
local Selectable, SelectableOption = SelectableModule.Selectable, SelectableModule.SelectableOption
local Style = require("../src/Style")
local style = Style.default

H.section("Selectable: toggle mode round trip + OnClick order", function()
	local sel = q.Source(false)
	local log: { string } = {}
	local row = Selectable({
		Text = "Row",
		Selected = sel,
		OnClick = function()
			table.insert(log, `click {tostring(sel:Get())}`)
		end,
	}) :: any
	assert(row.Name == "Selectable" and row.Text == "Row" and row.BackgroundTransparency == 1)
	assert(row.Size == UDim2.new(1, 0, 0, 0) and row.AutomaticSize == Enum.AutomaticSize.Y)
	H.fire(row, "Activated", H.input({}), 1)
	assert(sel:Get() == true and log[1] == "click true", "Source updated before OnClick")
	assert(row.BackgroundTransparency == style.Transparency.Header:Get(), "selected = Header look")
	sel:Set(false)
	assert(row.BackgroundTransparency == 1)
	H.fire(row, "MouseEnter", 1, 1)
	assert(row.BackgroundTransparency == style.Transparency.HeaderHovered:Get() and row.BackgroundColor3 == style.Color.HeaderHovered:Get())
	H.fire(row, "InputBegan", H.input({}))
	assert(row.BackgroundTransparency == style.Transparency.HeaderActive:Get())
	H.fire(row, "MouseLeave")
	assert(row.BackgroundTransparency == 1)
	q.dispose(row)
	H.assertNoDebugOutput("selectable toggle")
end)

H.section("Selectable: uncontrolled keeps its own boolean", function()
	local row = Selectable({ Text = "x" }) :: any
	H.fire(row, "Activated", H.input({}), 1)
	assert(row.BackgroundTransparency == style.Transparency.Header:Get())
	H.fire(row, "Activated", H.input({}), 1)
	assert(row.BackgroundTransparency == 1)
	q.dispose(row)
end)

H.section("Selectable: group mode shares one Value Source", function()
	local option = q.Source("b")
	local a = SelectableOption<<string>>({ Text = "A", Value = option, Option = "a" }) :: any
	local b = SelectableOption<<string>>({ Text = "B", Value = option, Option = "b" }) :: any
	assert(a.BackgroundTransparency == 1 and b.BackgroundTransparency ~= 1)
	H.fire(a, "Activated", H.input({}), 1)
	assert(option:Get() == "a" and a.BackgroundTransparency ~= 1 and b.BackgroundTransparency == 1)
	H.fire(a, "Activated", H.input({}), 1)
	assert(option:Get() == "a", "clicking the selected row keeps it selected")
	option:Set("b")
	assert(a.BackgroundTransparency == 1 and b.BackgroundTransparency ~= 1, "external write moves the highlight")
	q.dispose(a)
	q.dispose(b)
	H.assertNoDebugOutput("selectable group")
end)

H.section("Disabled: no click, no hover look, dimmed text; SelectableOption roles match RadioButton (Value = Source, Option = T)", function()
	local flag = q.Source(false)
	local clicks = 0
	local off = q.Source(true)
	local row = Selectable({ Text = "R", Selected = flag, Disabled = off, OnClick = function()
		clicks += 1
	end }) :: any
	H.fire(row, "MouseEnter", 0, 0)
	assert(row.BackgroundTransparency == 1, "disabled: hover shows nothing")
	H.fire(row, "Activated", H.input({}), 1)
	assert(flag:Get() == false and clicks == 0)
	assert(row.TextTransparency == style.Transparency.TextDisabled:Get() and row.TextColor3 == style.Color.TextDisabled:Get())
	off:Set(false)
	H.fire(row, "Activated", H.input({}), 1)
	assert(flag:Get() == true and clicks == 1 and row.BackgroundTransparency ~= 1)
	q.dispose(row)

	local pick = q.Source("a")
	local b = SelectableOption<<string>>({ Text = "B", Value = pick, Option = "b", Disabled = true }) :: any
	H.fire(b, "Activated", H.input({}), 1)
	assert(pick:Get() == "a", "a disabled option does not select")
	q.dispose(b)
	H.assertNoDebugOutput("selectable disabled")
end)


H.done()
