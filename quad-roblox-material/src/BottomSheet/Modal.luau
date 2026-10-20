--!strict
--[[
	M3 modal bottom sheet, opened through the kit Overlay — Compose material3 `ModalBottomSheet` (androidx/androidx@40ff481
	compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/ModalBottomSheet.kt 94-206) with its
	sheet `BottomSheet` (BottomSheet.kt 115-406).

	    local handle = Material.ModalBottomSheet.open({
	        Children = q.Slot<<Instance>>({ ... }),     -- the sheet's column
	        OnClose = function(result) ... end,          -- Compose onDismissRequest
	    })
	    handle.Close()                                    -- animate out and close (idempotent, no self)
	    handle.SheetState.Expand()

	OpenOptions (all optional, `read`)
	  Children              Slot<Instance>?   the sheet's content, stacked vertically (Compose `content: ColumnScope`)
	  SheetState            SheetState?       default a fresh `SheetState{ InitialValue = "Hidden" }` with all three values
	                                          (rememberModalBottomSheetState); a state whose target is Hidden is shown (`Show`)
	                                          once the sheet is laid out (Compose's LaunchedEffect, 175-187), so it rises from
	                                          the bottom; one that is already visible appears where it is
	  SheetMaxWidth         number?           default 640
	  SheetGesturesEnabled  boolean?          default true: the sheet follows a drag (sheetGesturesEnabled)
	  DragHandle            boolean?          default true (dragHandle = BottomSheetDefaults.DragHandle; false = none)
	  DismissOnScrim        boolean?          default true — ModalBottomSheetProperties.shouldDismissOnClickOutside: a tap on the
	                                          scrim hides the sheet (if ConfirmValueChange allows Hidden) and closes
	  DismissOnEscape       boolean?          default true — shouldDismissOnBackPress: Escape / gamepad B is the back press
	                                          (`settleToDismiss`, 125-134): Expanded with a PartiallyExpanded anchor steps down to
	                                          it, otherwise the sheet hides and closes. false: the key does nothing (the sheet still
	                                          shields entries opened below it)
	  OnClose               ((result: unknown?) -> ())?  once, when closing starts (a drag to Hidden, the scrim, the back key,
	                                          `handle.Close(result)`, the layer's death)
	  Overlay, Theme
	Handle (the kit-wide shape): Close(result?) (closure, no self — animates the sheet out), IsOpen / Closing (the Overlay
	entry's), SheetState (the state shown).

	The sheet: surfaceContainerLow, top corners 28, no shadow (ModalBottomSheet tonalElevation 0, the Surface's shadow 0),
	centered, at most 640 wide, as tall as its content + the 48 px handle box, at most the layer's height; anchors and drag
	in BottomSheet/Sheet.luau. Drag handle click (BottomSheet.kt 364-372): Expanded -> hide and close (animateToDismiss);
	PartiallyExpanded -> Expand; Hidden -> Show.
	SCRIM: the sheet's own (Compose's `Scrim` in the dialog window, 143-157): the scrim color at 0.32 while the target is not
	Hidden, faded (Sheet/Parts.luau Motion.Scrim) — so it starts fading the moment a released drag heads to Hidden. The
	Overlay entry carries no Overlay scrim; the entry still traps gamepad selection and owns the Escape plumbing (its
	`OnEscape` runs settleToDismiss). Closing: the entry closes as soon as the sheet heads to Hidden (`IsOpen` false at once,
	the kit rule) and is removed after its exit time (the scrim fade, which outlasts the 0.1 s hide); Compose calls
	onDismissRequest after the hide animation instead.
]]

local q = require("../Quad")
local Theme = require("../Theme")
local Overlay = require("../Overlay")
local StateModule = require("../Sheet/State")
local Anchored = require("../Sheet/Anchored")
local Parts = require("../Sheet/Parts")
local Sheet = require("./Sheet")
local Frame = q.Elem "Frame"

export type OpenOptions = {
	read Children: q.Slot<Instance>?,
	read SheetState: StateModule.SheetState?,
	read SheetMaxWidth: number?,
	read SheetGesturesEnabled: boolean?,
	read DragHandle: boolean?,
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

local MAX_WIDTH = 640

local function open(o: OpenOptions?): Handle
	local opts: OpenOptions = o or {}
	local overlay = opts.Overlay or Overlay.default()
	local theme = Theme.resolve(opts.Theme)
	local state = opts.SheetState or StateModule.SheetState({ InitialValue = "Hidden" })
	local rec = Anchored.recOf(state, "ModalBottomSheet.open")
	local ov: Overlay.Handle? = nil
	local built: Sheet.Built? = nil

	-- close the entry (idempotent); the sheet animates out during the entry's exit time
	local function dismiss()
		local h = ov
		if h ~= nil and h.IsOpen:Get() then
			h.Close(nil)
		end
	end

	-- Compose animateToDismiss (BottomSheet.kt 263-273 / ModalBottomSheet.kt 113-123)
	local function animateToDismiss()
		if rec.Enabled.Hidden and Anchored.confirm(rec, "Hidden") then
			Anchored.go(rec, "Hidden", "Hide")
		end
	end

	-- Compose settleToDismiss (ModalBottomSheet.kt 125-134): the back press
	local function settleToDismiss()
		local d = rec.Driver
		if rec.Current:Get() == "Expanded" and d ~= nil and d.HasAnchor("PartiallyExpanded") then
			state.PartialExpand()
			return
		end
		if rec.Enabled.Hidden and Anchored.confirm(rec, "Hidden") then
			Anchored.go(rec, "Hidden", "Hide")
		end
		dismiss()
	end

	local function build(h: Overlay.Handle): Instance
		ov = h
		local b = Sheet.build({
			Theme = theme,
			State = state,
			Who = "ModalBottomSheet.open",
			Modal = true,
			PeekHeight = 0,
			MaxWidth = opts.SheetMaxWidth or MAX_WIDTH,
			Gestures = opts.SheetGesturesEnabled ~= false,
			DragHandle = opts.DragHandle ~= false,
			Shadow = nil,
			Children = opts.Children,
			OnHandleClick = function(current: StateModule.SheetValue)
				if current == "Expanded" then
					animateToDismiss()
				elseif current == "PartiallyExpanded" then
					state.Expand()
				else
					state.Show()
				end
			end,
			OnGo = function(value: string)
				if value == "Hidden" then
					dismiss()
				end
			end,
			OnLaidOut = function()
				if h.IsOpen:Get() and rec.Target:Get() == "Hidden" then
					state.Show()
				end
			end,
		})
		built = b
		local scrimTransparency: q.State<any> = rec.Target:Compute(function(self)
			local m = Parts.Motion.Scrim
			return q.Tween({
				Value = if self:Get() ~= "Hidden" then 1 - Parts.ScrimOpacity else 1,
				Time = m.Time,
				Style = m.Style,
				Direction = m.Direction,
			})
		end)
		return Frame {
			Name = "ModalBottomSheet",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			b.HostHook,
			Parts.scrim({
				Theme = theme,
				Transparency = scrimTransparency,
				OnClick = function()
					if opts.DismissOnScrim ~= false then
						animateToDismiss()
					end
				end,
			}),
			b.Sheet,
		}
	end

	local handle = overlay:Open({
		Content = build,
		Scrim = false,
		DismissOnEscape = true,
		OnEscape = function()
			if opts.DismissOnEscape ~= false then
				settleToDismiss()
			end
		end,
		TrapSelection = true,
		ExitTime = Parts.Motion.Scrim.Time,
		OnClose = function(_reason: Overlay.CloseReason, result: unknown?)
			-- closed from code / the layer died: the sheet heads to Hidden without asking (it is going away)
			if rec.Target:Get() ~= "Hidden" then
				Anchored.go(rec, "Hidden", "Hide")
			end
			-- hand the state back now: the same state may open another sheet while this one slides out
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
