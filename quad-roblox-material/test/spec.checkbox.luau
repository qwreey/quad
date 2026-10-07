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
-- the toggle motion runs on Heartbeat (0.15 s close + 0.15 s open); then the property tweens
local function settle()
	H.advance(0.4)
	H.finishTweens()
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
	assert(n == 15, "Target, layer(3), Box(+corner+stroke), 3 marks, Bars frame + 4 motion bars = 15, got " .. n)
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
	settle()
	assert(v:Get() == true and #changes == 1 and changes[1] == true, "click writes the Source")
	assert(box.BackgroundTransparency == 0 and box.BackgroundColor3 == L.Primary, "checked: filled primary")
	assert(H.find(box, "Outline").Color == L.Primary)
	assert(H.find(box, "CheckShort").BackgroundTransparency == 0 and H.find(box, "CheckShort").BackgroundColor3 == L.OnPrimary)
	assert(H.find(box, "CheckShort").Rotation == 45 and H.find(box, "CheckLong").Rotation == -45)
	assert(H.find(box, "Dash").BackgroundTransparency == 1)
	-- Source -> UI
	v:Set(false)
	settle()
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
	settle()
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
	settle()
	assert(box.BackgroundTransparency == 0, "indeterminate is filled")
	assert(H.find(box, "Dash").BackgroundTransparency == 0 and H.find(box, "CheckShort").BackgroundTransparency == 1)
	H.fire(cb, "Activated", H.input({}), 1)
	settle()
	assert(v:Get() == true and ind:Get() == false)
	assert(H.find(box, "Dash").BackgroundTransparency == 1 and H.find(box, "CheckShort").BackgroundTransparency == 0, "dash -> check")
	q.dispose(cb)
	H.assertNoDebugOutput("checkbox indeterminate")
end)

H.section("error roles", function()
	local err = q.Source(true)
	local cb = Checkbox({ Value = q.Source(false), Error = err })
	settle()
	assert(H.find(cb, "Outline").Color == L.Error, "unchecked error outline")
	local ck = Checkbox({ Value = q.Source(true), Error = err })
	settle()
	assert(H.find(ck, "Box").BackgroundColor3 == L.Error and H.find(H.find(ck, "Box"), "CheckShort").BackgroundColor3 == L.OnError)
	err:Set(false)
	settle()
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
	settle()
	assert(cb.Interactable == false)
	local box = H.find(cb, "Box")
	assert(box.BackgroundColor3 == L.OnSurface and near(box.BackgroundTransparency, 0.62))
	assert(H.find(box, "CheckShort").BackgroundColor3 == L.Surface)
	assert(near(H.find(box, "Outline").Transparency, 1), "disabled + checked: no outline over the 38 % fill")
	v:Set(false)
	settle()
	assert(near(H.find(box, "Outline").Transparency, 0.62), "disabled + unchecked: 38 % outline")
	v:Set(true)
	settle()
	H.fire(cb, "Activated", H.input({}), 1)
	assert(v:Get() == true and calls == 0, "disabled swallows the click")
	H.fire(cb, "MouseEnter")
	settle()
	assert(H.find(cb, "StateLayer").BackgroundTransparency == 1, "no layer while disabled")
	dis:Set(false)
	H.fire(cb, "Activated", H.input({}), 1)
	assert(v:Get() == false and calls == 1)
	q.dispose(cb)
	H.assertNoDebugOutput("checkbox disabled")
end)

H.section("toggle motion: bars close in the OLD color, the look swaps at the midpoint, bars reopen in the new color", function()
	local v = q.Source(false)
	local cb = Checkbox({ Value = v })
	local box = H.find(cb, "Box")
	local left = H.find(box, "BarLeft")
	local bars = H.find(box, "Bars")
	assert(left.Size == UDim2.fromScale(0, 1) and left.Parent == bars and bars.ZIndex == 2, "bars rest at zero width, above the marks")
	assert(bars.Size == UDim2.fromOffset(14, 14), "bars frame sits inside the 2 px outline (never over the rounded corners)")
	v:Set(true)
	H.advance(0.075) -- halfway through the close
	assert(near(left.Size.X.Scale, 0.2), "left bar half way in: " .. tostring(left.Size))
	assert(left.BackgroundColor3 == L.OnSurfaceVariant, "closing in the old (unchecked) outline color")
	assert(box.BackgroundTransparency == 1 and H.find(box, "CheckShort").BackgroundTransparency == 1, "old look still shown")
	assert(box.Size.X.Offset > 18, "box swells while it closes")
	assert(bars.Size == UDim2.fromOffset(14, 14), "the bars frame does not swell with the outline (a gap ring opens)")
	H.advance(0.1) -- past the midpoint
	assert(box.BackgroundTransparency == 0 and H.find(box, "CheckShort").BackgroundTransparency == 0, "new look swapped in")
	assert(left.BackgroundColor3 == L.Primary, "reopening in the new color")
	assert(left.Size.X.Scale > 0 and left.Size.X.Scale < 0.4)
	H.advance(0.2)
	assert(left.Size == UDim2.fromScale(0, 1) and box.Size == UDim2.fromOffset(18, 18), "back at rest")
	-- an interrupting change resumes from the current bar width (no jump back to zero)
	v:Set(false)
	H.advance(0.05)
	local w = left.Size.X.Scale
	v:Set(true)
	H.advance(0.01)
	assert(left.Size.X.Scale >= w, "resumed, not restarted")
	H.advance(0.5)
	assert(left.Size == UDim2.fromScale(0, 1) and box.BackgroundTransparency == 0)
	q.dispose(cb)
	H.assertNoDebugOutput("checkbox motion")
end)

H.section("Label: the text belongs to the control (hover lights the box's layer, a click toggles)", function()
	local v = q.Source(false)
	local cb = Checkbox({ Value = v, Label = "Agree" })
	assert(cb.Size == UDim2.fromOffset(0, 48) and cb.AutomaticSize == Enum.AutomaticSize.X, "host grows to hold the text")
	local label = H.find(cb, "Label")
	assert(label.Parent == cb and label.Text == "Agree" and label.Position == UDim2.fromOffset(48, 0))
	assert(H.find(cb, "Target").Position == UDim2.fromOffset(24, 24), "box placed by offset on the auto-sized host")
	assert(H.countDescendants(cb) == 16)
	-- the label is a child of the host button: the host's hover / click ARE the label's
	H.fire(cb, "MouseEnter")
	H.finishTweens()
	assert(near(H.find(cb, "StateLayer").BackgroundTransparency, 1 - Tokens.State.Opacity.Hover), "hover over the row lights the layer")
	H.fire(cb, "Activated", H.input({}), 1)
	assert(v:Get() == true)
	-- a press that starts on the text ripples from the layer's center
	H.setAbs(H.find(cb, "StateLayer"), 4, 4, 40, 40)
	H.fire(cb, "InputBegan", H.input({ Position = Vector3.new(120, 24, 0) }))
	assert(H.find(cb, "RippleCircle").Position == UDim2.fromOffset(20, 20), "press on the label: ripple from the center")
	H.fire(cb, "InputEnded", H.input({}))
	H.advance(1)
	q.dispose(cb)
	H.assertNoDebugOutput("checkbox label")
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
