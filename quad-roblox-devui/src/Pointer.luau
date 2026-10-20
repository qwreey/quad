--!strict
--[[
	Pointer — internal "is this element on top under the pointer" (not exported from init.luau). ONE rule for hover,
	tooltips and the window manager's press-to-front: walking the engine's list of GUI objects at the point from the
	top, the element (or one of its descendants) comes before anything that TAKES THE CLICK — a GuiButton, a TextBox or
	an Active GuiObject. So a hover look agrees with where a press would go.

	Why it is needed: the engine sends MouseEnter / MouseLeave to COVERED elements too — a TextButton, an Active Frame
	or a ScrollingFrame on top does not stop them; only clicks are taken by what is on top (Studio-confirmed
	2026-10-20). `PlayerGui:GetGuiObjectsAtPosition` lists the objects topmost first (Studio-confirmed the same day).

		Pointer.takesClick(inst)           GuiButton / TextBox / Active GuiObject
		Pointer.containsTaker(inst)        inst or a descendant takes the click
		Pointer.objectsAt(inst, x, y)      the engine's list at (x, y) for the PlayerGui that shows inst; nil when inst is
		                                   not in a ScreenGui under a PlayerGui (a story host's plugin widget, detached)
		Pointer.isTop(inst, x, y)          true / false; nil when objectsAt is nil (callers keep the engine's own answer)
		Pointer.mouse()                    the mouse in AbsolutePosition space
		Pointer.watch(fn) -> unwatch       fn(x, y) runs on every mouse move, and after `invalidate`, while watched
		Pointer.invalidate()               something moved over or away from the pointer without the mouse moving (a
		                                   popup opened or closed, a window was raised or hidden): the watchers run once,
		                                   on the Heartbeat after the next render (when the engine's list has changed)

	x, y are AbsolutePosition space (`InputObject.Position`). Classes are recognised by ClassName (the spec mock has no
	IsA hierarchy).
]]

local GlobalInput = require("./GlobalInput")
local Input = require("./Input")
local Visibility = require("./Visibility")

local Pointer = {}

local TAKES_CLICK: { [string]: true } = {
	TextButton = true,
	ImageButton = true,
	TextBox = true,
}

function Pointer.takesClick(inst: Instance): boolean
	return TAKES_CLICK[inst.ClassName] == true or (Visibility.isGuiObject(inst) and (inst :: any).Active == true)
end

function Pointer.containsTaker(inst: Instance): boolean
	if Pointer.takesClick(inst) then
		return true
	end
	for _, child in inst:GetChildren() do
		if Pointer.containsTaker(child) then
			return true
		end
	end
	return false
end

function Pointer.objectsAt(inst: Instance, x: number, y: number): { GuiObject }?
	local layer = Visibility.layerOf(inst)
	if layer == nil or layer.ClassName ~= "ScreenGui" then
		return nil
	end
	local host: any = layer.Parent
	if host == nil or host.ClassName ~= "PlayerGui" then
		return nil
	end
	return host:GetGuiObjectsAtPosition(x, y)
end

local function within(o: Instance, root: Instance): boolean
	local cursor: Instance? = o
	while cursor ~= nil do
		if cursor == root then
			return true
		end
		cursor = cursor.Parent
	end
	return false
end

function Pointer.isTop(inst: Instance, x: number, y: number): boolean?
	local list = Pointer.objectsAt(inst, x, y)
	if list == nil then
		return nil
	end
	for _, o in list do
		if within(o, inst) then
			return true
		elseif Pointer.takesClick(o) then
			return false
		end
	end
	return false
end

function Pointer.mouse(): Vector2
	-- GetMouseLocation ignores the GUI inset; AbsolutePosition space includes it
	return Input.service():GetMouseLocation() - Input.guiInset()
end

type Watcher = (x: number, y: number) -> ()

local watchers: { [Watcher]: true } = {}
local watched = 0
local offMove: (() -> ())? = nil
local scheduled = false

local function runAll()
	local m = Pointer.mouse()
	for fn in watchers do
		fn(m.X, m.Y)
	end
end

function Pointer.watch(fn: Watcher): () -> ()
	watchers[fn] = true
	watched += 1
	if offMove == nil then
		offMove = GlobalInput.connect(Input.service(), "InputChanged", function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				runAll()
			end
		end)
	end
	return function()
		if watchers[fn] == nil then
			return
		end
		watchers[fn] = nil
		watched -= 1
		local off = offMove
		if watched == 0 and off ~= nil then
			offMove = nil
			off()
		end
	end
end

function Pointer.invalidate()
	if scheduled or watched == 0 then
		return
	end
	scheduled = true
	-- the engine's list changes only after the next render: a judge in task.defer, on the same frame's Heartbeat or in
	-- the next PreRender still sees the old list; the Heartbeat after the next PreRender sees the new one (Studio
	-- 2026-10-20, a window hidden and shown under a still mouse)
	local RunService = game:GetService("RunService")
	local onRender: RBXScriptConnection? = nil
	onRender = RunService.PreRender:Connect(function()
		local c = onRender
		if c then
			onRender = nil
			c:Disconnect()
		end
		local onBeat: RBXScriptConnection? = nil
		onBeat = RunService.Heartbeat:Connect(function()
			local b = onBeat
			if b then
				onBeat = nil
				b:Disconnect()
			end
			scheduled = false
			runAll()
		end)
	end)
end

return Pointer
