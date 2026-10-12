--!strict
--[[
	Choice — the one visual both Checkbox (square + check mark) and RadioButton (circle + dot) are: a whole-row
	TextButton (label as its Text, so the label is clickable too) with a box on the left.

	ONE TextButton (+ UIPadding) > Box Frame (+ UICorner + UIStroke) > Mark (ImageLabel check | Frame dot).
	The box is `FrameHeight` square and sits vertically centred; the label is indented past it by ItemInnerSpacing.
	Selected state drives the `Visible` of the mark; hover/press colours come from the FrameBg tokens (Common.fieldLook).

	Internal: use Checkbox / RadioButton.
]]

local Quad = require("../Quad")
local q = Quad
local D = q.Declaration
-- the host Name is an argument here; a closed set of names, so each builds one Modifier
local hostNames: { [string]: Quad.TextButtonModifier } = {}
local function hostName(name: string): Quad.TextButtonModifier
	local m = hostNames[name]
	if m == nil then
		m = D.Modifier.TextButton():Name(name)
		hostNames[name] = m
	end
	return m
end
local Common = require("../Common")
local Interaction = require("../Interaction")
local Style = require("../Style")

type State<T> = Quad.State<T>
type Style = Style.Style

export type ChoiceProps = {
	Name: string,
	Text: string | State<string>,
	Selected: State<boolean>,
	Enabled: State<boolean>,
	Round: boolean,
	OnActivate: () -> (),
	Style: Style,
	Modifier: Quad.TextButtonModifier?,
	Hooks: { any }?,
}

local Choice = {}

function Choice.build(props: ChoiceProps): TextButton
	local style = props.Style
	local hover = Interaction.hover()
	local look = Common.fieldLook(style, hover, props.Enabled)
	local textLook = Common.textLook(style, props.Enabled)
	local onActivate = props.OnActivate

	local boxSize: State<UDim2> = style.FrameHeight:Compute(function(self)
		return UDim2.fromOffset(self:Get(), self:Get())
	end)
	local indent: State<UDim> = style.FrameHeight:Compute(function(self, _prev, spacing)
		return UDim.new(0, self:Get() + spacing:Get().X)
	end, style.Metrics.ItemInnerSpacing)
	-- UIPadding moves the children's origin: the box sits at -indent to land on the button's left edge
	local boxPos: State<UDim2> = indent:Compute(function(self)
		return UDim2.new(0, -self:Get().Offset, 0.5, 0)
	end)
	-- keep the row at least as tall as the box (the text alone may be shorter)
	local padY: State<UDim> = style.FrameHeight:Compute(function(self, _prev, textSize)
		return UDim.new(0, math.max(0, (self:Get() - textSize:Get()) / 2))
	end, style.Metrics.TextSize)

	local mark: Instance
	if props.Round then
		mark = D.Frame({
			Name = "Dot",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = style.Color.CheckMark,
			BackgroundTransparency = style.Transparency.CheckMark,
			BorderSizePixel = 0,
			Visible = props.Selected,
			D.UICorner({ CornerRadius = UDim.new(0.5, 0) }),
		})
	else
		mark = D.ImageLabel({
			Name = "Check",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -4, 1, -4),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = style.Icons.CheckMark,
			ImageColor3 = style.Color.CheckMark,
			ImageTransparency = style.Transparency.CheckMark,
			Visible = props.Selected,
		})
	end

	return D.TextButton({
		hostName(props.Name),
		props.Modifier or q.None,
		hover.Hook,
		Text = props.Text,
		FontFace = style.Metrics.TextFont,
		TextSize = style.Metrics.TextSize,
		TextColor3 = textLook.Color,
		TextTransparency = textLook.Transparency,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		Activated = function()
			if props.Enabled:Get() then
				onActivate()
			end
		end,
		D.UIPadding({ PaddingLeft = indent, PaddingTop = padY, PaddingBottom = padY }),
		D.Frame({
			Name = "Box",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = boxPos,
			Size = boxSize,
			BackgroundColor3 = look.Color,
			BackgroundTransparency = look.Transparency,
			BorderSizePixel = 0,
			UICorner = if props.Round then 1000 else style.Metrics.FrameRounding,
			Common.stroke(style),
			mark,
		}),
		table.unpack(Common.hooks(props.Hooks)),
	})
end

return Choice
