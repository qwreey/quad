--!strict
local H = require("./support/harness")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
local Tokens = require("../src/Tokens")
local RangeSlider = require("../src/Slider/Range")
local M2 = require("../src/M2")

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

-- every look gets a 200 px RAIL from x = 110 (as spec.slider): M3 handle inset 8, M2 10
type LookCase = { Name: string, Make: (props: any) -> any, Inset: number, Halo: string }
local looks: { LookCase } = {
	{ Name = "M3", Make = RangeSlider, Inset = 8, Halo = "Handle" },
	{ Name = "M2", Make = M2.RangeSlider, Inset = 10, Halo = "Halo" },
}
local current: LookCase = looks[1]
local function layout(s: any)
	H.setAbs(s, 110 - current.Inset, 50, 200 + 2 * current.Inset, 40)
end
local function px(u: UDim, w: number): number
	return u.Scale * w + u.Offset
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

H.section("M3 mount: three pieces (outer rounded 8 / 2, middle 2 / 2), two bar handles, stop dots, instance count", function()
	current = looks[1]
	local s = RangeSlider({ Start = q.Source(0.25), End = q.Source(0.75) })
	assert(s.ClassName == "Frame" and s.Name == "RangeSlider" and s.Size == UDim2.new(1, 0, 0, 44))
	local n = H.countDescendants(s)
	print("RangeSlider (M3) descendants: " .. n .. " (+1 host = " .. (n + 1) .. ")")
	H.resetOutput()
	assert(n == 30, "2 outer pieces x 6 + active(2) + 2 stops x 2 + 2 x (handle 3 + label 3) = 30, got " .. n)
	local W = 216
	H.setAbs(s, 0, 0, W, 44)
	local hs, he = H.find(s, "HandleStart"), H.find(s, "HandleEnd")
	assert(hs.Size == UDim2.fromOffset(4, 44) and he.Size == UDim2.fromOffset(4, 44))
	local xs, xe = px(hs.Position.X, W), px(he.Position.X, W)
	assert(xs == 58 and xe == 158, "centers 8 + 200 f: " .. xs .. ", " .. xe)
	-- left inactive piece: cap [0, 8] + body [8, xs - 8]
	local sBody = H.find(s, "StartBody")
	assert(px(sBody.Position.X, W) == 8 and px(sBody.Position.X, W) + px(sBody.Size.X, W) == xs - 8)
	-- middle: [xs + 8, xe - 8], one frame rounded 2
	local active = H.find(s, "Active")
	assert(px(active.Position.X, W) == xs + 8 and px(active.Position.X, W) + px(active.Size.X, W) == xe - 8, "6 px gap beside each handle")
	assert(H.find(active, "_quad_round").CornerRadius == UDim.new(0, 2) and active.BackgroundColor3 == L.Primary)
	-- right inactive piece: body [xe + 8, W - 8] + cap [W - 8, W]
	local eBody, eCap = H.find(s, "EndBody"), H.find(s, "EndCap")
	assert(px(eBody.Position.X, W) == xe + 8 and px(eBody.Position.X, W) + px(eBody.Size.X, W) == W - 8 and px(eCap.Position.X, W) == W - 8)
	assert(H.find(H.find(s, "StartCap"), "Fill").BackgroundColor3 == L.SecondaryContainer)
	assert(H.find(H.find(s, "StartCap"), "Fill").Position == UDim2.fromOffset(0, 0) and H.find(eCap, "Fill").Position == UDim2.fromOffset(-8, 0), "outer halves kept")
	local stopS, stopE = H.find(s, "StopStart"), H.find(s, "StopEnd")
	assert(stopS.Visible and stopE.Visible and px(stopS.Position.X, W) == 8 and px(stopE.Position.X, W) == W - 8, "a stop dot inside each outer end")
	assert(s.Selectable == true and s.NextSelectionLeft == s and s.NextSelectionRight == s, "one selection stop")
	assert(keyConns() == baseKeys and uisConns() == baseConns)
	q.dispose(s)
	H.assertNoDebugOutput("m3 range mount")
end)

H.section("M3 pieces hide: handles together hide the middle; a handle at an end hides that piece and its stop", function()
	current = looks[1]
	local lo, hi = q.Source(0), q.Source(100)
	local s = RangeSlider({ Start = lo, End = hi, Min = 0, Max = 100 })
	H.setAbs(s, 0, 0, 216, 44)
	assert(not H.find(s, "StartCap").Visible and not H.find(s, "StopStart").Visible, "Start at Min")
	assert(not H.find(s, "EndCap").Visible and not H.find(s, "StopEnd").Visible, "End at Max")
	assert(H.find(s, "Active").Visible)
	lo:Set(50)
	hi:Set(58) -- middle 200 * 0.08 - 16 = 0 px
	assert(not H.find(s, "Active").Visible)
	hi:Set(60) -- 4 px > 2
	assert(H.find(s, "Active").Visible and H.find(s, "StartCap").Visible and H.find(s, "EndCap").Visible)
	q.dispose(s)
	H.assertNoDebugOutput("m3 range hide")
end)

H.section("M3 discrete: dots between the handles SecondaryContainer, outside Primary, none in a gap or at the stops", function()
	current = looks[1]
	local lo, hi = q.Source(2), q.Source(6)
	local s = RangeSlider({ Start = lo, End = hi, Min = 0, Max = 10, Step = 2 })
	layout(s)
	local ticks = H.findAll(s, function(c: any)
		return c.Name == "Tick"
	end)
	assert(#ticks == 4, "2, 4, 6, 8 (0 and 10 are the stop dots), got " .. #ticks)
	assert(not ticks[1].Visible and not ticks[3].Visible, "2 and 6 sit under the handles")
	assert(ticks[2].Visible and ticks[2].BackgroundColor3 == L.SecondaryContainer, "4: between the handles")
	assert(ticks[4].Visible and ticks[4].BackgroundColor3 == L.Primary, "8: outside")
	hi:Set(10)
	assert(ticks[3].Visible and ticks[3].BackgroundColor3 == L.SecondaryContainer and ticks[4].BackgroundColor3 == L.SecondaryContainer)
	q.dispose(s)
	H.assertNoDebugOutput("m3 range ticks")
end)

H.section("M3 key handle: narrows and shows the ring while focused; draws above the other", function()
	current = looks[1]
	local s = RangeSlider({ Start = q.Source(4), End = q.Source(6), Min = 0, Max = 10, Step = 1 })
	local hs, he = H.find(s, "HandleStart"), H.find(s, "HandleEnd")
	H.fire(s, "SelectionGained")
	H.finishTweens()
	assert(H.find(hs, "FocusRing").Enabled == true and H.find(he, "FocusRing").Enabled == false)
	assert(hs.Size == UDim2.fromOffset(2, 44) and he.Size == UDim2.fromOffset(4, 44) and hs.ZIndex > he.ZIndex)
	key(Enum.KeyCode.Return)
	H.finishTweens()
	assert(H.find(he, "FocusRing").Enabled == true and H.find(hs, "FocusRing").Enabled == false and he.ZIndex > hs.ZIndex)
	H.fire(s, "SelectionLost")
	q.dispose(s)
	H.assertNoDebugOutput("m3 range focus")
end)

H.section("M2 mount: structure, two handles, active track between them, instance count", function()
	local s = M2.RangeSlider({ Start = q.Source(0.25), End = q.Source(0.75) })
	assert(s.ClassName == "Frame" and s.Name == "M2RangeSlider" and s.Size == UDim2.new(1, 0, 0, 40))
	local n = H.countDescendants(s)
	print("M2.RangeSlider descendants: " .. n .. " (+1 host = " .. (n + 1) .. ")")
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
	local d = M2.RangeSlider({ Min = 10, Max = 20 })
	assert(H.find(d, "HaloStart").Position == UDim2.fromScale(0, 0.5) and H.find(d, "HaloEnd").Position == UDim2.fromScale(1, 0.5))
	q.dispose(d)
	H.assertNoDebugOutput("range mount")
end)

H.section("M2 discrete: ticks active only between the handles", function()
	local lo, hi = q.Source(2), q.Source(6)
	local s = M2.RangeSlider({ Start = lo, End = hi, Min = 0, Max = 10, Step = 2 })
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

H.section("M2 hover lights the halo nearest the pointer; disabled: no input", function()
	local lo, hi = q.Source(0.2), q.Source(0.8)
	local dis = q.Source(false)
	local s = M2.RangeSlider({ Start = lo, End = hi, Disabled = dis })
	current = looks[2]
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

for _, look in looks do
	H.section(look.Name .. " drag: the nearest handle moves, stops at the other, callbacks carry both values", function()
		current = look
		local lo, hi = q.Source(20), q.Source(80)
		local changes: { string } = {}
		local ends: { string } = {}
		local s = look.Make({
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
		assert(H.find(H.find(s, look.Halo .. "Start"), "Label").BackgroundTransparency == 0, "dragged handle's label shows")
		assert(H.find(H.find(s, look.Halo .. "End"), "Label").BackgroundTransparency == 1, "the other's stays hidden")
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
		H.assertNoDebugOutput(look.Name .. " range drag")
	end)

	H.section(look.Name .. " keys move the key handle; Return switches it; clamped at the other handle", function()
		current = look
		local lo, hi = q.Source(4), q.Source(6)
		local ends: { string } = {}
		local s = look.Make({
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
		H.assertNoDebugOutput(look.Name .. " range keys")
	end)

	H.section(look.Name .. " errors: Max must be greater than Min, Step positive", function()
		current = look
		local ok1 = pcall(function()
			look.Make({ Min = 1, Max = 1 })
		end)
		local ok2 = pcall(function()
			look.Make({ Step = 0 })
		end)
		assert(not ok1 and not ok2)
	end)

end

H.section("shared behaviour: the same input sequence gives the same values in M3 and M2", function()
	local logs: { string } = {}
	for i, look in looks do
		current = look
		local log: { string } = {}
		local lo, hi = q.Source(30), q.Source(60)
		local s = look.Make({
			Start = lo,
			End = hi,
			Min = 0,
			Max = 100,
			Step = 5,
			OnChange = function(a: number, b: number)
				table.insert(log, a .. ".." .. b)
			end,
		})
		layout(s)
		press(s, 110 + 50) -- 25: Start
		move(110 + 140) -- 70: stops at 60
		release(110 + 140)
		press(s, 110 + 160) -- 80: End
		move(110 + 30)
		release(110 + 30)
		H.fire(s, "SelectionGained")
		key(Enum.KeyCode.Right)
		key(Enum.KeyCode.Return)
		key(Enum.KeyCode.PageUp)
		H.fire(s, "SelectionLost")
		table.insert(log, "=" .. lo:Get() .. ".." .. hi:Get())
		logs[i] = table.concat(log, " ")
		q.dispose(s)
	end
	assert(logs[1] == logs[2], logs[1] .. " vs " .. logs[2])
	H.assertNoDebugOutput("range shared")
end)

H.done()
