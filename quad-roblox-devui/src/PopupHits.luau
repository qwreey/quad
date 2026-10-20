--!strict
--[[
	PopupHits — internal registry of the open Overlay popups that take input, for "is this point on a popup?" (not
	exported from init.luau). Used only where there is no PlayerGui (a story host's plugin widget); in a game the
	window manager asks the internal Pointer rule instead. Overlay adds a record when a popup opens and removes it when
	it closes; the window manager asks `covers(x, y)` before it focuses the window under a press, so pressing a popup
	(a Combo list, a Menu, or the click-outside catcher of a popup with one) never changes which window is focused. A
	popup that takes no input (a tooltip) is not listed: a press through it raises the window behind.

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
