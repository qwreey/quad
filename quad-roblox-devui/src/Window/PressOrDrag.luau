--!strict
--[[
	Press-or-drag (internal, compositor side): one pointer gesture on a decoration part that is EITHER a press (released
	without moving far) OR a drag (moved past a small threshold). A collapsed window's icon uses it (press = expand,
	drag = move); a tab of a future tab strip needs the same split (press = select, drag = tear off), so it lives here
	once instead of in each decoration.

		local gesture = PressOrDrag.new({
			OnPress = function() ... end,            -- released before the pointer moved THRESHOLD pixels
			OnDragBegin = function() ... end,        -- optional; the pointer crossed the threshold (once per gesture)
			OnDrag = function(dx, dy) ... end,       -- optional; every move after that, delta from the PRESS point
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
	OnDragBegin: (() -> ())?,
	OnDrag: ((dx: number, dy: number) -> ())?,
}

export type Gesture = {
	Hook: Types.GuiHook,
}

local PressOrDrag = {}

-- Dear ImGui's `io.MouseDragThreshold` default: a hand that only meant to click drifts a few pixels
PressOrDrag.THRESHOLD = 6

function PressOrDrag.new(options: Options): Gesture
	local onPress, onDragBegin, onDrag = options.OnPress, options.OnDragBegin, options.OnDrag
	local moved = false
	local handle = Interaction.drag({
		OnBegin = function()
			moved = false
		end,
		OnMove = function(_x, _y, dx, dy)
			if not moved then
				local t = PressOrDrag.THRESHOLD
				if dx * dx + dy * dy < t * t then
					return
				end
				moved = true
				if onDragBegin then
					onDragBegin()
				end
			end
			if onDrag then
				onDrag(dx, dy)
			end
		end,
		OnEnd = function(_x, _y, _dx, _dy, cancelled)
			if not moved and not cancelled then
				onPress()
			end
		end,
	})
	return { Hook = handle.Hook }
end

return PressOrDrag
