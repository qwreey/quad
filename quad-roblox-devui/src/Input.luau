--!strict
--[[
	Input — the ONE place the kit touches `UserInputService` / `GuiService:GetGuiInset()`.

	Why: a story host such as UI Labs renders into a plugin DockWidget where `UserInputService` receives no input; it
	offers an `Environment.InputListener` instead (InputBegan / InputChanged / InputEnded + MouseMoved, widget space).
	Every kit code path asks `Input.service()` AT USE TIME (never at module scope), so `Input.use(listener)` after
	require reroutes everything. Default (no listener): the engine service.

	Input.service()        -> the swapped-in service-shaped table, else game:GetService("UserInputService")
	Input.use(listener?)   -> install a listener (story mode) / nil restores the engine service
	Input.isOverridden()
	Input.guiInset()       -> GuiService:GetGuiInset() top-left in game mode; Vector2.zero while overridden
	Input.topbarHeight()   -> GuiService.TopbarInset.Max.Y in game mode (the Roblox top bar's bottom, screen space);
	                          0 while overridden or where the service has no TopbarInset (a mock)
	Input.onTopbarChanged(fn) -> disconnect: `fn` runs when TopbarInset changes (a no-op where it cannot change)

	While overridden: the three Input* signals come from the listener, GetMouseLocation() is the last `MouseMoved`
	position (ONE connection, dropped on the next `use`), WindowFocusReleased never fires, writes such as
	`MouseIconEnabled = false` are kept locally (never reach the engine), every other member falls back to the engine
	service (functions are called with the engine service as self). The kit's long-lived connections (window
	press-to-front, hover tracking) are re-made on the new service by `use` (internal GlobalInput).

	GuiService gamepad / selection APIs have no widget substitute: check them in play mode only.
]]

local GlobalInput = require("./GlobalInput")

export type Listener = {
	InputBegan: RBXScriptSignal,
	InputChanged: RBXScriptSignal,
	InputEnded: RBXScriptSignal,
	MouseMoved: RBXScriptSignal?,
}

local Input = {}

local overridden: UserInputService? = nil
local mouseConn: { Disconnect: (any) -> () }? = nil

local function engine(): any
	return game:GetService("UserInputService")
end

-- a signal that never fires (WindowFocusReleased has no widget-space source)
local function neverSignal(): any
	local conn = { Connected = false }
	function conn.Disconnect(_self: any) end
	local signal = {}
	function signal.Connect(_self: any, _fn: any)
		return conn
	end
	function signal.Once(_self: any, _fn: any)
		return conn
	end
	function signal.ConnectParallel(_self: any, _fn: any)
		return conn
	end
	return signal
end

local function dropMouseConn()
	if mouseConn then
		mouseConn:Disconnect()
		mouseConn = nil
	end
end

local function build(listener: Listener): UserInputService
	local mouse = Vector2.zero
	local locals: { [any]: any } = {
		InputBegan = listener.InputBegan,
		InputChanged = listener.InputChanged,
		InputEnded = listener.InputEnded,
		WindowFocusReleased = neverSignal(),
	}
	local wrappers: { [any]: any } = {}
	local moved = listener.MouseMoved
	if moved then
		mouseConn = (moved :: any):Connect(function(position: Vector2)
			mouse = position
		end)
	end
	locals.GetMouseLocation = function(_self: any): Vector2
		return mouse
	end
	local service = setmetatable({}, {
		__index = function(_t: any, key: any): any
			local own = locals[key]
			if own ~= nil then
				return own
			end
			local value: any = engine()[key]
			if type(value) == "function" then
				local fn: any = value
				local wrapper = wrappers[key]
				if wrapper == nil then
					wrapper = function(_self: any, ...: any)
						return fn(engine(), ...)
					end
					wrappers[key] = wrapper
				end
				return wrapper
			end
			return value
		end,
		__newindex = function(_t: any, key: any, value: any)
			locals[key] = value
		end,
	})
	return service :: any
end

function Input.service(): UserInputService
	return overridden or engine()
end

function Input.use(listener: Listener?)
	dropMouseConn()
	if listener == nil then
		overridden = nil
	else
		overridden = build(listener)
	end
	-- the kit's long-lived connections (window press-to-front, hover tracking) move to the new service
	GlobalInput.rebind(Input.service())
end

function Input.isOverridden(): boolean
	return overridden ~= nil
end

function Input.guiInset(): Vector2
	if overridden ~= nil then
		return Vector2.zero
	end
	local guiService = game:GetService("GuiService")
	if guiService.GetGuiInset then
		local inset = guiService:GetGuiInset()
		return inset
	end
	return Vector2.zero
end

-- read through pcall: a service table without the property (the spec mock, an old engine) is "no top bar"
function Input.topbarHeight(): number
	if overridden ~= nil then
		return 0
	end
	local guiService: any = game:GetService("GuiService")
	local ok, rect = pcall(function()
		return guiService.TopbarInset
	end)
	if ok and typeof(rect) == "Rect" then
		return math.max(0, rect.Max.Y)
	end
	return 0
end

function Input.onTopbarChanged(fn: () -> ()): () -> ()
	local guiService = game:GetService("GuiService") :: any
	-- (pcall: a service table without the method is "never changes")
	local ok, signal = pcall(function()
		return guiService:GetPropertyChangedSignal("TopbarInset")
	end)
	if not ok or signal == nil then
		return function() end
	end
	local conn = (signal :: RBXScriptSignal):Connect(fn)
	return function()
		conn:Disconnect()
	end
end

return Input
