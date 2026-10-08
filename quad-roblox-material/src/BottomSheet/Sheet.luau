--!strict
--[[
	The bottom sheet surface both bottom sheets share (BottomSheetScaffold's StandardBottomSheet and ModalBottomSheet's
	BottomSheet — Compose material3 androidx/androidx@40ff481 compose/material3/material3/src/commonMain/kotlin/androidx/
	compose/material3/BottomSheetScaffold.kt 241-449 and BottomSheet.kt 186-406): the sliding Surface, its drag handle, its
	anchors and its drag gesture. Not exported; the two public components configure it.

	GEOMETRY (Compose `draggableAnchors`): the surface is as wide as the host up to `MaxWidth` (BottomSheetDefaults.
	SheetMaxWidth 640, SheetDefaults.kt 536) and centered (`widthIn(max).fillMaxWidth()`, the scaffold's `sheetOffsetX`
	and the modal's `Alignment.TopCenter`); its height is the drag handle box (48, when shown) + the content's laid-out
	height, at most the host height (the sheet is measured with the host's constraints). Offsets are kept as the sheet
	top's distance ABOVE the host bottom, negated (so a pointer moving down adds to the offset): Hidden 0 (Compose `Hidden
	at fullHeight`), Expanded -min(sheet height, host height) (`max(0, fullHeight - sheetHeight)`),
	PartiallyExpanded:
	  modal     -min(host height / 2, sheet height) when enabled — ComposeMaterial3Flags.isBottomSheetPartiallyExpanded
	            DeterministicEnabled is true (ComposeMaterial3Flags.kt 114), so the anchor always exists and a short sheet
	            converges with Expanded (BottomSheet.kt 417-443); the modal's Hidden anchor always exists (299-308)
	  standard  -peek height when enabled, the peek is > 0 and differs from the sheet height; Hidden only when enabled (or
	            the sheet or the peek is 0) (BottomSheetScaffold.kt 303-344)
	Nothing is anchored before the host AND the content have been laid out (AbsoluteSize > 0); the first layout then snaps
	to the target value (Compose places the sheet at its anchor on the first measure) — the modal waits for that layout
	before it calls `Show`, so its opening animates up from Hidden.
	DRAG: anywhere on the surface and on the handle (Compose `anchoredDraggable` on the Surface); released, the target is
	Compose `computeTarget` with the sheet's thresholds — positional 56 (BottomSheetDefaults.PositionalThreshold, a fixed
	distance whatever the gap between anchors: `positionalThreshold = { _ -> state.positionalThreshold() }`, BottomSheet.kt
	211-216) and velocity 125 px/s (VelocityThreshold, also AnchoredDraggableMinFlingVelocity), SheetDefaults.kt 557-559.
	SHAPE: CornerExtraLargeTop (SheetBottomTokens DockedContainerShape) = UICorner 28 + a bottom `Parts.patch`.
	Color SurfaceContainerLow (DockedContainerColor). `Shadow` = an elevation level (the scaffold's sheetShadowElevation
	= BottomSheetDefaults.Elevation = Level1; the modal has none — tonalElevation 0, no shadow).

	Structure: Sheet (Frame, Active) + UICorner + UISizeConstraint [+ UIShadow] + CornerPatch [+ DragHandle (TextButton +
	state layer 3 + Bar + UICorner)] + ContentClip (ClipsDescendants) > Content (AutomaticSize Y + UIListLayout + the
	Children slot). 13 instances with the handle (+1 shadow), 7 without.
]]

local q = require("../Quad")
local Tokens = require("../Tokens")
local Theme = require("../Theme")
local Elevation = require("../Elevation")
local Anchored = require("../Sheet/Anchored")
local Slide = require("../Sheet/Slide")
local Parts = require("../Sheet/Parts")
local StateModule = require("../Sheet/State")
local D = q.Declaration

type SheetValue = StateModule.SheetValue

export type Config = {
	Theme: Theme.Theme,
	State: StateModule.SheetState,
	Who: string,
	Modal: boolean,
	PeekHeight: number,
	MaxWidth: number,
	Gestures: boolean,
	DragHandle: boolean,
	Shadow: number?,
	Children: q.Slot<Instance>?,
	OnHandleClick: (current: SheetValue) -> (),
	OnGo: ((value: string, kind: Anchored.Kind) -> ())?,
	OnLaidOut: (() -> ())?,
}

export type Built = {
	Sheet: Frame,
	Slide: Slide.Slide,
	-- the host's AbsoluteSize hook: put it in the host's array part
	HostHook: any,
	LaidOut: () -> boolean,
	Destroy: () -> (),
}

local POSITIONAL_THRESHOLD = 56 -- BottomSheetDefaults.PositionalThreshold
local VELOCITY_THRESHOLD = 125 -- BottomSheetDefaults.VelocityThreshold
local CORNER = Tokens.Shape.Radius.ExtraLarge :: number

local function build(cfg: Config): Built
	local theme = cfg.Theme
	local rec = Anchored.recOf(cfg.State, cfg.Who)
	local handleH = if cfg.DragHandle then Parts.HandleBox else 0
	local full = 0
	local contentH = 0
	local contentMeasured = false
	local sheetH = q.Source(handleH)
	local laidOutOnce = false

	local function laidOut(): boolean
		return full > 0 and contentMeasured
	end

	local function height(): number
		local h = handleH + contentH
		if full > 0 then
			h = math.min(h, full)
		end
		return h
	end

	local function anchors(): { Anchored.Anchor }?
		if not laidOut() then
			return nil
		end
		local h = height()
		local list: { Anchored.Anchor } = {}
		if cfg.Modal then
			table.insert(list, { Value = "Hidden", Pos = 0 })
			if rec.Enabled.PartiallyExpanded then
				table.insert(list, { Value = "PartiallyExpanded", Pos = -math.min(full / 2, h) })
			end
		else
			local peek = cfg.PeekHeight
			if rec.Enabled.PartiallyExpanded and peek > 0 and peek ~= h then
				table.insert(list, { Value = "PartiallyExpanded", Pos = -peek })
			end
			if h == 0 or peek == 0 or rec.Enabled.Hidden then
				table.insert(list, { Value = "Hidden", Pos = 0 })
			end
		end
		if h ~= 0 then
			table.insert(list, { Value = "Expanded", Pos = -math.min(h, full) })
		end
		return list
	end

	local slide = Slide.new({
		Rec = rec,
		Axis = "Y",
		Who = cfg.Who,
		Anchors = anchors,
		Motion = function(kind: Anchored.Kind): Slide.Motion
			return Parts.pick(Parts.Motion.Sheet, kind)
		end,
		Release = function(list: { Anchored.Anchor }, offset: number, velocity: number): string?
			return Anchored.computeTarget(list, offset, velocity, function()
				return POSITIONAL_THRESHOLD
			end, VELOCITY_THRESHOLD)
		end,
		CanDrag = function(): boolean
			if not cfg.Gestures then
				return false
			end
			return not cfg.Modal or rec.Current:Get() ~= "Hidden"
		end,
		OnGo = cfg.OnGo,
		Initial = 0,
	})

	local function relayout()
		sheetH:Set(height())
		slide.Relayout()
		if not laidOutOnce and laidOut() then
			laidOutOnce = true
			if cfg.OnLaidOut then
				cfg.OnLaidOut()
			end
		end
	end

	local position: q.State<any> = slide.Pos:Compute(function(self)
		local p = self:Get()
		return q.Tween({
			Value = UDim2.new(0.5, 0, 1, p.Offset),
			Time = p.Time,
			Style = p.Style,
			Direction = p.Direction,
		})
	end)
	local size: q.State<UDim2> = sheetH:Compute(function(self)
		return UDim2.new(1, 0, 0, self:Get())
	end)

	local handle: Instance? = nil
	if cfg.DragHandle then
		handle = Parts.dragHandle({
			Theme = theme,
			OnClick = function()
				if slide.Moved() then
					return -- the click that ends a drag is not a click
				end
				cfg.OnHandleClick(rec.Current:Get() :: SheetValue)
			end,
			Hooks = { slide.Hook() },
		})
	end

	local sheet = D.Frame {
		Name = "BottomSheet",
		Size = size,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = position,
		BackgroundColor3 = theme.Color.SurfaceContainerLow,
		BorderSizePixel = 0,
		Active = true,
		ZIndex = 2,
		UICorner = UDim.new(0, CORNER),
		slide.Hook(),
		D.UISizeConstraint { MaxSize = Vector2.new(cfg.MaxWidth, math.huge) },
		if cfg.Shadow then Elevation.Shadow({ Level = cfg.Shadow, Theme = theme }) else q.None,
		Parts.patch("Bottom", CORNER, theme.Color.SurfaceContainerLow),
		handle or q.None,
		D.Frame {
			Name = "ContentClip",
			Position = UDim2.fromOffset(0, handleH),
			Size = UDim2.new(1, 0, 1, -handleH),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 2,
			D.Frame {
				Name = "Content",
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				D.UIListLayout { FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder },
				q.OnChange("AbsoluteSize", function(v: Vector2)
					contentMeasured = contentMeasured or v.X > 0
					contentH = v.Y
					relayout()
				end),
				cfg.Children or q.None,
			},
		},
		q.OnDestroyed(function()
			slide.Destroy()
		end),
	} :: Frame

	local hostHook = q.OnChange("AbsoluteSize", function(v: Vector2)
		full = v.Y
		relayout()
	end)

	return {
		Sheet = sheet,
		Slide = slide,
		HostHook = hostHook,
		LaidOut = laidOut,
		Destroy = slide.Destroy,
	}
end

return { build = build }
