--!strict
--[[
	M3 navigation rail — Compose material3 `WideNavigationRail` + `WideNavigationRailItem` (androidx/androidx@40ff481
	compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/WideNavigationRail.kt 162-527 / 979-1021 /
	1229-1466 / 1673-1711, the item layout NavigationItem.kt 439-553 / 879-993 / 1145-1241; tokens
	NavigationRailCollapsedTokens.kt, NavigationRailExpandedTokens.kt, NavigationRailBaselineItemTokens.kt,
	NavigationRailVerticalItemTokens.kt, NavigationRailHorizontalItemTokens.kt, NavigationRailColorTokens.kt). The M3
	Expressive rail: collapsed (the original rail, now 96 wide) and expanded (it "replaces the navigation drawer" —
	material-components/material-components-android@60ff094 docs/components/NavigationRail.md 46-104); Compose's baseline
	`NavigationRail` (80 wide) is not in the kit.

	    local rail = Material.WideNavigationRailState()
	    local page = q.Source("home")
	    Material.WideNavigationRail<<string>>({
	        State = rail,
	        Header = Material.IconButton({ Icon = Material.Icons.asset("menu") or "", TouchTarget = true, OnClick = rail.Toggle,
	            Modifier = q.Declaration.Modifier.TextButton():Position(UDim2.fromOffset(24, 0)) }),
	        Selected = page,
	        Items = { { Key = "home", Label = "Home", Icon = "rbxassetid://…" }, { Key = "search", Label = "Search", Icon = "…" } },
	    })

	Props (`read`):
	  Items, Selected, OnChange, OnClick   the destination model and the Tabs selection rule (as ShortNavigationBar)
	  State        WideNavigationRailState?        default a fresh Collapsed one (rememberWideNavigationRailState)
	  Header       Instance?                       Compose `header` — a menu button, a FAB or a logo, placed at the top-left of
	                                               the content (the samples offset a menu IconButton by 24 so it centers on the
	                                               collapsed rail); its height is its `Size.Y.Offset` (48 when it has none)
	  Arrangement  ("Top" | "Center" | "Bottom")?  the items' vertical arrangement, default Top (WideNavigationRailDefaults.
	                                               arrangement); Center centers on the whole rail height (WideNavigationRailLayout
	                                               490-517), the header stays at the top
	  LayoutOrder, Theme, Modifier (Frame), Hooks
	Returns the rail Frame: the parent's height (`fillMaxHeight`), surface (NavigationRailCollapsedTokens.ContainerColor), no
	shadow, rectangle; clips its content (a Surface clips to its shape).

	GEOMETRY (all of it follows ONE expanded progress p, 0 collapsed .. 1 expanded — Compose animates the rail width, the item
	spacing / height and every item's `iconPositionProgress` with the same DefaultSpatial spring; the kit: Navigation/
	Motion.luau, Short4 0.2 s):
	  rail width   collapsed 96 (ContainerWidth), expanded = the widest item + 20, clamped to 220..360 (ContainerWidthMinimum /
	               Maximum; 460-475); in between the linear blend
	  content      44 from the top (WNRTopPadding = TopSpace); the header, then 40 (HeaderSpaceMinimum) before the items
	  items        64 high and 4 apart collapsed (TopIconItemMinHeight, ItemVerticalSpace); expanded 56 high (the 56 indicator) and
	               0 apart; the item's content is centered in its height
	  item         its content starts 20 from the rail's start edge (WNRItemHorizontalPadding). Collapsed (icon on top): the
	               56 x 32 pill (16 / 4 around the icon), 4 below it the label (LabelMedium) centered on the 96 rail.
	               Expanded (icon at the start): a 56 high pill 16 + icon + 8 (NavigationRailHorizontalItemTokens.IconLabelSpace) +
	               label (LabelLarge) + 16. Between, every size and offset is Compose's lerp (placeAnimatedLabelAndIcon): the
	               label fades out and back in (alpha 4 (p - 1/2)^2) and jumps to its new place and style at p = 1/2
	  indicator    grows from its START edge (x = 20, placeAnimatedLabelAndIcon places it there in both forms) with its alpha,
	               on the selection progress (Short4)
	Colors (WideNavigationRailItemDefaults.colors 1441-1465): icon onSecondaryContainer / onSurfaceVariant (not animated),
	label secondary (icon on top) / onSecondaryContainer (icon at the start) / onSurfaceVariant — the rail item's label color
	IS animated (AnimatedNavigationItem `animateColor = true`, Short4); indicator secondaryContainer; state layer onSurface
	(the rail's content color, read by `ripple()`), over the full pill.
	The item's click target is the item box: 96 wide collapsed, 20 + the pill expanded.
	Instances: rail Frame + per item 9 (TextButton + Indicator + UICorner + Icon + Label + Target + state layer 3; a badge adds
	the IconBox + the badge) + the header holder (1 + the header). Motion: one Heartbeat connection per animating progress
	(the rail's while it expands / collapses, an item's while its indicator grows), none at rest.
	Not here: ModalWideNavigationRail, a disabled item, the badge rulers.
]]

local q = require("./Quad")
local Tokens = require("./Tokens")
local Theme = require("./Theme")
local Util = require("./Util")
local Typography = require("./Tokens/Typography")
local Interactive = require("./Interactive")
local Style = require("./Button/Style")
local Destination = require("./Navigation/Destination")
local Item = require("./Navigation/Item")
local Motion = require("./Navigation/Motion")
local StateModule = require("@self/State")
local D = q.Declaration
local railName = D.Modifier.Frame():Name("WideNavigationRail")

export type Arrangement = "Top" | "Center" | "Bottom"
export type Value = StateModule.Value
export type WideNavigationRailState = StateModule.WideNavigationRailState
export type StateOptions = StateModule.Options

export type Props<K> = {
	read Items: { Destination.Destination<K> },
	read Selected: q.Source<K>,
	read OnChange: ((key: K) -> ())?,
	read OnClick: ((key: K) -> ())?,
	read State: WideNavigationRailState?,
	read Header: Instance?,
	read Arrangement: Arrangement?,
	read LayoutOrder: (number | q.State<number>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

local ICON = Item.ICON
local COLLAPSED_W = 96 -- NavigationRailCollapsedTokens.ContainerWidth
local EXPANDED_MIN = 220 -- NavigationRailExpandedTokens.ContainerWidthMinimum
local EXPANDED_MAX = 360 -- NavigationRailExpandedTokens.ContainerWidthMaximum
local TOP = 44 -- WNRTopPadding
local HEADER_GAP = 40 -- WNRHeaderPadding
local ITEM_PAD = 20 -- WNRItemHorizontalPadding
local SIDE = 16 -- indicator horizontal padding (both forms)
local TOP_V = 4 -- (32 - 24) / 2
local START_V = 16 -- (56 - 24) / 2
local LABEL_GAP = 4 -- NavigationRailVerticalItemTokens.IconLabelSpace
local START_GAP = 8 -- NavigationRailHorizontalItemTokens.IconLabelSpace
local TOP_LABEL_H = 16 -- LabelMedium
local START_LABEL_H = 20 -- LabelLarge
local TOP_MIN_H = 64 -- NavigationRailBaselineItemTokens.ContainerHeight
local A11Y_MIN = 48 -- LocalMinimumInteractiveComponentSize
local SPACING = 4 -- NavigationRailCollapsedTokens.ItemVerticalSpace

local railBase = D.Modifier.Frame():Size(UDim2.new(0, COLLAPSED_W, 1, 0))

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- the measured height of a header instance
local function heightOf(inst: Instance): number
	local ok, size = pcall(function(): UDim2
		return (inst :: any).Size
	end)
	if ok and typeof(size) == "UDim2" and size.Y.Offset > 0 then
		return size.Y.Offset
	end
	return A11Y_MIN
end

-- per-progress geometry of one item (placeAnimatedLabelAndIcon), from p and the label's measured width
type Geo = {
	ItemW: number,
	ItemH: number,
	OffY: number,
	PillW: number,
	PillH: number,
	IconY: number,
	LabelX: number,
	LabelY: number,
	LabelStart: boolean,
	LabelAlpha: number,
}

local function geometry(p: number, labelW: number, toStart: boolean): Geo
	local contentTop = TOP_V + ICON + TOP_V + LABEL_GAP + TOP_LABEL_H -- 52
	local contentStart = START_V + ICON + START_V -- 56
	local contentH = lerp(contentTop, contentStart, p)
	local itemH = math.max(contentH, lerp(TOP_MIN_H, A11Y_MIN, p))
	local offY = (itemH - contentH) / 2
	local pillW = lerp(ICON, ICON + START_GAP + labelW, p) + 2 * SIDE
	local padTop = lerp(TOP_V, START_V, p)
	local iconYStart = (contentH - ICON) / 2 - padTop
	local iconY = lerp(0, iconYStart, p) + padTop
	local itemW = lerp(COLLAPSED_W, ITEM_PAD + pillW, p)
	local labelStart = p >= 0.5
	local labelX, labelY
	if labelStart then
		local shift = if not toStart and p > 0 then 0 else ITEM_PAD * (1 - p)
		labelX = (ITEM_PAD + SIDE + ICON + START_GAP - shift) * p
		labelY = (contentH - START_LABEL_H) / 2
	else
		labelX = (ICON + 2 * SIDE + 2 * ITEM_PAD - labelW) / 2
		labelY = iconY + ICON + padTop + LABEL_GAP
	end
	return {
		ItemW = itemW,
		ItemH = itemH,
		OffY = offY,
		PillW = pillW,
		PillH = lerp(TOP_V * 2 + ICON, contentStart, p),
		IconY = iconY,
		LabelX = labelX,
		LabelY = labelY,
		LabelStart = labelStart,
		LabelAlpha = 4 * (p - 0.5) * (p - 0.5),
	}
end

local function WideNavigationRail<K>(props: Props<K>): Frame
	local theme = Theme.resolve(props.Theme)
	local R = theme.Raw
	local state = props.State or StateModule.WideNavigationRailState()
	local rec = StateModule.recOf(state)
	rec.Driven += 1
	local selected = props.Selected
	local items = props.Items
	local n = #items
	local arrangement: Arrangement = props.Arrangement or "Top"
	local corner = Tokens.Shape.corner("Full")
	local duration = Tokens.Motion.Duration.Short4

	local expanded: q.State<boolean> = rec.Target:Compute(function(self)
		return self:Get() == "Expanded"
	end)
	local p, railMotion = Motion.progress(expanded, duration, {
		Snap = rec.Snap,
		OnSettle = function(atOne: boolean)
			rec.Current:SetIfChanged(if atOne then "Expanded" else "Collapsed")
		end,
	})

	-- measured label widths (the expanded rail is as wide as its widest item); `widths` bumps when one changes
	local labelWidths: { number } = table.create(n, 0)
	local widths = q.Source(0)
	local railWidth: q.State<number> = p:Compute(function(self, _prev, _ver)
		local widest = 0
		for _, w in labelWidths do
			widest = math.max(widest, ITEM_PAD + ICON + START_GAP + w + 2 * SIDE)
		end
		local full = math.clamp(widest + ITEM_PAD, EXPANDED_MIN, EXPANDED_MAX)
		return lerp(COLLAPSED_W, full, self:Get())
	end, widths)

	local header = props.Header
	local headerOffset = if header ~= nil then heightOf(header) + HEADER_GAP else 0
	local itemsTop = TOP + headerOffset

	local function item(dest: Destination.Destination<K>, index: number): Instance
		local key = dest.Key
		local isSel = Destination.isSelected(selected, key)
		local sel, selMotion = Motion.progress(isSel, duration)
		local labelWidth = q.Source(0)
		local measure = q.OnChange("AbsoluteSize", function(v: Vector2)
			if labelWidth:Get() ~= v.X then
				labelWidth:Set(v.X)
				labelWidths[index] = v.X
				widths:Set(widths:Get() + 1)
			end
		end)
		local geo: q.State<Geo> = p:Compute(function(self, _prev, w, target)
			return geometry(self:Get(), w:Get(), target:Get())
		end, labelWidth, expanded)

		local position: q.State<UDim2> = geo:Compute(function(self, _prev, pr)
			local g = self:Get()
			local step = (index - 1) * (g.ItemH + lerp(SPACING, 0, pr:Get()))
			if arrangement == "Center" then
				local total = n * g.ItemH + (n - 1) * lerp(SPACING, 0, pr:Get())
				return UDim2.new(0, 0, 0.5, math.round(-total / 2 + step))
			elseif arrangement == "Bottom" then
				local total = n * g.ItemH + (n - 1) * lerp(SPACING, 0, pr:Get())
				return UDim2.new(0, 0, 1, math.round(-total + step))
			end
			return UDim2.fromOffset(0, math.round(itemsTop + step))
		end, p)
		local size: q.State<UDim2> = geo:Compute(function(self)
			local g = self:Get()
			return UDim2.fromOffset(math.round(g.ItemW), math.round(g.ItemH))
		end)
		local indicatorSize: q.State<UDim2> = geo:Compute(function(self, _prev, s)
			local g = self:Get()
			return UDim2.fromOffset(math.round(g.PillW * s:Get()), math.round(g.PillH))
		end, sel)
		local pillPosition: q.State<UDim2> = geo:Compute(function(self)
			return UDim2.fromOffset(ITEM_PAD, math.round(self:Get().OffY))
		end)
		local pillSize: q.State<UDim2> = geo:Compute(function(self)
			local g = self:Get()
			return UDim2.fromOffset(math.round(g.PillW), math.round(g.PillH))
		end)
		local indicatorTransparency: q.State<number> = sel:Compute(function(self)
			return 1 - self:Get()
		end)
		local iconPosition: q.State<UDim2> = geo:Compute(function(self)
			local g = self:Get()
			return UDim2.fromOffset(ITEM_PAD + SIDE, math.round(g.OffY + g.IconY))
		end)
		local labelPosition: q.State<UDim2> = geo:Compute(function(self)
			local g = self:Get()
			return UDim2.fromOffset(math.round(g.LabelX), math.round(g.OffY + g.LabelY))
		end)
		local labelTransparency: q.State<number> = geo:Compute(function(self)
			return 1 - math.min(self:Get().LabelAlpha, 1)
		end)
		local labelStart: q.State<boolean> = geo:Compute(function(self)
			return self:Get().LabelStart
		end)
		local labelFont: q.State<Font> = labelStart:Compute(function(self)
			return Typography.font(if self:Get() then "LabelLarge" else "LabelMedium")
		end)
		local labelSize: q.State<number> = labelStart:Compute(function(self)
			return if self:Get() then Typography.Scale.LabelLarge.Size else Typography.Scale.LabelMedium.Size
		end)
		local labelLine: q.State<number> = labelStart:Compute(function(self)
			return Typography.lineHeightScale(if self:Get() then "LabelLarge" else "LabelMedium")
		end)
		local labelHeight: q.State<UDim2> = labelStart:Compute(function(self)
			return UDim2.fromOffset(0, if self:Get() then START_LABEL_H else TOP_LABEL_H)
		end)

		local iconColor = Style.choose(isSel, R.OnSecondaryContainer, R.OnSurfaceVariant)
		local selectedLabel = Style.choose(expanded, R.OnSecondaryContainer, R.Secondary)
		local labelColor = Style.animated(Style.choose(isSel, selectedLabel, R.OnSurfaceVariant))
		local fx = Interactive.new({ Theme = theme, OnColor = theme.Color.OnSurface, Corner = corner })

		return D.TextButton {
			Name = "NavigationItem",
			Position = position,
			Size = size,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = index,
			fx.Hook,
			selMotion,
			Activated = function()
				Destination.click(selected, key, props.OnChange, props.OnClick)
			end,
			D.Frame {
				Name = "Indicator",
				Position = pillPosition,
				Size = indicatorSize,
				BackgroundColor3 = theme.Color.SecondaryContainer,
				BackgroundTransparency = indicatorTransparency,
				BorderSizePixel = 0,
				UICorner = corner,
			},
			Item.icon(dest, iconColor, theme, { Position = iconPosition }),
			D.TextLabel {
				Name = "Label",
				FontFace = labelFont,
				TextSize = labelSize,
				LineHeight = labelLine,
				Position = labelPosition,
				Size = labelHeight,
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = dest.Label,
				TextColor3 = labelColor,
				TextTransparency = labelTransparency,
				measure,
			},
			D.Frame {
				Name = "Target",
				Position = pillPosition,
				Size = pillSize,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				fx.Layer,
			},
		}
	end

	local children: { Instance } = {}
	for i, dest in items do
		table.insert(children, item(dest, i))
	end
	local headerHolder: Instance? = nil
	if header ~= nil then
		headerHolder = D.Frame {
			Name = "Header",
			Position = UDim2.fromOffset(0, TOP),
			Size = UDim2.new(1, 0, 0, heightOf(header)),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			header,
		}
	end

	local width: q.State<UDim2> = railWidth:Compute(function(self)
		return UDim2.new(0, math.round(self:Get()), 1, 0)
	end)

	return D.Frame {
		railName,
		railBase:Size(width),
		BackgroundColor3 = theme.Color.Surface,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = props.LayoutOrder,
		props.Modifier or q.None,
		railMotion,
		q.OnDestroyed(function()
			-- the rail is gone: its motion no longer reports the settled value, so hand the state back settled
			rec.Driven -= 1
			if rec.Driven == 0 then
				rec.Current:SetIfChanged(rec.Target:Get())
			end
		end),
		headerHolder or q.None,
		q.Slot<<Instance>>(children),
		table.unpack(Util.hooks(props.Hooks)),
	}
end

return {
	WideNavigationRail = WideNavigationRail,
	WideNavigationRailState = StateModule.WideNavigationRailState,
}
