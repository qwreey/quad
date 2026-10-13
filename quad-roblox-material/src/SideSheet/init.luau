--!strict
--[[
	Side sheets (Material 3) — material-components-android `SideSheetBehavior` / `SideSheetDialog` (material-components/
	material-components-android@60ff094 lib/java/com/google/android/material/sidesheet/; Compose material3 has no side sheet)
	— m3.material.io/components/side-sheets.

	    Material.SideSheet({ Headline = "Filters", Children = slot })              -- standard: docked at the parent's edge
	    Material.ModalSideSheet.open({ Headline = "Details", Children = slot })    -- modal: over a scrim, in the Overlay

	Both use the kit's `SheetState` with the two MDC states (EnabledValues { "Hidden", "Expanded" }) and both take
	`Detached = true` (MDC `Widget.Material3.SideSheet.Detached` / `.Modal.Detached`: 16 px off the edge, all four corners
	16). Files: Surface (the shared sheet: geometry, shape, drag, header) / Standard / Modal.
]]

local Standard = require("@self/Standard")
local Modal = require("@self/Modal")
local Surface = require("@self/Surface")

export type Edge = Surface.Edge
export type Props = Standard.Props
export type ModalOptions = Modal.OpenOptions
export type ModalHandle = Modal.Handle

return {
	SideSheet = Standard,
	ModalSideSheet = Modal,
}
