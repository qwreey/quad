--!strict
--[[
	PopupHits — internal registry of the open Overlay popups, for "is this point on a popup?" (not exported from
	init.luau). Overlay adds a record when a popup opens and removes it when it closes; the window manager asks
	`covers(x, y)` before it focuses the window under a press, so pressing a popup (a Combo list, a Menu, a tooltip, or
	the click-outside catcher of a popup with one) never changes which window is focused.

		PopupHits.add(record) / PopupHits.remove(record)
		PopupHits.covers(x, y) -> boolean      x, y in AbsolutePosition space (InputObject.Position)

	A record is { Area: GuiObject } — the popup's catcher area (the whole layer) for a popup that closes on a click
	outside, else the popup's content holder.
]]

export type Record = { Area: GuiObject }

local PopupHits = {}

local open: { [Record]: true } = {}

function PopupHits.add(record: Record)
	open[record] = true
end

function PopupHits.remove(record: Record)
	open[record] = nil
end

function PopupHits.covers(x: number, y: number): boolean
	for record in open do
		local area = record.Area
		local p, s = area.AbsolutePosition, area.AbsoluteSize
		if x >= p.X and y >= p.Y and x < p.X + s.X and y < p.Y + s.Y then
			return true
		end
	end
	return false
end

return PopupHits
