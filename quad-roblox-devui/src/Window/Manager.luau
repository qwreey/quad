--!strict
--[[
	WindowManager — z-order and focus for a group of windows (focus-on-click, "bring to front").

	Windows hosted as siblings in one container are layered by ZIndex (ScreenGui.ZIndexBehavior = Sibling, the
	default). The manager keeps the windows in stacking order (bottom first) and a window's ZIndex is its RANK in that
	list (1..n): `Focus` moves the window to the end and renumbers, so the ZIndex never grows past the number of live
	windows (an ever-increasing counter would climb above the Overlay layer's ZIndex 1000 after enough focus switches and
	draw windows over popups). The window that was focused last is `Focused` (its title bar draws in the "active" colour).
	A window releases its slot when it is destroyed (Window does it), so ranks stay compact. Supports up to 999 live
	windows below the default Overlay layer.

	USAGE
		local Manager = require("./Manager")
		local manager = Manager.new()                  -- or Manager.default (shared, used when props.Manager is nil)
		local slot = manager:Register()                -- one per window
		slot.ZIndex   : State<number>                  -- bind to the window root's ZIndex
		slot.Focused  : State<boolean>                 -- is this the focused window
		slot:Focus()                                   -- raise to front + focus (idempotent when already focused)
		slot:Release()                                 -- leave the manager (idempotent); the others close ranks
		manager.Focused : State<number>                -- id of the focused window (0 = none)

	A newly registered window starts on top but does NOT steal focus (the first click focuses it).
]]

local Quad = require("../Quad")
local q = Quad

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>

export type Slot = {
	Id: number,
	ZIndex: State<number>,
	Focused: State<boolean>,
	Focus: (self: Slot) -> (),
	Release: (self: Slot) -> (),
}

export type Manager = {
	Focused: State<number>,
	Register: (self: Manager) -> Slot,
}

type Entry = { Id: number, Z: Source<number> }

local Manager = {}

function Manager.new(): Manager
	local nextId = 0
	local focusedId: Source<number> = q.Source(0)
	-- live windows, bottom first; ZIndex = position
	local order: { Entry } = {}

	local function renumber()
		for i, entry in order do
			entry.Z:SetIfChanged(i)
		end
	end

	return {
		Focused = focusedId,
		Register = function(_self: Manager): Slot
			nextId += 1
			local id = nextId
			local z: Source<number> = q.Source(#order + 1)
			local entry: Entry = { Id = id, Z = z }
			table.insert(order, entry)
			local isFocused: State<boolean> = focusedId:Compute(function(self)
				return self:Get() == id
			end)
			return {
				Id = id,
				ZIndex = z,
				Focused = isFocused,
				Focus = function(_slot: Slot)
					if focusedId:Get() == id and order[#order] == entry then
						return -- already focused AND on top (a newer registration may cover a focused window)
					end
					local at = table.find(order, entry)
					if at == nil then
						return -- released
					end
					table.remove(order, at)
					table.insert(order, entry)
					renumber()
					focusedId:Set(id) -- no-op when unchanged
				end,
				Release = function(_slot: Slot)
					local at = table.find(order, entry)
					if at == nil then
						return
					end
					table.remove(order, at)
					renumber()
					if focusedId:Get() == id then
						focusedId:Set(0)
					end
				end,
			}
		end,
	}
end

Manager.default = Manager.new()

return Manager
