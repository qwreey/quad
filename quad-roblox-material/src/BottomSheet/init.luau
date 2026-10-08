--!strict
--[[
	Bottom sheets (Material 3) — Compose material3 (androidx/androidx@40ff481 compose/material3/material3/src/commonMain/
	kotlin/androidx/compose/material3/): the standard sheet `BottomSheetScaffold` (BottomSheetScaffold.kt) and the modal
	sheet `ModalBottomSheet` (ModalBottomSheet.kt + BottomSheet.kt), both driven by a `SheetState` (SheetDefaults.kt) —
	m3.material.io/components/bottom-sheets.

	    Material.BottomSheetScaffold({ SheetContent = slot, Content = page })     -- docked in a host, no scrim
	    Material.ModalBottomSheet.open({ Children = slot })                        -- over a scrim, in the Overlay
	    Material.SheetState({ InitialValue = "Hidden" })                           -- Hidden / PartiallyExpanded / Expanded

	Files: Sheet (the shared surface: anchors, drag, handle) / Scaffold / Modal. The state lives in Sheet/State.luau (the
	side sheets share it), the drag + motion driver in Sheet/Slide.luau, the anchor math in Sheet/Anchored.luau.
]]

local Scaffold = require("@self/Scaffold")
local Modal = require("@self/Modal")

export type ScaffoldProps = Scaffold.Props
export type ModalOptions = Modal.OpenOptions
export type ModalHandle = Modal.Handle

return {
	BottomSheetScaffold = Scaffold,
	ModalBottomSheet = Modal,
}
