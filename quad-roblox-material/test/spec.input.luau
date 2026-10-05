--!strict
local H = require("./support/harness")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
local mock = require("../../quad-base/test/mock")
local Input = require("../src/Input")
local Slider = require("../src/Slider")

local UIS = H.UserInputService :: any
local function conns(s: any): number
	return #s.InputChanged.connections + #s.InputEnded.connections + #s.WindowFocusReleased.connections
end
local baseEngine = conns(UIS)

local function newListener(): any
	return {
		InputBegan = mock.newSignal(),
		InputChanged = mock.newSignal(),
		InputEnded = mock.newSignal(),
		MouseMoved = mock.newSignal(),
	}
end
local function listenerConns(l: any): number
	return #l.InputBegan.connections + #l.InputChanged.connections + #l.InputEnded.connections + #l.MouseMoved.connections
end

H.section("default: the engine (harness fake) service", function()
	assert(not Input.isOverridden())
	assert((Input.service() :: any) == UIS, "default is the engine service")
	assert(Input.guiInset() ~= nil)
end)

H.section("use(listener): drag routes to the listener, engine untouched, restore on use(nil)", function()
	local l = newListener()
	Input.use(l)
	assert(Input.isOverridden() and (Input.service() :: any) ~= UIS)
	assert(Input.guiInset() == Vector2.new(0, 0), "no inset while overridden")
	assert(#l.MouseMoved.connections == 1, "one MouseMoved connection")

	local v = q.Source(0)
	local s = Slider({ Value = v, Min = 0, Max = 100 })
	H.setAbs(s, 100, 50, 220, 40)
	H.fire(s, "InputBegan", H.input({ Position = Vector3.new(160, 60, 0) }))
	assert(math.abs(v:Get() - 25) < 1e-6, "press jumps")
	assert(#l.InputChanged.connections == 1 and #l.InputEnded.connections == 1, "drag connections are on the listener")
	assert(conns(UIS) == baseEngine, "nothing on the engine service")
	l.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(210, 60, 0) }))
	assert(math.abs(v:Get() - 50) < 1e-6, "listener move drives the slider, got " .. v:Get())
	UIS.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(310, 60, 0) }))
	assert(math.abs(v:Get() - 50) < 1e-6, "engine signal is ignored")
	l.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(210, 60, 0) }))
	assert(#l.InputChanged.connections == 0 and #l.InputEnded.connections == 0, "drag ended: closed")

	-- GetMouseLocation follows MouseMoved
	assert(Input.service():GetMouseLocation() == Vector2.new(0, 0))
	l.MouseMoved:Fire(Vector2.new(12, 34))
	assert(Input.service():GetMouseLocation() == Vector2.new(12, 34), "mouse follows MouseMoved")

	-- engine fallbacks
	UIS.FocusedTextBox = nil
	assert(Input.service():GetFocusedTextBox() == nil)
	UIS.FocusedTextBox = {}
	assert(Input.service():GetFocusedTextBox() ~= nil, "GetFocusedTextBox falls back to the engine")
	UIS.FocusedTextBox = nil
	assert(Input.service().MouseEnabled == true, "plain property reads fall back")

	-- writes stay local
	local svc = Input.service()
	svc.MouseIconEnabled = false
	assert(UIS.MouseIconEnabled == true, "write did not reach the engine")
	assert(svc.MouseIconEnabled == false, "write is readable locally")
	-- WindowFocusReleased never fires but connects
	local c = svc.WindowFocusReleased:Connect(function() end)
	c:Disconnect()

	q.dispose(s)
	Input.use(nil)
	assert(not Input.isOverridden() and (Input.service() :: any) == UIS, "restored")
	assert(listenerConns(l) == 1 or #l.MouseMoved.connections == 0, "MouseMoved connection dropped")
	assert(#l.MouseMoved.connections == 0)
	assert(conns(UIS) == baseEngine)
	assert(UIS.MouseIconEnabled == true)
	H.assertNoDebugOutput("input override")
end)

H.section("a second use() drops the previous MouseMoved connection", function()
	local a, b = newListener(), newListener()
	Input.use(a)
	Input.use(b)
	assert(#a.MouseMoved.connections == 0 and #b.MouseMoved.connections == 1)
	Input.use(nil)
	assert(#b.MouseMoved.connections == 0)
	-- a listener without MouseMoved works
	local c = newListener()
	c.MouseMoved = nil
	Input.use(c)
	assert(Input.service():GetMouseLocation() == Vector2.new(0, 0))
	Input.use(nil)
end)

H.section("default mode: drag on the engine service, closed at the end", function()
	local v = q.Source(0)
	local s = Slider({ Value = v, Min = 0, Max = 100 })
	H.setAbs(s, 100, 50, 220, 40)
	H.fire(s, "InputBegan", H.input({ Position = Vector3.new(160, 60, 0) }))
	assert(conns(UIS) == baseEngine + 3)
	UIS.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(160, 60, 0) }))
	assert(conns(UIS) == baseEngine)
	q.dispose(s)
	H.assertNoDebugOutput("input default")
end)

H.done()
