--!strict
--[[
	Interaction — reusable input factories shared by every widget. Each factory returns a small handle; the handle's
	`Hook` goes into the ARRAY PART of the element's props (it is a PostRef — it fills in when the element is built and
	connects the element's own signals). Everything a factory opens is closed again: element signals die with the
	element, and the few global connections (UserInputService during a drag) are closed on drag end, on window-focus
	loss and when the element is destroyed.

	ONE HANDLE PER ELEMENT: a handle owns per-element state — do not put the same handle on two elements.

	USAGE
		local Interaction = require("./Interaction")

		-- hover / pressed -> State<boolean> for styling
		local hover = Interaction.hover()
		D.TextButton {
			hover.Hook,                          -- array part
			BackgroundColor3 = hover.Hovered:Compute(...),   -- hover.Hovered / hover.Pressed : State<boolean>
		}

		-- drag (begin on the element, then track the pointer GLOBALLY until release / focus loss / destroy)
		local drag = Interaction.drag({
			OnBegin = function(x, y) ... end,                  -- optional; pointer position at press
			OnMove = function(x, y, dx, dy) ... end,           -- current position + delta since press (numbers: no allocation)
			OnEnd = function(x, y, dx, dy, cancelled) ... end, -- optional; cancelled = focus lost / drag:Cancel()
			Enabled = state,                                   -- optional State<boolean>; while false a press starts nothing
			                                                   -- (no global connection is opened for a disabled widget)
		})
		D.Frame { drag.Hook, ... }                           -- drag.Dragging : State<boolean>, drag:Cancel()

		-- plain "pointer went down on me" (MouseButton1 / Touch), e.g. window focus-on-click
		D.Frame { Interaction.pointerDown(function(input) ... end) }

	Coordinates are `InputObject.Position` space (the same space for begin/move/end, so deltas are exact). Convert to
	element space yourself if you need absolute positions (subtract the element's AbsolutePosition at press time).

	Touch: only the touch that began the drag is tracked (InputObject identity); mouse: MouseMovement while MouseButton1
	is held, released by the matching InputEnded.
]]

local Input = require("./Input")
local Quad = require("./Quad")
local q = Quad
local Types = require("./Types")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
export type GuiHook = Types.GuiHook

export type HoverHandle = {
	Hovered: State<boolean>,
	Pressed: State<boolean>,
	Hook: GuiHook,
	Reset: () -> (), -- drop Hovered/Pressed now (for an owner that hides an ANCESTOR, which sends no MouseLeave)
}

export type DragOptions = {
	OnBegin: ((x: number, y: number) -> ())?,
	OnMove: (x: number, y: number, dx: number, dy: number) -> (),
	OnEnd: ((x: number, y: number, dx: number, dy: number, cancelled: boolean) -> ())?,
	Enabled: State<boolean>?,
}

export type DragHandle = {
	Dragging: State<boolean>,
	Hook: GuiHook,
	Cancel: (self: DragHandle) -> (),
}

local Interaction = {}

local function isPrimaryDown(input: InputObject): boolean
	local t = input.UserInputType
	return t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch
end

-- A hook that runs `connect(inst)` once the element exists.
local function hookInto(connect: (inst: GuiObject) -> ()): GuiHook
	local hook: GuiHook = q.PostRef(nil :: GuiObject?)
	hook:Callback(function(inst)
		if inst ~= nil then
			connect(inst)
		end
	end)
	return hook
end

function Interaction.hover(): HoverHandle
	local hovered: Source<boolean> = q.Source(false)
	local pressed: Source<boolean> = q.Source(false)
	local function reset()
		hovered:SetIfChanged(false)
		pressed:SetIfChanged(false)
	end
	local hook = hookInto(function(inst)
		-- the element's OWN `Visible` going false drops the looks (a hidden element gets no MouseLeave / InputEnded).
		-- An ANCESTOR being hidden fires no signal on the element (Visible changes do not propagate as events), so an
		-- owner that hides an ancestor (Window close) calls `Reset`; AncestryChanged covers reparent / removal only.
		inst:GetPropertyChangedSignal("Visible"):Connect(function()
			if not inst.Visible then
				reset()
			end
		end)
		inst.AncestryChanged:Connect(reset)
		inst.MouseEnter:Connect(function()
			hovered:SetIfChanged(true)
		end)
		inst.MouseLeave:Connect(function()
			hovered:SetIfChanged(false)
			-- a release outside the element may never reach it: drop the pressed look on leave
			pressed:SetIfChanged(false)
		end)
		inst.InputBegan:Connect(function(input: InputObject)
			if isPrimaryDown(input) then
				pressed:SetIfChanged(true)
			end
		end)
		inst.InputEnded:Connect(function(input: InputObject)
			if isPrimaryDown(input) then
				pressed:SetIfChanged(false)
			end
		end)
	end)
	return { Hovered = hovered, Pressed = pressed, Hook = hook, Reset = reset }
end

function Interaction.pointerDown(fn: (input: InputObject) -> ()): GuiHook
	return hookInto(function(inst)
		inst.InputBegan:Connect(function(input: InputObject)
			if isPrimaryDown(input) then
				fn(input)
			end
		end)
	end)
end

function Interaction.drag(options: DragOptions): DragHandle
	local dragging: Source<boolean> = q.Source(false)
	local onBegin, onMove, onEnd = options.OnBegin, options.OnMove, options.OnEnd
	local enabled = options.Enabled

	local began: InputObject? = nil
	local startX, startY = 0, 0
	local lastX, lastY = 0, 0
	local cChanged: RBXScriptConnection? = nil
	local cEnded: RBXScriptConnection? = nil
	local cFocus: RBXScriptConnection? = nil

	local function disconnect()
		if cChanged then
			cChanged:Disconnect()
			cChanged = nil
		end
		if cEnded then
			cEnded:Disconnect()
			cEnded = nil
		end
		if cFocus then
			cFocus:Disconnect()
			cFocus = nil
		end
	end

	local function finish(cancelled: boolean, silent: boolean)
		if began == nil then
			return
		end
		began = nil
		disconnect()
		dragging:SetIfChanged(false)
		if onEnd and not silent then
			onEnd(lastX, lastY, lastX - startX, lastY - startY, cancelled)
		end
	end

	local function begin(input: InputObject)
		if began ~= nil or (enabled ~= nil and not enabled:Get()) then
			return
		end
		began = input
		local p = input.Position
		startX, startY = p.X, p.Y
		lastX, lastY = startX, startY
		local uis = Input.service()
		local isTouch = input.UserInputType == Enum.UserInputType.Touch
		cChanged = uis.InputChanged:Connect(function(changed: InputObject)
			if began == nil then
				return
			end
			local relevant
			if isTouch then
				relevant = changed == began
			else
				relevant = changed.UserInputType == Enum.UserInputType.MouseMovement
			end
			if relevant then
				local cp = changed.Position
				lastX, lastY = cp.X, cp.Y
				onMove(lastX, lastY, lastX - startX, lastY - startY)
			end
		end)
		cEnded = uis.InputEnded:Connect(function(ended: InputObject)
			if began == nil then
				return
			end
			local matches
			if isTouch then
				matches = ended == began
			else
				matches = ended.UserInputType == input.UserInputType
			end
			if matches then
				local ep = ended.Position
				lastX, lastY = ep.X, ep.Y
				finish(false, false)
			end
		end)
		cFocus = uis.WindowFocusReleased:Connect(function()
			finish(true, false)
		end)
		dragging:SetIfChanged(true)
		if onBegin then
			onBegin(startX, startY)
		end
	end

	local hook = hookInto(function(inst)
		inst.InputBegan:Connect(function(input: InputObject)
			if isPrimaryDown(input) then
				begin(input)
			end
		end)
		-- an element destroyed mid-drag must not leave global connections behind (no OnEnd: the owner is gone)
		inst.Destroying:Connect(function()
			finish(true, true)
		end)
	end)

	return {
		Dragging = dragging,
		Hook = hook,
		Cancel = function(_self: DragHandle)
			finish(true, false)
		end,
	}
end

return Interaction
