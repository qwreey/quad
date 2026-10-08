--!strict
--[[
	M3 modal side sheet, opened through the kit Overlay — MDC `SideSheetDialog` (material-components/material-components-android
	@60ff094 lib/java/com/google/android/material/sidesheet/SideSheetDialog.java, SheetDialog.java; style
	`Widget.Material3.SideSheet.Modal`, res/values/styles.xml 42-51; docs/components/SideSheet.md "Modal side sheet").

	    local handle = Material.ModalSideSheet.open({ Headline = "Details", Children = q.Slot<<Instance>>({ ... }) })
	    handle.Close()

	OpenOptions (all optional, `read`)
	  Children        Slot<Instance>?   the content, stacked vertically under the header
	  Headline        (string | State<string>)?  the optional header: headline + a close icon button (closes)
	  SheetEdge       ("End" | "Start")?   default "End" (the right edge) — SideSheetDialog.setSheetEdge
	  Width           number?           default 256 (m3_side_sheet_width = the docked container width)
	  Draggable       boolean?          default true: dragging it off the screen closes it (MDC: "can be dragged horizontally and
	                                    dismissed by sliding them off of the screen")
	  DismissOnScrim  boolean?          default true — a tap outside cancels (Dialog canceledOnTouchOutside)
	  DismissOnEscape boolean?          default true — Escape / gamepad B is the back press (Dialog cancelable)
	  OnClose         ((result: unknown?) -> ())?  once, when closing starts
	  Overlay, Theme
	Handle (the kit-wide shape): Close(result?), IsOpen / Closing (the Overlay entry's), SheetState (its own state: Hidden ->
	Expanded on open).

	The sheet: surfaceContainerLow, corner 16 on the inner edge, a level-1 shadow, full height — SideSheet/Surface.luau.
	Scrim: the Overlay's (the scrim color at 0.32 — the dialog's dim). Enter and exit: the sheet slides in from / out to its
	edge, 275 ms Emphasized (m3_side_sheet_enter_from_right / exit_to_right, res/anim); the Overlay entry stays for that exit
	time. Escape / B and the gamepad selection trap are the Overlay's.
]]

local q = require("../Quad")
local Theme = require("../Theme")
local Util = require("../Util")
local Overlay = require("../Overlay")
local StateModule = require("../Sheet/State")
local Anchored = require("../Sheet/Anchored")
local Parts = require("../Sheet/Parts")
local Surface = require("./Surface")
local D = q.Declaration

export type OpenOptions = {
	read Children: q.Slot<Instance>?,
	read Headline: (string | q.State<string>)?,
	read SheetEdge: Surface.Edge?,
	read Width: number?,
	read Draggable: boolean?,
	read DismissOnScrim: boolean?,
	read DismissOnEscape: boolean?,
	read OnClose: ((result: unknown?) -> ())?,
	read Overlay: Overlay.Overlay?,
	read Theme: Theme.Theme?,
}

export type Handle = {
	Close: (result: unknown?) -> (),
	read IsOpen: q.State<boolean>,
	read Closing: q.State<boolean>,
	read SheetState: StateModule.SheetState,
}

local WIDTH = 256 -- m3_side_sheet_width

local function open(o: OpenOptions?): Handle
	local opts: OpenOptions = o or {}
	local overlay = opts.Overlay or Overlay.default()
	local theme = Theme.resolve(opts.Theme)
	local state = StateModule.SheetState({ InitialValue = "Hidden", EnabledValues = { "Hidden", "Expanded" } })
	local rec = Anchored.recOf(state, "ModalSideSheet.open")
	local ov: Overlay.Handle? = nil
	local built: Surface.Built? = nil

	local function dismiss()
		local h = ov
		if h ~= nil and h.IsOpen:Get() then
			h.Close(nil)
		end
	end

	local function build(h: Overlay.Handle): Instance
		ov = h
		local b = Surface.build({
			Theme = theme,
			State = state,
			Who = "ModalSideSheet.open",
			Modal = true,
			Edge = opts.SheetEdge or "End",
			Width = opts.Width or WIDTH,
			Draggable = opts.Draggable ~= false,
			Headline = opts.Headline,
			ShowClose = true,
			OnCloseClick = dismiss,
			Children = opts.Children,
			OnGo = function(value: string)
				if value == "Hidden" then
					dismiss()
				end
			end,
		})
		built = b
		return D.Frame {
			Name = "ModalSideSheet",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			b.Sheet,
			-- mounted hidden (the first write snaps), then slides in
			Util.postHook(function()
				if h.IsOpen:Get() then
					state.Expand()
				end
			end),
		}
	end

	local handle = overlay:Open({
		Content = build,
		Scrim = true,
		Dismissable = opts.DismissOnScrim ~= false,
		DismissOnEscape = opts.DismissOnEscape ~= false,
		TrapSelection = true,
		ExitTime = Parts.Motion.Side.Time,
		OnClose = function(_reason: Overlay.CloseReason, result: unknown?)
			if rec.Target:Get() ~= "Hidden" then
				Anchored.go(rec, "Hidden", "Hide")
			end
			local b = built
			if b ~= nil then
				b.Slide.Detach()
			end
			if opts.OnClose then
				opts.OnClose(result)
			end
		end,
	})
	ov = handle
	return {
		Close = function(result: unknown?)
			handle.Close(result)
		end,
		IsOpen = handle.IsOpen,
		Closing = handle.Closing,
		SheetState = state,
	}
end

return { open = open }
