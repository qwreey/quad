--!strict
--[[
	Slider value-label bubble: a pill (28 px, `Primary`, `LabelMedium` in `OnPrimary`) 4 px above the handle, visible while
	the handle is dragged or focused (and not disabled). It extends outside the host, so an ancestor with
	`ClipsDescendants` clips it. Cost: TextLabel + UICorner + UIPadding (3).

	    Bubble.build({ Dragging, Focused, Disabled, Value, Format, Theme, Inset = 10, Corner })  -> TextLabel
	The caller parents it inside the Halo frame (it positions itself relative to the halo center).
]]

local q = require("../Quad")
local Theme = require("../Theme")
local Text = require("../Text")
local Style = require("../Button/Style")
local D = q.Declaration

export type Options = {
	Dragging: q.State<boolean>,
	Focused: q.State<boolean>,
	Disabled: q.State<boolean>,
	Value: q.State<number>,
	Format: (value: number) -> string,
	Theme: Theme.Theme,
	Inset: number,
	Corner: UDim,
}

local bubbleStyle = Text.Label("LabelMedium")

local function build(o: Options): TextLabel
	local theme = o.Theme
	local format = o.Format
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
		bubbleStyle,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0, o.Inset - 4),
		Size = UDim2.fromOffset(0, 28),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = theme.Color.Primary,
		BackgroundTransparency = bubbleTransparency:Apply(Style.animation()),
		BorderSizePixel = 0,
		Text = text,
		TextColor3 = theme.Color.OnPrimary,
		TextTransparency = bubbleTransparency:Apply(Style.animation()),
		UICorner = o.Corner,
		D.UIPadding { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) },
	}
end

return { build = build }
