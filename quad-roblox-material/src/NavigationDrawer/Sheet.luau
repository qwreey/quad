--!strict
--[[
	Navigation drawer sheets — Compose material3 `ModalDrawerSheet`, `DismissibleDrawerSheet`, `PermanentDrawerSheet`
	(androidx/androidx@40ff481 compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/NavigationDrawer.kt
	644-902, DrawerDefaults 1052-1099; tokens/NavigationDrawerTokens.kt): the surface a drawer slides in, holding its items.

	    Material.ModalDrawerSheet({ Children = q.Slot<<Instance>>({ Material.NavigationDrawerItems<<string>>({ ... }) }) })

	Props (all optional, `read`): Children (Slot<Instance>?), Width (number?, default 360 — NavigationDrawerTokens.
	ContainerWidth = DrawerDefaults.MaximumDrawerWidth; clamped to 240..360, Compose's `sizeIn(minWidth = 240, maxWidth =
	360)`, MinimumDrawerWidth 1342-1343 — the permanent sample uses 240), Theme, Modifier (Frame), Hooks.
	  Modal        surfaceContainerLow (ModalContainerColor), corner 16 on the END edge (ContainerShape CornerLargeEnd =
	               UICorner 16 + a start-edge `Parts.patch`), no shadow (DrawerDefaults.ModalDrawerElevation = Level0 tonal;
	               the sheet has no shadow parameter)
	  Dismissible  surface (StandardContainerColor), rectangle, elevation 0
	  Permanent    surface, rectangle, elevation 0
	Height: the parent's (`fillMaxHeight`). The content is a vertical list (Compose ColumnScope) in a scrolling frame — MDC
	NavigationView's menu scrolls (design_navigation_menu.xml, `scrollbars="vertical"`, 8 bottom padding), and every Compose
	drawer sample wraps its items in `verticalScroll` after a 12 px Spacer: so 12 top, 8 bottom, items centered (each item
	carries its own 12 px side margins).
	Returns the sheet Frame (Active: 3D / camera input only). It has no ClickSink of its own: inside a ModalNavigationDrawer
	the drawer's holder carries the sink under the sheet — it stops a press on the sheet's padding from reaching the scrim
	AND takes the drawer's drag (a press stops at the first GuiButton, Util.luau "INPUT RULE": a sink on the sheet would sit
	above the holder's and swallow the drag). Structure: Frame [+ UICorner + CornerPatch] + Scroll (ScrollingFrame,
	ZIndex 2) > UIPadding + UIListLayout + the Children slot = 4 (modal 6) + the children.
]]

local q = require("../Quad")
local Tokens = require("../Tokens")
local Theme = require("../Theme")
local Util = require("../Util")
local Parts = require("../Sheet/Parts")
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

export type Props = {
	read Children: q.Slot<Instance>?,
	read Width: number?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

export type Kind = "Modal" | "Dismissible" | "Permanent"

local MAX_WIDTH = 360 -- NavigationDrawerTokens.ContainerWidth
local MIN_WIDTH = 240 -- MinimumDrawerWidth
local CORNER = Tokens.Shape.Radius.Large :: number

local function sheet(kind: Kind, props: Props?): Frame
	local p: Props = props or {}
	local theme = Theme.resolve(p.Theme)
	local modal = kind == "Modal"
	local width = math.clamp(p.Width or MAX_WIDTH, MIN_WIDTH, MAX_WIDTH)
	local color = if modal then theme.Color.SurfaceContainerLow else theme.Color.Surface
	return D.Frame {
		hostName(kind .. "DrawerSheet"),
		D.Modifier.Frame():Size(UDim2.new(0, width, 1, 0)),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Active = true, -- 3D / camera input only; inside a modal drawer the holder's ClickSink sinks the click (header)
		p.Modifier or q.None,
		if modal then D.UICorner { CornerRadius = UDim.new(0, CORNER) } else q.None,
		if modal then Parts.patch("Left", CORNER, color) else q.None,
		D.ScrollingFrame {
			Name = "Scroll",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 2,
			CanvasSize = UDim2.fromOffset(0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = theme.Color.OnSurface,
			ScrollBarImageTransparency = 1 - Tokens.State.Opacity.ScrollBar,
			D.UIPadding { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 8) },
			D.UIListLayout {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			},
			p.Children or q.None,
		},
		table.unpack(Util.hooks(p.Hooks)),
	}
end

return {
	ModalDrawerSheet = function(props: Props?): Frame
		return sheet("Modal", props)
	end,
	DismissibleDrawerSheet = function(props: Props?): Frame
		return sheet("Dismissible", props)
	end,
	PermanentDrawerSheet = function(props: Props?): Frame
		return sheet("Permanent", props)
	end,
}
