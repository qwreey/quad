--!strict
--[[
	Current-vs-initial preview: ONE rounded square whose `UIGradient` has a hard stop at 50 % — the INITIAL color
	on the left half, the CURRENT color on the right half (M3 shows the old and the new value side by side in its
	pickers). The two keypoints are a Compute of `model.initial` and
	`model.color`, so dragging and an outside change of the initial color both just flow; nothing calls an
	"update preview" function.

	Instances: preview + UICorner + UIGradient + UIStroke = 4.
]]

local q = require("../../Quad")
local Tokens = require("../../Tokens")
local Theme = require("../../Theme")
local Model = require("./Model")
local Frame = q.Elem "Frame"
local UIGradient = q.Elem "UIGradient"
local UIStroke = q.Elem "UIStroke"

export type Props = {
	read Model: Model.Model,
	read Theme: Theme.Theme?,
	read Size: number?,
}

local function Preview(props: Props)
	local model = props.Model
	local theme = Theme.resolve(props.Theme)
	local size = props.Size or 56
	local split: q.State<ColorSequence> = model.initial:Compute(function(self, _prev, current)
		local l, c = self:Get(), current:Get()
		return ColorSequence.new({
			ColorSequenceKeypoint.new(0, l),
			ColorSequenceKeypoint.new(0.5, l),
			ColorSequenceKeypoint.new(0.5001, c),
			ColorSequenceKeypoint.new(1, c),
		})
	end, model.color)

	return Frame {
		Name = "Preview",
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		UICorner = Tokens.Shape.corner("Large"),
		UIGradient { Color = split },
		UIStroke {
			Name = "Outline",
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = theme.Color.OutlineVariant,
			Thickness = 1,
		},
	}
end

return Preview
