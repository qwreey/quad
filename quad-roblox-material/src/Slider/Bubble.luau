--!strict
--[[
	Slider value-label bubble (shared by the M3 and M2 looks — each passes its own style): a pill with the formatted value,
	visible while the handle is dragged or focused (and not disabled). It sits outside the host (above the handle), so an
	ancestor with `ClipsDescendants` clips it. Cost: TextLabel + UICorner + UIPadding (3).

	    Bubble.build({ Dragging, Focused, Disabled, Value, Format, Theme, Style })  -> TextLabel
	The caller parents it under the handle (or the handle's halo) and gives the bottom-center `Position` in that parent.
	Styles (`Bubble.M3`, `Bubble.M2`):
	  M3  44 px tall, 16 px side padding, `InverseSurface` / `InverseOnSurface`, `LabelLarge` (androidx SliderTokens
	      ValueIndicator*; 44 px height from the M3 spec drawing, not a token)
	  M2  28 px tall, 12 px side padding, `Primary` / `OnPrimary`, `LabelMedium` (the 2022 classic form)
]]

local q = require("../Quad")
local Theme = require("../Theme")
local Text = require("../Text")
local Tokens = require("../Tokens")
local Style = require("../Button/Style")
local D = q.Declaration

export type BubbleStyle = {
	Height: number,
	Padding: number,
	Container: Theme.Role,
	Content: Theme.Role,
	Text: (typeof(Text.Label("LabelLarge"))),
}

export type Options = {
	Dragging: q.State<boolean>,
	Focused: q.State<boolean>,
	Disabled: q.State<boolean>,
	Value: q.State<number>,
	Format: (value: number) -> string,
	Theme: Theme.Theme,
	Style: BubbleStyle,
	Position: UDim2, -- bottom center, in the parent
}

local M3: BubbleStyle = { Height = 44, Padding = 16, Container = "InverseSurface", Content = "InverseOnSurface", Text = Text.Label("LabelLarge") }
local M2: BubbleStyle = { Height = 28, Padding = 12, Container = "Primary", Content = "OnPrimary", Text = Text.Label("LabelMedium") }

local function build(o: Options): TextLabel
	local theme = o.Theme
	local format = o.Format
	local style = o.Style
	local shown: q.State<boolean> = o.Dragging:Compute(function(self, _prev, focused, dis)
		return (self:Get() or focused:Get()) and not dis:Get()
	end, o.Focused, o.Disabled)
	local bubbleTransparency: q.State<number> = shown:Compute(function(self)
		return if self:Get() then 0 else 1
	end)
	local text: q.State<string> = o.Value:Compute(function(self)
		return format(self:Get())
	end)
	return D.TextLabel {
		Name = "Label",
		style.Text,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = o.Position,
		Size = UDim2.fromOffset(0, style.Height),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = theme.Color[style.Container],
		BackgroundTransparency = bubbleTransparency:Apply(Style.animation()),
		BorderSizePixel = 0,
		Text = text,
		TextColor3 = theme.Color[style.Content],
		TextTransparency = bubbleTransparency:Apply(Style.animation()),
		UICorner = Tokens.Shape.corner("Full"),
		D.UIPadding { PaddingLeft = UDim.new(0, style.Padding), PaddingRight = UDim.new(0, style.Padding) },
	}
end

return { build = build, M3 = M3, M2 = M2 }
