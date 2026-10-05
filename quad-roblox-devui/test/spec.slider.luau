--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Input = require("../src/Inputs")
local Style = require("../src/Style")

local UIS = H.UserInputService
local function conns(): number
	local function n(sig: any): number
		return #sig.connections
	end
	return n(UIS.InputChanged) + n(UIS.InputEnded) + n(UIS.WindowFocusReleased)
end
local function down(x: number): any
	return H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(x, 0, 0) })
end
local function move(x: number): any
	return H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(x, 0, 0) })
end
local function up(x: number): any
	return H.input({
		UserInputType = Enum.UserInputType.MouseButton1,
		UserInputState = Enum.UserInputState.End,
		Position = Vector3.new(x, 0, 0),
	})
end

-- track at x=100, 200px wide; GrabMinSize (Default density) = 10 -> grab centre range 105..295
local function mount(props: any): (any, any, any, any)
	local row = Input.SliderNum(props)
	local track = H.find(row, "Track") :: any
	H.setAbs(track, 100, 0, 200, 20)
	return row, track, H.find(row, "Grab"), H.find(row, "ValueText")
end

H.section("mount: value text, grab position follows the Source, budget", function()
	local v = q.Source(25)
	local row, _track, grab, text = mount({ Text = "Volume", Value = v })
	assert(text.Text == "25.000", text.Text)
	assert(grab.AnchorPoint == Vector2.new(0.25, 0.5) and grab.Position == UDim2.fromScale(0.25, 0.5))
	assert(grab.Size == UDim2.new(0, 10, 1, -4))
	assert((H.find(row, "Label") :: any).Text == "Volume")
	-- row + layout + track(+UICorner/UIStroke/UIFlex) + grab(+UICorner) + text + label
	assert(H.countDescendants(row) <= 11, `instances: {H.countDescendants(row)}`)
	v:Set(100)
	assert(grab.AnchorPoint.X == 1 and text.Text == "100.000", "external :Set moves the grab")
	v:Set(500)
	assert(grab.AnchorPoint.X == 1, "out-of-range value pins the grab")
	q.dispose(row)
	H.assertNoDebugOutput("mount")
end)

H.section("press on the track sets the value; drag follows; release closes tracking", function()
	local base = conns()
	local v = q.Source(0)
	local log: { number } = {}
	local row, track, grab, text = mount({
		Value = v,
		Step = 1,
		OnChange = function(n)
			table.insert(log, n)
		end,
	})
	assert(text.Text == "0", "integral step -> %d")
	H.fire(track, "InputBegan", down(200))
	assert(v:Get() == 50 and text.Text == "50" and log[1] == 50, "click at the middle")
	assert(conns() == base + 3, "global tracking only while pressed")
	UIS.InputChanged:Fire(move(295), false)
	assert(v:Get() == 100 and grab.AnchorPoint.X == 1)
	UIS.InputChanged:Fire(move(9999), false)
	assert(v:Get() == 100, "past the right end stays at Max")
	UIS.InputChanged:Fire(move(-50), false)
	assert(v:Get() == 0, "past the left end stays at Min")
	UIS.InputChanged:Fire(move(150), false)
	assert(v:Get() == 24, `x=150 -> fraction 0.2368 -> 24 (got {v:Get()})`)
	UIS.InputEnded:Fire(up(150), false)
	assert(conns() == base, "closed on release")
	local after = v:Get()
	UIS.InputChanged:Fire(move(290), false)
	assert(v:Get() == after, "moves after release are ignored")
	q.dispose(row)
	H.assertNoDebugOutput("drag")
end)

H.section("Min/Max/Step: negative range, snapping, clamping", function()
	local v = q.Source(0)
	local row, track = mount({ Value = v, Min = -10, Max = 10, Step = 5 })
	H.fire(track, "InputBegan", down(200))
	assert(v:Get() == 0, "middle of -10..10")
	UIS.InputChanged:Fire(move(105), false)
	assert(v:Get() == -10)
	UIS.InputChanged:Fire(move(105 + 190 * 0.3), false) -- fraction 0.3 -> -4 -> snaps to -5
	assert(v:Get() == -5, `snapped: {v:Get()}`)
	UIS.InputEnded:Fire(up(0), false)
	q.dispose(row)
	H.assertNoDebugOutput("range")
end)

H.section("Disabled: press and drag do nothing; re-enable works", function()
	local base = conns()
	local v = q.Source(10)
	local dis = q.Source(true)
	local row, track, _grab, text = mount({ Value = v, Disabled = dis })
	assert(text.TextColor3 == Color3.fromRGB(128, 128, 128))
	H.fire(track, "InputBegan", down(250))
	UIS.InputChanged:Fire(move(280), false)
	UIS.InputEnded:Fire(up(280), false)
	assert(v:Get() == 10 and conns() == base)
	dis:Set(false)
	H.fire(track, "InputBegan", down(105))
	assert(v:Get() == 0)
	UIS.InputEnded:Fire(up(105), false)
	q.dispose(row)
	H.assertNoDebugOutput("disabled")
end)

H.section("grab colour: active while dragging; track hover colour", function()
	local light = Style.new({ Scheme = "Light" })
	local row, track, grab = mount({ Value = q.Source(1), Style = light })
	local rest = grab.BackgroundColor3
	assert(rest == Color3.fromRGB(61, 133, 224))
	local trackRest = track.BackgroundColor3
	H.fire(track, "MouseEnter", 1, 1)
	assert(track.BackgroundColor3 ~= trackRest, "hover repaints the track")
	H.fire(track, "InputBegan", down(150))
	assert(grab.BackgroundColor3 == Color3.fromRGB(117, 138, 204), "SliderGrabActive while dragging")
	UIS.InputEnded:Fire(up(150), false)
	assert(grab.BackgroundColor3 == rest)
	q.dispose(row)
	H.assertNoDebugOutput("colours")
end)

H.section("dispose mid-drag closes the global connections", function()
	local base = conns()
	local v = q.Source(0)
	local row, track = mount({ Value = v })
	H.fire(track, "InputBegan", down(150))
	assert(conns() == base + 3)
	q.dispose(row)
	assert(conns() == base, "no leak")
	assert(H.isDestroyed(row))
	H.assertNoDebugOutput("dispose")
end)

H.done()
