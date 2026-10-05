--!strict
--[[
	Interaction: hover / pressed / focused States for any GuiObject, and a drag tracker.

	THE PATTERN (reusable for every component of the kit): a "tracker" is made BEFORE the element, exposes
	States for the component to derive from, and exposes ONE array-part value (`.Hook`, a lifecycle hook) that
	wires the element's events to those States. Put the hook in the element's array part like any other
	value; nothing else is needed — no event props to remember, no Ref juggling:

	    local ix = Interaction.new({ Disabled = props.Disabled })
	    local layerOpacity = ix.Hovered:Compute(function(self, _, pressed) ... end, ix.Pressed)
	    return D.TextButton {
	        ix.Hook,                                   -- <- connects MouseEnter/Leave, InputBegan/Ended, SelectionGained/Lost
	        Activated = props.OnClick,
	        ...
	    }

	ONE TRACKER = ONE ELEMENT: the hook is a one-shot PreRef (quad refuses to place it twice, Quad0069), so a
	component builds its tracker inside the component function, per instance — never at module scope.

	Why a hook and not event props: one table entry replaces six event keys, and the engine connections made
	by the hook live on the element itself, so they die with it (`q.dispose` / `Destroy`) — nothing to close.
	(Connections to GLOBAL signals — `UserInputService` — are the ones that can leak; `Interaction.drag` is
	the only place that opens them and it closes them at drag end AND on element death.)

	Interaction.new(opts) -> Interaction
	  opts.Disabled      boolean | State<boolean>   while true, hover/press/focus never turn ON (they can
	                                                still turn OFF, so nothing sticks when the flag flips)
	  opts.OnPressBegan  (position: Vector2?) -> () a pointer/gamepad press started; `position` is the input
	                                                position in the SAME space as `AbsolutePosition`, nil for
	                                                a gamepad/keyboard press (no pointer) — ripples use it
	  opts.OnPressEnded  (cancelled: boolean) -> () released (false) or cancelled by the pointer leaving (true)
	  opts.OnHost        (inst: GuiObject) -> ()    runs once when the hook meets the element, before any
	                                                connection (one place to set element properties, e.g. a
	                                                SelectionImageObject, without a second hook)
	  .Hovered / .Pressed / .Focused   State<boolean>   (Focused = gamepad/keyboard selection, not mouse)
	  .Hook              array-part value
	A press = MouseButton1, Touch, or gamepad ButtonA going down ON the element. The pointer leaving the
	element while pressed cancels the press (ripples fade, like Android) — one MouseLeave handler covers a
	touch lifting off outside too, so no global input connection is needed for plain buttons.

	Interaction.drag(opts) -> Drag     (sliders, scrubbers, color-picker areas, resizers)
	  opts.OnBegan  (x: number, y: number) -> ()                     drag started on the element
	  opts.OnMoved  (x: number, y: number, dx: number, dy: number) -> ()   pointer moved (screen px, no allocation)
	  opts.OnEnded  (x: number, y: number, cancelled: boolean) -> () released (false) / window focus lost or
	                                                                   element destroyed (true)
	  opts.Disabled boolean | State<boolean>
	  opts.LockScroll boolean?     while a drag runs, switch off `ScrollingEnabled` of the nearest ancestor `ScrollingFrame`
	                               (a drag inside a scrolling dialog body must not also scroll it) and restore it at the end
	  .Dragging     State<boolean>
	  .Hook         array-part value
	  :Cancel()     end an active drag now (cancelled = true)
	While dragging (and ONLY then) it holds three UserInputService connections: InputChanged, InputEnded,
	WindowFocusReleased. All three are disconnected when the drag ends, when the window loses focus, and
	when the element is destroyed. Mouse drags are tracked until MouseButton1 is released ANYWHERE (the
	pointer may leave the element); touch drags follow the touch that began on the element.
]]

local q = require("./Quad")

local UserInputService = game:GetService("UserInputService")

local Util = require("./Util")

local _hookProto = Util.preHook(function() end)
export type Hook = typeof(_hookProto)

export type Options = {
	Disabled: (boolean | q.State<boolean>)?,
	OnPressBegan: ((position: Vector2?) -> ())?,
	OnPressEnded: ((cancelled: boolean) -> ())?,
	OnHost: ((inst: GuiObject) -> ())?,
}

export type Interaction = {
	read Hovered: q.State<boolean>,
	read Pressed: q.State<boolean>,
	read Focused: q.State<boolean>,
	read Hook: Hook,
}

export type DragOptions = {
	Disabled: (boolean | q.State<boolean>)?,
	OnBegan: ((x: number, y: number) -> ())?,
	OnMoved: ((x: number, y: number, dx: number, dy: number) -> ())?,
	OnEnded: ((x: number, y: number, cancelled: boolean) -> ())?,
	LockScroll: boolean?,
}

export type Drag = {
	read Dragging: q.State<boolean>,
	read Hook: Hook,
	Cancel: (self: Drag) -> (),
}

-- Is this input a "press" of the element (primary pointer button, a touch, or the gamepad confirm button)?
local function isPress(input: InputObject): boolean
	local t = input.UserInputType
	return t == Enum.UserInputType.MouseButton1
		or t == Enum.UserInputType.Touch
		or (t == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.ButtonA)
end

local function new(opts: Options?): Interaction
	local o: Options = opts or {}
	local hovered = q.Source(false)
	local pressed = q.Source(false)
	local focused = q.Source(false)

	local function endPress(cancelled: boolean)
		if pressed:Get() then
			pressed:Set(false)
			if o.OnPressEnded then
				o.OnPressEnded(cancelled)
			end
		end
	end

	local hook = Util.preHook(function(inst)
		if o.OnHost then
			o.OnHost(inst)
		end
		inst.MouseEnter:Connect(function()
			if not Util.peekBool(o.Disabled) then
				hovered:SetIfChanged(true)
			end
		end)
		inst.MouseLeave:Connect(function()
			hovered:SetIfChanged(false)
			endPress(true)
		end)
		inst.InputBegan:Connect(function(input: InputObject)
			if Util.peekBool(o.Disabled) or not isPress(input) or pressed:Get() then
				return
			end
			pressed:Set(true)
			if o.OnPressBegan then
				local t = input.UserInputType
				if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
					o.OnPressBegan(Vector2.new(input.Position.X, input.Position.Y))
				else
					o.OnPressBegan(nil)
				end
			end
		end)
		inst.InputEnded:Connect(function(input: InputObject)
			if isPress(input) then
				endPress(false)
			end
		end)
		inst.SelectionGained:Connect(function()
			if not Util.peekBool(o.Disabled) then
				focused:SetIfChanged(true)
			end
		end)
		inst.SelectionLost:Connect(function()
			focused:SetIfChanged(false)
		end)
	end)

	return {
		Hovered = hovered,
		Pressed = pressed,
		Focused = focused,
		Hook = hook,
	}
end

local function drag(opts: DragOptions?): Drag
	local o: DragOptions = opts or {}
	local dragging = q.Source(false)

	-- Active drag session. Plain locals (one active drag per tracker); the connections are opened on begin
	-- and closed in `finish` — the ONLY exit path, reached from release / focus loss / destroy / Cancel.
	local connChanged: RBXScriptConnection? = nil
	local connEnded: RBXScriptConnection? = nil
	local connFocus: RBXScriptConnection? = nil
	local beginInput: InputObject? = nil
	local lastX, lastY = 0, 0
	local hostInst: GuiObject? = nil
	local lockedScroll: ScrollingFrame? = nil

	local function disconnectAll()
		if connChanged then
			connChanged:Disconnect()
			connChanged = nil
		end
		if connEnded then
			connEnded:Disconnect()
			connEnded = nil
		end
		if connFocus then
			connFocus:Disconnect()
			connFocus = nil
		end
	end

	local function finish(cancelled: boolean)
		if beginInput == nil then
			return
		end
		beginInput = nil
		disconnectAll()
		local locked = lockedScroll
		if locked ~= nil then
			lockedScroll = nil
			locked.ScrollingEnabled = true
		end
		dragging:Set(false)
		if o.OnEnded then
			o.OnEnded(lastX, lastY, cancelled)
		end
	end

	local function begin(input: InputObject)
		beginInput = input
		lastX, lastY = input.Position.X, input.Position.Y
		if o.LockScroll == true then
			local p: Instance? = if hostInst ~= nil then hostInst.Parent else nil
			while p ~= nil and p.ClassName ~= "ScrollingFrame" do
				p = p.Parent
			end
			if p ~= nil then
				local sf = p :: ScrollingFrame
				if sf.ScrollingEnabled then
					sf.ScrollingEnabled = false
					lockedScroll = sf
				end
			end
		end
		dragging:Set(true)
		local isTouch = input.UserInputType == Enum.UserInputType.Touch
		local kind = input.UserInputType
		connChanged = UserInputService.InputChanged:Connect(function(changed: InputObject)
			local ok = if isTouch then changed == beginInput else changed.UserInputType == Enum.UserInputType.MouseMovement
			if not ok then
				return
			end
			local x, y = changed.Position.X, changed.Position.Y
			lastX, lastY = x, y
			if o.OnMoved then
				o.OnMoved(x, y, changed.Delta.X, changed.Delta.Y)
			end
		end)
		connEnded = UserInputService.InputEnded:Connect(function(ended: InputObject)
			local ok = if isTouch then ended == beginInput else ended.UserInputType == kind
			if ok then
				lastX, lastY = ended.Position.X, ended.Position.Y
				finish(false)
			end
		end)
		connFocus = UserInputService.WindowFocusReleased:Connect(function()
			finish(true)
		end)
		if o.OnBegan then
			o.OnBegan(lastX, lastY)
		end
	end

	local hook = Util.preHook(function(inst)
		hostInst = inst
		inst.InputBegan:Connect(function(input: InputObject)
			local t = input.UserInputType
			if beginInput ~= nil or Util.peekBool(o.Disabled) then
				return
			end
			if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
				begin(input)
			end
		end)
		inst.Destroying:Connect(function()
			finish(true)
		end)
	end)

	local self: Drag
	self = {
		Dragging = dragging,
		Hook = hook,
		Cancel = function(_: Drag)
			finish(true)
		end,
	}
	return self
end

return {
	new = new,
	drag = drag,
}
