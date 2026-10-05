--!strict
-- Combo / ComboArray / ComboEnum. Popup lists open in the story's overlay (`ctx.Overlay`). Disabled is a control Source.
local Devui = require("../src")
local q = require("../src/Quad")
local StoryKit = require("./StoryKit")
local Shared = require("./Shared")
local Kids = Devui.Kids

local FRUIT = { "apple", "banana", "cherry", "date", "elderberry", "fig", "grape" }

return StoryKit.story({
	controls = {
		Text = "fruit",
		Disabled = false,
	},
	render = function(c, ctx)
		local fruit = q.Source("banana")
		local index = q.Source(2)
		local align = q.Source(Enum.TextXAlignment.Left :: EnumItem)
		return Devui.Window({
			Title = "Combo",
			Size = q.Source(Vector2.new(340, 280)),
			Children = Kids(
				Devui.Combo<<string>>({
					Text = c.Text,
					Value = fruit,
					Options = FRUIT,
					Disabled = c.Disabled,
					Overlay = ctx.Overlay,
					MaxHeight = 120,
				}),
				Shared.show("fruit", fruit),
				Devui.ComboArray<<string>>({
					Text = "by index",
					Index = index,
					Options = FRUIT,
					Format = function(s: string)
						return string.upper(s)
					end,
					Disabled = c.Disabled,
					Overlay = ctx.Overlay,
				}),
				Shared.show("index", index),
				Devui.ComboEnum({
					Text = "TextXAlignment",
					Value = align,
					Enum = Enum.TextXAlignment,
					Disabled = c.Disabled,
					Overlay = ctx.Overlay,
				}),
				Shared.show("enum", align)
			),
		})
	end,
})
