--!strict
--[[
	M3 top app bars — Compose material3 `TopAppBar` (with and without subtitle), `CenterAlignedTopAppBar`, `MediumTopAppBar`,
	`MediumFlexibleTopAppBar`, `LargeTopAppBar`, `LargeFlexibleTopAppBar` (androidx/androidx@40ff481 compose/material3/
	material3/src/commonMain/kotlin/androidx/compose/material3/AppBar.kt 235-866 the public functions, 2664-2775
	SingleRowTopAppBar, 2781-2920 TwoRowsTopAppBar, 2961-3257 TopAppBarLayout / TopAppBarMeasurePolicy, 3601-3615 the
	paddings and easings, 1510-1522 the default colors; tokens AppBarTokens.kt, AppBarSmallTokens.kt, AppBarMediumTokens.kt,
	AppBarLargeTokens.kt, AppBarMediumFlexibleTokens.kt, AppBarLargeFlexibleTokens.kt). MDC documents the flexible medium /
	large bars as the ones to use (material-components/material-components-android@60ff094 docs/components/TopAppBar.md
	66-92: "Deprecating medium and large app bars"); Compose still ships all six, and so does the kit.

	    Material.TopAppBar({
	        Title = "Inbox",
	        NavigationIcon = { Icon = "menu", Label = "Menu", OnClick = drawer.Open },
	        Actions = { { Icon = "rbxassetid://…", Label = "Search", OnClick = search } },
	        ScrollBehavior = Material.TopAppBarDefaults.pinnedScrollBehavior(),
	    })

	Props (`read`; one type for the six):
	  Title          string | State<string>        (Compose: a composable — the kit draws text)
	  Subtitle       (string | State<string>)?     TopAppBar, CenterAlignedTopAppBar, Medium/LargeFlexibleTopAppBar
	  TitleHorizontalAlignment ("Start" | "Center")?   TopAppBar and the flexible bars, default Start (CenterAligned = Center;
	                                               Medium / Large always Start, as in Compose)
	  NavigationIcon AppBarAction | Instance?      at the start (AppBar/Actions.luau — data becomes a 48 px icon button)
	  Actions        { AppBarAction | Instance }?  at the end, in order
	  MaxItemCount   number?                       more actions than this -> MaxItemCount - 1 + an overflow menu (AppBarRow)
	  ScrollBehavior TopAppBarScrollBehavior?      AppBar/Scroll.luau (TopAppBarDefaults.*ScrollBehavior)
	  ExpandedHeight number?                       Compose expandedHeight (default per bar, below)
	  CollapsedHeight number?                      two-row bars only, default 64
	  Overlay (for the actions' tooltips and overflow menu), LayoutOrder, Theme, Modifier (Frame), Hooks
	Returns the bar Frame (full width; ClipsDescendants — Compose clips the layout, so collapsing content is cut). The bar
	reports its expanded height and its current height to `Material.Scaffold` (`measureOf` — the Scaffold's content region
	follows the collapsing bar in the same frame, Scaffold.luau).

	COLORS (defaultTopAppBarColors): container surface, scrolled container surfaceContainer, navigation icon onSurface, title
	onSurface, actions onSurfaceVariant, subtitle onSurfaceVariant. No shadow (ContainerElevation Level0).
	SINGLE ROW (TopAppBar 64 / CenterAlignedTopAppBar 64 — AppBarSmallTokens.ContainerHeight): the navigation icon 4 from the
	start (TopAppBarHorizontalPadding), the actions 4 from the end; the title (TitleLarge) starts at max(12, 4 + navigation
	icon) + 4 — 16 with no icon, 56 after a 48 px icon (TopAppBarTitleInset + the title's own 4 padding); centered titles are
	centered on the whole bar (placeTopAppBar 3189-3213 — the kit keeps the centered title inside the room symmetric to the
	wider side instead of shifting it); with a Subtitle the title column (TitleLarge + LabelMedium) is centered vertically.
	Everything is centered on the bar's height, which collapses with the scroll (the content moves up at half the speed,
	clipped).
	TWO ROWS (TwoRowsTopAppBar): a top row as high as CollapsedHeight with the navigation icon, a small title (TitleLarge, +
	the subtitle in LabelMedium) and the actions; below it a row of ExpandedHeight - CollapsedHeight with the large title
	(Medium: HeadlineSmall, 112 high; Large: HeadlineMedium, 152; MediumFlexible: HeadlineMedium + LabelLarge subtitle, 112 /
	136 with a subtitle; LargeFlexible: DisplaySmall + TitleMedium subtitle, 120 / 152) at 16 from the start, its last
	baseline 24 (Medium) / 28 (Large) above the row's bottom (titleBottomPadding; less when the title does not fit — 3225-
	3241). The baseline uses Roboto's metrics (ascender 0.928 em, descender 0.244 em, the line box centered on the text) —
	an approximation of Compose's LastBaseline. Collapsing shrinks the bottom row; the small title fades in on
	TopTitleAlphaEasing (cubic-bezier .8, 0, .8, .15) of the collapsed fraction and the large one out (1 - fraction).
	Instances: single row = Frame + the navigation holder (1 + its button) + Title (+ TitleColumn + Subtitle) + Actions holder
	(Frame + UIListLayout) + the actions; two rows = Frame + TopRow + BottomRow + both titles + the same holders.
]]

local q = require("../Quad")
local Theme = require("../Theme")
local Util = require("../Util")
local Text = require("../Text")
local Typography = require("../Tokens/Typography")
local Style = require("../Button/Style")
local Overlay = require("../Overlay")
local Actions = require("./Actions")
local Scroll = require("./Scroll")
local D = q.Declaration

-- host Name per call (the name is an argument here); cached so each distinct name builds one Modifier
local hostNames: { [string]: q.FrameModifier } = {}
local function hostName(name: string): q.FrameModifier
	local m = hostNames[name]
	if m == nil then
		m = D.Modifier.Frame():Name(name)
		hostNames[name] = m
	end
	return m
end

export type Alignment = "Start" | "Center"

export type Props = {
	read Title: string | q.State<string>,
	read Subtitle: (string | q.State<string>)?,
	read TitleHorizontalAlignment: Alignment?,
	read NavigationIcon: Actions.Entry?,
	read Actions: { Actions.Entry }?,
	read MaxItemCount: number?,
	read ScrollBehavior: Scroll.TopAppBarScrollBehavior?,
	read ExpandedHeight: number?,
	read CollapsedHeight: number?,
	read Overlay: Overlay.Overlay?,
	read LayoutOrder: (number | q.State<number>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

local PAD = 4 -- TopAppBarHorizontalPadding
local TITLE_INSET = 12 -- TopAppBarTitleInset (16 - 4)
local SMALL_HEIGHT = 64 -- AppBarSmallTokens.ContainerHeight

-- Roboto (hhea): ascender 1900 / 2048, descender 500 / 2048
local ASCENT, DESCENT = 1900 / 2048, 500 / 2048

-- px from the bottom of a role's line box to its baseline
local function descentOf(role: Typography.Role): number
	local e = Typography.Scale[role]
	return (e.LineHeight - (ASCENT + DESCENT) * e.Size) / 2 + DESCENT * e.Size
end

local function lineOf(role: Typography.Role): number
	return Typography.Scale[role].LineHeight
end

-- y of a cubic bezier (0,0) (x1,y1) (x2,y2) (1,1) at x (CubicBezierEasing), by bisection on t
local function bezier(x1: number, y1: number, x2: number, y2: number): (number) -> number
	local function at(t: number, a: number, b: number): number
		local u = 1 - t
		return 3 * u * u * t * a + 3 * u * t * t * b + t * t * t
	end
	return function(x: number): number
		if x <= 0 then
			return 0
		elseif x >= 1 then
			return 1
		end
		local lo, hi = 0, 1
		for _ = 1, 30 do
			local mid = (lo + hi) / 2
			if at(mid, x1, x2) < x then
				lo = mid
			else
				hi = mid
			end
		end
		return at((lo + hi) / 2, y1, y2)
	end
end

local topTitleAlpha = bezier(0.8, 0, 0.8, 0.15) -- TopTitleAlphaEasing
local fastOutLinearIn = bezier(0.4, 0, 1, 1) -- FastOutLinearInEasing (TopAppBarColors.containerColor)

local function lerpColor(a: Color3, b: Color3, t: number): Color3
	return a:Lerp(b, t)
end

-- What a bar reports to the Scaffold (Scaffold.luau): its expanded height and, when it collapses, its current height
-- (the same State its Size follows, so the Scaffold's content region moves in the same frame). Keyed by the bar Frame.
export type Measure = {
	read Expanded: number,
	read Height: q.State<number>?, -- nil: the bar never changes height (no scroll behavior, or pinned)
}

local measures: { [Instance]: Measure } = setmetatable({}, { __mode = "k" }) :: any

local function measureOf(bar: Instance): Measure?
	return measures[bar]
end

type Built = {
	Nav: Instance?,
	NavWidth: number,
	Actions: Instance?,
	ActionsWidth: number,
}

-- the navigation icon holder (at PAD from the start) and the actions holder (at PAD from the end), centered vertically
local function slots(props: Props, theme: Theme.Theme): Built
	local R = theme.Raw
	local nav: Instance? = nil
	local navWidth = 0
	local entry = props.NavigationIcon
	if entry ~= nil then
		local list, width = Actions.build({ entry }, { Theme = theme, Color = R.OnSurface, Overlay = props.Overlay })
		navWidth = width
		nav = D.Frame {
			Name = "NavigationIcon",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, PAD, 0.5, 0),
			Size = UDim2.fromOffset(width, Actions.SIZE),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			q.Slot<<Instance>>(list),
		}
	end
	local actions: Instance? = nil
	local actionsWidth = 0
	if props.Actions ~= nil and #props.Actions > 0 then
		local list, width = Actions.build(props.Actions, {
			Theme = theme,
			Color = R.OnSurfaceVariant,
			Overlay = props.Overlay,
			MaxItemCount = props.MaxItemCount,
		})
		actionsWidth = width
		actions = D.Frame {
			Name = "Actions",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -PAD, 0.5, 0),
			Size = UDim2.fromOffset(width, Actions.SIZE),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			D.UIListLayout {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			},
			q.Slot<<Instance>>(list),
		}
	end
	return { Nav = nav, NavWidth = navWidth, Actions = actions, ActionsWidth = actionsWidth }
end

type TitleSpec = {
	Title: string | q.State<string>,
	TitleRole: Typography.Role,
	Subtitle: (string | q.State<string>)?,
	SubtitleRole: Typography.Role,
	Center: boolean,
	Start: number, -- the title box's start edge (before its own PAD)
	End: number, -- the room taken at the end (actions + PAD)
	AnchorY: number, -- 0.5 centered, 1 bottom
	OffsetY: number,
	Transparency: q.State<number>?,
	Theme: Theme.Theme,
}

-- the title (and subtitle) as one node
local function titleNode(s: TitleSpec): Instance
	local theme = s.Theme
	local titleH = lineOf(s.TitleRole)
	local subH = if s.Subtitle ~= nil then lineOf(s.SubtitleRole) else 0
	local height = titleH + subH
	local align = if s.Center then Enum.TextXAlignment.Center else Enum.TextXAlignment.Left
	local side = math.max(s.Start, s.End) + PAD
	local size = if s.Center
		then UDim2.new(1, -2 * side, 0, height)
		else UDim2.new(1, -(s.Start + PAD + s.End + PAD), 0, height)
	local anchor = Vector2.new(if s.Center then 0.5 else 0, s.AnchorY)
	local position = UDim2.new(if s.Center then 0.5 else 0, if s.Center then 0 else s.Start + PAD, s.AnchorY, s.OffsetY)
	local function label(
		name: string,
		text: string | q.State<string>,
		role: Typography.Role,
		color: any,
		at: { Anchor: Vector2?, Position: UDim2, Size: UDim2 }
	): Instance
		return D.TextLabel {
			Name = name,
			Text.Label(role),
			AnchorPoint = at.Anchor,
			Position = at.Position,
			Size = at.Size,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = text,
			TextColor3 = color,
			TextTransparency = s.Transparency,
			TextXAlignment = align,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}
	end
	if s.Subtitle == nil then
		return label("Title", s.Title, s.TitleRole, theme.Color.OnSurface, { Anchor = anchor, Position = position, Size = size })
	end
	return D.Frame {
		Name = "TitleColumn",
		AnchorPoint = anchor,
		Position = position,
		Size = size,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		label("Title", s.Title, s.TitleRole, theme.Color.OnSurface, {
			Position = UDim2.new(),
			Size = UDim2.new(1, 0, 0, titleH),
		}),
		label("Subtitle", s.Subtitle :: any, s.SubtitleRole, theme.Color.OnSurfaceVariant, {
			Position = UDim2.fromOffset(0, titleH),
			Size = UDim2.new(1, 0, 0, subH),
		}),
	}
end

local function singleRow(name: string, props: Props, center: boolean): Frame
	local theme = Theme.resolve(props.Theme)
	local R = theme.Raw
	local expanded = props.ExpandedHeight or SMALL_HEIGHT
	local built = slots(props, theme)
	local behavior = props.ScrollBehavior

	local height: UDim2 | q.State<UDim2> = UDim2.new(1, 0, 0, expanded)
	local px: q.State<number>? = nil
	local color: any = theme.Color.Surface
	if behavior ~= nil then
		Scroll.setLimit(behavior.State, -expanded)
		if not behavior.IsPinned then
			local current: q.State<number> = behavior.State.HeightOffset:Compute(function(self)
				return math.max(0, math.round(expanded + self:Get()))
			end)
			px = current
			height = current:Compute(function(self)
				return UDim2.new(1, 0, 0, self:Get())
			end)
		end
		local scrolled: q.State<boolean> = behavior.State.OverlappedFraction:Compute(function(self)
			return self:Get() > 0.01
		end)
		color = Style.animated(Style.choose(scrolled, R.SurfaceContainer, R.Surface))
	end

	local start = math.max(TITLE_INSET, PAD + built.NavWidth)
	local bar = D.Frame {
		hostName(name),
		D.Modifier.Frame():Size(height),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = props.LayoutOrder,
		props.Modifier or q.None,
		built.Nav or q.None,
		titleNode({
			Title = props.Title,
			TitleRole = "TitleLarge",
			Subtitle = props.Subtitle,
			SubtitleRole = "LabelMedium",
			Center = center,
			Start = start,
			End = built.ActionsWidth + PAD,
			AnchorY = 0.5,
			OffsetY = 0,
			Theme = theme,
		}),
		built.Actions or q.None,
		table.unpack(Util.hooks(props.Hooks)),
	}
	measures[bar] = { Expanded = expanded, Height = px }
	return bar
end

type TwoRowSpec = {
	TitleRole: Typography.Role,
	SubtitleRole: Typography.Role?, -- nil: the bar has no subtitle (Medium / Large)
	BottomPadding: number,
	Expanded: number,
	ExpandedWithSubtitle: number,
}

local function twoRows(name: string, props: Props, spec: TwoRowSpec): Frame
	local theme = Theme.resolve(props.Theme)
	local R = theme.Raw
	local subtitle = if spec.SubtitleRole ~= nil then props.Subtitle else nil
	local center = spec.SubtitleRole ~= nil and props.TitleHorizontalAlignment == "Center"
	local collapsed = props.CollapsedHeight or SMALL_HEIGHT
	local expanded = props.ExpandedHeight or (if subtitle ~= nil then spec.ExpandedWithSubtitle else spec.Expanded)
	if expanded < collapsed then
		error(`{name}: ExpandedHeight ({expanded}) must be at least CollapsedHeight ({collapsed})`, 3)
	end
	local bottom = expanded - collapsed
	local built = slots(props, theme)
	local behavior = props.ScrollBehavior

	-- a pinned behavior never moves HeightOffset; with no behavior a private state stays at 0
	local state = if behavior ~= nil then behavior.State else Scroll.TopAppBarState()
	Scroll.setLimit(state, -bottom)
	local offset = state.HeightOffset
	local fraction = state.CollapsedFraction

	local px: q.State<number> = offset:Compute(function(self)
		return math.round(collapsed + math.max(0, bottom + self:Get()))
	end)
	local hostSize: q.State<UDim2> = px:Compute(function(self)
		return UDim2.new(1, 0, 0, self:Get())
	end)
	local bottomSize: q.State<UDim2> = offset:Compute(function(self)
		return UDim2.new(1, 0, 0, math.round(math.max(0, bottom + self:Get())))
	end)
	local color: q.State<Color3> = fraction:Compute(function(self, _prev, a, b)
		return lerpColor(a:Get(), b:Get(), fastOutLinearIn(self:Get()))
	end, R.Surface, R.SurfaceContainer)
	local smallTransparency: q.State<number> = fraction:Compute(function(self)
		return 1 - topTitleAlpha(self:Get())
	end)
	local largeTransparency: q.State<number> = fraction:Compute(function(self)
		return self:Get()
	end)

	-- the large title's distance from the row's bottom (placeTopAppBar, Arrangement.Bottom)
	local lastRole: Typography.Role = if subtitle ~= nil and spec.SubtitleRole ~= nil then spec.SubtitleRole else spec.TitleRole
	local columnH = lineOf(spec.TitleRole) + (if subtitle ~= nil and spec.SubtitleRole ~= nil then lineOf(spec.SubtitleRole) else 0)
	local fromBottom = spec.BottomPadding - descentOf(lastRole)
	if fromBottom + columnH > bottom then
		fromBottom -= (fromBottom + columnH) - bottom
	end
	fromBottom = math.max(0, math.round(fromBottom))

	local start = math.max(TITLE_INSET, PAD + built.NavWidth)
	local bar = D.Frame {
		hostName(name),
		D.Modifier.Frame():Size(hostSize),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = props.LayoutOrder,
		props.Modifier or q.None,
		D.Frame {
			Name = "TopRow",
			Size = UDim2.new(1, 0, 0, collapsed),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			built.Nav or q.None,
			titleNode({
				Title = props.Title,
				TitleRole = "TitleLarge",
				Subtitle = subtitle,
				SubtitleRole = "LabelMedium",
				Center = center,
				Start = start,
				End = built.ActionsWidth + PAD,
				AnchorY = 0.5,
				OffsetY = 0,
				Transparency = smallTransparency,
				Theme = theme,
			}),
			built.Actions or q.None,
		},
		D.Frame {
			Name = "BottomRow",
			Position = UDim2.fromOffset(0, collapsed),
			Size = bottomSize,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			titleNode({
				Title = props.Title,
				TitleRole = spec.TitleRole,
				Subtitle = subtitle,
				SubtitleRole = spec.SubtitleRole or "LabelLarge",
				Center = center,
				Start = TITLE_INSET,
				End = PAD,
				AnchorY = 1,
				OffsetY = -fromBottom,
				Transparency = largeTransparency,
				Theme = theme,
			}),
		},
		table.unpack(Util.hooks(props.Hooks)),
	}
	measures[bar] = { Expanded = expanded, Height = if behavior ~= nil and not behavior.IsPinned then px else nil }
	return bar
end

local function TopAppBar(props: Props): Frame
	return singleRow("TopAppBar", props, props.TitleHorizontalAlignment == "Center")
end

local function CenterAlignedTopAppBar(props: Props): Frame
	return singleRow("CenterAlignedTopAppBar", props, true)
end

local function MediumTopAppBar(props: Props): Frame
	return twoRows("MediumTopAppBar", props, {
		TitleRole = "HeadlineSmall", -- AppBarMediumTokens.TitleFont
		SubtitleRole = nil,
		BottomPadding = 24, -- MediumTitleBottomPadding
		Expanded = 112, -- AppBarMediumTokens.ContainerHeight
		ExpandedWithSubtitle = 112,
	})
end

local function MediumFlexibleTopAppBar(props: Props): Frame
	return twoRows("MediumFlexibleTopAppBar", props, {
		TitleRole = "HeadlineMedium", -- AppBarMediumFlexibleTokens.TitleFont
		SubtitleRole = "LabelLarge", -- AppBarMediumFlexibleTokens.SubtitleFont
		BottomPadding = 24,
		Expanded = 112, -- ContainerHeight
		ExpandedWithSubtitle = 136, -- LargeContainerHeight
	})
end

local function LargeTopAppBar(props: Props): Frame
	return twoRows("LargeTopAppBar", props, {
		TitleRole = "HeadlineMedium", -- AppBarLargeTokens.TitleFont
		SubtitleRole = nil,
		BottomPadding = 28, -- LargeTitleBottomPadding
		Expanded = 152, -- AppBarLargeTokens.ContainerHeight
		ExpandedWithSubtitle = 152,
	})
end

local function LargeFlexibleTopAppBar(props: Props): Frame
	return twoRows("LargeFlexibleTopAppBar", props, {
		TitleRole = "DisplaySmall", -- AppBarLargeFlexibleTokens.TitleFont
		SubtitleRole = "TitleMedium", -- AppBarLargeFlexibleTokens.SubtitleFont
		BottomPadding = 28,
		Expanded = 120, -- ContainerHeight
		ExpandedWithSubtitle = 152, -- LargeContainerHeight
	})
end

return {
	TopAppBar = TopAppBar,
	CenterAlignedTopAppBar = CenterAlignedTopAppBar,
	MediumTopAppBar = MediumTopAppBar,
	MediumFlexibleTopAppBar = MediumFlexibleTopAppBar,
	LargeTopAppBar = LargeTopAppBar,
	LargeFlexibleTopAppBar = LargeFlexibleTopAppBar,
	descentOf = descentOf,
	measureOf = measureOf,
}
