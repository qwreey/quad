--!strict
--[[
	Compositor port (internal, not exported from init.luau): the private door between a window SURFACE (Window) and the
	compositor that owns its decoration (WindowManager). It keeps the public `Manager` / `ManagerSlot` types free of
	the calls only Window makes.

		Compositor.decorate(slot, hints) -> Placement   the manager builds the slot's decoration from the surface's
		                                                hints and answers where the surface goes (once per slot)
		Compositor.setOpen(slot, open)                   the surface's open state changed (or `Open:Set(true)` was asked
		                                                again): open raises with the focus, closed passes the focus on
		Compositor.partsOf(root) -> { Instance }        the decoration instances of a surface root (specs, tooling)
		Compositor.bind / bindRoot / unbind              the manager's side: a slot's port at Register, its root once
		                                                hooked, both dropped at the slot's Release

	A slot that never calls `decorate` is an undecorated window (a hand-made root with `slot.Hook`, Manager header).
]]

local Decoration = require("./Decoration")
local Util = require("../Util")

export type Port = {
	decorate: (hints: Decoration.Hints) -> Decoration.Placement,
	setOpen: (open: boolean) -> (),
	parts: () -> { Instance },
}

local Compositor = {}

-- slot table -> its port. Strong on purpose: a port's closures hold its slot and (through the manager entry) the
-- root, and Luau weak tables are not ephemerons, so weak keys would never be collected anyway. `unbind` (the slot's
-- Release) is what drops both entries.
local ports: { [any]: Port } = {}
-- surface root -> its port (for partsOf)
local byRoot: { [Instance]: Port } = {}

function Compositor.bind(slot: any, port: Port)
	ports[slot] = port
end

function Compositor.bindRoot(root: Instance, slot: any)
	local port = ports[slot]
	if port ~= nil then
		byRoot[root] = port
	end
end

function Compositor.unbind(slot: any, root: Instance?)
	ports[slot] = nil
	if root ~= nil then
		byRoot[root] = nil
	end
end

function Compositor.decorate(slot: any, hints: Decoration.Hints): Decoration.Placement
	local port = ports[slot]
	if port == nil then
		-- a hand-made `Manager` table: its slots have no compositor to draw the title bar and the frame
		return Util.fail("Window", "Manager must be made by Devui.WindowManager.new()")
	end
	return port.decorate(hints)
end

function Compositor.setOpen(slot: any, open: boolean)
	local port = ports[slot]
	if port ~= nil then
		port.setOpen(open)
	end
end

function Compositor.partsOf(root: Instance): { Instance }
	local port = byRoot[root]
	return if port ~= nil then port.parts() else {}
end

return Compositor
