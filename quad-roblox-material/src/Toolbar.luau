--!strict
--[[
	M3 Expressive floating toolbars — Compose material3 `HorizontalFloatingToolbar` / `VerticalFloatingToolbar`, both forms
	(with leading / trailing content, and with a floating action button) (androidx/androidx@40ff481 compose/material3/
	material3/src/commonMain/kotlin/androidx/compose/material3/FloatingToolbar.kt 175-487 the public functions, 632-1161
	FloatingToolbarDefaults, 1476-1935 the four layouts; tokens FloatingToolbarTokens.kt; MDC material-components/
	material-components-android@60ff094 docs/components/FloatingToolbar.md). The docked toolbar is `FlexibleBottomAppBar`
	(AppBar/Bottom.luau — Compose's name for it).

	    local expanded = q.Source(true)
	    Material.HorizontalFloatingToolbar({
	        Expanded = expanded,
	        LeadingContent = { { Icon = "rbxassetid://…", Label = "Bold", Checked = bold, OnCheckedChange = setBold } },
	        Content = { { Icon = "rbxassetid://…", Label = "Edit", OnClick = edit } },
	        TrailingContent = { … },
	    })
	    Material.VerticalFloatingToolbar({ Expanded = expanded, Colors = "Vibrant", Content = { … },
	        FloatingActionButton = { Icon = "rbxassetid://…", OnClick = add } })

	Props (`read`):
	  Expanded        boolean | State<boolean>          Compose `expanded`: shows the leading / trailing content; with a FAB the
	                                                    whole toolbar
	  Colors          ("Standard" | "Vibrant")?          standardFloatingToolbarColors (default): container surfaceContainer,
	                                                    icons onSurface, FAB primaryContainer; vibrantFloatingToolbarColors:
	                                                    container primaryContainer, icons onPrimaryContainer, FAB
	                                                    tertiaryContainer (defaultFloatingToolbar*Colors 1108-1142)
	  Content         { AppBarAction | Instance }        the main content (AppBar/Actions.luau — data becomes 48 px icon buttons)
	  LeadingContent, TrailingContent   { ... }?          shown only while expanded (no-FAB form)
	  FloatingActionButton  { Icon, OnClick }?           the FAB form (Compose's overload with `floatingActionButton`;
	                                                    Leading / TrailingContent are not used there); a kit FAB in the
	                                                    toolbar's FAB colors
	  FloatingActionButtonPosition  "Start" | "End" (horizontal, default End) / "Top" | "Bottom" (vertical, default Bottom)
	  Overlay, LayoutOrder, Theme, Modifier (Frame — position the toolbar with it; Compose's samples float it 16 from the
	  screen edge: FloatingToolbarDefaults.ScreenOffset), Hooks
	Returns the toolbar host Frame (its Size follows the content and the motion).

	NO-FAB FORM (HorizontalFloatingToolbarLayout 1476-1560): 64 thick (ContainerSize, heightIn / widthIn min), corner full
	(ContainerShape), padding 8 on all sides (ContentPadding), no shadow (ContainerExpanded/CollapsedElevation Level0); the
	leading content, the content, the trailing content in a row (column). Collapsing shrinks the leading / trailing groups
	to nothing (AnimatedVisibility expand / shrink — horizontal: leading revealed from its start, trailing from its end;
	vertical: leading from its bottom, trailing from its top), the content stays.
	FAB FORM (HorizontalFloatingToolbarWithFabLayout 1563-1695): the toolbar and the FAB 8 apart (ToolbarToFabGap) in an 80
	thick box; expanded: the toolbar at its full length and a 56 FAB (FabBaselineTokens), collapsed: no toolbar and an 80 FAB
	(FabMediumTokens) — FabSizeRange.lerp(1 - progress); the toolbar shrinks toward the FAB, its content staying at the toolbar's
	start (top) and clipped; its shadow goes from Level1 (expanded, ContainerExpandedElevationWithFab) to none.
	MOTION: one expanded progress (FloatingToolbarDefaults.animationSpec = the FastSpatial spring -> Navigation/Motion.luau,
	Short3 0.15 s) drives every size and offset.
	Not here: the scroll behavior (exitAlways), the touch-exploration rule (the kit has no TalkBack), the balanced minimum
	padding (minimumInteractiveBalancedPadding), the overflow by width.
	Instances: no-FAB = Frame + UICorner + 3 groups x (clip Frame + Row + UIListLayout) + the actions (the empty groups are
	left out); FAB = Frame + Toolbar (+ UICorner + UIShadow) + Clip + Row (+ UIListLayout) + the actions + the FAB (7).
]]

local q = require("./Quad")
local Tokens = require("./Tokens")
local Theme = require("./Theme")
local Util = require("./Util")
local Icons = require("./Icons")
local Elevation = require("./Elevation")
local FAB = require("./Button/FAB")
local Overlay = require("./Overlay")
local Actions = require("./AppBar/Actions")
local Motion = require("./Navigation/Motion")
local ColorTokens = require("./Tokens/Color")
local D = q.Declaration

export type Colors = "Standard" | "Vibrant"
export type Fab = {
	read Icon: string,
	read OnClick: (() -> ())?,
}

export type HorizontalProps = {
	read Expanded: boolean | q.State<boolean>,
	read Colors: Colors?,
	read Content: { Actions.Entry },
	read LeadingContent: { Actions.Entry }?,
	read TrailingContent: { Actions.Entry }?,
	read FloatingActionButton: Fab?,
	read FloatingActionButtonPosition: ("Start" | "End")?,
	read Overlay: Overlay.Overlay?,
	read LayoutOrder: (number | q.State<number>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

export type VerticalProps = {
	read Expanded: boolean | q.State<boolean>,
	read Colors: Colors?,
	read Content: { Actions.Entry },
	read LeadingContent: { Actions.Entry }?,
	read TrailingContent: { Actions.Entry }?,
	read FloatingActionButton: Fab?,
	read FloatingActionButtonPosition: ("Top" | "Bottom")?,
	read Overlay: Overlay.Overlay?,
	read LayoutOrder: (number | q.State<number>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

type Common = {
	Expanded: boolean | q.State<boolean>,
	Colors: Colors?,
	Content: { Actions.Entry },
	LeadingContent: { Actions.Entry }?,
	TrailingContent: { Actions.Entry }?,
	FloatingActionButton: Fab?,
	FabAtStart: boolean,
	Overlay: Overlay.Overlay?,
	LayoutOrder: (number | q.State<number>)?,
	Theme: Theme.Theme?,
	Modifier: q.FrameModifier?,
	Hooks: Util.Hooks?,
}

local THICK = 64 -- FloatingToolbarTokens.ContainerHeight
local PAD = 8 -- ContainerLeadingSpace / TrailingSpace
local ITEM = Actions.SIZE -- 48: the content's cross size (64 - 2 x 8)
local GAP = 8 -- ToolbarToFabGap
local FAB_MIN = 56 -- FabBaselineTokens.ContainerWidth
local FAB_MAX = 80 -- FabMediumTokens.ContainerWidth

type Palette = { Container: ColorTokens.Role, Content: ColorTokens.Role, Fab: "Primary" | "Tertiary" }
local Palettes: { [Colors]: Palette } = {
	Standard = { Container = "SurfaceContainer", Content = "OnSurface", Fab = "Primary" },
	Vibrant = { Container = "PrimaryContainer", Content = "OnPrimaryContainer", Fab = "Tertiary" },
}

local function toolbar(name: string, vertical: boolean, props: Common): Frame
	local theme = Theme.resolve(props.Theme)
	local colors: Colors = props.Colors or "Standard"
	local palette = Palettes[colors]
	local axis: "X" | "Y" = if vertical then "Y" else "X"
	local expanded = Util.asState(props.Expanded)
	local e, motion = Motion.progress(expanded, Tokens.Motion.Duration.Short3)
	local corner = Tokens.Shape.corner("Full")
	local opts: Actions.Options = { Theme = theme, Color = theme.Raw[palette.Content], Overlay = props.Overlay }

	-- a group of entries laid out along the axis
	local function row(list: { Instance }, length: number, anchor: Vector2, position: UDim2): Frame
		return D.Frame {
			Name = "Row",
			AnchorPoint = anchor,
			Position = position,
			Size = if vertical then UDim2.fromOffset(ITEM, length) else UDim2.fromOffset(length, ITEM),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			D.UIListLayout {
				FillDirection = if vertical then Enum.FillDirection.Vertical else Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			},
			q.Slot<<Instance>>(list),
		}
	end
	-- a size / position on the main axis (`along`) and the cross axis (`across`)
	local function size2(along: number, across: number): UDim2
		return if vertical then UDim2.fromOffset(across, along) else UDim2.fromOffset(along, across)
	end
	local function pos2(along: number, across: number): UDim2
		return if vertical then UDim2.fromOffset(across, along) else UDim2.fromOffset(along, across)
	end

	local content, contentLength = Actions.build(props.Content, opts, axis)

	local spec = props.FloatingActionButton
	if spec == nil then
		local leading, leadLength = Actions.build(props.LeadingContent or {}, opts, axis)
		local trailing, trailLength = Actions.build(props.TrailingContent or {}, opts, axis)
		local hostSize: q.State<UDim2> = e:Compute(function(self)
			local p = self:Get()
			return size2(math.round(PAD + (leadLength + trailLength) * p + contentLength + PAD), THICK)
		end)
		local shown: q.State<boolean> = e:Compute(function(self)
			return self:Get() > 0
		end)
		-- a clipped group that grows with the progress; `far` = its content is anchored at the group's far end
		local function group(groupName: string, list: { Instance }, length: number, at: (p: number) -> number, far: boolean): Instance
			if #list == 0 then
				return q.None :: any
			end
			local clipSize: q.State<UDim2> = e:Compute(function(self)
				return size2(math.round(length * self:Get()), ITEM)
			end)
			local clipPos: q.State<UDim2> = e:Compute(function(self)
				return pos2(math.round(at(self:Get())), PAD)
			end)
			local anchor = if far then (if vertical then Vector2.new(0, 1) else Vector2.new(1, 0)) else Vector2.new(0, 0)
			local position = if far then (if vertical then UDim2.fromScale(0, 1) else UDim2.fromScale(1, 0)) else UDim2.new()
			return D.Frame {
				Name = groupName,
				Position = clipPos,
				Size = clipSize,
				Visible = shown,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ClipsDescendants = true,
				row(list, length, anchor, position),
			}
		end
		local contentPos: q.State<UDim2> = e:Compute(function(self)
			return pos2(math.round(PAD + leadLength * self:Get()), PAD)
		end)
		return D.Frame {
			Util.frameName(name),
			D.Modifier.Frame():Size(hostSize),
			BackgroundColor3 = theme.Color[palette.Container],
			BorderSizePixel = 0,
			LayoutOrder = props.LayoutOrder,
			props.Modifier or q.None,
			motion,
			UICorner = corner,
			-- horizontal: leading revealed from its start, trailing from its end; vertical: leading from its bottom, trailing
			-- from its top (FloatingToolbar.kt 1515-1557 / 1738-1781)
			group("Leading", leading, leadLength, function(_p: number): number
				return PAD
			end, vertical),
			D.Frame {
				Name = "Content",
				Position = contentPos,
				Size = size2(contentLength, ITEM),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				row(content, contentLength, Vector2.new(0, 0), UDim2.new()),
			},
			group("Trailing", trailing, trailLength, function(p: number): number
				return PAD + leadLength * p + contentLength
			end, not vertical),
			table.unpack(Util.hooks(props.Hooks)),
		}
	end

	-- FAB form
	local maxLength = PAD + contentLength + PAD
	local total = maxLength + GAP + FAB_MIN
	local fabAtStart = props.FabAtStart
	local toolbarSize: q.State<UDim2> = e:Compute(function(self)
		return size2(math.round(maxLength * self:Get()), THICK)
	end)
	local toolbarPos: q.State<UDim2> = e:Compute(function(self)
		local current = math.round(maxLength * self:Get())
		local at = if fabAtStart then total - maxLength else maxLength - current
		return pos2(at, (FAB_MAX - THICK) / 2)
	end)
	local fabSizeNow: q.State<number> = e:Compute(function(self)
		return math.round(FAB_MIN + (FAB_MAX - FAB_MIN) * (1 - self:Get()))
	end)
	local fabSize: q.State<UDim2> = fabSizeNow:Compute(function(self)
		return UDim2.fromOffset(self:Get(), self:Get())
	end)
	local fabPos: q.State<UDim2> = fabSizeNow:Compute(function(self)
		local s = self:Get()
		return pos2(if fabAtStart then 0 else total - s, (FAB_MAX - s) / 2)
	end)
	local level: q.State<number> = e:Compute(function(self)
		return self:Get()
	end)
	return D.Frame {
		Util.frameName(name),
		D.Modifier.Frame():Size(size2(total, FAB_MAX)),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = props.LayoutOrder,
		props.Modifier or q.None,
		motion,
		D.Frame {
			Name = "Toolbar",
			Position = toolbarPos,
			Size = toolbarSize,
			BackgroundColor3 = theme.Color[palette.Container],
			BorderSizePixel = 0,
			UICorner = corner,
			Elevation.Shadow({ Level = level, Theme = theme }),
			D.Frame {
				Name = "Clip",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ClipsDescendants = true,
				-- the content stays at the toolbar's start (top) and is clipped (a scrolling Row / Column in Compose)
				row(content, contentLength, Vector2.new(0, 0), pos2(PAD, PAD)),
			},
		},
		FAB({
			Icon = Icons.imageOf(spec.Icon),
			Color = palette.Fab,
			Theme = theme,
			OnClick = spec.OnClick,
			Modifier = D.Modifier.TextButton():Size(fabSize):Position(fabPos),
		}),
		table.unpack(Util.hooks(props.Hooks)),
	}
end

local function HorizontalFloatingToolbar(props: HorizontalProps): Frame
	return toolbar("HorizontalFloatingToolbar", false, {
		Expanded = props.Expanded,
		Colors = props.Colors,
		Content = props.Content,
		LeadingContent = props.LeadingContent,
		TrailingContent = props.TrailingContent,
		FloatingActionButton = props.FloatingActionButton,
		FabAtStart = props.FloatingActionButtonPosition == "Start",
		Overlay = props.Overlay,
		LayoutOrder = props.LayoutOrder,
		Theme = props.Theme,
		Modifier = props.Modifier,
		Hooks = props.Hooks,
	})
end

local function VerticalFloatingToolbar(props: VerticalProps): Frame
	return toolbar("VerticalFloatingToolbar", true, {
		Expanded = props.Expanded,
		Colors = props.Colors,
		Content = props.Content,
		LeadingContent = props.LeadingContent,
		TrailingContent = props.TrailingContent,
		FloatingActionButton = props.FloatingActionButton,
		FabAtStart = props.FloatingActionButtonPosition == "Top",
		Overlay = props.Overlay,
		LayoutOrder = props.LayoutOrder,
		Theme = props.Theme,
		Modifier = props.Modifier,
		Hooks = props.Hooks,
	})
end

return {
	HorizontalFloatingToolbar = HorizontalFloatingToolbar,
	VerticalFloatingToolbar = VerticalFloatingToolbar,
}
