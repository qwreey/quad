--!strict
-- Window: title, collapse, close, resize. Title / Open / Collapsed are control-panel Sources the window binds directly;
-- dragging the grip or title bar shows up in the readouts below (Size / Position are Sources the window writes).
local Devui = require("../src")
local q = require("../src/Quad")
local StoryKit = require("./StoryKit")
local Shared = require("./Shared")
local Frame = q.Elem "Frame"
local Kids = Devui.Kids

return StoryKit.story({
	controls = {
		Title = "My window",
		Open = true,
		Collapsed = false,
	},
	render = function(c)
		local size = q.Source(Vector2.new(320, 220))
		local position = q.Source(UDim2.fromOffset(20, 20))
		local window = Devui.Window({
			Title = c.Title,
			Open = c.Open,
			Collapsed = c.Collapsed,
			Size = size,
			Position = position,
			Children = Kids(
				Devui.Text({ Text = "Drag the title bar, the corner grip, collapse or close me." }),
				Devui.Separator({}),
				Shared.show("Open", c.Open),
				Shared.show("Collapsed", c.Collapsed),
				Shared.show("Size", size),
				Shared.show("Position", position)
			),
		})
		return Frame({
			Name = "WindowStory",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			window,
			Frame({
				Name = "Reopen",
				Position = UDim2.new(0, 20, 1, -40),
				Size = UDim2.fromOffset(160, 24),
				BackgroundTransparency = 1,
				Devui.Button({
					Text = "reopen the window",
					OnClick = function()
						c.Open:Set(true)
					end,
				}),
			}),
		})
	end,
})
