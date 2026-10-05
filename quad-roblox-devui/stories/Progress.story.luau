--!strict
-- ProgressBar: the Value slider is the bar's Value State; Text overrides the default percentage label.
local Devui = require("../src")
local q = require("../src/Quad")
local StoryKit = require("./StoryKit")
local Kids = Devui.Kids

return StoryKit.story({
	controls = {
		Value = StoryKit.Slider(0.4, 0, 1, 0.01),
		Text = "Loading…",
	},
	render = function(c)
		return Devui.Window({
			Title = "ProgressBar",
			Size = q.Source(Vector2.new(300, 150)),
			Children = Kids(
				Devui.ProgressBar({ Value = c.Value }),
				Devui.ProgressBar({ Value = c.Value, Text = c.Text }),
				Devui.ProgressBar({ Value = 1, Text = "done" })
			),
		})
	end,
})
