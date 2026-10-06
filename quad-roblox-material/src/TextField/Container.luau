--!strict
--[[
	TextField container: the floating label and the 56 px container (Filled: rounded fill + state layer + active indicator,
	clipped so only the TOP corners show; Outlined: one UICorner + UIStroke). Row / slots are built by Field.luau and
	handed in; the container only seats them.

	Floating label (BodyLarge 16 -> BodySmall 12): one TextLabel whose Position and TextSize are two animated derivations of
	`floated = focused or non-empty` (Motion Short4/Standard). Outlined notch: the label has a background in the surface
	color (`NotchColor`, default theme `Surface`) + 4 px side padding that fades in while floated; the label is a later
	sibling of the stroked container's content, so it paints over the border line. It is only correct when the field sits on a
	`Surface`-colored area — pass `NotchColor` for any other backdrop. (A transparent notch would need the border split in
	segments: not worth ~4 more instances, deviation documented.)
]]

local q = require("../Quad")
local Tokens = require("../Tokens")
local Util = require("../Util")
local StateLayer = require("../StateLayer")
local Style = require("../Button/Style")
local Text = require("../Text")
local Ctx = require("./Ctx")
local D = q.Declaration

local Corner = Tokens.Shape.corner("ExtraSmall")
local DisabledOutlineTransparency = 1 - Tokens.State.Opacity.DisabledContainer
local DisabledIndicatorTransparency = 1 - Tokens.State.Opacity.DisabledContent
local DisabledFillTransparency = 0.96 -- M3: disabled filled container = onSurface @ 4 %

local bodyLarge = Text.Label("BodyLarge")

local function label(c: Ctx.Ctx, inset: number): Instance?
	local props = c.Props
	if not c.HasLabel then
		return nil
	end
	local filled = c.Filled
	local floated = c.Floated
	-- resting label: its 16 px text box centered on the container (a single-line field) or on the first line (multi-line,
	-- whose text starts 16 px down). The label's LineHeight is forced to 1 (below), so its auto-sized box IS the text size
	-- and these offsets do not depend on how the engine spreads BodyLarge's 1.5 line height around one line. (The first
	-- version put the resting label at y = 16, assuming a 24 px line box; the auto-sized box was the 16 px text, so the
	-- label sat 4 px above the container's center — Studio QA 2026-10-07.)
	local restY = if c.Multi then 16 else c.Height // 2 - 8
	local labelPos: q.State<UDim2> = floated:Compute(function(self)
		if filled then
			return if self:Get() then UDim2.fromOffset(inset, 7) else UDim2.fromOffset(inset, restY)
		end
		return if self:Get() then UDim2.fromOffset(12, -9) else UDim2.fromOffset(inset - 4, restY)
	end)
	local labelSize: q.State<number> = floated:Compute(function(self)
		return if self:Get() then 12 else 16
	end)
	local notchColor: Color3 | q.State<Color3> = props.NotchColor or c.Theme.Color.Surface
	local notchTransparency: q.State<number> = floated:Compute(function(self)
		return if self:Get() then 0 else 1
	end)
	return D.TextLabel {
		Name = "Label",
		bodyLarge,
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		Position = labelPos:Apply(Style.animation()),
		TextSize = labelSize:Apply(Style.animation()),
		BackgroundColor3 = notchColor,
		BackgroundTransparency = if filled then 1 else notchTransparency:Apply(Style.animation()),
		BorderSizePixel = 0,
		LineHeight = 1, -- one line: the box is exactly the text size (see restY)
		Text = Util.asStringState(props.Label),
		TextColor3 = c.Colors.Label,
		TextTransparency = c.ContentTransparency,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = false,
		if filled then q.None else D.UIPadding { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) },
	}
end

export type Seats = {
	Hook: any, -- the Interaction hook (array part)
	Selectable: (boolean | q.State<boolean>)?,
	Row: Instance,
	Label: Instance?,
	Leading: Instance?,
	Trailing: Instance?,
	ErrorMark: Instance?,
}

local function container(c: Ctx.Ctx, seats: Seats): Frame
	local R = c.Theme.Raw
	local disabled = c.Disabled
	local height = c.Height
	local filled = c.Filled
	local thickness: q.State<number> = c.Focused:Compute(function(self)
		return if self:Get() then 2 else 1
	end)
	local fillColor = Style.disabledPick(disabled, R.SurfaceContainerHighest, R.OnSurface)
	local fillTransparency = Style.disabledNumber(disabled, 0, DisabledFillTransparency)

	local layer: Instance? = nil
	local indicator: Instance? = nil
	local stroke: Instance? = nil
	if filled then
		layer = StateLayer.new({
			Color = c.Theme.Color.OnSurface,
			Corner = Corner,
			Hovered = c.Hovered,
			Pressed = q.Source(false),
			Focused = q.Source(false),
			Disabled = disabled,
		})
		local indicatorHeight: q.State<UDim2> = thickness:Compute(function(self)
			return UDim2.new(1, 0, 0, self:Get())
		end)
		indicator = D.Frame {
			Name = "Indicator",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = indicatorHeight:Apply(Style.animation()),
			BackgroundColor3 = c.Colors.Line,
			BackgroundTransparency = Style.disabledNumber(disabled, 0, DisabledIndicatorTransparency),
			BorderSizePixel = 0,
		}
	else
		stroke = D.UIStroke {
			Name = "Outline",
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = thickness:Apply(Style.animation()),
			Color = c.Colors.Line,
			Transparency = Style.disabledNumber(disabled, 0, DisabledOutlineTransparency),
		}
	end

	-- Filled: M3 rounds only the TOP corners. UICorner rounds all four, so the rounded fill is drawn Corner px taller than
	-- its clipping parent (the Container) and the rounded bottom is cut away (the Tabs indicator trick). The state layer
	-- lives inside the fill so it is cut the same way. Outlined keeps one UICorner + UIStroke on the Container itself.
	local fill: Instance? = nil
	if filled then
		fill = D.Frame {
			Name = "Fill",
			Size = UDim2.new(1, 0, 0, height + Corner.Offset),
			BackgroundColor3 = fillColor,
			BackgroundTransparency = fillTransparency,
			BorderSizePixel = 0,
			UICorner = Corner,
			layer or q.None,
		}
	end
	return D.Frame {
		Name = "Container",
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = filled,
		LayoutOrder = 1,
		Selectable = seats.Selectable,
		seats.Hook,
		UICorner = if filled then nil else Corner,
		stroke or q.None,
		fill or q.None,
		indicator or q.None,
		seats.Row,
		seats.Label or q.None,
		seats.Leading or q.None,
		seats.Trailing or q.None,
		seats.ErrorMark or q.None,
	}
end

return { label = label, container = container }
