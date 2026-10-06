--!strict
local H = require("./support/harness")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
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

local FULL = Vector2.new(360, 0) -- sprite frame 9: ring + dot
local EMPTY = Vector2.new(0, 0) -- frame 0: the ring alone

H.section("mount: structure and instance count", function()
	local r = Radio({ Value = q.Source("a"), Option = "a" })
	assert(r.ClassName == "TextButton" and r.Name == "Radio" and r.Size == UDim2.fromOffset(48, 48))
	local n = H.countDescendants(r)
	print("Radio descendants: " .. n .. " (+1 host = " .. (n + 1) .. ")")
	H.resetOutput()
	assert(n == 5, "Target, layer(3), Sprite = 5, got " .. n)
	local sprite = H.find(r, "Sprite")
	assert(sprite.ClassName == "ImageLabel" and sprite.Size == UDim2.fromOffset(20, 20))
	assert(sprite.Image == "rbxassetid://4667411351" and sprite.ImageRectSize == Vector2.new(40, 40), "the MaterialUI sprite sheet")
	assert(sprite.ImageRectOffset == FULL, "initially selected mounts on the last frame")
	assert(sprite.ImageColor3 == L.Primary)
	q.dispose(r)
	local off = Radio({ Value = q.Source("a"), Option = "b" })
	assert(H.find(off, "Sprite").ImageRectOffset == EMPTY and H.find(off, "Sprite").ImageColor3 == L.OnSurfaceVariant)
	q.dispose(off)
	H.assertNoDebugOutput("radio mount")
end)

H.section("click selects; Source drives the sprite; radios of one Source exclude each other", function()
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
	local sa, sb = H.find(a, "Sprite"), H.find(b, "Sprite")
	assert(sa.ImageRectOffset == FULL and sb.ImageRectOffset == EMPTY)
	H.fire(b, "Activated", H.input({}), 1)
	assert(v:Get() == "b" and picked[1] == "b", "click writes Value")
	H.advance(0.3)
	H.finishTweens()
	assert(sb.ImageRectOffset == FULL and sa.ImageRectOffset == EMPTY, "frames step in / out")
	-- clicking the selected radio is a no-op
	H.fire(b, "Activated", H.input({}), 1)
	assert(#picked == 1)
	-- Source -> UI
	v:Set("a")
	H.advance(0.3)
	assert(sa.ImageRectOffset == FULL and sb.ImageRectOffset == EMPTY)
	assert(#picked == 1, "programmatic writes do not call OnChange")
	q.dispose(a)
	q.dispose(b)
	H.assertNoDebugOutput("radio click")
end)

H.section("the selection is a frame-by-frame sprite run (whole frames, 0.2 s), reversible mid-way", function()
	local v = q.Source("a")
	local b = Radio({ Value = v, Option = "b" })
	local sprite = H.find(b, "Sprite")
	v:Set("b")
	H.advance(0.1) -- half the run: frame 4 (whole frames only)
	assert(sprite.ImageRectOffset == Vector2.new(160, 0), "mid-run frame: " .. tostring(sprite.ImageRectOffset))
	v:Set("a") -- reverse from where it is
	H.advance(0.05)
	local x = sprite.ImageRectOffset.X
	assert(x < 160 and x > 0 and x % 40 == 0, "stepping back from the current frame: " .. tostring(x))
	H.advance(0.3)
	assert(sprite.ImageRectOffset == EMPTY)
	q.dispose(b)
	H.assertNoDebugOutput("radio sprite")
end)

H.section("error + disabled", function()
	local v = q.Source("b")
	local err = q.Source(true)
	local r = Radio({ Value = v, Option = "a", Error = err })
	H.finishTweens()
	assert(H.find(r, "Sprite").ImageColor3 == L.Error, "unselected error ring")
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
	assert(d.Interactable == false and H.find(d, "Sprite").ImageColor3 == L.OnSurface)
	assert(near(H.find(d, "Sprite").ImageTransparency, 0.62))
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
	local radios = H.findAll(g, function(c: any)
		return c.Name == "Radio"
	end)
	assert(#radios == 3 and radios[2].LayoutOrder == 2, "one Radio host per row")
	H.fire(radios[2], "Activated", H.input({}), 1)
	assert(v:Get() == "b")
	local labels = H.findAll(g, function(c: any)
		return c.Name == "Label"
	end)
	assert(labels[1].Text == "Alpha" and labels[1].Parent == radios[1], "the label is the radio's own (label-for)")
	assert(radios[1].AutomaticSize == Enum.AutomaticSize.X and radios[1].Size == UDim2.fromOffset(0, 48))
	-- hover over the row (label included) lights that radio's layer
	H.fire(radios[1], "MouseEnter")
	H.finishTweens()
	assert(near(H.find(radios[1], "StateLayer").BackgroundTransparency, 1 - Tokens.State.Opacity.Hover))
	H.fire(radios[1], "Activated", H.input({}), 1)
	assert(v:Get() == "a", "row click selects")
	H.fire(radios[3], "Activated", H.input({}), 1)
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
