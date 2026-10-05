--!strict
-- Style: this story builds its OWN `Style.new()` (nothing touches the global `Style.default`) and passes it to every
-- widget. The Scheme / Density controls write that style's Sources, so the whole window repaints live.
local Devui = require("../src")
local q = require("../src/Quad")
local StoryKit = require("./StoryKit")
local Shared = require("./Shared")
local D = q.Declaration
local Kids = Devui.Kids

local function noCleanup(_dying: boolean) end

return StoryKit.story({
	controls = {
		Scheme = StoryKit.Choose({ "Dark", "Light" }, 1),
		Density = StoryKit.Choose({ "Default", "Clear" }, 1),
	},
	render = function(c, ctx)
		local style = Devui.Style.new()
		local number = q.Source(30)
		local color = q.Source(Color3.fromRGB(66, 150, 250))
		local flavor = q.Source("a")
		-- control Sources -> the story's own Style (an Effect: it writes a different Source than it reads)
		local bridge = D.Frame({
			Name = "StyleBridge",
			Visible = false,
			Size = UDim2.fromOffset(0, 0),
			q.Effect(function()
				style.Scheme:SetIfChanged(c.Scheme:Get())
				return noCleanup
			end, c.Scheme),
			q.Effect(function()
				style.Density:SetIfChanged(c.Density:Get())
				return noCleanup
			end, c.Density),
		})
		return Devui.Window({
			Title = "Style",
			Style = style,
			Size = q.Source(Vector2.new(360, 460)),
			Children = Kids(
				bridge,
				Devui.Text({ Text = "Every widget here shares one story-local Style.", Style = style }),
				Shared.show("scheme", style.Scheme, style),
				Shared.show("density", style.Density, style),
				Devui.SeparatorText({ Text = "Sample widgets", Style = style }),
				Devui.SameLine({
					Style = style,
					Children = Kids(Devui.Button({ Text = "Button", Style = style }), Devui.SmallButton({ Text = "small", Style = style })),
				}),
				Devui.Checkbox({ Text = "checkbox", Style = style }),
				Devui.RadioButton<<string>>({ Text = "radio a", Value = flavor, Option = "a", Style = style }),
				Devui.RadioButton<<string>>({ Text = "radio b", Value = flavor, Option = "b", Style = style }),
				Devui.InputNum({ Text = "InputNum", Value = number, Style = style }),
				Devui.SliderNum({ Text = "SliderNum", Value = number, Min = 0, Max = 100, Style = style }),
				Devui.InputColor3({ Text = "color", Value = color, Style = style }),
				Devui.ProgressBar({ Value = 0.6, Style = style }),
				Devui.CollapsingHeader({
					Text = "CollapsingHeader",
					Style = style,
					Children = Kids(Devui.TextDisabled({ Text = "disabled text", Style = style })),
				})
			),
		})
	end,
})
