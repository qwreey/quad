--!strict
--[[
	Tree / CollapsingHeader (Iris: Tree / CollapsingHeader).

		Tree             { Text: string | State<string>, Open: Source<boolean>?, OnChange: ((open: boolean) -> ())?,
		                   Children: Slot<Instance>?, SpanAvailWidth: boolean?, NoIndent: boolean?, Style: Style?,
		                   Modifier: FrameModifier? }
		CollapsingHeader { Text, Open?, OnChange?, Children?, Style?, Modifier? }     full-width header bar, children not indented

	Structure: root Frame (vertical list) > Header (TextButton: the label, a hover/active highlight, UICorner/UIPadding)
	+ Arrow (ImageLabel child of the header, drawn left of the text) and, when `Children` is given, a Children Frame
	(vertical list, indented by IndentSpacing unless NoIndent).

	`Open` is two-way: clicking the header toggles it (`Set`), setting it from outside shows/hides the children (the
	widget creates an internal Source, closed, when none is passed). `OnChange(open)` runs after a USER toggle (not for an
	outside `:Set`). Tree: the header is highlighted only on hover /
	press unless `SpanAvailWidth` (then it is full width, still highlight-on-hover); CollapsingHeader always paints the
	Header colour and always spans the width.

	CLOSED CHILDREN STAY MOUNTED with `Visible = false` (Roblox skips invisible children in UIListLayouts and
	rendering): opening is instant, widget/Source state inside survives a collapse, and a Slot stays a plain
	DOMless child list (a literal child is bound to its host's lifetime, so a mount/unmount design would need a State-held
	child slot per Tree). The cost is that closed subtrees keep their instances alive — a debug tree with thousands of
	nodes should build children lazily itself (e.g. a `Slot:Single` fed from `Open`).
]]

local Quad = require("./Quad")
local q = Quad
local D = q.Declaration
-- the host Name is an argument here; a closed set of names, so each builds one Modifier
local hostNames: { [string]: Quad.FrameModifier } = {}
local function hostName(name: string): Quad.FrameModifier
	local m = hostNames[name]
	if m == nil then
		m = D.Modifier.Frame():Name(name)
		hostNames[name] = m
	end
	return m
end
local Common = require("./Common")
local Interaction = require("./Interaction")
local Style = require("./Style")
local Util = require("./Util")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Slot<T> = Quad.Slot<T>
type Style = Style.Style

export type TreeProps = {
	read Text: string | State<string>,
	read Open: Source<boolean>?,
	read OnChange: ((open: boolean) -> ())?,
	read Children: Slot<Instance>?,
	read SpanAvailWidth: boolean?,
	read NoIndent: boolean?,
	read Style: Style?,
	read Modifier: Quad.FrameModifier?,
}

export type CollapsingHeaderProps = {
	read Text: string | State<string>,
	read Open: Source<boolean>?,
	read OnChange: ((open: boolean) -> ())?,
	read Children: Slot<Instance>?,
	read Style: Style?,
	read Modifier: Quad.FrameModifier?,
}

local function build(
	name: string,
	text: string | State<string>,
	openProp: Source<boolean>?,
	onChange: ((open: boolean) -> ())?,
	children: Slot<Instance>?,
	span: boolean,
	indented: boolean,
	collapsing: boolean,
	styleProp: Style?,
	modifier: Quad.FrameModifier?
): Frame
	local style = styleProp or Style.default
	local open: Source<boolean> = openProp or q.Source(false)
	local hover = Interaction.hover()
	-- Tree: transparent until hovered / pressed; CollapsingHeader: always the Header look
	local look = Common.headerLook(style, hover, nil, collapsing)

	local downIcon, rightIcon = style.Icons.DownTriangle, style.Icons.RightTriangle
	local icon: State<string> = open:Compute(function(self)
		return if self:Get() then downIcon else rightIcon
	end)

	local metrics = style.Metrics
	local padLeft: State<UDim> = metrics.TextSize:Compute(function(self, _prev, framePad, inner)
		return UDim.new(0, framePad:Get().X + self:Get() + inner:Get().X)
	end, metrics.FramePadding, metrics.ItemInnerSpacing)
	-- UIPadding insets the children's space too, so the arrow sits at a negative offset from the padded origin
	local arrowPos: State<UDim2> = metrics.TextSize:Compute(function(self, _prev, inner)
		return UDim2.new(0, -(self:Get() + inner:Get().X), 0.5, 0)
	end, metrics.ItemInnerSpacing)
	local arrowSize: State<UDim2> = metrics.TextSize:Compute(function(self)
		return UDim2.fromOffset(self:Get(), self:Get())
	end)
	local padX, padY = Common.padXY(metrics.FramePadding)
	local indent: State<UDim> | UDim = if indented then Util.px(metrics.IndentSpacing) else UDim.new(0, 0)

	local header = D.TextButton({
		hover.Hook,
		Name = "Header",
		Text = text,
		FontFace = metrics.TextFont,
		TextSize = metrics.TextSize,
		TextColor3 = style.Color.Text,
		TextTransparency = style.Transparency.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = look.Color,
		BackgroundTransparency = look.Transparency,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		AutomaticSize = if span then Enum.AutomaticSize.Y else Enum.AutomaticSize.XY,
		Size = if span then UDim2.new(1, 0, 0, 0) else UDim2.fromOffset(0, 0),
		Activated = function()
			local nextOpen = not open:Get()
			open:Set(nextOpen)
			if onChange then
				onChange(nextOpen)
			end
		end,
		UICorner = metrics.FrameRounding,
		D.UIPadding({ PaddingLeft = padLeft, PaddingRight = padX, PaddingTop = padY, PaddingBottom = padY }),
		D.ImageLabel({
			Name = "Arrow",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = arrowPos,
			Size = arrowSize,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = icon,
			ImageColor3 = style.Color.Text,
			ImageTransparency = style.Transparency.Text,
		}),
	})

	return D.Frame({
		hostName(name),
		modifier or q.None,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		D.UIListLayout({
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = Util.pxY(metrics.ItemSpacing),
		}),
		header,
		if children
			then D.Frame({
				Name = "Children",
				LayoutOrder = 1,
				Visible = open,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				D.UIPadding({ PaddingLeft = indent }),
				D.UIListLayout({
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = Util.pxY(metrics.ItemSpacing),
				}),
				children,
			})
			else q.None,
	})
end

local Tree = {}

function Tree.Tree(props: TreeProps): Frame
	return build(
		"Tree",
		props.Text,
		props.Open,
		props.OnChange,
		props.Children,
		props.SpanAvailWidth == true,
		props.NoIndent ~= true,
		false,
		props.Style,
		props.Modifier
	)
end

function Tree.CollapsingHeader(props: CollapsingHeaderProps): Frame
	return build(
		"CollapsingHeader",
		props.Text,
		props.Open,
		props.OnChange,
		props.Children,
		true,
		false,
		true,
		props.Style,
		props.Modifier
	)
end

return Tree
