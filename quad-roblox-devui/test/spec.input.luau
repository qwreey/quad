--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local D = q.Declaration
local Interaction = require("../src/Interaction")
local Input = require("../src/Input")

local UIS: any = H.UserInputService
local function count(sig: any): number
	return #sig.connections
end
local function engineConns(): number
	return count(UIS.InputBegan) + count(UIS.InputChanged) + count(UIS.InputEnded) + count(UIS.WindowFocusReleased)
end
local function mkListener(): any
	return {
		InputBegan = H.mock.newSignal(),
		InputChanged = H.mock.newSignal(),
		InputEnded = H.mock.newSignal(),
		MouseMoved = H.mock.newSignal(),
	}
end
local function total(l: any): number
	return count(l.InputBegan) + count(l.InputChanged) + count(l.InputEnded) + count(l.MouseMoved)
end
local function mouseDown(x: number, y: number): any
	return H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(x, y, 0) })
end
local function mouseMove(x: number, y: number): any
	return H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(x, y, 0) })
end
local function mouseUp(x: number, y: number): any
	return H.input({
		UserInputType = Enum.UserInputType.MouseButton1,
		UserInputState = Enum.UserInputState.End,
		Position = Vector3.new(x, y, 0),
	})
end

H.section("default is the engine (harness fake)", function()
	assert(not Input.isOverridden())
	assert(Input.service() == UIS)
	assert(Input.guiInset() == Vector2.new(0, 0))
end)

H.section("a drag follows the swapped-in listener", function()
	local base = engineConns()
	local listener = mkListener()
	Input.use(listener)
	assert(Input.isOverridden() and Input.service() ~= UIS)
	assert(count(listener.MouseMoved) == 1, "one MouseMoved connection")
	assert(Input.guiInset() == Vector2.zero)

	local log: { string } = {}
	local drag = Interaction.drag({
		OnMove = function(x, y, dx, dy)
			table.insert(log, `move {x},{y} d{dx},{dy}`)
		end,
		OnEnd = function(x, y, _dx, _dy, cancelled)
			table.insert(log, `end {x},{y} {cancelled}`)
		end,
	})
	local f = D.Frame({ drag.Hook })
	H.fire(f, "InputBegan", mouseDown(10, 20))
	assert(drag.Dragging:Get() == true)
	assert(count(listener.InputChanged) == 1 and count(listener.InputEnded) == 1)
	assert(engineConns() == base, "nothing opened on the engine service")
	-- engine-side input is ignored, listener input drives the widget
	UIS.InputChanged:Fire(mouseMove(99, 99), false)
	assert(#log == 0)
	listener.InputChanged:Fire(mouseMove(15, 28), false)
	assert(log[1] == "move 15,28 d5,8", table.concat(log, "|"))
	listener.InputEnded:Fire(mouseUp(15, 28), false)
	assert(drag.Dragging:Get() == false and log[2] == "end 15,28 false")
	assert(count(listener.InputChanged) == 0 and count(listener.InputEnded) == 0 and count(listener.WindowFocusReleased or { connections = {} }) == 0)
	q.dispose(f)

	-- GetMouseLocation follows MouseMoved
	local svc = Input.service()
	assert(svc:GetMouseLocation() == Vector2.zero)
	listener.MouseMoved:Fire(Vector2.new(7, 9))
	assert(svc:GetMouseLocation() == Vector2.new(7, 9))
	-- writes stay local, reads of other members fall back to the engine
	svc.MouseIconEnabled = false
	assert(UIS.MouseIconEnabled == true and svc.MouseIconEnabled == false)
	assert(svc.KeyboardEnabled == true)
	UIS.FocusedTextBox = "tb"
	assert((svc :: any):GetFocusedTextBox() == "tb")
	assert(svc:IsKeyDown(Enum.KeyCode.A) == false)
	-- WindowFocusReleased is a never-firing stand-in
	local fired = false
	local c = svc.WindowFocusReleased:Connect(function()
		fired = true
	end)
	UIS.WindowFocusReleased:Fire()
	assert(not fired)
	c:Disconnect()
	UIS.FocusedTextBox = nil
	UIS.MouseIconEnabled = true

	-- swapping listener drops the old MouseMoved connection
	local second = mkListener()
	Input.use(second)
	assert(total(listener) == 0 and count(second.MouseMoved) == 1)
	assert(Input.service():GetMouseLocation() == Vector2.zero)

	Input.use(nil)
	assert(not Input.isOverridden() and Input.service() == UIS)
	assert(total(second) == 0 and engineConns() == base)
end)

H.section("a listener without MouseMoved works; restore reaches the engine again", function()
	local base = engineConns()
	local l = mkListener()
	l.MouseMoved = nil
	Input.use(l)
	assert(Input.service():GetMouseLocation() == Vector2.zero)
	Input.use(nil)
	local drag = Interaction.drag({ OnMove = function() end })
	local f = D.Frame({ drag.Hook })
	H.fire(f, "InputBegan", mouseDown(1, 1))
	assert(count(UIS.InputChanged) >= 1 and count(l.InputChanged) == 0)
	UIS.InputEnded:Fire(mouseUp(1, 1), false)
	q.dispose(f)
	assert(engineConns() == base)
end)

H.assertNoDebugOutput("input")
H.done()
