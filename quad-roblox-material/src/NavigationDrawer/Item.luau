--!strict
--[[
	Navigation drawer content: the destination row, the section headline, the divider, and the data-driven list of them.

	NavigationDrawerItem — Compose material3 `NavigationDrawerItem` (androidx/androidx@40ff481 compose/material3/material3/src/
	commonMain/kotlin/androidx/compose/material3/NavigationDrawer.kt 1122-1244; tokens/NavigationDrawerTokens.kt):
	    Material.NavigationDrawerItem({ Label = "Inbox", Icon = "rbxassetid://…", Badge = "24", Selected = isInbox, OnClick = go })
	  Props (`read`): Label (string | State<string>, required), Icon (icon prop — Icons.resolve; or a State<string> image)?,
	  Badge (string | State<string>)?, Selected (boolean | State<boolean>)?, OnClick (() -> ())?, LayoutOrder, Theme,
	  Modifier (TextButton), Hooks.
	  Geometry: 56 tall (ActiveIndicatorHeight; `heightIn(min = 56)`), as wide as the drawer minus 12 on each side
	  (NavigationDrawerItemDefaults.ItemPadding, 1243 — Compose's samples pass it as the item's modifier; the item spans
	  336 of the 360 drawer = ActiveIndicatorWidth), the whole row is the pill indicator (ActiveIndicatorShape CornerFull),
	  content padded 16 / 24 (start / end, 1147), icon 24 (IconSize) then 12, the label (LabelLarge, weight 1, one line), then
	  12 + the badge (LargeBadgeLabelFont LabelLarge).
	  Colors (NavigationDrawerItemDefaults.colors, 1218-1237): selected container secondaryContainer, icon / label / badge
	  onSecondaryContainer; unselected container transparent, icon / label / badge onSurfaceVariant. State layer: the
	  container's content color — onSecondaryContainer when selected, onSurface (the drawer's content color) otherwise
	  (the tokens' Active*/Inactive* state-layer colors). There is no disabled item in Compose (no `enabled` parameter), so
	  this row has no `Disabled`.
	  Instances: TextButton + UICorner + state layer 3 + Content (UIPadding + UIListLayout) + Label (+ UIFlexItem) = 10;
	  + Icon 1, + Badge 1. The state layer is a direct child of the button (Interactive's rule); the ripple stays inside the
	  fixed 56 px row (Ripple.luau "BOUNDED").

	NavigationDrawerHeadline({ Text, LayoutOrder, Theme, Modifier, Hooks }) — a section headline. Compose has none; MDC
	NavigationView's subheader (material-components-android@60ff094 lib/java/com/google/android/material/internal/res/layout/
	design_navigation_item_subheader.xml: `listPreferredItemHeightSmall` = 48 — appcompat abc_list_item_height_small_material;
	navigation/res/values/styles.xml 58-59, 80-81 + dimens.xml 44: TitleSmall onSurfaceVariant — the tokens'
	HeadlineFont / HeadlineColor — inset 28 on both sides). A TextLabel + UIPadding (2 instances).
	NavigationDrawerDivider({ LayoutOrder, Theme, Modifier, Hooks }) — MDC's separator (design_navigation_item_separator.xml:
	1 px of `listDivider`, which ThemeOverlay.Material3.NavigationView sets to colorOutline, styles.xml 89-90; inset 28 /
	28 — m3_navigation_menu_divider_horizontal_padding, dimens.xml 43; 8 above and below — design_navigation_separator_
	vertical_padding, NavigationMenuPresenter 116-117 / 772). Host + UIPadding + Line (3 instances).

	NavigationDrawerItems<<K>>({ Items, Selected, OnChange, OnClick, Theme, Modifier, Hooks }) — the drawer's content from
	data, with ONE selection like `Tabs`: `Selected: Source<K>`; a click selects that key (Navigation/Destination.luau rule:
	`OnChange` only when the selection changed, `OnClick` on every click). Items are
	  { Key, Label, Icon?, Badge? }   a destination (Navigation.Destination<K>)
	  { Headline = "…" }             a section headline
	  "divider"                       a divider
	Returns a transparent Frame (full width, AutomaticSize Y, a centered vertical list) — put it in a drawer sheet's
	`Children`. Built once from the array (static, like Menu items).
]]

local q = require("../Quad")
local Tokens = require("../Tokens")
local Theme = require("../Theme")
local Util = require("../Util")
local Text = require("../Text")
local Interactive = require("../Interactive")
local IconView = require("../IconView")
local Style = require("../Button/Style")
local Destination = require("../Navigation/Destination")
local D = q.Declaration

export type ItemProps = {
	read Label: string | q.State<string>,
	read Icon: (string | q.State<string>)?,
	read Badge: (string | q.State<string>)?,
	read Selected: (boolean | q.State<boolean>)?,
	read OnClick: (() -> ())?,
	read LayoutOrder: (number | q.State<number>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.TextButtonModifier?,
	read Hooks: Util.Hooks?,
}

export type HeadlineProps = {
	read Text: string | q.State<string>,
	read LayoutOrder: (number | q.State<number>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.TextLabelModifier?,
	read Hooks: Util.Hooks?,
}

export type DividerProps = {
	read LayoutOrder: (number | q.State<number>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

export type Entry<K> = Destination.Destination<K> | { read Headline: string | q.State<string> } | "divider"

export type ItemsProps<K> = {
	read Items: { Entry<K> },
	read Selected: q.Source<K>,
	read OnChange: ((key: K) -> ())?,
	read OnClick: ((key: K) -> ())?,
	read LayoutOrder: (number | q.State<number>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

local HEIGHT = 56 -- NavigationDrawerTokens.ActiveIndicatorHeight
local ITEM_PADDING = 12 -- NavigationDrawerItemDefaults.ItemPadding (horizontal)
local ICON = 24 -- NavigationDrawerTokens.IconSize
local HEADLINE_HEIGHT = 48 -- listPreferredItemHeightSmall
local INSET = 28 -- m3_navigation_menu_headline / divider_horizontal_padding

local headlineBase = D.Modifier.TextLabel():Size(UDim2.new(1, 0, 0, HEADLINE_HEIGHT))
local dividerBase = D.Modifier.Frame():Size(UDim2.new(1, 0, 0, 1 + 2 * 8))
local itemsBase = D.Modifier.Frame():Size(UDim2.fromScale(1, 0)):AutomaticSize(Enum.AutomaticSize.Y)

local labelStyle = Text.Label("LabelLarge")
local headlineStyle = Text.Label("TitleSmall")

local itemBase = D.Modifier.TextButton()
	:Size(UDim2.new(1, -2 * ITEM_PADDING, 0, HEIGHT))
	:BorderSizePixel(0)
	:AutoButtonColor(false)
	:Text("")

local function NavigationDrawerItem(props: ItemProps): TextButton
	local theme = Theme.resolve(props.Theme)
	local R = theme.Raw
	local selected = Util.asState(props.Selected)
	local contentColor = Style.animated(Style.choose(selected, R.OnSecondaryContainer, R.OnSurfaceVariant))
	local layerColor = Style.animated(Style.choose(selected, R.OnSecondaryContainer, R.OnSurface))
	local corner = Tokens.Shape.corner("Full")
	local fx = Interactive.new({ Theme = theme, OnColor = layerColor, Corner = corner })
	local containerTransparency: q.State<number> = Style.select(selected, 0, 1)

	local icon: Instance? = nil
	if props.Icon ~= nil then
		icon = IconView.new({ Name = "Icon", Icon = props.Icon, Size = ICON, Color = contentColor, LayoutOrder = 1 })
	end
	local badge: Instance? = nil
	if props.Badge ~= nil then
		badge = D.TextLabel {
			Name = "Badge",
			labelStyle,
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = props.Badge,
			TextColor3 = contentColor,
			LayoutOrder = 3,
		}
	end

	return D.TextButton {
		Name = "NavigationDrawerItem",
		itemBase,
		props.Modifier or q.None,
		fx.Hook,
		BackgroundColor3 = theme.Color.SecondaryContainer,
		BackgroundTransparency = containerTransparency:Apply(Style.animation()),
		LayoutOrder = props.LayoutOrder,
		UICorner = corner,
		Activated = function()
			if props.OnClick then
				props.OnClick()
			end
		end,
		fx.Layer,
		D.Frame {
			Name = "Content",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			D.UIPadding { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 24) },
			D.UIListLayout {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 12),
			},
			icon or q.None,
			D.TextLabel {
				Name = "Label",
				labelStyle,
				Size = UDim2.fromScale(0, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = props.Label,
				TextColor3 = contentColor,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				LayoutOrder = 2,
				D.UIFlexItem { FlexMode = Enum.UIFlexMode.Fill },
			},
			badge or q.None,
		},
		table.unpack(Util.hooks(props.Hooks)),
	}
end

local function NavigationDrawerHeadline(props: HeadlineProps): TextLabel
	local theme = Theme.resolve(props.Theme)
	return D.TextLabel {
		Name = "NavigationDrawerHeadline",
		headlineStyle,
		headlineBase,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = props.Text,
		TextColor3 = theme.Color.OnSurfaceVariant,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = props.LayoutOrder,
		props.Modifier or q.None,
		D.UIPadding { PaddingLeft = UDim.new(0, INSET), PaddingRight = UDim.new(0, INSET) },
		table.unpack(Util.hooks(props.Hooks)),
	}
end

local function NavigationDrawerDivider(props: DividerProps?): Frame
	local p: DividerProps = props or {}
	local theme = Theme.resolve(p.Theme)
	return D.Frame {
		Name = "NavigationDrawerDivider",
		dividerBase,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = p.LayoutOrder,
		p.Modifier or q.None,
		D.UIPadding {
			PaddingLeft = UDim.new(0, INSET),
			PaddingRight = UDim.new(0, INSET),
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
		},
		D.Frame {
			Name = "Line",
			Size = UDim2.fromScale(1, 1),
			BorderSizePixel = 0,
			BackgroundColor3 = theme.Color.Outline,
		},
		table.unpack(Util.hooks(p.Hooks)),
	}
end

local function NavigationDrawerItems<K>(props: ItemsProps<K>): Frame
	local theme = Theme.resolve(props.Theme)
	local selected = props.Selected
	local rows: { Instance } = {}
	for i, entry in props.Items do
		if entry == "divider" then
			table.insert(rows, NavigationDrawerDivider({ LayoutOrder = i, Theme = theme }))
		elseif type(entry) == "table" and (entry :: any).Headline ~= nil then
			table.insert(rows, NavigationDrawerHeadline({ Text = (entry :: any).Headline, LayoutOrder = i, Theme = theme }))
		else
			local d = entry :: Destination.Destination<K>
			local key = d.Key
			table.insert(
				rows,
				NavigationDrawerItem({
					Label = d.Label,
					Icon = d.Icon,
					Badge = d.Badge,
					Selected = Destination.isSelected(selected, key),
					OnClick = function()
						Destination.click(selected, key, props.OnChange, props.OnClick)
					end,
					LayoutOrder = i,
					Theme = theme,
				})
			)
		end
	end
	return D.Frame {
		Name = "NavigationDrawerItems",
		itemsBase,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = props.LayoutOrder,
		props.Modifier or q.None,
		D.UIListLayout {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
		q.Slot<<Instance>>(rows),
		table.unpack(Util.hooks(props.Hooks)),
	}
end

return {
	NavigationDrawerItem = NavigationDrawerItem,
	NavigationDrawerHeadline = NavigationDrawerHeadline,
	NavigationDrawerDivider = NavigationDrawerDivider,
	NavigationDrawerItems = NavigationDrawerItems,
}
