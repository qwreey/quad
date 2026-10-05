--!strict
local H = require("./support/harness")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
local D = q.Declaration
local Tokens = require("../src/Tokens")
local RadioModule = require("../src/Radio")
local Radio = RadioModule.Radio
local RadioGroup = RadioModule.RadioGroup

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

H.section("mount: structure and instance count", function()
	local r = Radio({ Value = q.Source("a"), Option = "a" })
	assert(r.ClassName == "TextButton" and r.Name == "Radio" and r.Size == UDim2.fromOffset(48, 48))
	local n = H.countDescendants(r)
	print("Radio descendants: " .. n .. " (+1 host = " .. (n + 1) .. ")")
	H.resetOutput()
	assert(n == 9, "Target, layer(3), Ring(+corner+stroke), Dot(+corner) = 9, got " .. n)
	assert(H.find(r, "Ring").Size == UDim2.fromOffset(20, 20))
	assert(H.find(H.find(r, "Ring"), "Outline").Thickness == 2)
	assert(H.find(r, "Dot").Size == UDim2.fromOffset(10, 10), "initially selected mounts with the dot at 10 px")
	assert(H.find(H.find(r, "Ring"), "Outline").Color == L.Primary and H.find(r, "Dot").BackgroundColor3 == L.Primary)
	q.dispose(r)
	local off = Radio({ Value = q.Source("a"), Option = "b" })
	assert(H.find(off, "Dot").Size == UDim2.fromOffset(0, 0))
	assert(H.find(H.find(off, "Ring"), "Outline").Color == L.OnSurfaceVariant)
	q.dispose(off)
	H.assertNoDebugOutput("radio mount")
end)

H.section("click selects; Source drives the dot (size animates); radios of one Source exclude each other", function()
	local v = q.Source("a")
	local picked: { string } = {}
	local function make(o: string)
		return Radio({
			Value = v,
			Option = o,
			OnChange = function(x: string)
				table.insert(picked, x)
			end,
		})
	end
	local a, b = make("a"), make("b")
	local dotA, dotB = H.find(a, "Dot"), H.find(b, "Dot")
	assert(dotA.Size == UDim2.fromOffset(10, 10) and dotB.Size == UDim2.fromOffset(0, 0))
	H.fire(b, "Activated", H.input({}), 1)
	assert(v:Get() == "b" and picked[1] == "b", "click writes Value")
	H.finishTweens()
	assert(dotB.Size == UDim2.fromOffset(10, 10) and dotA.Size == UDim2.fromOffset(0, 0), "dot scales in / out")
	assert(#H.tweenLog() == 0)
	-- clicking the selected radio is a no-op
	H.fire(b, "Activated", H.input({}), 1)
	assert(#picked == 1)
	-- Source -> UI
	v:Set("a")
	H.finishTweens()
	assert(dotA.Size == UDim2.fromOffset(10, 10) and dotB.Size == UDim2.fromOffset(0, 0))
	assert(#picked == 1, "programmatic writes do not call OnChange")
	q.dispose(a)
	q.dispose(b)
	H.assertNoDebugOutput("radio click")
end)

H.section("the dot size change is an animation (engine tween), not a snap", function()
	local v = q.Source("a")
	local b = Radio({ Value = v, Option = "b" })
	local root = D.Frame { b }
	v:Set("b")
	assert(#H.tweenLog() > 0, "a size tween was started")
	H.finishTweens()
	assert(H.find(b, "Dot").Size == UDim2.fromOffset(10, 10))
	q.dispose(root)
	H.assertNoDebugOutput("radio tween")
end)

H.section("error + disabled", function()
	local v = q.Source("b")
	local err = q.Source(true)
	local r = Radio({ Value = v, Option = "a", Error = err })
	H.finishTweens()
	assert(H.find(H.find(r, "Ring"), "Outline").Color == L.Error, "unselected error ring")
	local dis = q.Source(true)
	local calls = 0
	local d = Radio({
		Value = v,
		Option = "a",
		Disabled = dis,
		OnChange = function()
			calls += 1
		end,
	})
	H.finishTweens()
	assert(d.Interactable == false and H.find(H.find(d, "Ring"), "Outline").Color == L.OnSurface)
	assert(near(H.find(d, "Dot").BackgroundTransparency, 0.62))
	H.fire(d, "Activated", H.input({}), 1)
	assert(v:Get() == "b" and calls == 0, "disabled blocks input")
	H.fire(d, "MouseEnter")
	H.finishTweens()
	assert(H.find(d, "StateLayer").BackgroundTransparency == 1)
	dis:Set(false)
	H.fire(d, "Activated", H.input({}), 1)
	assert(v:Get() == "a" and calls == 1)
	q.dispose(r)
	q.dispose(d)
	H.assertNoDebugOutput("radio disabled")
end)

H.section("RadioGroup: rows, label click, per-option disabled, direction", function()
	local v = q.Source("a")
	local g = RadioGroup({
		Value = v,
		Options = {
			{ Option = "a", Label = "Alpha" },
			{ Option = "b", Label = "Beta" },
			{ Option = "c", Label = "Gamma", Disabled = true },
		},
	})
	local rows = H.findAll(g, function(c: any)
		return c.Name == "Row"
	end)
	assert(#rows == 3 and rows[2].LayoutOrder == 2)
	local radios = H.findAll(g, function(c: any)
		return c.Name == "Radio"
	end)
	assert(#radios == 3)
	H.fire(radios[2], "Activated", H.input({}), 1)
	assert(v:Get() == "b")
	local labels = H.findAll(g, function(c: any)
		return c.Name == "Label"
	end)
	assert(labels[1].Text == "Alpha" and labels[1].Selectable == false)
	H.fire(labels[1], "Activated", H.input({}), 1)
	assert(v:Get() == "a", "label click selects")
	H.fire(radios[3], "Activated", H.input({}), 1)
	H.fire(labels[3], "Activated", H.input({}), 1)
	assert(v:Get() == "a", "disabled option cannot be chosen")
	local layout = H.findAll(g, function(c: any)
		return c.ClassName == "UIListLayout" and c.Parent == g
	end)[1]
	assert(layout.FillDirection == Enum.FillDirection.Vertical)
	q.dispose(g)
	local h = RadioGroup({ Value = v, Options = { { Option = "a", Label = "A" } }, Direction = "Horizontal" })
	local hl = H.findAll(h, function(c: any)
		return c.ClassName == "UIListLayout" and c.Parent == h
	end)[1]
	assert(hl.FillDirection == Enum.FillDirection.Horizontal)
	q.dispose(h)
	H.assertNoDebugOutput("radio group")
end)

H.section("dispose: destroyed, no leaked connections", function()
	local r = Radio({ Value = q.Source(1), Option = 1 })
	H.fire(r, "InputBegan", H.input({}))
	q.dispose(r)
	assert(H.isDestroyed(r) and uisConns() == baseConns)
	H.assertNoDebugOutput("radio dispose")
end)

H.done()
