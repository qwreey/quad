--!strict
local H = require("./support/harness")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
local D = q.Declaration
local Tokens = require("../src/Tokens")
local Switch = require("../src/Switch")
local M2 = require("../src/M2")
local SwitchBehavior = require("../src/Switch/Behavior")
local SLOP = SwitchBehavior.SLOP

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

-- ── M2 look ──────────────────────────────────────────────────────────────

H.section("M2 mount: 56x40 host, 36x14 track, 20 px thumb overhanging it, everything inside the host", function()
	local v = q.Source(false)
	local sw = M2.Switch({ Value = v, IconOn = "rbxassetid://1" })
	assert(sw.ClassName == "TextButton" and sw.Name == "M2Switch" and sw.Size == UDim2.fromOffset(56, 40) and sw.BackgroundTransparency == 1)
	local n = H.countDescendants(sw)
	print("M2.Switch descendants: " .. n .. " (+1 host = " .. (n + 1) .. ")")
	H.resetOutput()
	assert(n == 9, "Track(+corner), Halo, layer(3), Thumb(+corner+shadow) = 9 (icons ignored), got " .. n)
	local track, halo, thumb = H.find(sw, "Track"), H.find(sw, "Halo"), H.find(sw, "Thumb")
	assert(track.Size == UDim2.fromOffset(36, 14) and track.Position == UDim2.fromOffset(28, 20) and track.AnchorPoint == Vector2.new(0.5, 0.5))
	assert(thumb.Size == UDim2.fromOffset(20, 20) and H.find(thumb, "Icon") == nil)
	assert(H.findAll(thumb, function(c: any)
		return c.ClassName == "UIShadow"
	end)[1] ~= nil, "thumb shadow")
	assert(halo.Position == UDim2.fromOffset(20, 20) and halo.Size == UDim2.fromOffset(40, 40))
	-- bounded: halo 0..40 (off) / 16..56 (on) x 0..40 inside the 56 x 40 host; the thumb (20) is taller than the track (14)
	assert(20 - 20 >= 0 and 36 + 20 <= 56, "halo inside the host at both ends")
	assert(thumb.Size.Y.Offset > track.Size.Y.Offset, "thumb overhangs the track")
	H.finishTweens()
	assert(thumb.BackgroundColor3 == L.Surface and track.BackgroundColor3 == L.OnSurface and near(track.BackgroundTransparency, 0.62), "off: light thumb, onSurface 38 % track")
	H.fire(sw, "Activated", H.input({}), 1)
	H.finishTweens()
	assert(v:Get() == true and halo.Position == UDim2.fromOffset(36, 20))
	assert(thumb.BackgroundColor3 == L.Primary and track.BackgroundColor3 == L.Primary and near(track.BackgroundTransparency, 0.5), "on: Primary thumb, Primary 50 % track")
	q.dispose(sw)
	local dis = M2.Switch({ Value = q.Source(false), Disabled = true })
	H.finishTweens()
	assert(dis.Interactable == false and near(H.find(dis, "Track").BackgroundTransparency, 0.88))
	q.dispose(dis)
	H.assertNoDebugOutput("m2 switch mount")
end)

-- ── drag (shared behaviour, both looks) ──────────────────────────────────

type SwitchCase = { Name: string, Make: (props: any) -> any, Off: number, On: number, Y: number }
local cases: { SwitchCase } = {
	{ Name = "M3", Make = Switch, Off = 16, On = 36, Y = 16 },
	{ Name = "M2", Make = M2.Switch, Off = 20, On = 36, Y = 20 },
}
local function pressAt(sw: any, x: number)
	H.fire(sw, "InputBegan", H.input({ Position = Vector3.new(x, 10, 0) }))
end
local function moveTo(x: number)
	UIS.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(x, 10, 0) }))
end
local function releaseAt(sw: any, x: number)
	UIS.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(x, 10, 0) }))
	H.fire(sw, "InputEnded", H.input({}))
end
local function click(sw: any)
	H.fire(sw, "Activated", H.input({}), 1)
end
-- press at `x` and move `dir` * SLOP: the first move that crosses the slop — the drag's ORIGIN (returned) is that pointer
-- position, not the press point (Studio QA 2026-10-08: measured from the press point the handle jumped by the slop)
local function startDrag(sw: any, x: number, dir: number): number
	pressAt(sw, x)
	moveTo(x + dir * SLOP)
	return x + dir * SLOP
end

for _, c in cases do
	local travel = c.On - c.Off
	local tag = c.Name .. " "

	H.section(tag .. "drag past the half lands on the other state; the release click is not a second toggle", function()
		local v = q.Source(false)
		local changes: { boolean } = {}
		local sw = c.Make({ Value = v, OnChange = function(x: boolean)
			table.insert(changes, x)
		end })
		local root = D.Frame { sw }
		local halo = H.find(sw, "Halo")
		pressAt(sw, 100)
		assert(uisConns() == baseConns + 3)
		moveTo(102) -- inside the 4 px slop: still a tap
		assert(halo.Position == UDim2.fromOffset(c.Off, c.Y), "no movement inside the slop")
		moveTo(100 + SLOP + 1) -- the first move past the slop: the origin is HERE
		assert(halo.Position == UDim2.fromOffset(c.Off, c.Y), "crossing the slop: the handle stays where it rests (no jump)")
		local o = 100 + SLOP + 1
		moveTo(o + travel * 0.3)
		assert(halo.Position == UDim2.fromOffset(c.Off + travel * 0.3, c.Y), "then follows the pointer 1:1 at once (no tween)")
		moveTo(o + travel * 0.6)
		assert(halo.Position == UDim2.fromOffset(c.Off + travel * 0.6, c.Y))
		moveTo(o + travel * 3)
		assert(halo.Position == UDim2.fromOffset(c.On, c.Y), "clamped to the on end")
		moveTo(o + travel * 0.6)
		releaseAt(sw, o + travel * 0.6)
		assert(v:Get() == true and #changes == 1 and changes[1] == true, "past the half: on")
		click(sw) -- the engine's click of that same release
		assert(v:Get() == true and #changes == 1, "the release click is ignored")
		assert(halo.Position == UDim2.fromOffset(c.Off + travel * 0.6, c.Y), "animates from where the pointer let go")
		H.finishTweens()
		assert(halo.Position == UDim2.fromOffset(c.On, c.Y))
		assert(uisConns() == baseConns, "drag connections closed")
		-- and back: from on, dragged left past the half
		local o2 = startDrag(sw, 200, -1)
		assert(halo.Position == UDim2.fromOffset(c.On, c.Y), "from on: crossing the slop leaves the handle at the on end")
		moveTo(o2 - travel * 0.7)
		assert(halo.Position == UDim2.fromOffset(c.On - travel * 0.7, c.Y), "displacement from the re-based origin")
		click(sw) -- a click arriving BEFORE the release (engine order not relied on)
		assert(v:Get() == true, "a click while the moved drag runs is ignored")
		releaseAt(sw, o2 - travel * 0.7)
		assert(v:Get() == false and #changes == 2 and changes[2] == false)
		H.finishTweens()
		assert(halo.Position == UDim2.fromOffset(c.Off, c.Y))
		q.dispose(root)
		H.assertNoDebugOutput(tag .. "drag over")
	end)

	H.section(tag .. "drag not past the half springs back; exactly half stays; cancel springs back", function()
		local v = q.Source(false)
		local changes = 0
		local sw = c.Make({ Value = v, OnChange = function()
			changes += 1
		end })
		local halo = H.find(sw, "Halo")
		local o = startDrag(sw, 100, 1)
		moveTo(o + travel * 0.4)
		releaseAt(sw, o + travel * 0.4)
		click(sw)
		assert(v:Get() == false and changes == 0, "0.4: back to off, click ignored")
		H.finishTweens()
		assert(halo.Position == UDim2.fromOffset(c.Off, c.Y))
		o = startDrag(sw, 100, 1)
		moveTo(o + travel * 0.5)
		releaseAt(sw, o + travel * 0.5)
		assert(v:Get() == false and changes == 0, "exactly half: stays")
		v:Set(true)
		H.finishTweens()
		o = startDrag(sw, 100, -1)
		moveTo(o - travel * 0.5)
		releaseAt(sw, o - travel * 0.5)
		assert(v:Get() == true and changes == 0, "exactly half from on: stays")
		o = startDrag(sw, 100, -1)
		moveTo(o - travel * 0.9)
		UIS.WindowFocusReleased:Fire()
		assert(v:Get() == true and changes == 0 and uisConns() == baseConns, "cancelled: no change")
		H.finishTweens()
		assert(halo.Position == UDim2.fromOffset(c.On, c.Y), "sprang back")
		q.dispose(sw)
		H.assertNoDebugOutput(tag .. "drag back")
	end)

	H.section(tag .. "tap still toggles; a later click after a drag toggles; controlled and disabled", function()
		local v = q.Source(false)
		local sw = c.Make({ Value = v })
		pressAt(sw, 50)
		moveTo(53) -- under the slop
		releaseAt(sw, 53)
		click(sw)
		assert(v:Get() == true, "a tap toggles")
		local o = startDrag(sw, 50, -1)
		moveTo(o - travel)
		releaseAt(sw, o - travel)
		assert(v:Get() == false)
		local t0 = os.clock()
		repeat
		until os.clock() - t0 > 0.12
		click(sw) -- a keyboard / gamepad activation well after the drag
		assert(v:Get() == true, "only the drag's own release click is swallowed")
		q.dispose(sw)
		-- controlled: the drag reports, writes nothing
		local checked = q.Source(false)
		local got: { boolean } = {}
		local ctl = c.Make({ Checked = checked, OnChange = function(x: boolean)
			table.insert(got, x)
		end })
		local oc = startDrag(ctl, 0, 1)
		moveTo(oc + travel)
		releaseAt(ctl, oc + travel)
		assert(checked:Get() == false and got[1] == true and #got == 1, "controlled: OnChange(true), nothing written")
		H.finishTweens()
		assert(H.find(ctl, "Halo").Position == UDim2.fromOffset(c.Off, c.Y), "shows Checked until the owner writes it")
		q.dispose(ctl)
		local dis = c.Make({ Value = v, Disabled = true })
		pressAt(dis, 0)
		assert(uisConns() == baseConns, "disabled: no drag session")
		q.dispose(dis)
		H.assertNoDebugOutput(tag .. "tap")
	end)
end

H.done()
