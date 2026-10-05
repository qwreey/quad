--!strict
-- Button / SmallButton. Text and Disabled are control Sources the widgets bind directly; the click count is a Source too.
local Devui = require("../src")
local q = require("../src/Quad")
local StoryKit = require("./StoryKit")
local Shared = require("./Shared")
local Kids = Devui.Kids

return StoryKit.story({
	controls = {
		Text = "Click me",
		Disabled = false,
	},
	render = function(c)
		local clicks = q.Source(0)
		local function bump()
			clicks:Set(clicks:Get() + 1)
		end
		return Devui.Window({
			Title = "Button",
			Size = q.Source(Vector2.new(280, 200)),
			Children = Kids(
				Devui.Button({ Text = c.Text, Disabled = c.Disabled, OnClick = bump }),
				Devui.SmallButton({ Text = c.Text, Disabled = c.Disabled, OnClick = bump }),
				Devui.Button({ Text = "wide (Size)", Size = UDim2.new(1, 0, 0, 30), OnClick = bump }),
				Devui.Button({ Text = "always disabled", Disabled = true, OnClick = bump }),
				Shared.show("clicks", clicks)
			),
		})
	end,
})
