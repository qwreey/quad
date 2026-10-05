--!strict
-- Checkbox / RadioButton / Selectable / SelectableOption — all write back to Sources shown live underneath.
local Devui = require("../src")
local q = require("../src/Quad")
local StoryKit = require("./StoryKit")
local Shared = require("./Shared")
local Kids = Devui.Kids

return StoryKit.story({
	controls = {
		Text = "option",
		Disabled = false,
	},
	render = function(c)
		local checked = q.Source(true)
		local flavor = q.Source("vanilla")
		local picked = q.Source(false)
		local size = q.Source("M")
		return Devui.Window({
			Title = "Checkbox / Radio / Selectable",
			Size = q.Source(Vector2.new(320, 380)),
			Children = Kids(
				Devui.SeparatorText({ Text = "Checkbox" }),
				Devui.Checkbox({ Text = c.Text, Value = checked, Disabled = c.Disabled }),
				Devui.Checkbox({ Text = "always disabled", Disabled = true }),
				Shared.show("checked", checked),
				Devui.SeparatorText({ Text = "RadioButton" }),
				Devui.RadioButton<<string>>({ Text = "vanilla", Value = flavor, Option = "vanilla", Disabled = c.Disabled }),
				Devui.RadioButton<<string>>({ Text = "chocolate", Value = flavor, Option = "chocolate", Disabled = c.Disabled }),
				Devui.RadioButton<<string>>({ Text = "mint", Value = flavor, Option = "mint", Disabled = c.Disabled }),
				Shared.show("flavor", flavor),
				Devui.SeparatorText({ Text = "Selectable" }),
				Devui.Selectable({ Text = c.Text, Selected = picked, Disabled = c.Disabled }),
				Shared.show("selected", picked),
				Devui.SeparatorText({ Text = "SelectableOption" }),
				Devui.SelectableOption<<string>>({ Text = "S", Value = size, Option = "S", Disabled = c.Disabled }),
				Devui.SelectableOption<<string>>({ Text = "M", Value = size, Option = "M", Disabled = c.Disabled }),
				Devui.SelectableOption<<string>>({ Text = "L", Value = size, Option = "L", Disabled = c.Disabled }),
				Shared.show("size", size)
			),
		})
	end,
})
