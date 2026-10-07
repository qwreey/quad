--!strict
local H = require("./support/harness")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
local Tokens = require("../src/Tokens")
local RangeSlider = require("../src/Slider/Range")

local UIS = H.UserInputService
local function uisConns(): number
	local u = UIS :: any
	return #u.InputChanged.connections + #u.InputEnded.connections + #u.WindowFocusReleased.connections
end
local function keyConns(): number
	return #(UIS :: any).InputBegan.connections
end
local baseConns, baseKeys = uisConns(), keyConns()
local L = Tokens.Color.Light

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

-- host at x=100, 220 wide -> rail from 110, 200 wide (as spec.slider)
local function layout(s: any)
	H.setAbs(s, 100, 50, 220, 40)
end
local function press(s: any, x: number)
	H.fire(s, "InputBegan", H.input({ Position = Vector3.new(x, 60, 0) }))
end
local function move(x: number)
	UIS.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(x, 60, 0) }))
end
local function release(x: number)
	UIS.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(x, 60, 0) }))
end
local function key(code: any)
	UIS.InputBegan:Fire(H.input({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = code }))
end

H.section("mount: structure, two handles, active track between them, instance count", function()
	local s = RangeSlider({ Start = q.Source(0.25), End = q.Source(0.75) })
	assert(s.ClassName == "Frame" and s.Name == "RangeSlider" and s.Size == UDim2.new(1, 0, 0, 40))
	local n = H.countDescendants(s)
	print("RangeSlider descendants: " .. n .. " (+1 host = " .. (n + 1) .. ")")
	H.resetOutput()
	assert(n == 23, "Rail, 2 bars(+2 corners), 2 x (Halo, layer(3), Handle(+corner), Label(+corner+padding)) = 23, got " .. n)
	assert(H.find(s, "HaloStart").Position == UDim2.fromScale(0.25, 0.5) and H.find(s, "HaloEnd").Position == UDim2.fromScale(0.75, 0.5))
	local active = H.find(s, "Active")
	assert(active.Position == UDim2.fromScale(0.25, 0.5) and active.Size == UDim2.new(0.5, 0, 0, 4), "active between the handles")
	assert(active.BackgroundColor3 == L.Primary and H.find(s, "Inactive").BackgroundColor3 == L.SurfaceVariant)
	assert(s.Selectable == true and s.NextSelectionLeft == s and s.NextSelectionRight == s, "one selection stop, horizontal pin")
	assert(keyConns() == baseKeys and uisConns() == baseConns, "no global connection at rest")
	q.dispose(s)
	-- defaults: own Sources at Min / Max
	local d = RangeSlider({ Min = 10, Max = 20 })
	assert(H.find(d, "HaloStart").Position == UDim2.fromScale(0, 0.5) and H.find(d, "HaloEnd").Position == UDim2.fromScale(1, 0.5))
	q.dispose(d)
	H.assertNoDebugOutput("range mount")
end)

H.section("drag: the nearest handle moves, stops at the other, callbacks carry both values", function()
	local lo, hi = q.Source(20), q.Source(80)
	local changes: { string } = {}
	local ends: { string } = {}
	local s = RangeSlider({
		Start = lo,
		End = hi,
		Min = 0,
		Max = 100,
		OnChange = function(a: number, b: number)
			table.insert(changes, a .. ".." .. b)
		end,
		OnChangeEnd = function(a: number, b: number)
			table.insert(ends, a .. ".." .. b)
		end,
	})
	layout(s)
	press(s, 110 + 60) -- 30: nearer Start (20)
	assert(near(lo:Get(), 30) and hi:Get() == 80 and uisConns() == baseConns + 3)
	H.finishTweens()
	assert(H.find(H.find(s, "HaloStart"), "Label").BackgroundTransparency == 0, "dragged handle's label shows")
	assert(H.find(H.find(s, "HaloEnd"), "Label").BackgroundTransparency == 1, "the other's stays hidden")
	move(110 + 190) -- 95: Start stops at End
	assert(near(lo:Get(), 80) and hi:Get() == 80, "start stops at end")
	release(110 + 190)
	assert(#ends == 1 and ends[1] == "80..80" and uisConns() == baseConns)
	assert(changes[1] == "30..80")
	-- closed range: the drag direction picks the handle (left -> Start, right -> End)
	press(s, 110 + 160) -- exactly at 80
	move(110 + 180) -- 90
	assert(lo:Get() == 80 and near(hi:Get(), 90), "moving right reopens with End")
	release(110 + 180)
	lo:Set(50)
	hi:Set(50)
	press(s, 110 + 100)
	move(110 + 60) -- 30
	assert(near(lo:Get(), 30) and hi:Get() == 50, "moving left reopens with Start")
	release(110 + 60)
	-- a press near End grabs End
	press(s, 110 + 98) -- 49: nearer End (50) than Start (30)
	assert(near(hi:Get(), 49) and near(lo:Get(), 30))
	release(110 + 98)
	q.dispose(s)
	assert(uisConns() == baseConns)
	H.assertNoDebugOutput("range drag")
end)

H.section("discrete: ticks active only between the handles", function()
	local lo, hi = q.Source(2), q.Source(6)
	local s = RangeSlider({ Start = lo, End = hi, Min = 0, Max = 10, Step = 2 })
	local ticks = H.findAll(s, function(c: any)
		return c.Name == "Tick"
	end)
	assert(#ticks == 6)
	local function on(i: number): boolean
		return ticks[i].BackgroundColor3 == L.OnPrimary
	end
	assert(not on(1) and on(2) and on(3) and on(4) and not on(5) and not on(6), "0 off, 2..6 on, 8..10 off")
	hi:Set(10)
	assert(on(6) and on(5))
	q.dispose(s)
	H.assertNoDebugOutput("range ticks")
end)

H.section("keys move the key handle; Return switches it; clamped at the other handle", function()
	local lo, hi = q.Source(4), q.Source(6)
	local ends: { string } = {}
	local s = RangeSlider({
		Start = lo,
		End = hi,
		Min = 0,
		Max = 10,
		Step = 1,
		OnChangeEnd = function(a: number, b: number)
			table.insert(ends, a .. ".." .. b)
		end,
	})
	H.fire(s, "SelectionGained")
	assert(keyConns() == baseKeys + 1)
	key(Enum.KeyCode.Left)
	assert(lo:Get() == 3 and ends[1] == "3..6", "Start is the key handle at first")
	key(Enum.KeyCode.End)
	assert(lo:Get() == 6, "End key clamps Start at the other handle")
	key(Enum.KeyCode.Return)
	key(Enum.KeyCode.Right)
	assert(hi:Get() == 7 and lo:Get() == 6, "Return switched to End")
	key(Enum.KeyCode.Home)
	assert(hi:Get() == 6, "End stops at Start")
	key(Enum.KeyCode.ButtonX)
	key(Enum.KeyCode.Home)
	assert(lo:Get() == 0, "ButtonX switched back to Start")
	H.fire(s, "SelectionLost")
	assert(keyConns() == baseKeys)
	q.dispose(s)
	H.assertNoDebugOutput("range keys")
end)

H.section("hover lights the halo nearest the pointer; disabled: no input", function()
	local lo, hi = q.Source(0.2), q.Source(0.8)
	local dis = q.Source(false)
	local s = RangeSlider({ Start = lo, End = hi, Disabled = dis })
	layout(s)
	H.fire(s, "MouseEnter")
	H.fire(s, "MouseMoved", 110 + 170, 60)
	H.finishTweens()
	local layerS = H.find(H.find(s, "HaloStart"), "StateLayer")
	local layerE = H.find(H.find(s, "HaloEnd"), "StateLayer")
	assert(layerE.BackgroundTransparency < 1 and layerS.BackgroundTransparency == 1, "End (nearest) hovered")
	H.fire(s, "MouseMoved", 110 + 10, 60)
	H.finishTweens()
	assert(layerS.BackgroundTransparency < 1 and layerE.BackgroundTransparency == 1, "Start (nearest) hovered")
	dis:Set(true)
	H.finishTweens()
	assert(s.Interactable == false and s.Selectable == false)
	press(s, 110 + 100)
	assert(near(lo:Get(), 0.2) and uisConns() == baseConns, "disabled: no drag")
	q.dispose(s)
	H.assertNoDebugOutput("range hover")
end)

H.section("errors: Max must be greater than Min, Step positive", function()
	local ok1 = pcall(function()
		RangeSlider({ Min = 1, Max = 1 })
	end)
	local ok2 = pcall(function()
		RangeSlider({ Step = 0 })
	end)
	assert(not ok1 and not ok2)
end)

H.done()
