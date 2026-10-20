--!strict
--[[
	M3 Scaffold — Compose material3 `Scaffold` (androidx/androidx@40ff481 compose/material3/material3/src/commonMain/kotlin/
	androidx/compose/material3/Scaffold.kt 86-119 the public function, 133-306 ScaffoldLayout: 174-178 topBarHeight,
	195-225 the FAB's horizontal place, 234-244 fabOffsetFromBottom, 246-254 snackbarOffsetFromBottom, 256-269 the content
	PaddingValues, 276-304 the placement and its z order (373-377); 316-356 FabPosition, 369-370 FabSpacing = 16). The
	screen frame that puts a top app bar, a bottom bar, a floating action button and a snackbar host around the content.

	    local scroll = Material.TopAppBarDefaults.exitUntilCollapsedScrollBehavior()
	    local snackbarLayer = Material.Overlay.new()                                  -- Compose SnackbarHost(...)
	    local snackbars = Material.Snackbar.new({ Overlay = snackbarLayer })          -- Compose SnackbarHostState
	    Material.Scaffold({
	        TopBar = Material.MediumFlexibleTopAppBar({ Title = "Inbox", ScrollBehavior = scroll }),
	        BottomBar = Material.ShortNavigationBar<<string>>({ Items = items, Selected = page }),
	        FloatingActionButton = Material.FAB({ Icon = "rbxassetid://…", OnClick = function()
	            snackbars:Show({ Text = "Draft saved" })
	        end }),
	        SnackbarHost = snackbarLayer.Layer,
	        Content = function(innerPadding)
	            return q.Elem "ScrollingFrame" { Size = UDim2.fromScale(1, 1), scroll.Hook,   -- Compose: Modifier.nestedScroll(...)
	                q.Elem "UIPadding" { PaddingTop = innerPadding.Top }, … }
	        end,
	    })

	Props (`read`):
	  Content         GuiObject | (innerPadding: PaddingValues) -> GuiObject   required. The screen's content; it is placed in
	                                          the content region (below) — give it Size = UDim2.fromScale(1, 1). The function
	                                          form receives `innerPadding` (PaddingValues = { Top: State<UDim> }) once, at
	                                          build: put `innerPadding.Top` in the PaddingTop of the UIPadding of the
	                                          ScrollingFrame that carries the top bar's scroll `Hook` (see CONTENT).
	  TopBar          GuiObject?              typically a kit top app bar (TopAppBar ... LargeFlexibleTopAppBar)
	  BottomBar       GuiObject?              typically ShortNavigationBar, BottomAppBar or FlexibleBottomAppBar
	  SnackbarHost    GuiObject?              the layer the snackbars draw in: an `Overlay.new()`'s `Layer`, with a
	                                          `Snackbar.new({ Overlay = thatOverlay })` host showing them (Compose: the
	                                          `SnackbarHost(hostState)` composable / its `SnackbarHostState`)
	  FloatingActionButton  GuiObject?        typically a kit FAB (any size, Extended too)
	  FloatingActionButtonPosition  FabPosition?   "Start" | "Center" | "End" (default) | "EndOverlay"
	  ContainerColor  (Color3 | State<Color3>)?    default the theme's background (Compose containerColor =
	                                          colorScheme.background)
	  Theme, Modifier (Frame), Hooks
	Returns the host Frame (100 % of its parent).

	LAYOUT (ScaffoldLayout, adapted). The top bar sits at the top, the bottom bar at the bottom (the Scaffold writes their
	AnchorPoint and Position once — it places them, as Compose places its slots). Bar heights: a kit top app bar reports its
	expanded height and its current height (the same State its Size follows — AppBar/Top.luau `measureOf`), so the content
	region moves in the same frame as a collapsing bar; any other bar is read from its `Size.Y.Offset`, followed through its
	Size change signal (give such a bar a pixel height: an AutomaticSize or Scale height reads as its offset only).
	CONTENT (the ROBLOX DIFFERENCE): Compose places the content at (0, 0) BEHIND the bars and hands it PaddingValues(top =
	the top bar's measured height, bottom = the bottom bar's height) — the bar consumes the scroll first (nested scrolling),
	so the list's padding follows the bar. A Roblox ScrollingFrame cannot hand its scroll to a parent and its scrollbar
	spans the whole frame (it cannot be inset), so content placed behind a bar has its scrollbar covered. The kit places the
	content in a REGION from the top bar's CURRENT bottom to the bottom bar's top — Body Position = (0, top), Size = (1, 0,
	1, -(top + bottom)) — so native scrollbars are never under a bar, and `innerPadding.Top` = the kit top bar's expanded
	height - its current height (what it has collapsed; 0 for any other bar or none). With it as the scrolling content's
	PaddingTop, a row sits at `expanded - CanvasPosition.Y` from the screen top — where Compose's content-behind-the-bar
	layout puts it — and the canvas grows exactly as the region shrinks, so the CanvasPosition never clamps (the layout of
	AppBar/Scroll.luau "ROBLOX DIFFERENCE"; the settle there moves the canvas with the bar). The bar's scroll `Hook` stays
	the caller's (Compose: the caller adds `Modifier.nestedScroll(scrollBehavior.nestedScrollConnection)`): put it in the
	array part of the content's ScrollingFrame. A wheel over a bar does not reach the content (it is not under the bar).
	FAB (195-225, 234-244): 16 (FabSpacing) from the start ("Start") / end ("End", "EndOverlay") edge or centered
	("Center"), its bottom 16 above the bottom bar's top — "EndOverlay" (and every position without a bottom bar) 16 above
	the scaffold's bottom, over the bottom bar.
	SNACKBAR (246-254): the SnackbarHost layer spans the scaffold's width and ends at the FAB's top when there is a FAB, else
	at the bottom bar's top, else at the scaffold's bottom; the kit Snackbar sits centered at its host's Offset (default
	16) above that edge (Compose's Snackbar adds 12 of its own padding — Snackbar.kt 272).
	Z ORDER (373-377: content 0 < top bar 1 < snackbar 2 < bottom bar 3 < FAB 4): the content region and the bars at the
	default ZIndex (they do not overlap), the FAB and the snackbar layer in one frame above them (ZIndex 2) — so a
	snackbar sliding in over a bottom bar draws above it (Compose: below).
	Not here: contentColor (Roblox has no inherited content color — each kit component picks its own role),
	contentWindowInsets (the ScreenGui's ScreenInsets / SafeAreaCompatibility own the safe area on Roblox), right-to-left
	layout.
	Instances: Scaffold + Body = 2; + Floating (1) when there is a FAB or a SnackbarHost; a FAB adds the Floating frame's
	UIPadding + UIListLayout (2); a SnackbarHost next to a FAB sits in a SnackbarHost frame + UIFlexItem (2) — at most 7 of
	its own. No connection for a kit top app bar; one Size signal per other bar; nothing per frame.
]]

local q = require("./Quad")
local Theme = require("./Theme")
local Util = require("./Util")
local Top = require("./AppBar/Top")
local Frame = q.Elem "Frame"
local UIFlexItem = q.Elem "UIFlexItem"
local UIListLayout = q.Elem "UIListLayout"
local UIPadding = q.Elem "UIPadding"
local FrameModifier = q.Modifier "Frame"
local scaffoldName = FrameModifier():Name("Scaffold")

export type FabPosition = "Start" | "Center" | "End" | "EndOverlay"

export type PaddingValues = {
	read Top: q.State<UDim>,
}

export type Props = {
	read Content: GuiObject | (innerPadding: PaddingValues) -> GuiObject,
	read TopBar: GuiObject?,
	read BottomBar: GuiObject?,
	read SnackbarHost: GuiObject?,
	read FloatingActionButton: GuiObject?,
	read FloatingActionButtonPosition: FabPosition?,
	read ContainerColor: (Color3 | q.State<Color3>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.ModifierInto<Frame>?,
	read Hooks: Util.Hooks?,
}

local FAB_SPACING = 16 -- FabSpacing (Scaffold.kt 369-370)

local ALIGN: { [FabPosition]: Enum.HorizontalAlignment } = {
	Start = Enum.HorizontalAlignment.Left,
	Center = Enum.HorizontalAlignment.Center,
	End = Enum.HorizontalAlignment.Right,
	EndOverlay = Enum.HorizontalAlignment.Right,
}

local baseModifier = FrameModifier():Size(UDim2.fromScale(1, 1)):BorderSizePixel(0)

-- a bar's current height (+ its expanded height when it is a kit top app bar)
local function heightOf(bar: GuiObject): (q.State<number>, number?)
	local m = Top.measureOf(bar)
	if m ~= nil then
		return m.Height or q.Source(m.Expanded), m.Expanded
	end
	local height = q.Source(bar.Size.Y.Offset)
	bar:GetPropertyChangedSignal("Size"):Connect(function()
		height:SetIfChanged(bar.Size.Y.Offset)
	end)
	return height, nil
end

local function Scaffold(props: Props): Frame
	local theme = Theme.resolve(props.Theme)
	local fabPosition: FabPosition = props.FloatingActionButtonPosition or "End"
	local align = ALIGN[fabPosition]
	if align == nil then
		error(`Scaffold: FloatingActionButtonPosition must be "Start", "Center", "End" or "EndOverlay" (got {fabPosition})`, 2)
	end
	local topBar, bottomBar = props.TopBar, props.BottomBar
	local fab, snackbar = props.FloatingActionButton, props.SnackbarHost

	local top: q.State<number> = q.Source(0)
	local padTop: q.State<UDim> = q.Source(UDim.new(0, 0))
	if topBar ~= nil then
		topBar.AnchorPoint = Vector2.new(0, 0)
		topBar.Position = UDim2.new()
		local current, expanded = heightOf(topBar)
		top = current
		if expanded ~= nil then
			local full = expanded
			padTop = current:Compute(function(self)
				return UDim.new(0, full - self:Get())
			end)
		end
	end
	local bottom: q.State<number> = q.Source(0)
	if bottomBar ~= nil then
		bottomBar.AnchorPoint = Vector2.new(0, 1)
		bottomBar.Position = UDim2.fromScale(0, 1)
		bottom = (heightOf(bottomBar))
	end

	local bodyPosition: q.State<UDim2> = top:Compute(function(self)
		return UDim2.fromOffset(0, self:Get())
	end)
	local bodySize: q.State<UDim2> = top:Compute(function(self, _prev, b)
		return UDim2.new(1, 0, 1, -(self:Get() + b:Get()))
	end, bottom)

	local given = props.Content
	local content: GuiObject = if type(given) == "function" then given({ Top = padTop }) else given

	-- the FAB and the snackbar layer: one frame above the content and the bars, its bottom at the bottom bar's top (or
	-- the scaffold's bottom for an EndOverlay FAB)
	local floating: Instance? = nil
	if fab ~= nil or snackbar ~= nil then
		local overBar = fab ~= nil and fabPosition == "EndOverlay"
		local size: UDim2 | q.State<UDim2> = UDim2.fromScale(1, 1)
		if bottomBar ~= nil and not overBar then
			local s: q.State<UDim2> = bottom:Compute(function(self)
				return UDim2.new(1, 0, 1, -self:Get())
			end)
			size = s
		end
		local stack: { Instance } = {}
		if fab ~= nil then
			table.insert(stack, UIPadding {
				PaddingLeft = UDim.new(0, FAB_SPACING),
				PaddingRight = UDim.new(0, FAB_SPACING),
				PaddingBottom = UDim.new(0, FAB_SPACING),
			})
			table.insert(stack, UIListLayout {
				FillDirection = Enum.FillDirection.Vertical,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
				HorizontalAlignment = align,
				SortOrder = Enum.SortOrder.LayoutOrder,
			})
			if snackbar ~= nil then
				-- above the FAB: fills the height the FAB leaves (LayoutOrder -1 sorts it before a FAB at the default 0)
				table.insert(stack, Frame {
					Name = "SnackbarHost",
					Size = UDim2.fromScale(1, 0),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					LayoutOrder = -1,
					UIFlexItem { FlexMode = Enum.UIFlexMode.Fill },
					snackbar,
				})
			end
			table.insert(stack, fab)
		elseif snackbar ~= nil then
			table.insert(stack, snackbar)
		end
		floating = Frame {
			Name = "Floating",
			Size = size,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 2,
			q.Slot<<Instance>>(stack),
		}
	end

	return Frame {
		scaffoldName,
		baseModifier,
		BackgroundColor3 = props.ContainerColor or theme.Color.Background,
		props.Modifier or q.None,
		Frame {
			Name = "Body",
			Position = bodyPosition,
			Size = bodySize,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			content,
		},
		topBar or q.None,
		bottomBar or q.None,
		floating or q.None,
		table.unpack(Util.hooks(props.Hooks)),
	}
end

return {
	Scaffold = Scaffold,
}
