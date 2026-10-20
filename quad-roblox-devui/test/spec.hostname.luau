--!strict
-- Host Name rule (src/init.luau "HOW TO WRITE A DEVUI WIDGET"): a host's default Name sits in the kit's base Modifier, so a
-- caller's `Modifier = q.Modifier "Class" ():Name("X")` renames it; without one the default name is unchanged.
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Frame = q.Elem "Frame"
local Layout = require("../src/Layout")
local Text = require("../src/Text")
local Button = require("../src/Button")
local Checkbox = require("../src/Checkbox")
local RadioButton = require("../src/RadioButton")
local Inputs = require("../src/Inputs")
local Tree = require("../src/Tree")
local TabModule = require("../src/Tab")
local Table = require("../src/Table").Table
local Selectable = require("../src/Selectable")
local Progress = require("../src/Progress")
local Plot = require("../src/Plot")
local Combo = require("../src/Combo")
local Menu = require("../src/Menu")
local Overlay = require("../src/Overlay")
local Window = require("../src/Window")

H.section("every host: its default Name is unchanged, and the caller's Modifier :Name(...) overrides it", function()
	local checked = 0
	-- `locate` finds the instance that receives the Modifier (the root unless a field/track modifier is probed)
	local function probe(label: string, default: string, build: (m: any) -> any, locate: ((root: any, name: string) -> any)?)
		local function target(root: any, name: string): any
			if locate then
				return locate(root, name)
			end
			return root
		end
		local plain = build(nil)
		local t = target(plain, default)
		assert(t.Name == default, label .. ": default Name " .. tostring(t.Name) .. " ~= " .. default)
		local class = t.ClassName
		q.dispose(plain)
		local custom = "Custom_" .. label
		local mod = ((q.Modifier :: any)(class) :: any)():Name(custom)
		local host = build(mod)
		local renamed = target(host, custom)
		assert(renamed ~= nil and renamed.Name == custom, label .. ": Modifier Name did not win")
		checked += 1
		q.dispose(host)
	end
	local overlay = Overlay.new()
	local kids = function()
		return q.Slot({ Frame {} })
	end
	probe("SameLine", "SameLine", function(m) return Layout.SameLine({ Modifier = m }) end)
	probe("Group", "Group", function(m) return Layout.Group({ Modifier = m }) end)
	probe("Indent", "Indent", function(m) return Layout.Indent({ Modifier = m }) end)
	probe("Separator", "Separator", function(m) return Layout.Separator({ Modifier = m }) end)
	probe("SeparatorText", "SeparatorText", function(m) return Layout.SeparatorText({ Text = "x", Modifier = m }) end)
	probe("Text", "Text", function(m) return Text.Text({ Text = "x", Modifier = m }) end)
	probe("TextWrapped", "Text", function(m) return Text.TextWrapped({ Text = "x", Modifier = m }) end)
	probe("TextColored", "Text", function(m) return Text.TextColored({ Text = "x", Color = Color3.new(1, 0, 0), Modifier = m }) end)
	probe("TextDisabled", "Text", function(m) return Text.TextDisabled({ Text = "x", Modifier = m }) end)
	probe("LabelText", "LabelText", function(m) return Text.LabelText({ Label = "a", Text = "b", Modifier = m }) end)
	probe("Button", "Button", function(m) return Button.Button({ Text = "x", Modifier = m }) end)
	probe("SmallButton", "SmallButton", function(m) return Button.SmallButton({ Text = "x", Modifier = m }) end)
	probe("Checkbox", "Checkbox", function(m) return Checkbox({ Text = "x", Modifier = m }) end)
	probe("RadioButton", "RadioButton", function(m)
		return RadioButton<<string>>({ Text = "x", Value = q.Source("a"), Option = "a", Modifier = m })
	end)
	probe("Selectable", "Selectable", function(m) return Selectable.Selectable({ Text = "x", Modifier = m }) end)
	probe("SelectableOption", "Selectable", function(m)
		return Selectable.SelectableOption<<string>>({ Text = "x", Value = q.Source("a"), Option = "a", Modifier = m })
	end)
	probe("Tree", "Tree", function(m) return Tree.Tree({ Text = "x", Modifier = m }) end)
	probe("CollapsingHeader", "CollapsingHeader", function(m) return Tree.CollapsingHeader({ Text = "x", Modifier = m }) end)
	probe("TabBar", "TabBar", function(m)
		return TabModule.TabBar<<string>>({ Tabs = { TabModule.Tab<<string>>({ Key = "a", Text = "A" }) }, Modifier = m })
	end)
	probe("Table", "Table", function(m)
		return Table({
			Columns = { { Title = "N", Width = 80 } },
			Rows = ({ { Id = "a" } } :: any),
			Key = function(r: any): any return r.Id end,
			Cell = function(_r: any, _c: number) return Frame {} end,
			Modifier = m,
		})
	end)
	probe("ProgressBar", "ProgressBar", function(m) return Progress.ProgressBar({ Value = 0.5, Modifier = m }) end)
	probe("PlotHistogram", "PlotHistogram", function(m) return Plot.PlotHistogram({ Values = q.Source({ 1, 2 }), Modifier = m }) end)
	probe("PlotLines", "PlotLines", function(m) return Plot.PlotLines({ Values = q.Source({ 1, 2 }), Modifier = m }) end)
	probe("Combo", "Combo", function(m)
		return Combo.Combo<<string>>({ Text = "t", Value = q.Source("a"), Options = { "a", "b" }, Overlay = overlay, Modifier = m })
	end)
	probe("ComboArray", "Combo", function(m)
		return Combo.ComboArray<<string>>({ Text = "t", Index = q.Source(1), Options = { "a", "b" }, Overlay = overlay, Modifier = m })
	end)
	probe("ComboEnum", "Combo", function(m)
		return Combo.ComboEnum({ Text = "t", Value = q.Source(Enum.EasingStyle.Linear :: any) :: any, Enum = Enum.EasingStyle, Overlay = overlay, Modifier = m })
	end)
	probe("MenuBar", "MenuBar", function(m) return Menu.MenuBar({ Children = kids(), Modifier = m }) end)
	probe("Window", "Window", function(m) return Window.Window({ Title = "w", Modifier = m }) end)
	probe("InputNum", "InputNum", function(m) return Inputs.InputNum({ Value = q.Source(1), Modifier = m }) end)
	probe("DragNum", "DragNum", function(m) return Inputs.DragNum({ Value = q.Source(1), Modifier = m }) end)
	probe("SliderNum", "SliderNum", function(m) return Inputs.SliderNum({ Value = q.Source(1), Min = 0, Max = 10, Modifier = m }) end)
	probe("InputText", "InputText", function(m) return Inputs.InputText({ Value = q.Source("x"), Modifier = m }) end)
	probe("InputVector2", "InputVector2", function(m) return Inputs.InputVector2({ Modifier = m }) end)
	probe("InputUDim2", "InputUDim2", function(m) return Inputs.InputUDim2({ Modifier = m }) end)
	probe("InputColor3", "InputColor3", function(m) return Inputs.InputColor3({ Modifier = m }) end)
	-- the field / track modifiers hand the caller a second host to rename
	probe("InputNum.FieldModifier", "InputField", function(m) return Inputs.InputNum({ Value = q.Source(1), FieldModifier = m }) end, function(r, n) return H.find(r, n) end)
	probe("DragNum.FieldModifier", "DragField", function(m) return Inputs.DragNum({ Value = q.Source(1), FieldModifier = m }) end, function(r, n) return H.find(r, n) end)
	probe("InputText.FieldModifier", "Field", function(m) return Inputs.InputText({ Value = q.Source("x"), FieldModifier = m }) end, function(r, n) return H.find(r, n) end)
	probe("SliderNum.TrackModifier", "Track", function(m) return Inputs.SliderNum({ Value = q.Source(1), Min = 0, Max = 10, TrackModifier = m }) end, function(r, n) return H.find(r, n) end)
	assert(checked == 39, "probed " .. checked)
	H.assertNoDebugOutput("host names")
end)

H.done()
