--!strict
--[[
	Layout widgets (Iris: SameLine / Group / Indent / Separator / SeparatorText).

		SameLine      { Children: Slot<Instance>?, Spacing: number?, Style: Style?, Modifier: ModifierInto<Frame>? }
		              a horizontal row (children keep their own widths); Spacing defaults to Style ItemSpacing.X
		Group         { Children, Style?, Modifier? }                 a vertical stack (ItemSpacing.Y apart)
		Indent        { Children, Width: number?, Style?, Modifier? } a vertical stack indented by IndentSpacing
		Separator     { Style?, Modifier? }                           a 1px horizontal rule, as wide as its parent — or,
		              under a parent that sizes its width to its children (AutomaticSize X / XY: a menu panel), as wide
		              as the widest sibling
		SeparatorText { Text: string | State<string>, Style?, Modifier? }   rule - text - rule
		Kids(...)     helper: `Kids(a, b, c)` = `q.Slot({ a, b, c })` (a manual-CRUD Slot<Instance>) — Instances only:
		              a Slot element cannot be nil or `q.None` (unlike an element's array part); build the list first for
		              conditional children. An empty Slot in an element's array part is `q.Slot<<Instance>>()`.

	Containers are ONE Frame (+ one UIListLayout); they grow with their content (AutomaticSize Y, full width) and take
	their children as a Slot (docs/how-to/01 §4) so a caller can add/remove children later.
]]

local Quad = require("./Quad")
local q = Quad
local Frame = q.Elem "Frame"
local UIFlexItem = q.Elem "UIFlexItem"
local UIListLayout = q.Elem "UIListLayout"
local UIPadding = q.Elem "UIPadding"
local FrameModifier = q.Modifier "Frame"
local TextLabelModifier = q.Modifier "TextLabel"
local sameLineName = FrameModifier():Name("SameLine")
local groupName = FrameModifier():Name("Group")
local indentName = FrameModifier():Name("Indent")
local separatorName = FrameModifier():Name("Separator")
local separatorTextName = FrameModifier():Name("SeparatorText")
local Style = require("./Style")
local Text = require("./Text")
local Util = require("./Util")
local Visibility = require("./Visibility")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Slot<T> = Quad.Slot<T>
type Style = Style.Style

export type ContainerProps = {
	read Children: Slot<Instance>?,
	read Style: Style?,
	read Modifier: Quad.ModifierInto<Frame>?,
}

export type SameLineProps = {
	read Children: Slot<Instance>?,
	read Spacing: number?,
	read Style: Style?,
	read Modifier: Quad.ModifierInto<Frame>?,
}

export type IndentProps = {
	read Children: Slot<Instance>?,
	read Width: number?,
	read Style: Style?,
	read Modifier: Quad.ModifierInto<Frame>?,
}

export type SeparatorProps = {
	read Style: Style?,
	read Modifier: Quad.ModifierInto<Frame>?,
}

export type SeparatorTextProps = {
	read Text: string | State<string>,
	read Style: Style?,
	read Modifier: Quad.ModifierInto<Frame>?,
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
	return Frame({
		sameLineName,
		props.Modifier or q.None,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		UIListLayout({
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
	return Frame({
		groupName,
		props.Modifier or q.None,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		UIListLayout({
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
	return Frame({
		indentName,
		props.Modifier or q.None,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		UIPadding({ PaddingLeft = width }),
		UIListLayout({
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = Util.pxY(style.Metrics.ItemSpacing),
		}),
		props.Children or q.None,
	})
end

-- [2026-10-21 user decision — devplorer U28] a scale width under a parent that sizes its width to its children makes
-- that parent grow to ITS parent's width (a menu panel became a screen-wide band, Studio-confirmed). Under such a
-- parent the rule is 0 wide and stretched to the widest sibling instead (the menu rows' way); everywhere else it is
-- the parent's width — the stretch alone gives 0 in a fixed-width list (it follows the widest item, not the
-- container), and the two together still grow the panel (Studio 2026-10-21). The UIFlexItem is harmless in both
local function separatorSize(parent: Instance?): UDim2
	local auto = if parent ~= nil and Visibility.isGuiObject(parent) then (parent :: GuiObject).AutomaticSize else nil
	if auto == Enum.AutomaticSize.X or auto == Enum.AutomaticSize.XY then
		return UDim2.new(0, 0, 0, 1)
	end
	return UDim2.new(1, 0, 0, 1)
end

function Layout.Separator(props: SeparatorProps): Frame
	local style = props.Style or Style.default
	local size: Source<UDim2> = q.Source(UDim2.new(1, 0, 0, 1))
	local placed = q.PostRef(nil :: Frame?)
	placed:Callback(function(inst)
		if inst ~= nil then
			size:SetIfChanged(separatorSize(inst.Parent))
			inst.AncestryChanged:Connect(function()
				size:SetIfChanged(separatorSize(inst.Parent))
			end)
		end
	end)
	return Frame({
		separatorName,
		props.Modifier or q.None,
		placed,
		Size = size,
		UIFlexItem({ ItemLineAlignment = Enum.ItemLineAlignment.Stretch }),
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
	return Frame({
		separatorTextName,
		props.Modifier or q.None,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		UIPadding({ PaddingTop = padY, PaddingBottom = padY }),
		UIListLayout({
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = Util.pxX(style.Metrics.ItemSpacing),
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		Frame({
			Name = "Left",
			LayoutOrder = 1,
			Size = thickness,
			BackgroundColor3 = style.Color.Separator,
			BackgroundTransparency = style.Transparency.Separator,
			BorderSizePixel = 0,
		}),
		Text.Text({ Text = props.Text, Style = style, Modifier = TextLabelModifier():LayoutOrder(2) }),
		Frame({
			Name = "Right",
			LayoutOrder = 3,
			Size = fillThickness,
			BackgroundColor3 = style.Color.Separator,
			BackgroundTransparency = style.Transparency.Separator,
			BorderSizePixel = 0,
			UIFlexItem({ FlexMode = Enum.UIFlexMode.Fill }),
		}),
	})
end

return Layout
