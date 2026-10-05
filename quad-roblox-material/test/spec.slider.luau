--!strict
local H = require("./support/harness")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
local Tokens = require("../src/Tokens")
local Slider = require("../src/Slider")

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

-- host at x=100, 220 wide -> rail from 110, 200 wide
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

H.section("mount: structure, geometry, instance count", function()
	local s = Slider({ Value = q.Source(0.5) })
	assert(s.ClassName == "Frame" and s.Name == "Slider" and s.Size == UDim2.new(1, 0, 0, 40))
	local n = H.countDescendants(s)
	print("Slider descendants: " .. n .. " (+1 host = " .. (n + 1) .. ")")
	H.resetOutput()
	assert(n == 14, "Rail, 2 bars(+2 corners), Halo, layer(3), Handle(+corner), Label(+corner+padding) = 14, got " .. n)
	assert(H.find(s, "Rail").Size == UDim2.new(1, -20, 1, 0))
	assert(H.find(s, "Handle").Size == UDim2.fromOffset(20, 20) and H.find(s, "Halo").Size == UDim2.fromOffset(40, 40))
	assert(H.find(s, "Active").Size == UDim2.new(0.5, 0, 0, 4) and H.find(s, "Inactive").Size == UDim2.new(1, 0, 0, 4))
	assert(H.find(s, "Halo").Position == UDim2.fromScale(0.5, 0.5))
	assert(H.find(s, "Active").BackgroundColor3 == L.Primary and H.find(s, "Inactive").BackgroundColor3 == L.SurfaceVariant)
	assert(s.Selectable == true and s.NextSelectionLeft == s and s.NextSelectionRight == s)
	assert(#H.findAll(s, function(c: any)
		return c.Name == "Tick"
	end) == 0, "continuous: no ticks")
	assert(keyConns() == baseKeys and uisConns() == baseConns, "no global connection at rest")
	q.dispose(s)
	H.assertNoDebugOutput("slider mount")
end)

H.section("Source -> UI: handle and active track follow, clamped", function()
	local v = q.Source(0)
	local s = Slider({ Value = v, Min = 0, Max = 100 })
	assert(H.find(s, "Active").Size == UDim2.new(0, 0, 0, 4))
	v:Set(25)
	assert(H.find(s, "Halo").Position == UDim2.fromScale(0.25, 0.5) and H.find(s, "Active").Size == UDim2.new(0.25, 0, 0, 4))
	v:Set(500)
	assert(H.find(s, "Halo").Position == UDim2.fromScale(1, 0.5), "clamped to the end")
	assert(H.find(s, "Label").Text == "500", "label shows the raw Value")
	q.dispose(s)
	H.assertNoDebugOutput("slider source")
end)

H.section("drag: press jumps, moves follow, release ends; UI -> Source; callbacks", function()
	local v = q.Source(0)
	local changes: { number } = {}
	local ends: { number } = {}
	local s = Slider({
		Value = v,
		Min = 0,
		Max = 100,
		OnChange = function(x: number)
			table.insert(changes, x)
		end,
		OnChangeEnd = function(x: number)
			table.insert(ends, x)
		end,
	})
	layout(s)
	assert(uisConns() == baseConns)
	press(s, 160) -- 50 px into a 200 px rail -> 25
	assert(near(v:Get(), 25) and uisConns() == baseConns + 3, "press jumps to the pointer, 3 connections while dragging")
	assert(#ends == 0)
	-- the label bubble is visible while dragging
	H.finishTweens()
	assert(H.find(s, "Label").BackgroundTransparency == 0, "label shown while dragging")
	move(210)
	assert(near(v:Get(), 50))
	move(1000) -- far past the end: clamped
	assert(near(v:Get(), 100))
	move(-500)
	assert(near(v:Get(), 0))
	move(310)
	release(310)
	assert(near(v:Get(), 100) and #ends == 1 and near(ends[1], 100), "OnChangeEnd on release")
	assert(uisConns() == baseConns, "connections closed at release")
	H.finishTweens()
	assert(H.find(s, "Label").BackgroundTransparency == 1, "label hidden after release")
	assert(near(changes[1], 25) and near(changes[2], 50), "OnChange per user change")
	local count = #changes
	move(150) -- no drag: ignored
	assert(#changes == count)
	-- changed-only: pressing at the same value does not write again
	v:Set(25)
	press(s, 160)
	assert(#changes == count)
	release(160)
	q.dispose(s)
	H.assertNoDebugOutput("slider drag")
end)

H.section("discrete: Step snaps, ticks, OnChange only on changed steps", function()
	local v = q.Source(0)
	local changes: { number } = {}
	local s = Slider({
		Value = v,
		Min = 0,
		Max = 10,
		Step = 2,
		OnChange = function(x: number)
			table.insert(changes, x)
		end,
	})
	layout(s)
	local ticks = H.findAll(s, function(c: any)
		return c.Name == "Tick"
	end)
	assert(#ticks == 6, "0,2,..,10 -> 6 ticks, got " .. #ticks)
	assert(ticks[1].BackgroundColor3 == L.OnPrimary and ticks[6].BackgroundColor3 == L.OnSurfaceVariant, "active vs inactive ticks")
	press(s, 110 + 55) -- 27.5 % of 10 = 2.75 -> snaps to 2
	assert(v:Get() == 2 and #changes == 1)
	move(110 + 70) -- 3.5 -> 4
	assert(v:Get() == 4 and #changes == 2)
	move(110 + 72) -- 3.6 -> still 4: no new change
	assert(v:Get() == 4 and #changes == 2, "same step is not a change")
	release(110 + 72)
	assert(ticks[3].BackgroundColor3 == L.OnPrimary and ticks[4].BackgroundColor3 == L.OnSurfaceVariant)
	v:Set(10)
	assert(ticks[6].BackgroundColor3 == L.OnPrimary, "ticks follow Source writes")
	q.dispose(s)
	local off = Slider({ Min = 0, Max = 4, Step = 1, ShowTicks = false })
	assert(#H.findAll(off, function(c: any)
		return c.Name == "Tick"
	end) == 0)
	q.dispose(off)
	H.assertNoDebugOutput("slider discrete")
end)

H.section("keyboard: connection only while focused, closed on blur and destroy", function()
	local v = q.Source(5)
	local changes: { number } = {}
	local ends: { number } = {}
	local s = Slider({
		Value = v,
		Min = 0,
		Max = 10,
		Step = 1,
		OnChange = function(x: number)
			table.insert(changes, x)
		end,
		OnChangeEnd = function(x: number)
			table.insert(ends, x)
		end,
	})
	key(Enum.KeyCode.Right)
	assert(v:Get() == 5, "not focused: ignored")
	H.fire(s, "SelectionGained")
	assert(keyConns() == baseKeys + 1, "one InputBegan connection while focused")
	H.fire(s, "SelectionGained")
	assert(keyConns() == baseKeys + 1, "not doubled")
	key(Enum.KeyCode.Right)
	assert(v:Get() == 6 and ends[1] == 6)
	key(Enum.KeyCode.Left)
	key(Enum.KeyCode.Left)
	assert(v:Get() == 4)
	key(Enum.KeyCode.PageUp)
	assert(v:Get() == 10, "page up clamps")
	key(Enum.KeyCode.Right)
	assert(v:Get() == 10 and #ends == 4, "clamped: no change, no OnChangeEnd")
	key(Enum.KeyCode.Home)
	assert(v:Get() == 0)
	key(Enum.KeyCode.End)
	assert(v:Get() == 10)
	key(Enum.KeyCode.DPadLeft)
	assert(v:Get() == 9)
	key(Enum.KeyCode.A) -- unrelated
	assert(v:Get() == 9)
	key(Enum.KeyCode.Up)
	key(Enum.KeyCode.Down)
	assert(v:Get() == 9, "D6: Up/Down are not mapped (they walk the selection on)")
	local sAny: any = s
	assert(sAny.NextSelectionLeft == s and sAny.NextSelectionRight == s and sAny.NextSelectionUp == nil and sAny.NextSelectionDown == nil)
	H.finishTweens()
	assert(H.find(s, "Label").BackgroundTransparency == 0, "label shown while focused")
	H.fire(s, "SelectionLost")
	assert(keyConns() == baseKeys, "closed on blur")
	key(Enum.KeyCode.Left)
	assert(v:Get() == 9)
	H.fire(s, "SelectionGained")
	assert(keyConns() == baseKeys + 1)
	q.dispose(s)
	assert(keyConns() == baseKeys, "closed on destroy")
	H.assertNoDebugOutput("slider keyboard")
end)

H.section("continuous KeyStep default is range / 20", function()
	local v = q.Source(0)
	local s = Slider({ Value = v, Min = 0, Max = 1 })
	H.fire(s, "SelectionGained")
	key(Enum.KeyCode.Right)
	assert(near(v:Get(), 0.05))
	q.dispose(s)
	local s2 = Slider({ Value = v, Min = 0, Max = 1, KeyStep = 0.25 })
	H.fire(s2, "SelectionGained")
	key(Enum.KeyCode.Right)
	assert(near(v:Get(), 0.3))
	q.dispose(s2)
	H.assertNoDebugOutput("slider keystep")
end)

H.section("disabled blocks drag and keys, uses 38 % / 12 % roles", function()
	local v = q.Source(5)
	local dis = q.Source(true)
	local s = Slider({ Value = v, Min = 0, Max = 10, Disabled = dis })
	layout(s)
	H.finishTweens()
	assert(s.Interactable == false and s.Selectable == false)
	assert(H.find(s, "Active").BackgroundColor3 == L.OnSurface and near(H.find(s, "Active").BackgroundTransparency, 0.62))
	assert(near(H.find(s, "Inactive").BackgroundTransparency, 0.88))
	press(s, 150)
	assert(v:Get() == 5 and uisConns() == baseConns, "no drag while disabled")
	H.fire(s, "SelectionGained")
	key(Enum.KeyCode.Right)
	assert(v:Get() == 5, "keys ignored while disabled")
	H.fire(s, "SelectionLost")
	dis:Set(false)
	press(s, 150)
	assert(v:Get() ~= 5)
	release(150)
	q.dispose(s)
	H.assertNoDebugOutput("slider disabled")
end)

H.section("dispose mid-drag: connections closed, no OnChangeEnd; focus loss cancels", function()
	local ends = 0
	local v = q.Source(0)
	local s = Slider({
		Value = v,
		Min = 0,
		Max = 100,
		OnChangeEnd = function()
			ends += 1
		end,
	})
	layout(s)
	press(s, 150)
	assert(uisConns() == baseConns + 3)
	q.dispose(s)
	assert(uisConns() == baseConns and ends == 0 and H.isDestroyed(s))
	local s2 = Slider({ Value = v, Min = 0, Max = 100, OnChangeEnd = function()
		ends += 1
	end })
	layout(s2)
	press(s2, 150)
	UIS.WindowFocusReleased:Fire()
	assert(uisConns() == baseConns and ends == 0, "cancelled drag skips OnChangeEnd")
	q.dispose(s2)
	assert(keyConns() == baseKeys)
	H.assertNoDebugOutput("slider dispose")
end)

H.section("custom Format and ShowLabel = false; bad arguments", function()
	local s = Slider({ Value = q.Source(0.5), Format = function(x: number)
		return string.format("%d%%", x * 100)
	end })
	assert(H.find(s, "Label").Text == "50%")
	q.dispose(s)
	local nl = Slider({ ShowLabel = false })
	assert(H.find(nl, "Label") == nil and H.countDescendants(nl) == 11)
	q.dispose(nl)
	local ok = pcall(function()
		Slider({ Min = 1, Max = 1 })
	end)
	assert(not ok, "Max must exceed Min")
	local d = Slider({ Value = q.Source(0.125) })
	assert(H.find(d, "Label").Text == "0.13" or H.find(d, "Label").Text == "0.12")
	q.dispose(d)
	H.assertNoDebugOutput("slider format")
end)

H.done()
