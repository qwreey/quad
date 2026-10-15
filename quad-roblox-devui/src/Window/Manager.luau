--!strict
--[[
	WindowManager — z-order and focus for a group of windows (focus-on-press, "bring to front").

	Windows hosted as siblings in one container are layered by ZIndex. This needs `ScreenGui.ZIndexBehavior = Sibling`,
	which is the default only for a ScreenGui inserted in Studio: one made in code (`D.ScreenGui`, `Instance.new`) is
	Global unless you set it, and under Global a window root with rank 2+ draws over its own content (a ZIndex is then
	compared across the whole ScreenGui, and the content's is 1). The manager keeps the windows in stacking order (bottom first) and a window's ZIndex is its RANK in that
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
		slot.Hook     : GuiHook                        -- put in the window ROOT's array part (press-to-front, see below)
		slot:Focus()                                   -- raise to front + focus (idempotent when already focused)
		slot:Release()                                 -- leave the manager (idempotent); the others close ranks
		manager.Focused : State<number>                -- id of the focused window (0 = none)

	A newly registered window starts on top but does NOT steal focus (the first press focuses it).

	PRESS TO FRONT. A press stops at the first GuiButton / TextBox under the pointer (engine rule): the window frame
	behind a button, a checkbox or a text box never sees an InputBegan. So the manager listens to ONE global press
	(`UserInputService.InputBegan`, mouse button 1 / touch — through `Input.service()`, opened while at least one root is
	hooked and closed when the last one leaves) and focuses the topmost (highest rank) hooked root under the pointer whose
	`Visible` is on and whose ancestors are shown. `gameProcessedEvent` is NOT filtered: a press on a widget is exactly
	the case that needs it. A press on an open Overlay popup (a Combo list, a Menu, a tooltip — or the click-outside
	catcher of a popup that has one) changes nothing. It focuses on PRESS, not release, like the title bar and Dear ImGui
	(devui has no drag-and-drop between windows that would need release-time focus).
	Hit test: the root's AbsolutePosition / AbsoluteSize rectangle against `InputObject.Position` (overlapping windows:
	the highest rank wins). Chosen over `PlayerGui:GetGuiObjectsAtPosition` because it needs no PlayerGui (a story
	host renders into a plugin widget), knows nothing about which object is "the window", and runs under the spec mock.

	FOCUS SUCCESSION (Dear ImGui: closing the focused window gives focus to the topmost remaining one). When the focused
	window is hidden (its root's `Visible` goes false — Window binds it to `Open`) or released, the topmost hooked window
	whose root is still `Visible` is focused (and raised); none left = `Focused` 0. A closed window keeps its slot; when it
	is shown again it comes to the front WITH the focus (Dear ImGui focuses an appearing window — user decision
	2026-10-15). A window that is open from the start does not steal the focus (the line above).
]]

local Input = require("../Input")
local PopupHits = require("../PopupHits")
local Quad = require("../Quad")
local q = Quad
local Types = require("../Types")
local Visibility = require("../Visibility")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>

export type Slot = {
	Id: number,
	ZIndex: State<number>,
	Focused: State<boolean>,
	Hook: Types.GuiHook,
	Focus: (self: Slot) -> (),
	Release: (self: Slot) -> (),
}

export type Manager = {
	Focused: State<number>,
	Register: (self: Manager) -> Slot,
}

type Entry = { Id: number, Z: Source<number>, Root: GuiObject? }

local Manager = {}

local function isPrimaryDown(input: InputObject): boolean
	local t = input.UserInputType
	return t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch
end

function Manager.new(): Manager
	local nextId = 0
	local focusedId: Source<number> = q.Source(0)
	-- live windows, bottom first; ZIndex = position
	local order: { Entry } = {}
	-- entries whose root is hooked (the global press listener is open while this is > 0)
	local hooked = 0
	local pressConn: RBXScriptConnection? = nil

	local function renumber()
		for i, entry in order do
			entry.Z:SetIfChanged(i)
		end
	end

	local function focus(entry: Entry)
		if focusedId:Get() == entry.Id and order[#order] == entry then
			return -- already focused AND on top (a newer registration may cover a focused window)
		end
		local at = table.find(order, entry)
		if at == nil then
			return -- released
		end
		table.remove(order, at)
		table.insert(order, entry)
		renumber()
		focusedId:SetIfChanged(entry.Id) -- (a focused window that was only covered: the rank changed, the focus did not)
	end

	-- the focused window went away (hidden or released): the topmost window still open takes the focus
	local function succeed()
		for i = #order, 1, -1 do
			local root = order[i].Root
			if root ~= nil and root.Visible ~= false then
				focus(order[i])
				return
			end
		end
		focusedId:Set(0)
	end

	local function onPress(input: InputObject)
		if not isPrimaryDown(input) then
			return
		end
		local x, y = input.Position.X, input.Position.Y
		if PopupHits.covers(x, y) then
			return
		end
		for i = #order, 1, -1 do
			local entry = order[i]
			local root = entry.Root
			if root ~= nil then
				local p, s = root.AbsolutePosition, root.AbsoluteSize
				if x >= p.X and y >= p.Y and x < p.X + s.X and y < p.Y + s.Y and Visibility.isShown(root) then
					focus(entry)
					return
				end
			end
		end
	end

	local function hook(delta: number)
		hooked += delta
		if hooked > 0 and pressConn == nil then
			pressConn = Input.service().InputBegan:Connect(onPress)
		elseif hooked == 0 and pressConn ~= nil then
			pressConn:Disconnect()
			pressConn = nil
		end
	end

	return {
		Focused = focusedId,
		Register = function(_self: Manager): Slot
			nextId += 1
			local id = nextId
			local z: Source<number> = q.Source(#order + 1)
			local entry: Entry = { Id = id, Z = z, Root = nil }
			table.insert(order, entry)
			local isFocused: State<boolean> = focusedId:Compute(function(self)
				return self:Get() == id
			end)
			local visibleConn: RBXScriptConnection? = nil

			local rootHook: Types.GuiHook = q.PostRef(nil :: GuiObject?)
			rootHook:Callback(function(inst)
				if inst == nil or entry.Root ~= nil or table.find(order, entry) == nil then
					return
				end
				entry.Root = inst
				hook(1)
				visibleConn = inst:GetPropertyChangedSignal("Visible"):Connect(function()
					if inst.Visible then
						focus(entry) -- shown again: to the front with the focus (Dear ImGui focuses an appearing window)
					elseif focusedId:Get() == id then
						succeed()
					end
				end)
			end)

			return {
				Id = id,
				ZIndex = z,
				Focused = isFocused,
				Hook = rootHook,
				Focus = function(_slot: Slot)
					focus(entry)
				end,
				Release = function(_slot: Slot)
					local at = table.find(order, entry)
					if at == nil then
						return
					end
					table.remove(order, at)
					renumber()
					if entry.Root ~= nil then
						entry.Root = nil
						local c = visibleConn
						if c then
							visibleConn = nil
							c:Disconnect()
						end
						hook(-1)
					end
					if focusedId:Get() == id then
						succeed()
					end
				end,
			}
		end,
	}
end

Manager.default = Manager.new()

return Manager
