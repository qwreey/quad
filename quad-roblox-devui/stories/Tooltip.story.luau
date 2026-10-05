--!strict
-- Tooltip: a hook attached to the element it hints. Text is a live control Source; Delay is a construction value, so
-- the buttons are rebuilt when its slider moves. One tooltip uses a Content factory instead of Text.
local Devui = require("../src")
local q = require("../src/Quad")
local StoryKit = require("./StoryKit")
local Shared = require("./Shared")
local Kids = Devui.Kids

return StoryKit.story({
	controls = {
		Text = "Saves the file",
		Delay = StoryKit.Slider(0.3, 0, 2, 0.1),
	},
	render = function(c, ctx)
		local rebuilt = StoryKit.rebuild(c.Delay, function(delay: any)
			local tip = Devui.Tooltip({ Text = c.Text, Delay = delay, Overlay = ctx.Overlay })
			local rich = Devui.Tooltip({
				Delay = delay,
				Overlay = ctx.Overlay,
				Content = function()
					return Devui.SameLine({
						Children = Kids(
							Devui.TextColored({ Text = "custom", Color = Color3.fromRGB(255, 160, 60) }),
							Devui.Text({ Text = "content" })
						),
					})
				end,
			})
			return Devui.Group({
				Children = Kids(
					Devui.SameLine({
						Children = Kids(
							Devui.Button({ Text = "Hover me", Hooks = { tip.Hook } }),
							Devui.Button({ Text = "Content factory", Hooks = { rich.Hook } })
						),
					}),
					Shared.show("text tooltip visible", tip.Visible),
					Shared.show("content tooltip visible", rich.Visible)
				),
			})
		end)
		return Devui.Window({
			Title = "Tooltip",
			Size = q.Source(Vector2.new(360, 160)),
			Children = Kids(rebuilt, Devui.TextDisabled({ Text = "Hover a button and wait for the delay." })),
		})
	end,
})
