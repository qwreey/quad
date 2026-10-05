--!strict
-- Inputs. InputNum / DragNum / SliderNum share ONE Source — the control panel's Number slider — so the control panel and
-- the three widgets edit the same value. Text and colour likewise. Vector2 / UDim2 use story-local Sources.
local Devui = require("../src")
local q = require("../src/Quad")
local StoryKit = require("./StoryKit")
local Shared = require("./Shared")
local Kids = Devui.Kids

return StoryKit.story({
	controls = {
		Number = StoryKit.Slider(42, 0, 100, 1),
		Text = "hello",
		Color = Color3.fromRGB(66, 150, 250),
		Disabled = false,
	},
	render = function(c)
		local vec = q.Source(Vector2.new(3, 4))
		local udim = q.Source(UDim2.new(0.5, 10, 0, 100))
		local submitted = q.Source("")
		return Devui.Window({
			Title = "Inputs",
			Size = q.Source(Vector2.new(380, 520)),
			Children = Kids(
				Devui.SeparatorText({ Text = "Text" }),
				Devui.InputText({ Text = "name", Value = c.Text, Placeholder = "type here", Disabled = c.Disabled }),
				Devui.InputText({
					Text = "on submit",
					Placeholder = "press Enter",
					Commit = "submit",
					OnSubmit = function(t: string)
						submitted:Set(t)
					end,
					Disabled = c.Disabled,
				}),
				Shared.show("text", c.Text),
				Shared.show("submitted", submitted),
				Devui.SeparatorText({ Text = "Numbers (one shared Source)" }),
				Devui.InputNum({ Text = "InputNum", Value = c.Number, Min = 0, Max = 100, Step = 1, Disabled = c.Disabled }),
				Devui.DragNum({ Text = "DragNum", Value = c.Number, Min = 0, Max = 100, Speed = 0.5, Disabled = c.Disabled }),
				Devui.SliderNum({ Text = "SliderNum", Value = c.Number, Min = 0, Max = 100, Disabled = c.Disabled }),
				Shared.show("number", c.Number),
				Devui.SeparatorText({ Text = "Vectors" }),
				Devui.InputVector2({ Text = "Vector2", Value = vec, Disabled = c.Disabled }),
				Devui.InputVector2({ Text = "Vector2 drag", Value = vec, Drag = true, Speed = 0.1, Disabled = c.Disabled }),
				Shared.show("vector2", vec),
				Devui.InputUDim2({ Text = "UDim2", Value = udim, Disabled = c.Disabled }),
				Shared.show("udim2", udim),
				Devui.SeparatorText({ Text = "Color" }),
				Devui.InputColor3({ Text = "Color3", Value = c.Color, Disabled = c.Disabled }),
				Shared.show("color", c.Color)
			),
		})
	end,
})
