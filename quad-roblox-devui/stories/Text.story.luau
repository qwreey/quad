--!strict
-- Text / TextWrapped / TextColored / TextDisabled / LabelText — every text and colour is a control Source.
local Devui = require("../src")
local q = require("../src/Quad")
local StoryKit = require("./StoryKit")
local Kids = Devui.Kids

return StoryKit.story({
	controls = {
		Text = "The quick brown fox",
		Label = "label",
		Color = Color3.fromRGB(255, 160, 60),
	},
	render = function(c)
		local long: q.State<string> = c.Text:Compute(function(self)
			return `{self:Get()} jumps over the lazy dog, and keeps going until the line has to wrap.`
		end)
		return Devui.Window({
			Title = "Text",
			Size = q.Source(Vector2.new(300, 240)),
			Children = Kids(
				Devui.Text({ Text = c.Text }),
				Devui.TextWrapped({ Text = long }),
				Devui.TextColored({ Text = c.Text, Color = c.Color }),
				Devui.TextDisabled({ Text = c.Text }),
				Devui.Text({ Text = "<b>rich</b> <i>text</i>", RichText = true }),
				Devui.LabelText({ Label = c.Label, Text = c.Text })
			),
		})
	end,
})
