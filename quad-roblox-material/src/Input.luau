--!strict
--[[
	The ONE place the kit touches `UserInputService`.

	Why: UI Labs (Studio plugin) renders stories inside a plugin DockWidget where `UserInputService` receives no input.
	UI Labs hands a story `Environment.InputListener` (`InputBegan` / `InputChanged` / `InputEnded` with the engine
	signatures + `MouseMoved`, widget-space). Every kit module that needs input reads `Input.service()` AT USE TIME
	(inside the function that connects / reads — never at module scope), so `Input.use(listener)` after require works.

	    Input.service(): UserInputService   the swapped-in service-shaped table, else `game:GetService("UserInputService")`
	    Input.use(listener: Listener?)      install a listener (story mode) or nil to restore the engine service
	    Input.isOverridden(): boolean
	    Input.guiInset(): Vector2           GuiService:GetGuiInset() top-left in game mode, Vector2.zero while overridden

	While overridden: the three Input* signals are the listener's; `GetMouseLocation()` is the last `MouseMoved`
	position; `IsMouseButtonPressed(type)` answers from the listener's own `InputBegan` / `InputEnded` for that mouse
	button (inside a widget the engine reports no button held — a held scrollbar thumb would look released; a button
	released outside the preview area stays "held" until the next press there); those three connections are dropped
	on the next `use`; `WindowFocusReleased` never fires; property writes (`MouseIconEnabled = false`) stay local and
	never reach the engine; every other member (`GetFocusedTextBox`, `GetLastInputType`, `MouseEnabled`, ...) falls
	back to the engine service (methods are called with the engine as self).

	Studio + UI Labs (ui-labs@1e8f45f, src/UI/StoryPreview/PreviewController/index.tsx and
	src/Context/UserInputContext/index.tsx): the listener is a transparent full-size Frame ("UILabsInputListener",
	ZIndex 50) over the story holder; its GuiObject InputBegan / InputChanged / InputEnded are re-fired as the three
	signals and MouseMovement positions as `MouseMoved`. So positions are in the same (widget) space as the story's
	AbsolutePosition, which is why `guiInset()` is zero while overridden. A story finds it under the global
	`__hotreload_env_global_injection__` of ITS OWN function environment (UI Labs setfenv's every virtual module) —
	read it with a plain `getfenv()`, never `pcall(getfenv, 1)` (level 1 is then pcall itself, a C function, and the
	thread's globals come back: the injection is invisible — stories/StoryKit.luau, 2026-10-08).

	GuiService selection / gamepad APIs are NOT substituted — they are verified in play mode only.
]]

export type Listener = {
	InputBegan: RBXScriptSignal,
	InputChanged: RBXScriptSignal,
	InputEnded: RBXScriptSignal,
	MouseMoved: RBXScriptSignal?,
}

local overridden: any = nil
local listenerConns: { { Disconnect: (any) -> () } } = {}

local dummyConnection = { Connected = false }
function dummyConnection.Disconnect(_self: any) end
local neverFires = {}
function neverFires.Connect(_self: any, _fn: any): any
	return dummyConnection
end
function neverFires.Once(_self: any, _fn: any): any
	return dummyConnection
end

local function engine(): any
	return game:GetService("UserInputService")
end

local Input = {}

function Input.service(): UserInputService
	if overridden ~= nil then
		return overridden
	end
	return engine() :: any
end

function Input.use(listener: Listener?): ()
	for _, conn in listenerConns do
		conn:Disconnect()
	end
	table.clear(listenerConns)
	if listener == nil then
		overridden = nil
		return
	end
	local mouse = Vector2.new(0, 0)
	local lst: any = listener
	if lst.MouseMoved ~= nil then
		local conn: any = lst.MouseMoved:Connect(function(position: Vector2)
			mouse = position
		end)
		table.insert(listenerConns, conn)
	end
	-- mouse buttons held, as the listener saw them (the engine sees none inside a plugin widget); compared with `==`,
	-- not used as table keys (the test harness's Enum items are not interned)
	local held = { false, false, false }
	local function buttonIndex(t: Enum.UserInputType): number?
		if t == Enum.UserInputType.MouseButton1 then
			return 1
		elseif t == Enum.UserInputType.MouseButton2 then
			return 2
		elseif t == Enum.UserInputType.MouseButton3 then
			return 3
		end
		return nil
	end
	local function track(down: boolean): (InputObject) -> ()
		return function(input: InputObject)
			local i = buttonIndex(input.UserInputType)
			if i ~= nil then
				held[i] = down
			end
		end
	end
	local began: any = lst.InputBegan:Connect(track(true))
	local ended: any = lst.InputEnded:Connect(track(false))
	table.insert(listenerConns, began)
	table.insert(listenerConns, ended)
	local own: { [string]: any } = {
		InputBegan = lst.InputBegan,
		InputChanged = lst.InputChanged,
		InputEnded = lst.InputEnded,
		WindowFocusReleased = neverFires,
		GetMouseLocation = function(_self: any): Vector2
			return mouse
		end,
		IsMouseButtonPressed = function(_self: any, inputType: Enum.UserInputType): boolean
			local i = buttonIndex(inputType)
			return i ~= nil and held[i]
		end,
	}
	local locals: { [string]: any } = {}
	overridden = setmetatable({}, {
		__index = function(_, key: string): any
			local l = locals[key]
			if l ~= nil then
				return l
			end
			local o = own[key]
			if o ~= nil then
				return o
			end
			local eng = engine()
			local value: any = eng[key]
			if type(value) == "function" then
				local fn = value :: (any, ...any) -> ...any
				return function(_self: any, ...: any): ...any
					return fn(eng, ...)
				end
			end
			return value
		end,
		__newindex = function(_, key: string, value: any)
			locals[key] = value
		end,
	})
end

function Input.isOverridden(): boolean
	return overridden ~= nil
end

function Input.guiInset(): Vector2
	if overridden ~= nil then
		return Vector2.new(0, 0)
	end
	local inset = (game:GetService("GuiService") :: any):GetGuiInset()
	return inset
end

return Input
