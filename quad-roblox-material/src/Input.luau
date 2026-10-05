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
	position (ONE connection, dropped on the next `use`); `WindowFocusReleased` never fires; property writes
	(`MouseIconEnabled = false`) stay local and never reach the engine; every other member (`GetFocusedTextBox`,
	`GetLastInputType`, `MouseEnabled`, ...) falls back to the engine service (methods are called with the engine as self).

	GuiService selection / gamepad APIs are NOT substituted — they are verified in play mode only.
]]

export type Listener = {
	InputBegan: RBXScriptSignal,
	InputChanged: RBXScriptSignal,
	InputEnded: RBXScriptSignal,
	MouseMoved: RBXScriptSignal?,
}

local overridden: any = nil
local mouseConn: { Disconnect: (any) -> () }? = nil

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
	if mouseConn ~= nil then
		mouseConn:Disconnect()
		mouseConn = nil
	end
	if listener == nil then
		overridden = nil
		return
	end
	local mouse = Vector2.new(0, 0)
	local lst: any = listener
	if lst.MouseMoved ~= nil then
		mouseConn = lst.MouseMoved:Connect(function(position: Vector2)
			mouse = position
		end)
	end
	local own: { [string]: any } = {
		InputBegan = lst.InputBegan,
		InputChanged = lst.InputChanged,
		InputEnded = lst.InputEnded,
		WindowFocusReleased = neverFires,
		GetMouseLocation = function(_self: any): Vector2
			return mouse
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
