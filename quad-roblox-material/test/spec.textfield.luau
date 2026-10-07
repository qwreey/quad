--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local TextField = require("../src/TextField")
local Tokens = require("../src/Tokens")

local L = Tokens.Color.Light

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

local function class(inst: any, name: string): { any }
	return H.findAll(inst, function(c: any)
		return c.ClassName == name
	end)
end

local function typeInto(box: any, text: string)
	box.Text = text
end

H.section("Filled at rest: structure, label at rest, instance count", function()
	local v = q.Source("")
	local tf = TextField({ Label = "Name", Value = v })
	assert(tf.ClassName == "Frame" and tf.Name == "TextField")
	local count = H.countDescendants(tf)
	print("Filled+label descendants: " .. count .. " (+1 host = " .. (count + 1) .. ")")
	H.resetOutput()
	assert(count == 13, "Filled+label descendants: " .. count .. " (Fill + its UICorner replace the container UICorner)")
	local container = H.find(tf, "Container")
	assert(container.Size == UDim2.new(1, 0, 0, 56))
	assert(container.BackgroundTransparency == 1 and container.ClipsDescendants == true, "the container clips; the fill draws")
	local fill = H.find(tf, "Fill")
	assert(fill.BackgroundColor3 == L.SurfaceContainerHighest and fill.Size == UDim2.new(1, 0, 0, 60), "fill is 4 px taller: only the top corners show")
	assert(H.find(fill, "StateLayer") ~= nil, "layer inside the fill")
	for _, c in container:GetChildren() do
		assert(c.ClassName ~= "UICorner", "no corner on the container itself")
	end
	local label = H.find(tf, "Label")
	assert(label.Text == "Name" and label.TextSize == 16 and label.LineHeight == 1 and label.Position == UDim2.fromOffset(16, 20), "resting label: its 16 px box centered on the 56 px container")
	assert(H.find(tf, "Indicator").Size == UDim2.new(1, 0, 0, 1) and H.find(tf, "Indicator").BackgroundColor3 == L.OnSurfaceVariant)
	assert(H.find(tf, "Supporting") == nil, "no supporting row without text")
	local box = H.find(tf, "Input")
	assert(box.ClassName == "TextBox" and box.ClearTextOnFocus == false and box.TextSize == 16)
	assert(box.PlaceholderText == "")
	assert(#class(tf, "UIFlexItem") == 1)
	q.dispose(tf)
	H.assertNoDebugOutput("rest")
end)

H.section("typing round trip + label float + focus indicator", function()
	local v = q.Source("")
	local tf = TextField({ Label = "Name", Value = v, Placeholder = "Ada" })
	local box = H.find(tf, "Input")
	local label = H.find(tf, "Label")
	local ind = H.find(tf, "Indicator")
	-- focus: label floats, indicator thickens, primary
	H.fire(box, "Focused")
	H.finishTweens()
	assert(label.TextSize == 12 and label.Position == UDim2.fromOffset(16, 7), "floated on focus")
	assert(ind.Size == UDim2.new(1, 0, 0, 2) and ind.BackgroundColor3 == L.Primary)
	assert(label.TextColor3 == L.Primary)
	assert(box.PlaceholderText == "Ada")
	-- typing writes the source
	typeInto(box, "abc")
	assert(v:Get() == "abc")
	-- blur with text: label stays floated
	H.fire(box, "FocusLost", false, H.input({}))
	H.finishTweens()
	assert(label.TextSize == 12 and ind.Size == UDim2.new(1, 0, 0, 1), "stays floated while non-empty")
	assert(label.TextColor3 == L.OnSurfaceVariant)
	-- source -> UI
	v:Set("")
	H.finishTweens()
	assert(box.Text == "" and label.TextSize == 16, "empty + unfocused: label drops back")
	v:Set("hello")
	H.finishTweens()
	assert(box.Text == "hello" and label.TextSize == 12)
	q.dispose(tf)
	H.assertNoDebugOutput("typing")
end)

H.section("OnSubmit on Enter, OnFocusChanged", function()
	local v = q.Source("")
	local submitted: { string } = {}
	local changes: { boolean } = {}
	local tf = TextField({
		Value = v,
		OnSubmit = function(t: string)
			table.insert(submitted, t)
		end,
		OnFocusChanged = function(f: boolean)
			table.insert(changes, f)
		end,
	})
	local box = H.find(tf, "Input")
	H.fire(box, "Focused")
	typeInto(box, "go")
	H.fire(box, "FocusLost", true, H.input({}))
	assert(#submitted == 1 and submitted[1] == "go")
	H.fire(box, "Focused")
	H.fire(box, "FocusLost", false, H.input({}))
	assert(#submitted == 1, "no submit without enter")
	assert(#changes == 4 and changes[1] == true and changes[2] == false)
	q.dispose(tf)
	H.assertNoDebugOutput("submit")
end)

H.section("error state: colors + error text swaps supporting text", function()
	local err = q.Source(false)
	local tf = TextField({ Label = "Mail", SupportingText = "Required", Error = err, ErrorText = "Invalid address" })
	local sup = H.find(tf, "Supporting")
	assert(sup.Text == "Required" and sup.TextColor3 == L.OnSurfaceVariant)
	err:Set(true)
	H.finishTweens()
	assert(sup.Text == "Invalid address" and sup.TextColor3 == L.Error)
	assert(H.find(tf, "Indicator").BackgroundColor3 == L.Error and H.find(tf, "Label").TextColor3 == L.Error)
	err:Set(false)
	H.finishTweens()
	assert(sup.Text == "Required" and H.find(tf, "Indicator").BackgroundColor3 == L.OnSurfaceVariant)
	q.dispose(tf)
	H.assertNoDebugOutput("error")
end)

H.section("MaxLength clips typing (also when the source already sits at the limit) + counter", function()
	local v = q.Source("")
	local tf = TextField({ Label = "Code", Value = v, MaxLength = 5 })
	local box = H.find(tf, "Input")
	local counter = H.find(tf, "Counter")
	assert(counter.Text == "0/5")
	typeInto(box, "abc")
	assert(v:Get() == "abc" and counter.Text == "3/5")
	typeInto(box, "abcdefg")
	assert(v:Get() == "abcde" and box.Text == "abcde", "clipped, TextBox rewritten: " .. box.Text)
	assert(counter.Text == "5/5")
	typeInto(box, "abcdeX") -- source already at the limit: clipped string == source
	assert(v:Get() == "abcde" and box.Text == "abcde", "TextBox still rewritten at the limit: " .. box.Text)
	-- multibyte: 4 characters, 12 bytes
	typeInto(box, "가나다라")
	assert(v:Get() == "가나다라" and counter.Text == "4/5")
	typeInto(box, "가나다라마바")
	assert(v:Get() == "가나다라마" and box.Text == "가나다라마")
	q.dispose(tf)
	H.assertNoDebugOutput("maxlength")
end)

H.section("Outlined: stroke, notch label, thickness", function()
	local v = q.Source("")
	local tf = TextField({ Variant = "Outlined", Label = "Email", Value = v })
	assert(H.countDescendants(tf) == 11, "Outlined+label descendants: " .. H.countDescendants(tf))
	local stroke = H.find(tf, "Outline")
	local label = H.find(tf, "Label")
	local container = H.find(tf, "Container")
	assert(container.BackgroundTransparency == 1 and H.find(tf, "Indicator") == nil)
	assert(stroke.Thickness == 1 and stroke.Color == L.Outline)
	assert(label.BackgroundTransparency == 1 and label.Position == UDim2.fromOffset(12, 20))
	local box = H.find(tf, "Input")
	H.fire(box, "Focused")
	H.finishTweens()
	assert(stroke.Thickness == 2 and stroke.Color == L.Primary)
	assert(label.BackgroundTransparency == 0 and label.BackgroundColor3 == L.Surface and label.Position == UDim2.fromOffset(12, -9), "notch")
	assert(label.TextSize == 12)
	q.dispose(tf)
	H.assertNoDebugOutput("outlined")
end)

H.section("hover state layer (filled) and outline (outlined)", function()
	local tf = TextField({ Label = "A" })
	local container = H.find(tf, "Container")
	local layer = H.find(tf, "StateLayer")
	assert(layer.BackgroundTransparency == 1)
	H.fire(container, "MouseEnter")
	H.finishTweens()
	assert(near(layer.BackgroundTransparency, 0.92))
	assert(H.find(tf, "Indicator").BackgroundColor3 == L.OnSurface)
	q.dispose(tf)
	local o = TextField({ Variant = "Outlined", Label = "A" })
	H.fire(H.find(o, "Container"), "MouseEnter")
	H.finishTweens()
	assert(H.find(o, "Outline").Color == L.OnSurface)
	q.dispose(o)
	H.assertNoDebugOutput("hover")
end)

H.section("disabled: not editable/interactable, disabled opacities", function()
	local dis = q.Source(true)
	local tf = TextField({ Label = "D", Disabled = dis, Value = q.Source("x") })
	local box = H.find(tf, "Input")
	H.finishTweens()
	assert(box.TextEditable == false and box.Interactable == false)
	assert(near(box.TextTransparency, 0.62) and H.find(tf, "Label").TextColor3 == L.OnSurface)
	assert(H.find(tf, "Fill").BackgroundColor3 == L.OnSurface and near(H.find(tf, "Fill").BackgroundTransparency, 0.96))
	H.fire(H.find(tf, "Container"), "MouseEnter")
	H.finishTweens()
	assert(H.find(tf, "StateLayer").BackgroundTransparency == 1, "no hover layer while disabled")
	dis:Set(false)
	H.finishTweens()
	assert(box.TextEditable == true and box.Interactable == true and box.TextTransparency == 0)
	q.dispose(tf)
	H.assertNoDebugOutput("disabled")
end)

H.section("icons, prefix/suffix, multi-line", function()
	local tf = TextField({
		Label = "Amount",
		LeadingIcon = "rbxassetid://1",
		TrailingIcon = "rbxassetid://2",
		Prefix = "$",
		Suffix = "USD",
		Value = q.Source(""),
	})
	assert(H.find(tf, "LeadingIcon").Image == "rbxassetid://1" and H.find(tf, "TrailingIcon").Image == "rbxassetid://2")
	local pad = class(H.find(tf, "Row"), "UIPadding")[1]
	assert(pad.PaddingLeft == UDim.new(0, 52) and pad.PaddingRight == UDim.new(0, 52))
	assert(H.find(tf, "Label").Position == UDim2.fromOffset(52, 20))
	assert(H.find(tf, "Prefix").Visible == false and H.find(tf, "Suffix").Visible == false, "affixes hidden until floated")
	H.fire(H.find(tf, "Input"), "Focused")
	assert(H.find(tf, "Prefix").Visible == true and H.find(tf, "Prefix").Text == "$" and H.find(tf, "Suffix").Text == "USD")
	q.dispose(tf)
	local m = TextField({ Label = "Notes", MultiLine = true })
	local box = H.find(m, "Input")
	assert(box.MultiLine == true and box.TextWrapped == true and H.find(m, "Container").Size == UDim2.new(1, 0, 0, 120))
	assert(H.find(m, "Label").Position == UDim2.fromOffset(16, 16), "multi-line: the resting label sits on the first line")
	q.dispose(m)
	local tall = TextField({ Label = "Tall", Height = 80 })
	assert(H.find(tall, "Label").Position == UDim2.fromOffset(16, 32), "custom single-line height: centered (80 / 2 - 8)")
	q.dispose(tall)
	H.assertNoDebugOutput("extras")
end)

H.section("OnClick: press+release on the container (not after leaving)", function()
	local clicks = 0
	local tf = TextField({
		Text = q.Source("fixed"),
		OnClick = function()
			clicks += 1
		end,
	})
	local c = H.find(tf, "Container")
	assert(H.find(tf, "Input").Interactable == false and c.Selectable == true)
	H.fire(c, "InputBegan", H.input({}))
	H.fire(c, "InputEnded", H.input({}))
	assert(clicks == 1)
	H.fire(c, "InputBegan", H.input({}))
	H.fire(c, "MouseLeave")
	H.fire(c, "InputEnded", H.input({}))
	assert(clicks == 1, "cancelled press does not click")
	assert(H.find(tf, "Input").Text == "fixed")
	q.dispose(tf)
	H.assertNoDebugOutput("click")
end)

H.section("a click anywhere on the container focuses the editable TextBox (Filled and Outlined)", function()
	for _, variant in { "Filled", "Outlined" } do
		local focusChanges: { boolean } = {}
		local tf = TextField({
			Variant = variant :: any,
			Label = "Name",
			OnFocusChanged = function(f: boolean)
				table.insert(focusChanges, f)
			end,
		})
		local c = H.find(tf, "Container")
		local box = H.find(tf, "Input")
		H.fire(c, "InputBegan", H.input({}))
		H.fire(c, "InputEnded", H.input({}))
		assert(box:IsFocused() and #focusChanges == 1 and focusChanges[1] == true, variant .. ": container click focused the box")
		-- already focused (the click landed on the TextBox itself): no second capture
		H.fire(c, "InputBegan", H.input({}))
		H.fire(c, "InputEnded", H.input({}))
		assert(#focusChanges == 1, variant .. ": no refocus while focused")
		box:ReleaseFocus()
		-- a cancelled press (pointer left) does not focus
		H.fire(c, "InputBegan", H.input({}))
		H.fire(c, "MouseLeave")
		H.fire(c, "InputEnded", H.input({}))
		assert(not box:IsFocused(), variant .. ": cancelled press")
		q.dispose(tf)
	end
	-- disabled: never focused by a container click
	local tf = TextField({ Label = "D", Disabled = true })
	local c = H.find(tf, "Container")
	H.fire(c, "InputBegan", H.input({}))
	H.fire(c, "InputEnded", H.input({}))
	assert(not H.find(tf, "Input"):IsFocused(), "disabled field stays unfocused")
	q.dispose(tf)
	H.assertNoDebugOutput("container focus")
end)

H.section("dispose destroys everything, connections baseline, Modifier applies", function()
	local u = H.UserInputService :: any
	local base = #u.InputChanged.connections + #u.InputEnded.connections + #u.WindowFocusReleased.connections
	local tf = TextField({
		Label = "M",
		Value = q.Source("v"),
		Modifier = require("../src/Quad").Declaration.Modifier.Frame():Size(UDim2.new(1, 0, 0, 0)),
	})
	assert(tf.Size == UDim2.new(1, 0, 0, 0), "caller Size wins")
	local inner = H.findAll(tf, function()
		return true
	end)
	q.dispose(tf)
	assert(H.isDestroyed(tf))
	for _, i in inner do
		assert(H.isDestroyed(i))
	end
	assert(#u.InputChanged.connections + #u.InputEnded.connections + #u.WindowFocusReleased.connections == base)
	H.assertNoDebugOutput("dispose")
end)

H.section("D12 error is not color alone: a bold ! mark shows in the trailing slot while Error is on", function()
	local err = q.Source(false)
	local tf = TextField({ Label = "Email", Value = q.Source("x"), Error = err, ErrorText = "bad" })
	local mark = H.find(tf, "ErrorMark")
	assert(mark ~= nil and mark.Text == "!" and mark.Visible == false, "hidden while fine")
	local pad = class(H.find(tf, "Row"), "UIPadding")[1]
	assert(pad.PaddingRight == UDim.new(0, 16))
	err:Set(true)
	H.finishTweens()
	assert(mark.Visible == true and pad.PaddingRight == UDim.new(0, 52), "mark shown, row makes room")
	assert(mark.TextColor3 == L.Error)
	local plain = TextField({ Label = "No error prop", Value = q.Source("") })
	assert(H.find(plain, "ErrorMark") == nil, "fields that cannot error pay nothing")
	local withTrailing = TextField({ Label = "T", Value = q.Source(""), Error = err, TrailingIcon = "rbxassetid://5" })
	assert(H.find(withTrailing, "TrailingIcon").Visible == false and H.find(withTrailing, "ErrorMark").Visible == true, "the mark replaces the trailing icon")
	err:Set(false)
	assert(H.find(withTrailing, "TrailingIcon").Visible == true and H.find(withTrailing, "ErrorMark").Visible == false)
	q.dispose(tf)
	q.dispose(plain)
	q.dispose(withTrailing)
	H.assertNoDebugOutput("error mark")
end)

H.section("D10 gamepad selection of the editable TextBox draws the focused look; the engine selection box is hidden", function()
	local tf = TextField({ Label = "Name", Value = q.Source("") })
	local box = H.find(tf, "Input")
	assert(box.SelectionImageObject ~= nil and H.find(tf, "Container").SelectionImageObject ~= nil)
	H.fire(box, "SelectionGained")
	H.finishTweens()
	assert(H.find(tf, "Indicator").BackgroundColor3 == L.Primary and H.find(tf, "Label").TextSize == 12, "focused look")
	H.fire(box, "SelectionLost")
	H.finishTweens()
	assert(H.find(tf, "Label").TextSize == 16)
	q.dispose(tf)
	H.assertNoDebugOutput("textbox selection")
end)

H.done()
