--!strict
--[[
	The side sheet surface both side sheets share — material-components-android `SideSheetBehavior` (MDC, material-components/
	material-components-android@60ff094 lib/java/com/google/android/material/sidesheet/SideSheetBehavior.java,
	RightSheetDelegate.java, LeftSheetDelegate.java, res/values/tokens.xml, styles.xml, dimens.xml). Compose has no side sheet,
	so MDC is the canon here. Not exported; `SideSheet` and `ModalSideSheet` configure it.

	GEOMETRY: a full-height column `Width` wide (default 256 — md.comp.sheet.side docked container width, tokens.xml 30) docked
	at the sheet edge of its parent ("End" = the right edge, MDC's default `layout_gravity="end"`, styles.xml 27; "Start" = the
	left edge — the kit lays out left-to-right). Offsets are the horizontal translation from the docked spot: Expanded 0,
	Hidden +Width at the end edge / -Width at the start edge (off the parent, which must clip — a ModalSideSheet sits in
	the full-screen overlay).
	SHAPE / COLOR / ELEVATION (tokens.xml 24-33, styles.xml 20-51): standard = surface, corner none, elevation level0; modal =
	surfaceContainerLow, corner large (16) on the INNER edge only (setSheetEdge clears the two corners on the docked edge when
	the sheet has no margin, SideSheetBehavior.java 176-194) — UICorner 16 + an outer-edge `Parts.patch`, elevation level1
	(a UIShadow).
	DRAG (MDC `draggable`, default true): the sheet follows a horizontal drag; released, `calculateTargetStateOnViewReleased`
	(SideSheetBehavior.java 871-900): moving outwards (towards the inner side: the end sheet's x velocity < 0, the start
	sheet's > 0 — the delegates' isExpandingOutwards) -> Expanded; otherwise Hidden when the swipe is significant (mostly
	horizontal and faster than 500 px/s — SIGNIFICANT_VEL_THRESHOLD, 87, RightSheetDelegate isSwipeSignificant 70-73) or
	the sheet was released more than halfway to the edge (isReleasedCloseToInnerEdge 63-67), else Expanded. (MDC's
	`shouldHide` gate compares a pixel coordinate with 0.5 and is true for every real release, so its other branches never
	run — the kit keeps the reachable path.) The press hook sits on the instance a press on the sheet stops at
	(Util.luau "INPUT RULE"): the modal sheet's ClickSink (a GuiButton — the Frame under it never gets InputBegan), the
	standard sheet's Frame itself (it has no sink: MDC's standard sheet is a plain view in the layout). A press on a
	GuiButton of the content stops there and drags nothing.
	HEADER (optional, `Headline`): MDC itself has no header view; the M3 anatomy names a headline and a close icon button
	(docs/components/SideSheet.md 28-49), laid out as MDC's catalog sheet does (catalog/java/io/material/catalog/sidesheet/res/
	layout/cat_sidesheet_content.xml 23-54): 16 px padding, the headline TitleLarge on the left, a standard icon button
	"close" (onSurfaceVariant) at the end on the headline's line, 24 px under the headline before the content.

	Structure: Sheet (Frame, Active) [+ UICorner + UIShadow + CornerPatch when modal] + Inner (ZIndex 2, UIPadding 16) >
	[Header > Headline + Close (GlyphButton)] + Body (UIListLayout + the Children slot). Standard without a header 5,
	a header +8 (Header, Headline, the close GlyphButton 6), modal +3 (counted in test/spec.sidesheet.luau).
]]

local q = require("../Quad")
local Tokens = require("../Tokens")
local Theme = require("../Theme")
local Util = require("../Util")
local Text = require("../Text")
local Elevation = require("../Elevation")
local Icons = require("../Icons")
local GlyphButton = require("../GlyphButton")
local Anchored = require("../Sheet/Anchored")
local Slide = require("../Sheet/Slide")
local Parts = require("../Sheet/Parts")
local StateModule = require("../Sheet/State")
local D = q.Declaration

export type Edge = "End" | "Start"

export type Config = {
	Theme: Theme.Theme,
	State: StateModule.SheetState,
	Who: string,
	Modal: boolean,
	Edge: Edge,
	Width: number,
	Draggable: boolean,
	Headline: (string | q.State<string>)?,
	ShowClose: boolean,
	OnCloseClick: () -> (),
	Children: q.Slot<Instance>?,
	OnGo: ((value: string, kind: Anchored.Kind) -> ())?,
	Modifier: q.FrameModifier?,
	Hooks: { any }?,
}

export type Built = { Sheet: Frame, Slide: Slide.Slide }

local SIGNIFICANT_VELOCITY = 500 -- SideSheetBehavior.SIGNIFICANT_VEL_THRESHOLD
local PADDING = 16 -- cat_sidesheet_content.xml android:padding
local HEADLINE_HEIGHT = 28 -- TitleLarge line height
local HEADLINE_GAP = 24 -- the headline's paddingBottom
local CORNER = Tokens.Shape.Radius.Large :: number

local headlineStyle = Text.Label("TitleLarge")

local function build(cfg: Config): Built
	local theme = cfg.Theme
	local rec = Anchored.recOf(cfg.State, cfg.Who)
	if rec.Enabled.PartiallyExpanded then
		error(
			`{cfg.Who}: a side sheet has no PartiallyExpanded state (MDC SideSheetBehavior: STATE_EXPANDED / STATE_HIDDEN) — make its SheetState with EnabledValues = \{ "Hidden", "Expanded" }`,
			3
		)
	end
	local width = cfg.Width
	local hiddenPos = if cfg.Edge == "End" then width else -width
	local anchors: { Anchored.Anchor } = {}
	if rec.Enabled.Hidden then
		table.insert(anchors, { Value = "Hidden", Pos = hiddenPos })
	end
	table.insert(anchors, { Value = "Expanded", Pos = 0 })

	local initial = if rec.Target:Get() == "Hidden" then hiddenPos else 0
	local slide = Slide.new({
		Rec = rec,
		Axis = "X",
		Who = cfg.Who,
		Anchors = function(): { Anchored.Anchor }?
			return anchors
		end,
		Motion = function(): Slide.Motion
			return Parts.Motion.Side
		end,
		Release = function(_list: { Anchored.Anchor }, offset: number, velocity: number, cross: number): string?
			local outwards = if cfg.Edge == "End" then velocity < 0 else velocity > 0
			if outwards or not rec.Enabled.Hidden then
				return "Expanded"
			end
			local significant = math.abs(velocity) > math.abs(cross) and math.abs(velocity) > SIGNIFICANT_VELOCITY
			if significant or math.abs(offset) > width / 2 then
				return "Hidden"
			end
			return "Expanded"
		end,
		CanDrag = function(): boolean
			return cfg.Draggable
		end,
		OnGo = cfg.OnGo,
		Initial = initial,
	})

	local atEnd = cfg.Edge == "End"
	local position: q.State<any> = slide.Pos:Compute(function(self)
		local p = self:Get()
		return q.Tween({
			Value = UDim2.new(if atEnd then 1 else 0, p.Offset, 0, 0),
			Time = p.Time,
			Style = p.Style,
			Direction = p.Direction,
		})
	end)

	local header: Instance? = nil
	local hasHeader = cfg.Headline ~= nil
	if hasHeader then
		header = D.Frame {
			Name = "Header",
			Size = UDim2.new(1, 0, 0, HEADLINE_HEIGHT),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			D.TextLabel {
				Name = "Headline",
				headlineStyle,
				Size = UDim2.new(1, if cfg.ShowClose then -48 else 0, 1, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = cfg.Headline :: any,
				TextColor3 = theme.Color.OnSurface,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			},
			if cfg.ShowClose
				then GlyphButton.new({
					Name = "Close",
					Asset = Icons.asset("close"),
					Glyph = Icons.glyph("close"),
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.fromScale(1, 0.5),
					Theme = theme,
					OnClick = cfg.OnCloseClick,
				})
				else q.None,
		}
	end
	local bodyTop = if hasHeader then HEADLINE_HEIGHT + HEADLINE_GAP else 0

	local container = if cfg.Modal then theme.Color.SurfaceContainerLow else theme.Color.Surface
	local sheet = D.Frame {
		Name = "SideSheet",
		D.Modifier.Frame():Size(UDim2.new(0, width, 1, 0)),
		AnchorPoint = Vector2.new(if atEnd then 1 else 0, 0),
		Position = position,
		BackgroundColor3 = container,
		BorderSizePixel = 0,
		Active = true, -- 3D / camera input only; a modal sheet's GUI clicks are sunk by the ClickSink child
		-- the drag hook goes where the press lands: the sink when there is one (the Frame below it never gets InputBegan)
		if cfg.Modal then Util.clickSink({ slide.Hook() }) else slide.Hook() :: any,
		cfg.Modifier or q.None,
		if cfg.Modal then D.UICorner { CornerRadius = UDim.new(0, CORNER) } else q.None,
		if cfg.Modal then Elevation.Shadow({ Level = 1, Theme = theme }) else q.None,
		if cfg.Modal then Parts.patch(if atEnd then "Right" else "Left", CORNER, container) else q.None,
		D.Frame {
			Name = "Inner",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 2,
			UIPaddingOffset = PADDING,
			header or q.None,
			D.Frame {
				Name = "Body",
				Position = UDim2.fromOffset(0, bodyTop),
				Size = UDim2.new(1, 0, 1, -bodyTop),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				D.UIListLayout { FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder },
				cfg.Children or q.None,
			},
		},
		q.OnDestroyed(function()
			slide.Destroy()
		end),
		table.unpack(cfg.Hooks or {}),
	} :: Frame

	return { Sheet = sheet, Slide = slide }
end

return { build = build }
