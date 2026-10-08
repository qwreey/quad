--!strict
--[[
	M3 standard side sheet — MDC `SideSheetBehavior` on a view styled `Widget.Material3.SideSheet` (material-components/
	material-components-android@60ff094 lib/java/com/google/android/material/sidesheet/; docs/components/SideSheet.md
	"Standard side sheet"): a column docked at the end (or start) edge of its parent, beside the content and without a scrim,
	that slides out (Hidden) and back (Expanded).

	    local side = Material.SheetState({ InitialValue = "Expanded", EnabledValues = { "Hidden", "Expanded" } })
	    D.Frame { ClipsDescendants = true, Size = ..., content, Material.SideSheet({ SheetState = side, Headline = "Filters",
	        Children = q.Slot<<Instance>>({ ... }) }) }
	    side.Hide() / side.Expand()

	Props (all optional, `read`)
	  SheetState   SheetState?      default a fresh `SheetState{ InitialValue = "Expanded", EnabledValues = { "Hidden",
	                                "Expanded" } }`. A side sheet has no PartiallyExpanded: a state that enables it is an error
	  SheetEdge    ("End" | "Start")?  default "End" (the right edge); MDC `layout_gravity` end / start
	  Width        number?          default 256 (md.comp.sheet.side docked container width)
	  Draggable    boolean?         default true (MDC behavior_draggable): the sheet follows a horizontal drag and a release
	                                settles it (MDC's rule — SideSheet/Surface.luau)
	  Headline     (string | State<string>)?  the optional header: the headline + a close icon button (which calls `Hide`;
	                                the button is left out when the state cannot hide)
	  Children     Slot<Instance>?  the content, stacked vertically under the header
	  Theme, Modifier (Frame, after the base style), Hooks
	Returns the sheet Frame (surface, no corner, no elevation — tokens md.comp.sheet.side docked standard). The PARENT must
	clip (`ClipsDescendants`): a hidden sheet sits just past its edge. Motion: 275 ms Emphasized (Sheet/Parts.luau).
	Not here: MDC's coplanar mode (the sibling squeezed as the sheet expands) and the detached style (16 px margin, all
	corners large).
]]

local q = require("../Quad")
local Theme = require("../Theme")
local Util = require("../Util")
local StateModule = require("../Sheet/State")
local Anchored = require("../Sheet/Anchored")
local Surface = require("./Surface")

export type Props = {
	read SheetState: StateModule.SheetState?,
	read SheetEdge: Surface.Edge?,
	read Width: number?,
	read Draggable: boolean?,
	read Headline: (string | q.State<string>)?,
	read Children: q.Slot<Instance>?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

local WIDTH = 256 -- m3_comp_sheet_side_docked_container_width

local function SideSheet(props: Props?): Frame
	local p: Props = props or {}
	local theme = Theme.resolve(p.Theme)
	local state = p.SheetState or StateModule.SheetState({ InitialValue = "Expanded", EnabledValues = { "Hidden", "Expanded" } })
	local rec = Anchored.recOf(state, "SideSheet")
	local built = Surface.build({
		Theme = theme,
		State = state,
		Who = "SideSheet",
		Modal = false,
		Edge = p.SheetEdge or "End",
		Width = p.Width or WIDTH,
		Draggable = p.Draggable ~= false,
		Headline = p.Headline,
		ShowClose = rec.Enabled.Hidden == true,
		OnCloseClick = function()
			if rec.Enabled.Hidden then
				state.Hide()
			end
		end,
		Children = p.Children,
		Modifier = p.Modifier,
		Hooks = Util.hooks(p.Hooks),
	})
	return built.Sheet
end

return SideSheet
