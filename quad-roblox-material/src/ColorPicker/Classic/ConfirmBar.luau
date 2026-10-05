--!strict
--[[
	Bottom bar: [ last | current ] preview pill on the left, Cancel and Select pills on the right.

	Preview: ONE pill Frame whose UIGradient has a hard stop at 50 % (last color left, current color right) —
	the original joined two 32 px round images with two 10 px rectangles (6 instances + shadow image). The
	gradient's keypoints are a Compute of `model.last` and `model.color`, so confirming (last := draft) and
	dragging (draft changes) both just flow; nothing calls an "update preview" function.

	Buttons: hover darkens by 20 % (dim 0.8), press by 32 % (dim 0.68), all tweened 0.28 s Quad. The original
	laid a black image over each button and tweened its transparency; here the dim is applied to the button's
	own BackgroundColor3 and TextColor3 (lerp toward `ButtonDimColor`), so there is no overlay instance. The
	soft colored drop shadow image is a UIShadow child (offset 2 px down).
	Instances at rest: bar, preview (+UICorner, UIGradient, UIShadow), 2 x button (+UICorner, UIShadow) = 11.
]]

local q = require("../../Quad")
local Anim = require("./Anim")
local Interaction = require("../../Interaction")
local Model = require("./Model")
local Themes = require("./Themes")
local D = q.Declaration

export type Props = {
	read Model: Model.Model,
	read Theme: Themes.Theme,
	read LayoutOrder: number?,
}

local function shadow(color: Color3)
	return D.UIShadow {
		Name = "Shadow",
		BlurRadius = UDim.new(0, 4),
		Offset = UDim2.fromOffset(0, 2),
		Transparency = 0.2,
		Color = color,
		ShowBehindParent = true,
	}
end

type ButtonOptions = {
	Name: string,
	Text: string,
	Color: Color3,
	TextColor: Color3,
	ShadowColor: Color3,
	Theme: Themes.Theme,
	Position: UDim2,
	OnClick: () -> (),
}

local function DimButton(o: ButtonOptions)
	local theme = o.Theme
	local ix = Interaction.new()
	-- dim transparency target: pressed 0.68 > hovered 0.8 > idle 1
	local dim: q.State<number> = ix.Pressed:Compute(function(self, _prev, hovered)
		if self:Get() then
			return theme.ButtonDimTransparencyOn
		end
		return if hovered:Get() then theme.ButtonDimTransparencyHover else theme.ButtonDimTransparencyOff
	end, ix.Hovered)
	local function dimmed(base: Color3)
		return dim:Compute(function(self)
			return Anim.tween(base:Lerp(theme.ButtonDimColor, 1 - self:Get()), 0.28)
		end)
	end
	return D.TextButton {
		Name = o.Name,
		ix.Hook,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0),
		Position = o.Position,
		Size = UDim2.fromOffset(63, 32),
		Font = Enum.Font.GothamBold,
		Text = o.Text,
		TextSize = 14,
		TextColor3 = dimmed(o.TextColor),
		BackgroundColor3 = dimmed(o.Color),
		Activated = function(_input: InputObject, _clicks: number)
			o.OnClick()
		end,
		UICorner = UDim.new(0.5, 0),
		shadow(o.ShadowColor),
	}
end

local function ConfirmBar(props: Props)
	local model, theme = props.Model, props.Theme
	local split = model.last:Compute(function(self, _prev, current)
		local l, c = self:Get(), current:Get()
		return ColorSequence.new({
			ColorSequenceKeypoint.new(0, l),
			ColorSequenceKeypoint.new(0.5, l),
			ColorSequenceKeypoint.new(0.5001, c),
			ColorSequenceKeypoint.new(1, c),
		})
	end, model.color)

	return D.Frame {
		Name = "ConfirmBar",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 32),
		LayoutOrder = props.LayoutOrder or 0,

		D.Frame {
			Name = "Preview",
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Size = UDim2.new(0, 52, 1, 0),
			UICorner = UDim.new(0.5, 0),
			D.UIGradient { Color = split },
			shadow(theme.PreviewShadowColor),
		},
		DimButton({
			Name = "CancelButton",
			Text = theme.CancelButtonText,
			Color = theme.CancelButtonColor,
			TextColor = theme.CancelButtonTextColor,
			ShadowColor = theme.CancelButtonShadowColor,
			Theme = theme,
			Position = UDim2.new(1, -69, 0, 0),
			OnClick = model.cancel,
		}),
		DimButton({
			Name = "SelectButton",
			Text = theme.SelectButtonText,
			Color = theme.SelectButtonColor,
			TextColor = theme.SelectButtonTextColor,
			ShadowColor = theme.SelectButtonShadowColor,
			Theme = theme,
			Position = UDim2.new(1, 0, 0, 0),
			OnClick = model.confirm,
		}),
	}
end

return ConfirmBar
