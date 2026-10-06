--!strict
local H = require("./support/harness")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
local D = q.Declaration
local Tokens = require("../src/Tokens")
local Switch = require("../src/Switch")

local UIS = H.UserInputService
local function uisConns(): number
	local u = UIS :: any
	return #u.InputChanged.connections + #u.InputEnded.connections + #u.WindowFocusReleased.connections
end
local baseConns = uisConns()
local L = Tokens.Color.Light

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

H.section("mount: 52x32 track, handle 16, instance count", function()
	local sw = Switch({})
	assert(sw.ClassName == "TextButton" and sw.Name == "Switch" and sw.Size == UDim2.fromOffset(52, 32))
	local n = H.countDescendants(sw)
	print("Switch descendants: " .. n .. " (+1 host = " .. (n + 1) .. ")")
	H.resetOutput()
	assert(n == 8, "UICorner, UIStroke, Halo, layer(3), Handle(+corner) = 8, got " .. n)
	local handle = H.find(sw, "Handle")
	assert(handle.Size == UDim2.fromOffset(16, 16), "off handle 16")
	assert(H.find(sw, "Halo").Position == UDim2.fromOffset(16, 16) and H.find(sw, "Halo").Size == UDim2.fromOffset(40, 40))
	assert(sw.BackgroundColor3 == L.SurfaceContainerHighest and handle.BackgroundColor3 == L.Outline)
	assert(H.find(sw, "Outline").Thickness == 2 and H.find(sw, "Outline").Color == L.Outline)
	q.dispose(sw)
	H.assertNoDebugOutput("switch mount")
end)

H.section("click toggles; handle position + size animate; Source round trip", function()
	local v = q.Source(false)
	local changes: { boolean } = {}
	local sw = Switch({
		Value = v,
		OnChange = function(x: boolean)
			table.insert(changes, x)
		end,
	})
	local root = D.Frame { sw }
	local halo, handle = H.find(sw, "Halo"), H.find(sw, "Handle")
	H.fire(sw, "Activated", H.input({}), 1)
	assert(v:Get() == true and changes[1] == true)
	assert(#H.tweenLog() >= 2, "position and size/color tweens run")
	H.finishTweens()
	assert(halo.Position == UDim2.fromOffset(36, 16), "handle slid to the on end")
	assert(handle.Size == UDim2.fromOffset(24, 24) and handle.BackgroundColor3 == L.OnPrimary, "on handle 24, onPrimary")
	assert(sw.BackgroundColor3 == L.Primary and H.find(sw, "Outline").Color == L.Primary)
	v:Set(false)
	H.finishTweens()
	assert(halo.Position == UDim2.fromOffset(16, 16) and handle.Size == UDim2.fromOffset(16, 16) and #changes == 1)
	q.dispose(root)
	H.assertNoDebugOutput("switch click")
end)

H.section("pressed handle: 24 off (clear of the outline), 28 on; hover recolors", function()
	local sw = Switch({ Value = q.Source(false) })
	local handle = H.find(sw, "Handle")
	H.fire(sw, "MouseEnter")
	H.finishTweens()
	assert(handle.BackgroundColor3 == L.OnSurfaceVariant, "hover handle color")
	H.fire(sw, "InputBegan", H.input({ Position = Vector3.new(10, 10, 0) }))
	H.finishTweens()
	assert(handle.Size == UDim2.fromOffset(24, 24), "pressed while off: 24 (the off track's inside is 28)")
	H.fire(sw, "InputEnded", H.input({}))
	H.finishTweens()
	assert(handle.Size == UDim2.fromOffset(16, 16))
	q.dispose(sw)
	local onSw = Switch({ Value = q.Source(true) })
	H.fire(onSw, "InputBegan", H.input({ Position = Vector3.new(40, 10, 0) }))
	H.finishTweens()
	assert(H.find(onSw, "Handle").Size == UDim2.fromOffset(28, 28), "pressed while on: 28")
	H.fire(onSw, "InputEnded", H.input({}))
	q.dispose(onSw)
	H.assertNoDebugOutput("switch pressed")
end)

H.section("icons: image follows the state, off handle becomes 24", function()
	local v = q.Source(false)
	local sw = Switch({ Value = v, IconOn = "rbxassetid://1", IconOff = "rbxassetid://2" })
	local icon = H.find(sw, "Icon")
	assert(icon.Image == "rbxassetid://2" and icon.Size == UDim2.fromOffset(16, 16))
	assert(H.find(sw, "Handle").Size == UDim2.fromOffset(24, 24), "off handle with icon is 24")
	assert(H.countDescendants(sw) == 9)
	v:Set(true)
	H.finishTweens()
	assert(icon.Image == "rbxassetid://1" and icon.ImageColor3 == L.OnPrimaryContainer)
	q.dispose(sw)
	H.assertNoDebugOutput("switch icons")
end)

H.section("disabled: no input, 12 % / 38 % roles, Surface handle when on", function()
	local v = q.Source(true)
	local dis = q.Source(true)
	local calls = 0
	local sw = Switch({
		Value = v,
		Disabled = dis,
		OnChange = function()
			calls += 1
		end,
	})
	H.finishTweens()
	assert(sw.Interactable == false)
	assert(sw.BackgroundColor3 == L.OnSurface and near(sw.BackgroundTransparency, 0.88))
	assert(H.find(sw, "Handle").BackgroundColor3 == L.Surface and H.find(sw, "Handle").BackgroundTransparency == 0)
	H.fire(sw, "Activated", H.input({}), 1)
	assert(v:Get() == true and calls == 0)
	v:Set(false)
	H.finishTweens()
	assert(H.find(sw, "Handle").BackgroundColor3 == L.OnSurface and near(H.find(sw, "Handle").BackgroundTransparency, 0.62))
	H.fire(sw, "MouseEnter")
	H.finishTweens()
	assert(H.find(sw, "StateLayer").BackgroundTransparency == 1)
	dis:Set(false)
	H.fire(sw, "Activated", H.input({}), 1)
	assert(v:Get() == true and calls == 1)
	q.dispose(sw)
	H.assertNoDebugOutput("switch disabled")
end)

H.section("dispose", function()
	local sw = Switch({})
	H.fire(sw, "InputBegan", H.input({ Position = Vector3.new(5, 5, 0) }))
	q.dispose(sw)
	assert(H.isDestroyed(sw) and uisConns() == baseConns)
	H.assertNoDebugOutput("switch dispose")
end)

H.done()
