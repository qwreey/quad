--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Frame = q.Elem "Frame"
local Devui = require("../src")
local Overlay = require("../src/Overlay")
Overlay.warnUnmounted = false -- (popups on a bare layer)

local UIS = H.UserInputService
local function down(x: number, y: number): any
	return H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(x, y, 0) })
end
local function move(x: number, y: number): any
	return H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(x, y, 0) })
end
local function up(x: number, y: number): any
	return H.input({
		UserInputType = Enum.UserInputType.MouseButton1,
		UserInputState = Enum.UserInputState.End,
		Position = Vector3.new(x, y, 0),
	})
end
local function click(inst: any)
	H.fire(inst, "Activated", H.input({}), 1)
end
local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

H.section("ColorPicker3: square and hue bar write Value live; black keeps the hue; the original swatch puts it back", function()
	local value = q.Source(Color3.fromHSV(0.5, 1, 1))
	local changes = 0
	local picker = Devui.ColorPicker3({
		Value = value,
		OnChange = function()
			changes += 1
		end,
	})
	local square = H.find(picker, "SVSquare") :: any
	local bar = H.find(picker, "HueBar") :: any
	H.setAbs(square, 0, 0, 100, 100)
	H.setAbs(bar, 110, 0, 20, 100)
	-- the square: x = saturation, y = 1 - value
	H.fire(square, "InputBegan", down(25, 50))
	local h, s, v = value:Get():ToHSV()
	assert(near(h, 0.5) and near(s, 0.25) and near(v, 0.5), `square ({h} {s} {v})`)
	UIS.InputChanged:Fire(move(100, 100), false) -- to black
	UIS.InputEnded:Fire(up(100, 100), false)
	assert(value:Get() == Color3.new(0, 0, 0))
	-- the hue bar while black: the colour stays black, the hue is kept for when it brightens
	H.fire(bar, "InputBegan", down(115, 25))
	UIS.InputEnded:Fire(up(115, 25), false)
	H.fire(square, "InputBegan", down(100, 0))
	UIS.InputEnded:Fire(up(100, 0), false)
	h, s, v = value:Get():ToHSV()
	assert(near(h, 0.25) and near(s, 1) and near(v, 1), `hue kept through black ({h} {s} {v})`)
	assert(changes == 4, `OnChange per change ({changes})`)
	-- an outside write is followed (no OnChange)
	value:Set(Color3.new(1, 0, 0))
	assert((H.find(picker, "Current") :: any).BackgroundColor3 == Color3.new(1, 0, 0) and changes == 4)
	-- the original swatch
	click(H.find(picker, "Original"))
	h = value:Get():ToHSV()
	assert(near(h, 0.5), "original put back")
	assert(H.find(H.find(picker, "InputColor3"), "Swatch").ClassName == "Frame", "its own row's swatch opens nothing")
	q.dispose(picker)
	H.assertNoDebugOutput("picker")
end)

H.section("OpenColorPicker: live; Cancel / Escape put the opening colour back; OK keeps it; OnResult once", function()
	local o = Overlay.new()
	local value = q.Source(Color3.new(0, 0, 1))
	local results: { any } = {}
	local function open(): any
		return Devui.OpenColorPicker({
			Value = value,
			Overlay = o,
			OnResult = function(ok, c)
				table.insert(results, { ok, c })
			end,
		})
	end
	local d = open()
	assert(H.find(o.Layer, "DialogScrim") ~= nil, "no Window: Global")
	value:Set(Color3.new(0, 1, 0)) -- (as a drag would)
	click(H.find(o.Layer, "CancelButton"))
	assert(value:Get() == Color3.new(0, 0, 1) and not d.IsOpen:Get(), "Cancel restores")
	assert(#results == 1 and results[1][1] == false)
	open()
	value:Set(Color3.new(0, 1, 0))
	UIS.InputBegan:Fire(H.input({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Escape }), false)
	assert(value:Get() == Color3.new(0, 0, 1), "Escape restores")
	open()
	value:Set(Color3.new(0, 1, 0))
	click(H.find(o.Layer, "OkButton"))
	assert(value:Get() == Color3.new(0, 1, 0) and #results == 3 and results[3][1] == true and results[3][2] == Color3.new(0, 1, 0), "OK keeps")
	assert(o.Count:Get() == 0)
	q.dispose(o.Layer)
	H.assertNoDebugOutput("open picker")
end)

H.section("InputColor3: the swatch opens the picker over the window it is in; NoPicker keeps a plain swatch", function()
	local value = q.Source(Color3.new(1, 1, 1))
	local window = Frame({ Name = "Window" })
	local row = Devui.InputColor3({ Value = value })
	row.Parent = window
	local o = Overlay.getDefault()
	click(H.find(row, "Swatch"))
	assert(H.find(o.Layer, "ColorPicker3") ~= nil and window:FindFirstChild("DialogVeil") ~= nil, "opened, the window veiled")
	o:CloseAll()
	local plain = Devui.InputColor3({ Value = value, NoPicker = true })
	assert(H.find(plain, "Swatch").ClassName == "Frame")
	q.dispose(window)
	q.dispose(plain)
	H.assertNoDebugOutput("swatch")
end)

H.done()
