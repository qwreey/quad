--!strict
--[[
	Text widgets (Iris: Text / TextWrapped / TextColored / LabelText).

		Text         { Text: string | State<string>, RichText: boolean?, Hooks: { any }?, Style: Style?, Modifier: TextLabelModifier? }
		TextWrapped  { same }              wraps at the available width (fills width, grows in height)
		TextColored  { same + Color: Color3 | State<Color3> }
		TextDisabled { same }              the dimmed token
		LabelText    { Label: string | State<string>, Text: string | State<string>, Hooks?, Style?, Modifier: FrameModifier? }
		             value first, label after it (Dear ImGui LabelText order), one row; `Modifier` / `Hooks` go on the row Frame

	`Hooks` is a list of hook values appended at the END of the element's array part (see Button).

	One TextLabel each (LabelText: a row Frame + two TextLabels). Colours/size/font come from the Style tokens and
	follow runtime scheme/density switches. `props.Modifier` is spliced in the array part: inline props win, later
	modifier entries win over earlier ones (docs/how-to/01).
]]

local Quad = require("./Quad")
local q = Quad
local Frame = q.Elem "Frame"
local TextLabel = q.Elem "TextLabel"
local UIListLayout = q.Elem "UIListLayout"
local UIPadding = q.Elem "UIPadding"
local FrameModifier = q.Modifier "Frame"
local TextLabelModifier = q.Modifier "TextLabel"
local textName = TextLabelModifier():Name("Text")
local labelTextName = FrameModifier():Name("LabelText")
local Common = require("./Common")
local Style = require("./Style")
local Util = require("./Util")

type State<T> = Quad.State<T>
type Style = Style.Style

export type TextProps = {
	read Text: string | State<string>,
	read RichText: boolean?,
	read Hooks: { any }?,
	read Style: Style?,
	read Modifier: Quad.ModifierInto<TextLabel>?,
}

export type TextColoredProps = {
	read Text: string | State<string>,
	read Color: Color3 | State<Color3>,
	read RichText: boolean?,
	read Hooks: { any }?,
	read Style: Style?,
	read Modifier: Quad.ModifierInto<TextLabel>?,
}

export type LabelTextProps = {
	read Label: string | State<string>,
	read Text: string | State<string>,
	read Hooks: { any }?,
	read Style: Style?,
	read Modifier: Quad.ModifierInto<Frame>?,
}

local function label(
	style: Style,
	text: string | State<string>,
	color: Color3 | State<Color3>,
	alpha: State<number>,
	wrapped: boolean,
	richText: boolean?,
	modifier: Quad.ModifierInto<TextLabel>?,
	hooks: { any }?
): TextLabel
	return TextLabel({
		textName,
		modifier or q.None,
		Text = text,
		FontFace = style.Metrics.TextFont,
		TextSize = style.Metrics.TextSize,
		TextColor3 = color,
		TextTransparency = alpha,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = wrapped,
		RichText = richText == true,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticSize = if wrapped then Enum.AutomaticSize.Y else Enum.AutomaticSize.XY,
		Size = if wrapped then UDim2.new(1, 0, 0, 0) else UDim2.fromOffset(0, 0),
		UIPadding({ PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2) }),
		table.unpack(Common.hooks(hooks)),
	})
end

local Text = {}

function Text.Text(props: TextProps): TextLabel
	local style = props.Style or Style.default
	return label(style, props.Text, style.Color.Text, style.Transparency.Text, false, props.RichText, props.Modifier, props.Hooks)
end

function Text.TextWrapped(props: TextProps): TextLabel
	local style = props.Style or Style.default
	return label(style, props.Text, style.Color.Text, style.Transparency.Text, true, props.RichText, props.Modifier, props.Hooks)
end

function Text.TextColored(props: TextColoredProps): TextLabel
	local style = props.Style or Style.default
	return label(style, props.Text, props.Color, style.Transparency.Text, false, props.RichText, props.Modifier, props.Hooks)
end

function Text.TextDisabled(props: TextProps): TextLabel
	local style = props.Style or Style.default
	return label(
		style,
		props.Text,
		style.Color.TextDisabled,
		style.Transparency.TextDisabled,
		false,
		props.RichText,
		props.Modifier,
		props.Hooks
	)
end

function Text.LabelText(props: LabelTextProps): Frame
	local style = props.Style or Style.default
	local spacing: State<UDim> = Util.pxX(style.Metrics.ItemInnerSpacing)
	return Frame({
		labelTextName,
		props.Modifier or q.None,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		UIListLayout({
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = spacing,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		label(style, props.Text, style.Color.Text, style.Transparency.Text, false, nil, TextLabelModifier():LayoutOrder(1), nil),
		label(style, props.Label, style.Color.Text, style.Transparency.Text, false, nil, TextLabelModifier():LayoutOrder(2), nil),
		table.unpack(Common.hooks(props.Hooks)),
	})
end

return Text
