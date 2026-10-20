--!strict
--[[
	M3 navigation bar — Compose material3 `ShortNavigationBar` + `ShortNavigationBarItem` (androidx/androidx@40ff481
	compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/ShortNavigationBar.kt 97-642, the item
	layout NavigationItem.kt 334-431 / 555-1143; tokens NavigationBarTokens.kt, NavigationBarVerticalItemTokens.kt,
	NavigationBarHorizontalItemTokens.kt). This is the M3 Expressive bar (64 tall) that MDC documents as the current one
	(material-components/material-components-android@60ff094 docs/components/BottomNavigation.md 48-88 "M3 Expressive": height
	80 -> 64, active indicator 64 -> 56, horizontal items on medium windows); Compose's baseline `NavigationBar` (80 tall) is
	not in the kit.

	    local page = q.Source("home")
	    Material.ShortNavigationBar<<string>>({ Selected = page, Items = {
	        { Key = "home", Label = "Home", Icon = "rbxassetid://…" },
	        { Key = "inbox", Label = "Inbox", Icon = "rbxassetid://…", Badge = "8" },
	    } })

	Props (`read`):
	  Items         { NavigationDestination<K> }   { Key, Label, Icon?, Badge? } (Navigation/Destination.luau); built once
	  Selected      Source<K>                      the selected key — the Tabs rule: a click does `SetIfChanged(key)`, then
	                                               `OnChange(key)` if that changed it, then `OnClick(key)` on every click
	  OnChange, OnClick   ((key: K) -> ())?
	  Arrangement   ("EqualWeight" | "Centered")?  ShortNavigationBarArrangement (189-214), default EqualWeight (small windows):
	                                               every item 1/n of the bar. Centered (medium windows): the items share
	                                               60 / 70 / 80 / 90 % of the width for 3 / 4 / 5 / 6 items and are centered
	                                               (calculateCenteredContentHorizontalPadding 600-617); an item whose content
	                                               is wider keeps its content width (the group stays centered). More than six
	                                               items: 1/n each.
	  IconPosition  ("Top" | "Start")?             NavigationItemIconPosition, default Top (icon above the label); Start = the
	                                               icon before the label in one pill (Compose's recommendation for Centered)
	  LayoutOrder, Theme, Modifier (Frame), Hooks
	Returns the bar Frame: full width, 64 tall (NavigationBarTokens.ContainerHeight), surfaceContainer (ContainerColor), no
	shadow (ShortNavigationBar is a Surface without tonal / shadow elevation).

	ITEM, Top (ShortNavigationBarItem 252-302, placeLabelAndTopIcon 1047-1094): 6 above (TopIconItemVerticalPadding =
	ContainerBetweenSpace), the 56 x 32 indicator pill (ActiveIndicatorWidth / Height, CornerFull) with the 24 px icon in it
	(4 above / below, 16 each side), 4 below it (TopIconIndicatorToLabelPadding) the label (LabelMedium), 6 below.
	ITEM, Start (placeLabelAndStartIcon 1107-1143): one 40 high pill (NavigationBarHorizontalItemTokens.ActiveIndicatorHeight)
	centered in the bar, 16 + icon + 4 (ItemActiveIndicatorIconLabelSpace) + label + 16.
	Colors (ShortNavigationBarItemDefaults.colors 462-486): icon onSecondaryContainer when selected, onSurfaceVariant
	otherwise; label secondary when selected (Top) / onSecondaryContainer (Start), onSurfaceVariant otherwise; indicator
	secondaryContainer. NOT animated (NavigationItem `animateColor = false`): the colors switch at once.
	THE INDICATOR animates (animateIndicatorProgressAsState 1267-1272, the DefaultSpatial spring): its width grows from 0 to the
	full pill around the pill's center and its alpha follows the same progress (Indicator 1284-1297); deselecting runs it
	back. The kit drives one progress number per item (Navigation/Motion.luau: Short4 0.2 s, Standard).
	The state layer and ripple cover the full pill, not the whole item (IndicatorRipple 1275-1281: the ripple is clipped to
	the indicator shape at the indicator's full size, drawn above the icon and label); the whole item is the click target.
	The ripple / state layer color is the bar's content color onSurface (Compose's `ripple()` reads LocalContentColor, which
	ShortNavigationBar sets to contentColorFor(surfaceContainer)).
	Badge: on the icon (Navigation/Item.luau — `Badge = ""` a small dot, otherwise the large badge with the text).
	Labels are always shown (ShortNavigationBarItem has no alwaysShowLabel). No disabled item (the destination model has no
	Disabled).
	Instances per item, Top: TextButton + Indicator (+UICorner) + Icon + Label + Target + state layer 3 = 9; Start: the same 9;
	+1 UISizeConstraint with Centered; a badge adds the IconBox + the badge (2 small / 5 large). Bar: Frame + Row + UIListLayout
	= 3. The label's measured width (q.OnChange on its AbsoluteSize, as Tabs) sizes the Start pill and the Centered minimum.
]]

local q = require("./Quad")
local Tokens = require("./Tokens")
local Theme = require("./Theme")
local Util = require("./Util")
local Text = require("./Text")
local Interactive = require("./Interactive")
local Style = require("./Button/Style")
local Destination = require("./Navigation/Destination")
local Item = require("./Navigation/Item")
local Motion = require("./Navigation/Motion")
local Frame = q.Elem "Frame"
local TextButton = q.Elem "TextButton"
local TextLabel = q.Elem "TextLabel"
local UIListLayout = q.Elem "UIListLayout"
local UISizeConstraint = q.Elem "UISizeConstraint"
local FrameModifier = q.Modifier "Frame"
local barName = FrameModifier():Name("ShortNavigationBar")

export type Arrangement = "EqualWeight" | "Centered"
export type IconPosition = "Top" | "Start"

export type Props<K> = {
	read Items: { Destination.Destination<K> },
	read Selected: q.Source<K>,
	read OnChange: ((key: K) -> ())?,
	read OnClick: ((key: K) -> ())?,
	read Arrangement: Arrangement?,
	read IconPosition: IconPosition?,
	read LayoutOrder: (number | q.State<number>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.ModifierInto<Frame>?,
	read Hooks: Util.Hooks?,
}

local HEIGHT = 64 -- NavigationBarTokens.ContainerHeight
local ICON = Item.ICON
local TOP_PAD = 6 -- TopIconItemVerticalPadding
local PILL_W = 56 -- NavigationBarVerticalItemTokens.ActiveIndicatorWidth
local PILL_H = 32 -- NavigationBarVerticalItemTokens.ActiveIndicatorHeight
local LABEL_GAP = 4 -- TopIconIndicatorToLabelPadding
local LABEL_H = 16 -- LabelMedium line height
local START_PILL_H = 40 -- NavigationBarHorizontalItemTokens.ActiveIndicatorHeight
local START_SIDE = 16 -- ActiveIndicatorLeadingSpace / TrailingSpace
local START_GAP = 4 -- NavigationBarTokens.ItemActiveIndicatorIconLabelSpace

local labelStyle = Text.Label("LabelMedium")
local barBase = FrameModifier():Size(UDim2.new(1, 0, 0, HEIGHT))

-- the share of the bar the items take with Centered (calculateCenteredContentHorizontalPadding)
local function centeredShare(n: number): number
	if n > 6 then
		return 1
	end
	return 1 - 2 * ((100 - 10 * (n + 3)) / 2) / 100
end

local function ShortNavigationBar<K>(props: Props<K>): Frame
	local theme = Theme.resolve(props.Theme)
	local R = theme.Raw
	local selected = props.Selected
	local items = props.Items
	local n = #items
	local centered = props.Arrangement == "Centered"
	local start = props.IconPosition == "Start"
	local share = if centered then centeredShare(n) else 1
	local cellWidth = UDim2.new(share / math.max(n, 1), 0, 1, 0)
	local corner = Tokens.Shape.corner("Full")
	local duration = Tokens.Motion.Duration.Short4

	local function cell(dest: Destination.Destination<K>, index: number): Instance
		local key = dest.Key
		local isSel = Destination.isSelected(selected, key)
		local progress, motion = Motion.progress(isSel, duration)
		local iconColor = Style.choose(isSel, R.OnSecondaryContainer, R.OnSurfaceVariant)
		local labelColor = Style.choose(isSel, if start then R.OnSecondaryContainer else R.Secondary, R.OnSurfaceVariant)
		local fx = Interactive.new({ Theme = theme, OnColor = theme.Color.OnSurface, Corner = corner })
		local labelWidth = q.Source(0)
		local measure = q.OnChange "TextLabel" "AbsoluteSize" (function(v: Vector2)
			labelWidth:SetIfChanged(v.X)
		end)

		-- the full pill (the ripple area) and the animated indicator
		local pill: q.State<Vector2> = labelWidth:Compute(function(self)
			if start then
				return Vector2.new(START_SIDE + ICON + START_GAP + self:Get() + START_SIDE, START_PILL_H)
			end
			return Vector2.new(PILL_W, PILL_H)
		end)
		local indicatorSize: q.State<UDim2> = pill:Compute(function(self, _prev, p)
			local full = self:Get()
			return UDim2.fromOffset(math.round(full.X * p:Get()), full.Y)
		end, progress)
		local indicatorTransparency: q.State<number> = progress:Compute(function(self)
			return 1 - self:Get()
		end)
		local pillSize: q.State<UDim2> = pill:Compute(function(self)
			local full = self:Get()
			return UDim2.fromOffset(full.X, full.Y)
		end)
		local pillAnchor = if start then Vector2.new(0.5, 0.5) else Vector2.new(0.5, 0)
		local pillPosition = if start then UDim2.fromScale(0.5, 0.5) else UDim2.new(0.5, 0, 0, TOP_PAD)

		local iconAt: any
		local labelAt: any
		if start then
			-- icon and label centered as one group inside the pill
			iconAt = labelWidth:Compute(function(self)
				return UDim2.new(0.5, -math.round((ICON + START_GAP + self:Get()) / 2), 0.5, 0)
			end)
			labelAt = labelWidth:Compute(function(self)
				return UDim2.new(0.5, -math.round((ICON + START_GAP + self:Get()) / 2) + ICON + START_GAP, 0.5, 0)
			end)
		else
			iconAt = UDim2.new(0.5, 0, 0, TOP_PAD + (PILL_H - ICON) / 2)
			labelAt = UDim2.new(0.5, 0, 0, TOP_PAD + PILL_H + LABEL_GAP)
		end

		-- the Centered minimum width: the item's content (Compose measures the item's max intrinsic width)
		local minWidth: Instance? = nil
		if centered then
			local min: q.State<Vector2> = pill:Compute(function(self, _prev, w)
				local content = if start then self:Get().X else math.max(PILL_W, w:Get())
				return Vector2.new(content, 0)
			end, labelWidth)
			minWidth = UISizeConstraint { MinSize = min }
		end

		return TextButton {
			Name = "NavigationItem",
			Size = cellWidth,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = index,
			fx.Hook,
			motion,
			Activated = function()
				Destination.click(selected, key, props.OnChange, props.OnClick)
			end,
			minWidth or q.None,
			Frame {
				Name = "Indicator",
				AnchorPoint = pillAnchor,
				Position = pillPosition,
				Size = indicatorSize,
				BackgroundColor3 = theme.Color.SecondaryContainer,
				BackgroundTransparency = indicatorTransparency,
				BorderSizePixel = 0,
				UICorner = corner,
			},
			Item.icon(dest, iconColor, theme, {
				AnchorPoint = if start then Vector2.new(0, 0.5) else Vector2.new(0.5, 0),
				Position = iconAt,
			}),
			TextLabel {
				Name = "Label",
				labelStyle,
				AnchorPoint = if start then Vector2.new(0, 0.5) else Vector2.new(0.5, 0),
				Position = labelAt,
				Size = UDim2.fromOffset(0, LABEL_H),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = dest.Label,
				TextColor3 = labelColor,
				measure,
			},
			Frame {
				Name = "Target",
				AnchorPoint = pillAnchor,
				Position = pillPosition,
				Size = pillSize,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				fx.Layer,
			},
		}
	end

	local cells: { Instance } = {}
	for i, dest in items do
		table.insert(cells, cell(dest, i))
	end

	return Frame {
		barName,
		barBase,
		BackgroundColor3 = theme.Color.SurfaceContainer,
		BorderSizePixel = 0,
		LayoutOrder = props.LayoutOrder,
		props.Modifier or q.None,
		Frame {
			Name = "Row",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			UIListLayout {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = if centered then Enum.HorizontalAlignment.Center else Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			},
			q.Slot<<Instance>>(cells),
		},
		table.unpack(Util.hooks(props.Hooks)),
	}
end

return ShortNavigationBar
