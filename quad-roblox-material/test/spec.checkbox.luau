--!strict
local H = require("./support/harness")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
local Tokens = require("../src/Tokens")
local Checkbox = require("../src/Checkbox")

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
local function class(inst: any, name: string): { any }
	return H.findAll(inst, function(c: any)
		return c.ClassName == name
	end)
end

H.section("mount: structure, size, instance count", function()
	local cb = Checkbox({})
	assert(cb.ClassName == "TextButton" and cb.Name == "Checkbox" and cb.Size == UDim2.fromOffset(48, 48))
	local n = H.countDescendants(cb)
	print("Checkbox descendants: " .. n .. " (+1 host = " .. (n + 1) .. ")")
	H.resetOutput()
	assert(n == 10, "Target, layer(3), Box(+corner+stroke), 3 marks = 10, got " .. n)
	local target = H.find(cb, "Target")
	assert(target.Size == UDim2.fromOffset(40, 40), "40 px state layer area")
	local box = H.find(cb, "Box")
	assert(box.Size == UDim2.fromOffset(18, 18))
	local stroke = H.find(box, "Outline")
	assert(stroke.Thickness == 2 and stroke.Color == L.OnSurfaceVariant, "2 px outline, unchecked color")
	assert(box.BackgroundTransparency == 1, "unchecked box is not filled")
	assert(H.find(box, "CheckShort").BackgroundTransparency == 1 and H.find(box, "CheckLong").BackgroundTransparency == 1)
	assert(#class(cb, "CanvasGroup") == 0, "no CanvasGroup at rest")
	q.dispose(cb)
	H.assertNoDebugOutput("checkbox mount")
end)

H.section("click toggles Source; Source drives UI both ways; OnChange only for user clicks", function()
	local v = q.Source(false)
	local changes: { boolean } = {}
	local cb = Checkbox({
		Value = v,
		OnChange = function(x: boolean)
			table.insert(changes, x)
		end,
	})
	local box = H.find(cb, "Box")
	H.fire(cb, "Activated", H.input({}), 1)
	H.finishTweens()
	assert(v:Get() == true and #changes == 1 and changes[1] == true, "click writes the Source")
	assert(box.BackgroundTransparency == 0 and box.BackgroundColor3 == L.Primary, "checked: filled primary")
	assert(H.find(box, "Outline").Color == L.Primary)
	assert(H.find(box, "CheckShort").BackgroundTransparency == 0 and H.find(box, "CheckShort").BackgroundColor3 == L.OnPrimary)
	assert(H.find(box, "CheckShort").Rotation == 45 and H.find(box, "CheckLong").Rotation == -45)
	assert(H.find(box, "Dash").BackgroundTransparency == 1)
	-- Source -> UI
	v:Set(false)
	H.finishTweens()
	assert(box.BackgroundTransparency == 1 and H.find(box, "CheckLong").BackgroundTransparency == 1, "programmatic uncheck")
	assert(#changes == 1, "programmatic writes do not call OnChange")
	H.fire(cb, "Activated", H.input({}), 1)
	H.fire(cb, "Activated", H.input({}), 1)
	assert(v:Get() == false and #changes == 3 and changes[3] == false)
	q.dispose(cb)
	H.assertNoDebugOutput("checkbox click")
end)

H.section("initial checked mounts snapped; no Value keeps its own state", function()
	local cb = Checkbox({ Value = q.Source(true) })
	assert(H.find(cb, "Box").BackgroundTransparency == 0, "mounted checked")
	local own = Checkbox({})
	H.fire(own, "Activated", H.input({}), 1)
	H.finishTweens()
	assert(H.find(own, "Box").BackgroundTransparency == 0, "internal state toggled")
	q.dispose(cb)
	q.dispose(own)
	H.assertNoDebugOutput("checkbox own state")
end)

H.section("indeterminate: dash, click checks it, owner clears the flag", function()
	local v = q.Source(false)
	local ind = q.Source(true)
	local cb = Checkbox({
		Value = v,
		Indeterminate = ind,
		OnChange = function()
			ind:Set(false)
		end,
	})
	local box = H.find(cb, "Box")
	H.finishTweens()
	assert(box.BackgroundTransparency == 0, "indeterminate is filled")
	assert(H.find(box, "Dash").BackgroundTransparency == 0 and H.find(box, "CheckShort").BackgroundTransparency == 1)
	H.fire(cb, "Activated", H.input({}), 1)
	H.finishTweens()
	assert(v:Get() == true and ind:Get() == false)
	assert(H.find(box, "Dash").BackgroundTransparency == 1 and H.find(box, "CheckShort").BackgroundTransparency == 0, "dash -> check")
	q.dispose(cb)
	H.assertNoDebugOutput("checkbox indeterminate")
end)

H.section("error roles", function()
	local err = q.Source(true)
	local cb = Checkbox({ Value = q.Source(false), Error = err })
	H.finishTweens()
	assert(H.find(cb, "Outline").Color == L.Error, "unchecked error outline")
	local ck = Checkbox({ Value = q.Source(true), Error = err })
	H.finishTweens()
	assert(H.find(ck, "Box").BackgroundColor3 == L.Error and H.find(H.find(ck, "Box"), "CheckShort").BackgroundColor3 == L.OnError)
	err:Set(false)
	H.finishTweens()
	assert(H.find(ck, "Box").BackgroundColor3 == L.Primary)
	q.dispose(cb)
	q.dispose(ck)
	H.assertNoDebugOutput("checkbox error")
end)

H.section("disabled blocks input and uses 38 % roles", function()
	local v = q.Source(true)
	local dis = q.Source(true)
	local calls = 0
	local cb = Checkbox({
		Value = v,
		Disabled = dis,
		OnChange = function()
			calls += 1
		end,
	})
	H.finishTweens()
	assert(cb.Interactable == false)
	local box = H.find(cb, "Box")
	assert(box.BackgroundColor3 == L.OnSurface and near(box.BackgroundTransparency, 0.62))
	assert(H.find(box, "CheckShort").BackgroundColor3 == L.Surface)
	H.fire(cb, "Activated", H.input({}), 1)
	assert(v:Get() == true and calls == 0, "disabled swallows the click")
	H.fire(cb, "MouseEnter")
	H.finishTweens()
	assert(H.find(cb, "StateLayer").BackgroundTransparency == 1, "no layer while disabled")
	dis:Set(false)
	H.fire(cb, "Activated", H.input({}), 1)
	assert(v:Get() == false and calls == 1)
	q.dispose(cb)
	H.assertNoDebugOutput("checkbox disabled")
end)

H.section("hover shows the state layer; press ripples; dispose closes everything", function()
	local cb = Checkbox({ Value = q.Source(false) })
	H.setAbs(H.find(cb, "StateLayer"), 0, 0, 40, 40)
	H.fire(cb, "MouseEnter")
	H.finishTweens()
	assert(near(H.find(cb, "StateLayer").BackgroundTransparency, 1 - Tokens.State.Opacity.Hover))
	H.fire(cb, "InputBegan", H.input({ Position = Vector3.new(20, 20, 0) }))
	assert(#class(cb, "CanvasGroup") == 1, "press starts a ripple")
	H.fire(cb, "InputEnded", H.input({}))
	H.advance(1)
	assert(#class(cb, "CanvasGroup") == 0, "ripple removed")
	q.dispose(cb)
	assert(H.isDestroyed(cb))
	assert(uisConns() == baseConns, "no global connections")
	H.assertNoDebugOutput("checkbox fx")
end)

H.done()
