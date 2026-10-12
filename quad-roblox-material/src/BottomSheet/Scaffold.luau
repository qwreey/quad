--!strict
--[[
	M3 standard bottom sheet — Compose material3 `BottomSheetScaffold` (androidx/androidx@40ff481 compose/material3/material3/
	src/commonMain/kotlin/androidx/compose/material3/BottomSheetScaffold.kt 114-201, 241-501): a screen (the host) with its
	content and a sheet docked at the bottom that peeks, expands and (optionally) hides, without a scrim — the content stays
	usable.

	    local sheet = Material.SheetState({ InitialValue = "PartiallyExpanded", EnabledValues = { "PartiallyExpanded", "Expanded" } })
	    Material.BottomSheetScaffold({
	        SheetState = sheet,                                   -- optional (this is the default)
	        SheetContent = q.Slot<<Instance>>({ ... }),           -- the sheet's column
	        Content = q.Slot<<Instance>>({ ... }),                -- the screen behind it
	    })
	    sheet.Expand()

	Props (all optional, `read`)
	  SheetContent      Slot<Instance>?   the sheet's content, stacked vertically (Compose `sheetContent: ColumnScope`)
	  Content           Slot<Instance>?   the screen content, in a full-size `Body` frame whose bottom padding is the peek
	                                      height (Compose hands `PaddingValues(bottom = sheetPeekHeight)` to `content`)
	  SheetState        SheetState?       default: a fresh `SheetState{ InitialValue = "PartiallyExpanded", EnabledValues =
	                                      { "PartiallyExpanded", "Expanded" } }` (rememberBottomSheetScaffoldState, 187-201)
	  SheetPeekHeight   number?           default 56 (BottomSheetDefaults.SheetPeekHeight)
	  SheetMaxWidth     number?           default 640 (BottomSheetDefaults.SheetMaxWidth)
	  SheetSwipeEnabled boolean?          default true: the sheet follows a drag (sheetSwipeEnabled)
	  SheetDragHandle   boolean?          default true: the 32 x 4 handle on top (sheetDragHandle; false = none)
	  Theme, Modifier (Frame), Hooks
	Returns the host Frame: 100 % of its parent, surface color (Compose containerColor = colorScheme.surface),
	ClipsDescendants (the hidden / peeking part of the sheet is below the host's bottom edge).

	The sheet: surfaceContainerLow, top corners 28, shadow Level1 (sheetShadowElevation = BottomSheetDefaults.Elevation,
	tonal 0), centered, at most 640 wide, as tall as its content (+ the 48 px handle box) — BottomSheet/Sheet.luau.
	Drag handle click (StandardBottomSheet 393-408): Expanded -> Hide when Hidden is enabled, else PartialExpand;
	PartiallyExpanded -> Expand; Hidden -> Show.
	Not here: the scaffold's top app bar and snackbar host slots (Compose `topBar` / `snackbarHost` — put an app bar in
	`Content`, or a `Material.Scaffold` (Scaffold.luau) as the content; the kit Snackbar has its own host).
]]

local q = require("../Quad")
local Theme = require("../Theme")
local Util = require("../Util")
local StateModule = require("../Sheet/State")
local Anchored = require("../Sheet/Anchored")
local Sheet = require("./Sheet")
local D = q.Declaration
local scaffoldName = D.Modifier.Frame():Name("BottomSheetScaffold")

export type Props = {
	read SheetContent: q.Slot<Instance>?,
	read Content: q.Slot<Instance>?,
	read SheetState: StateModule.SheetState?,
	read SheetPeekHeight: number?,
	read SheetMaxWidth: number?,
	read SheetSwipeEnabled: boolean?,
	read SheetDragHandle: boolean?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

local PEEK = 56 -- BottomSheetDefaults.SheetPeekHeight
local MAX_WIDTH = 640 -- BottomSheetDefaults.SheetMaxWidth

local baseModifier = D.Modifier.Frame():Size(UDim2.fromScale(1, 1)):BorderSizePixel(0):ClipsDescendants(true)

local function BottomSheetScaffold(props: Props?): Frame
	local p: Props = props or {}
	local theme = Theme.resolve(p.Theme)
	local state = p.SheetState
		or StateModule.SheetState({ InitialValue = "PartiallyExpanded", EnabledValues = { "PartiallyExpanded", "Expanded" } })
	local rec = Anchored.recOf(state, "BottomSheetScaffold")
	local peek = p.SheetPeekHeight or PEEK

	local built = Sheet.build({
		Theme = theme,
		State = state,
		Who = "BottomSheetScaffold",
		Modal = false,
		PeekHeight = peek,
		MaxWidth = p.SheetMaxWidth or MAX_WIDTH,
		Gestures = p.SheetSwipeEnabled ~= false,
		DragHandle = p.SheetDragHandle ~= false,
		Shadow = 1,
		Children = p.SheetContent,
		OnHandleClick = function(current: StateModule.SheetValue)
			if current == "Expanded" then
				if rec.Enabled.Hidden then
					state.Hide()
				elseif rec.Enabled.PartiallyExpanded then
					state.PartialExpand()
				end
			elseif current == "PartiallyExpanded" then
				state.Expand()
			else
				state.Show()
			end
		end,
	})

	return D.Frame {
		scaffoldName,
		baseModifier,
		BackgroundColor3 = theme.Color.Surface,
		p.Modifier or q.None,
		built.HostHook,
		D.Frame {
			Name = "Body",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			D.UIPadding { PaddingBottom = UDim.new(0, peek) },
			p.Content or q.None,
		},
		built.Sheet,
		table.unpack(Util.hooks(p.Hooks)),
	}
end

return BottomSheetScaffold
