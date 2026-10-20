--!strict
--[[
	Layout widgets (Iris: SameLine / Group / Indent / Separator / SeparatorText).

		SameLine      { Children: Slot<Instance>?, Spacing: number?, Style: Style?, Modifier: FrameModifier? }
		              a horizontal row (children keep their own widths); Spacing defaults to Style ItemSpacing.X
		Group         { Children, Style?, Modifier? }                 a vertical stack (ItemSpacing.Y apart)
		Indent        { Children, Width: number?, Style?, Modifier? } a vertical stack indented by IndentSpacing
		Separator     { Style?, Modifier? }                           a 1px horizontal rule (scale width 1: inside an
		              AutomaticSize-X popup it grows to the popup's limit — give it a fixed width or a UIFlexItem there)
		SeparatorText { Text: string | State<string>, Style?, Modifier? }   rule - text - rule
		Kids(...)     helper: `Kids(a, b, c)` = `q.Slot({ a, b, c })` (a manual-CRUD Slot<Instance>) — Instances only:
		              a Slot element cannot be nil or `q.None` (unlike an element's array part); build the list first for
		              conditional children. An empty Slot in an element's array part is `q.Slot<<Instance>>()`.

	Containers are ONE Frame (+ one UIListLayout); they grow with their content (AutomaticSize Y, full width) and take
	their children as a Slot (docs/how-to/01 §4) so a caller can add/remove children later.
]]

local Quad = require("./Quad")
local q = Quad
local D = q.Declaration
local sameLineName = D.Modifier.Frame():Name("SameLine")
local groupName = D.Modifier.Frame():Name("Group")
local indentName = D.Modifier.Frame():Name("Indent")
local separatorName = D.Modifier.Frame():Name("Separator")
local separatorTextName = D.Modifier.Frame():Name("SeparatorText")
local Style = require("./Style")
local Text = require("./Text")
local Util = require("./Util")

type State<T> = Quad.State<T>
type Slot<T> = Quad.Slot<T>
type Style = Style.Style

export type ContainerProps = {
	read Children: Slot<Instance>?,
	read Style: Style?,
	read Modifier: Quad.FrameModifier?,
}

export type SameLineProps = {
	read Children: Slot<Instance>?,
	read Spacing: number?,
	read Style: Style?,
	read Modifier: Quad.FrameModifier?,
}

export type IndentProps = {
	read Children: Slot<Instance>?,
	read Width: number?,
	read Style: Style?,
	read Modifier: Quad.FrameModifier?,
}

export type SeparatorProps = {
	read Style: Style?,
	read Modifier: Quad.FrameModifier?,
}

export type SeparatorTextProps = {
	read Text: string | State<string>,
	read Style: Style?,
	read Modifier: Quad.FrameModifier?,
}

local Layout = {}

function Layout.Kids(...: Instance): Slot<Instance>
	return q.Slot({ ... } :: { Instance })
end

function Layout.SameLine(props: SameLineProps): Frame
	local style = props.Style or Style.default
	local spacing: State<UDim> | UDim
	if props.Spacing then
		spacing = UDim.new(0, props.Spacing)
	else
		spacing = Util.pxX(style.Metrics.ItemSpacing)
	end
	return D.Frame({
		sameLineName,
		props.Modifier or q.None,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		D.UIListLayout({
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = spacing,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		props.Children or q.None,
	})
end

function Layout.Group(props: ContainerProps): Frame
	local style = props.Style or Style.default
	return D.Frame({
		groupName,
		props.Modifier or q.None,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		D.UIListLayout({
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = Util.pxY(style.Metrics.ItemSpacing),
		}),
		props.Children or q.None,
	})
end

function Layout.Indent(props: IndentProps): Frame
	local style = props.Style or Style.default
	local width: State<UDim> | UDim
	if props.Width then
		width = UDim.new(0, props.Width)
	else
		width = Util.px(style.Metrics.IndentSpacing)
	end
	return D.Frame({
		indentName,
		props.Modifier or q.None,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		D.UIPadding({ PaddingLeft = width }),
		D.UIListLayout({
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = Util.pxY(style.Metrics.ItemSpacing),
		}),
		props.Children or q.None,
	})
end

function Layout.Separator(props: SeparatorProps): Frame
	local style = props.Style or Style.default
	return D.Frame({
		separatorName,
		props.Modifier or q.None,
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = style.Color.Separator,
		BackgroundTransparency = style.Transparency.Separator,
		BorderSizePixel = 0,
	})
end

function Layout.SeparatorText(props: SeparatorTextProps): Frame
	local style = props.Style or Style.default
	local thickness: State<UDim2> = style.Metrics.SeparatorTextBorderSize:Compute(function(self)
		return UDim2.new(0, 10, 0, math.max(1, self:Get() - 2))
	end)
	local fillThickness: State<UDim2> = style.Metrics.SeparatorTextBorderSize:Compute(function(self)
		return UDim2.new(1, 0, 0, math.max(1, self:Get() - 2))
	end)
	local padY: State<UDim> = Util.pxY(style.Metrics.SeparatorTextPadding)
	return D.Frame({
		separatorTextName,
		props.Modifier or q.None,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		D.UIPadding({ PaddingTop = padY, PaddingBottom = padY }),
		D.UIListLayout({
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = Util.pxX(style.Metrics.ItemSpacing),
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		D.Frame({
			Name = "Left",
			LayoutOrder = 1,
			Size = thickness,
			BackgroundColor3 = style.Color.Separator,
			BackgroundTransparency = style.Transparency.Separator,
			BorderSizePixel = 0,
		}),
		Text.Text({ Text = props.Text, Style = style, Modifier = D.Modifier.TextLabel():LayoutOrder(2) }),
		D.Frame({
			Name = "Right",
			LayoutOrder = 3,
			Size = fillThickness,
			BackgroundColor3 = style.Color.Separator,
			BackgroundTransparency = style.Transparency.Separator,
			BorderSizePixel = 0,
			D.UIFlexItem({ FlexMode = Enum.UIFlexMode.Fill }),
		}),
	})
end

return Layout
