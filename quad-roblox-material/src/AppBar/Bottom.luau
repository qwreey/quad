--!strict
--[[
	M3 bottom app bar and docked toolbar — Compose material3 `BottomAppBar` (the actions + FAB form) and `FlexibleBottomAppBar`
	(androidx/androidx@40ff481 compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/AppBar.kt
	1077-1112, 1194-1216, 1286-1389, 2308-2362 BottomAppBarDefaults, 2650-2656 the paddings; tokens BottomAppBarTokens.kt,
	DockedToolbarTokens.kt). MDC calls the flexible one the DOCKED TOOLBAR and recommends it over the bottom app bar
	(material-components/material-components-android@60ff094 docs/components/BottomAppBar.md 45-62, DockedToolbar.md); the
	kit keeps Compose's names.

	    Material.BottomAppBar({
	        Actions = { { Icon = "rbxassetid://…", Label = "Search", OnClick = search }, … },
	        FloatingActionButton = { Icon = "rbxassetid://…", OnClick = compose },
	    })
	    Material.FlexibleBottomAppBar({ Actions = { … } })                       -- the docked toolbar

	BottomAppBar props (`read`): Actions ({ AppBarAction | Instance }?), FloatingActionButton ({ Icon, OnClick }? — a kit FAB
	  in bottomAppBarFabColor = secondaryContainer), Overlay, LayoutOrder, Theme, Modifier (Frame), Hooks.
	  Geometry: full width, 80 high (BottomAppBarTokens.ContainerHeight), surfaceContainer, no shadow
	  (BottomAppBarDefaults.ContainerElevation = 0). Content padding 4 start / 4 top / 4 end (16 - 12: the icon buttons' own
	  touch-target margin); the actions start at 4, centered in the padded height; the FAB 12 below the top and 16 from the
	  end (FABVerticalPadding / FABHorizontalPadding). Icons in the bar's content color onSurface (contentColorFor
	  (surfaceContainer)). The kit FAB keeps its own shadow (Compose's sample passes bottomAppBarFabElevation = 0).
	FlexibleBottomAppBar props (`read`): Actions ({ AppBarAction | Instance }), HorizontalArrangement (("SpaceBetween" |
	  "Fixed")? — BottomAppBarDefaults.FlexibleHorizontalArrangement = SpaceBetween (default) / FlexibleFixedHorizontal
	  Arrangement = 32 apart around the center), ExpandedHeight (number?, default 64 — DockedToolbarTokens.ContainerHeight),
	  Overlay, LayoutOrder, Theme, Modifier (Frame), Hooks. Surface container, rectangle, no shadow (tonalElevation Level0),
	  16 start / end padding (FlexibleContentPadding), icons onSurface.
	Not here: BottomAppBarScrollBehavior (exitAlways) — the bars do not hide on scroll.
	Instances: BottomAppBar = Frame + Actions holder (Frame + UIListLayout) + the actions + the FAB (7);
	FlexibleBottomAppBar = Frame + Row (+ UIPadding + UIListLayout) + the actions.
]]

local q = require("../Quad")
local Theme = require("../Theme")
local Util = require("../Util")
local Icons = require("../Icons")
local FAB = require("../Button/FAB")
local Overlay = require("../Overlay")
local Actions = require("./Actions")
local D = q.Declaration

export type Fab = {
	read Icon: string,
	read OnClick: (() -> ())?,
}

export type BottomProps = {
	read Actions: { Actions.Entry }?,
	read FloatingActionButton: Fab?,
	read Overlay: Overlay.Overlay?,
	read LayoutOrder: (number | q.State<number>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

export type Arrangement = "SpaceBetween" | "Fixed"

export type FlexibleProps = {
	read Actions: { Actions.Entry },
	read HorizontalArrangement: Arrangement?,
	read ExpandedHeight: number?,
	read Overlay: Overlay.Overlay?,
	read LayoutOrder: (number | q.State<number>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

local HEIGHT = 80 -- BottomAppBarTokens.ContainerHeight
local PAD = 4 -- BottomAppBarHorizontalPadding / VerticalPadding (16 - 12)
local FAB_TOP = PAD + 8 -- + FABVerticalPadding (12 - 4)
local FAB_END = PAD + 12 -- + FABHorizontalPadding (16 - 4)
local FLEX_HEIGHT = 64 -- DockedToolbarTokens.ContainerHeight
local FLEX_PAD = 16 -- ContainerLeadingSpace / TrailingSpace
local FIXED_GAP = 32 -- ContainerMaxSpacing

local bottomBase = D.Modifier.Frame():Size(UDim2.new(1, 0, 0, HEIGHT))

local function BottomAppBar(props: BottomProps): Frame
	local theme = Theme.resolve(props.Theme)
	local holder: Instance? = nil
	if props.Actions ~= nil and #props.Actions > 0 then
		local list, width = Actions.build(props.Actions, { Theme = theme, Color = theme.Raw.OnSurface, Overlay = props.Overlay })
		holder = D.Frame {
			Name = "Actions",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromOffset(PAD, PAD + (HEIGHT - PAD) / 2),
			Size = UDim2.fromOffset(width, Actions.SIZE),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			D.UIListLayout {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			},
			q.Slot<<Instance>>(list),
		}
	end
	local fab: Instance? = nil
	local spec = props.FloatingActionButton
	if spec ~= nil then
		fab = FAB({
			Icon = Icons.imageOf(spec.Icon),
			Color = "Secondary",
			Theme = theme,
			OnClick = spec.OnClick,
			Modifier = D.Modifier.TextButton():AnchorPoint(Vector2.new(1, 0)):Position(UDim2.new(1, -FAB_END, 0, FAB_TOP)),
		})
	end
	return D.Frame {
		Name = "BottomAppBar",
		bottomBase,
		BackgroundColor3 = theme.Color.SurfaceContainer,
		BorderSizePixel = 0,
		LayoutOrder = props.LayoutOrder,
		props.Modifier or q.None,
		holder or q.None,
		fab or q.None,
		table.unpack(Util.hooks(props.Hooks)),
	}
end

local function FlexibleBottomAppBar(props: FlexibleProps): Frame
	local theme = Theme.resolve(props.Theme)
	local fixed = props.HorizontalArrangement == "Fixed"
	local height = props.ExpandedHeight
	if height == nil or height <= 0 then
		height = FLEX_HEIGHT
	end
	local list = Actions.build(props.Actions, { Theme = theme, Color = theme.Raw.OnSurface, Overlay = props.Overlay })
	return D.Frame {
		Name = "FlexibleBottomAppBar",
		D.Modifier.Frame():Size(UDim2.new(1, 0, 0, height :: number)),
		BackgroundColor3 = theme.Color.SurfaceContainer,
		BorderSizePixel = 0,
		LayoutOrder = props.LayoutOrder,
		props.Modifier or q.None,
		D.Frame {
			Name = "Row",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			D.UIPadding { PaddingLeft = UDim.new(0, FLEX_PAD), PaddingRight = UDim.new(0, FLEX_PAD) },
			D.UIListLayout {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalAlignment = if fixed then Enum.HorizontalAlignment.Center else Enum.HorizontalAlignment.Left,
				HorizontalFlex = if fixed then Enum.UIFlexAlignment.None else Enum.UIFlexAlignment.SpaceBetween,
				Padding = UDim.new(0, if fixed then FIXED_GAP else 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
			},
			q.Slot<<Instance>>(list),
		},
		table.unpack(Util.hooks(props.Hooks)),
	}
end

return {
	BottomAppBar = BottomAppBar,
	FlexibleBottomAppBar = FlexibleBottomAppBar,
}
