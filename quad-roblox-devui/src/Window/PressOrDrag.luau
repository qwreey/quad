--!strict
--[[
	Press-or-drag (internal, compositor side): one pointer gesture on a decoration part that is EITHER a press (released
	without moving far) OR a drag (moved past a small threshold). A collapsed window's icon uses it (press = expand,
	drag = move) and so does a tab of a tab strip (press = select, drag = reorder or tear off), so it lives here once
	instead of in each decoration.

		local gesture = PressOrDrag.new({
			OnPress = function() ... end,            -- released before the pointer moved THRESHOLD pixels
			OnDragBegin = function(px, py) ... end,  -- optional; the pointer crossed the threshold (once per gesture),
			                                         -- with the PRESS point
			OnDrag = function(dx, dy, x, y) ... end, -- optional; every move after that, delta from the press point and
			                                         -- the pointer
			OnDragEnd = function(cancelled) ... end, -- optional; a gesture that was a drag ended (released or cancelled)
		})
		q.Elem "TextButton" { gesture.Hook, ... }

	Without `OnDrag` the gesture still measures the distance: a pointer that wandered past the threshold and came back
	is not a press (it was an aborted drag). A cancelled gesture (focus lost, the element destroyed) is neither.
	Tracking is Interaction.drag's (global connections only while the pointer is down).
]]

local Interaction = require("../Interaction")
local Types = require("../Types")

export type Options = {
	OnPress: () -> (),
	OnDragBegin: ((pressX: number, pressY: number) -> ())?,
	OnDrag: ((dx: number, dy: number, x: number, y: number) -> ())?,
	OnDragEnd: ((cancelled: boolean) -> ())?,
}

export type Gesture = {
	Hook: Types.GuiHook,
}

local PressOrDrag = {}

-- Dear ImGui's `io.MouseDragThreshold` default: a hand that only meant to click drifts a few pixels
PressOrDrag.THRESHOLD = 6

function PressOrDrag.new(options: Options): Gesture
	local onPress, onDragBegin, onDrag, onDragEnd = options.OnPress, options.OnDragBegin, options.OnDrag, options.OnDragEnd
	local moved = false
	local pressX, pressY = 0, 0
	local handle = Interaction.drag({
		OnBegin = function(x, y)
			moved = false
			pressX, pressY = x, y
		end,
		OnMove = function(x, y, dx, dy)
			if not moved then
				local t = PressOrDrag.THRESHOLD
				if dx * dx + dy * dy < t * t then
					return
				end
				moved = true
				if onDragBegin then
					onDragBegin(pressX, pressY)
				end
			end
			if onDrag then
				onDrag(dx, dy, x, y)
			end
		end,
		OnEnd = function(_x, _y, _dx, _dy, cancelled)
			if not moved then
				if not cancelled then
					onPress()
				end
			elseif onDragEnd then
				onDragEnd(cancelled)
			end
		end,
	})
	return { Hook = handle.Hook }
end

return PressOrDrag
