--!strict
--[[
	Navigation drawers — Compose material3 `ModalNavigationDrawer`, `DismissibleNavigationDrawer`, `PermanentNavigationDrawer`
	(androidx/androidx@40ff481 compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/NavigationDrawer.kt
	334-622). Like Compose, they are LAYOUTS in the tree (not overlay entries): a host that fills its parent and holds the
	screen content and the drawer sheet.

	    local drawer = Material.DrawerState({ InitialValue = "Closed" })
	    Material.ModalNavigationDrawer({
	        DrawerState = drawer,
	        DrawerContent = Material.ModalDrawerSheet({ Children = q.Slot<<Instance>>({ Material.NavigationDrawerItems<<string>>({ ... }) }) }),
	        Content = q.Slot<<Instance>>({ page }),                -- e.g. a top bar whose menu button calls drawer.Open
	    })

	ModalNavigationDrawer (334-466) props (`read`): DrawerContent (Instance — a ModalDrawerSheet), Content (Slot<Instance>?),
	  DrawerState (DrawerState?, default a fresh Closed one), GesturesEnabled (boolean?, default true), Theme, Modifier (Frame),
	  Hooks. The drawer slides in over the content from the start (left) edge with a scrim between them whose opacity follows
	  the drawer (`alpha = calculateFraction(closed, open, offset)` x 0.32, 391); a tap on the scrim closes it (only while
	  open and only with gestures enabled — `onDismissRequest`, 383-387); Escape / gamepad B closes it (the kit puts it on the
	  Overlay's shared Escape stack while the target is Open — `Overlay.onEscape`, so a dialog opened above gets the key
	  first; Compose closes on the Escape key, 420-431). The drawer and the scrim are not shown at all while closed and at
	  rest (Compose only places the drawer when it is visible, 456-462 — so gamepad selection cannot wander into it).
	DismissibleNavigationDrawer (488-592): the same props without the scrim; the drawer pushes the content aside (the content
	  is placed at drawer width + offset, 581-588). Escape / B closes it too.
	PermanentNavigationDrawer (612-622) props: DrawerContent, Content, Theme, Modifier, Hooks — a row: the sheet, then the
	  content filling the rest. No state, no motion.
	DRAG (modal and dismissible): the drawer sheet (and the modal's scrim) follows a horizontal drag; released, Compose
	  `computeTarget` with the DrawerState thresholds — positional half the distance (DrawerPositionalThreshold 0.5, 1339) and
	  velocity 400 px/s (DrawerVelocityThreshold, 1340-1341); a target the ConfirmStateChange vetoes settles back. Compose
	  also drags the drawer open from anywhere over the content (`anchoredDraggable` on the whole Box); the kit does NOT
	  start a drag on the content (it would take every press and scroll of the screen's own buttons and lists) — open it
	  from a control (the Compose samples' "Click to open" button, an app bar's menu icon).
	ANCHORS: Closed at -drawer width, Open at 0 (450-454); the width is the DrawerContent's `Size.X.Offset` (the kit sheets
	  set it: 360 by default), 360 when it has none. The host clips (`ClipsDescendants`): the closed drawer waits just past
	  its left edge.
	Motion (Sheet/Parts.luau): open 0.2 s, close 0.1 s, a released drag settles in 0.2 s (modal) / 0.256 s (dismissible).
]]

local q = require("../Quad")
local Theme = require("../Theme")
local Util = require("../Util")
local Overlay = require("../Overlay")
local Anchored = require("../Sheet/Anchored")
local Slide = require("../Sheet/Slide")
local Parts = require("../Sheet/Parts")
local StateModule = require("./State")
local D = q.Declaration

export type ModalProps = {
	read DrawerContent: Instance,
	read Content: q.Slot<Instance>?,
	read DrawerState: StateModule.DrawerState?,
	read GesturesEnabled: boolean?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

export type DismissibleProps = ModalProps

export type PermanentProps = {
	read DrawerContent: Instance,
	read Content: q.Slot<Instance>?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

local POSITIONAL = 0.5 -- DrawerPositionalThreshold
local VELOCITY = 400 -- DrawerVelocityThreshold
local DEFAULT_WIDTH = 360 -- DrawerDefaults.MaximumDrawerWidth

local hostBase = D.Modifier.Frame():Size(UDim2.fromScale(1, 1)):BackgroundTransparency(1):BorderSizePixel(0):ClipsDescendants(true)

local function contentWidth(content: Instance): number
	local ok, size = pcall(function(): UDim2
		return (content :: any).Size
	end)
	if ok and typeof(size) == "UDim2" and size.X.Offset > 0 then
		return size.X.Offset
	end
	return DEFAULT_WIDTH
end

local function slidingDrawer(props: ModalProps, modal: boolean): Frame
	local who = if modal then "ModalNavigationDrawer" else "DismissibleNavigationDrawer"
	if props.DrawerContent == nil then
		error(`{who}: DrawerContent is required (a {if modal then "ModalDrawerSheet" else "DismissibleDrawerSheet"})`, 3)
	end
	local theme = Theme.resolve(props.Theme)
	local state = props.DrawerState or StateModule.DrawerState()
	local rec = Anchored.recOf(state, who)
	local gestures = props.GesturesEnabled ~= false
	local width = contentWidth(props.DrawerContent)
	local anchors: { Anchored.Anchor } = { { Value = "Closed", Pos = -width }, { Value = "Open", Pos = 0 } }

	local slide = Slide.new({
		Rec = rec,
		Axis = "X",
		Who = who,
		Anchors = function(): { Anchored.Anchor }?
			return anchors
		end,
		Motion = function(kind: Anchored.Kind): Slide.Motion
			if not modal and kind == "Settle" then
				return Parts.Motion.DismissibleSettle
			end
			return Parts.pick(Parts.Motion.Drawer, kind)
		end,
		Release = function(list: { Anchored.Anchor }, offset: number, velocity: number): string?
			return Anchored.computeTarget(list, offset, velocity, function(distance: number): number
				return distance * POSITIONAL
			end, VELOCITY)
		end,
		CanDrag = function(): boolean
			return gestures
		end,
		Initial = if rec.Target:Get() == "Open" then 0 else -width,
	})

	local function tween<T>(value: T, p: Slide.Pos): any
		return q.Tween({ Value = value, Time = p.Time, Style = p.Style, Direction = p.Direction })
	end

	local shown: q.State<boolean> = rec.Current:Compute(function(self, _prev, target, dragging)
		return not (self:Get() == "Closed" and target:Get() == "Closed" and not dragging:Get())
	end, rec.Target, slide.Dragging)
	local drawerPosition: q.State<any> = slide.Pos:Compute(function(self)
		local p = self:Get()
		return tween(UDim2.fromOffset(p.Offset, 0), p)
	end)

	-- Escape / B while the drawer heads open (Compose: Escape closes an open drawer)
	local escape = q.Effect(function()
		if rec.Target:Get() == "Open" then
			local release = Overlay.onEscape(function()
				state.Close()
			end)
			return function(_dying: boolean)
				release()
			end
		end
		return nil :: any
	end, rec.Target)

	local holder = D.Frame {
		Name = "Drawer",
		Size = UDim2.new(0, width, 1, 0),
		Position = drawerPosition,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = shown,
		ZIndex = 3,
		-- sinks presses over the drawer even when the DrawerContent is not Active itself: a press on empty sheet padding must
		-- never reach the scrim below (Studio, 2026-10-08: picker modal cards without Active closed on a press)
		Active = true,
		slide.Hook(),
		props.DrawerContent,
	}

	local content: Instance
	local scrim: Instance? = nil
	if modal then
		content = D.Frame {
			Name = "Content",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			props.Content or q.None,
		}
		local transparency: q.State<any> = slide.Pos:Compute(function(self)
			local p = self:Get()
			local fraction = math.clamp((p.Offset + width) / width, 0, 1)
			return tween(1 - Parts.ScrimOpacity * fraction, p)
		end)
		scrim = Parts.scrim({
			Theme = theme,
			Transparency = transparency,
			Visible = shown,
			ZIndex = 2,
			OnClick = function()
				if slide.Moved() then
					return -- the click that ends a drag on the scrim
				end
				if rec.Current:Get() == "Open" and gestures and Anchored.confirm(rec, "Closed") then
					state.Close()
				end
			end,
			Hooks = { slide.Hook() },
		})
	else
		local contentPosition: q.State<any> = slide.Pos:Compute(function(self)
			local p = self:Get()
			return tween(UDim2.fromOffset(width + p.Offset, 0), p)
		end)
		content = D.Frame {
			Name = "Content",
			Size = UDim2.fromScale(1, 1),
			Position = contentPosition,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			props.Content or q.None,
		}
	end

	return D.Frame {
		Name = who,
		hostBase,
		props.Modifier or q.None,
		escape,
		content,
		scrim or q.None,
		holder,
		q.OnDestroyed(function()
			slide.Destroy()
		end),
		table.unpack(Util.hooks(props.Hooks)),
	}
end

local function ModalNavigationDrawer(props: ModalProps): Frame
	return slidingDrawer(props, true)
end

local function DismissibleNavigationDrawer(props: DismissibleProps): Frame
	return slidingDrawer(props, false)
end

local function PermanentNavigationDrawer(props: PermanentProps): Frame
	if props.DrawerContent == nil then
		error("PermanentNavigationDrawer: DrawerContent is required (a PermanentDrawerSheet)", 2)
	end
	local _ = Theme.resolve(props.Theme)
	return D.Frame {
		Name = "PermanentNavigationDrawer",
		hostBase,
		props.Modifier or q.None,
		D.UIListLayout { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder },
		props.DrawerContent,
		D.Frame {
			Name = "Content",
			Size = UDim2.fromScale(0, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			LayoutOrder = 2,
			D.UIFlexItem { FlexMode = Enum.UIFlexMode.Fill },
			props.Content or q.None,
		},
		table.unpack(Util.hooks(props.Hooks)),
	}
end

return {
	ModalNavigationDrawer = ModalNavigationDrawer,
	DismissibleNavigationDrawer = DismissibleNavigationDrawer,
	PermanentNavigationDrawer = PermanentNavigationDrawer,
}
