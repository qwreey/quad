--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Input = require("../src/Input")

local UIS = H.UserInputService
local function conns(): number
	local function n(sig: any): number
		return #sig.connections
	end
	return n(UIS.InputChanged) + n(UIS.InputEnded) + n(UIS.WindowFocusReleased)
end
local function lost(box: any, enter: boolean)
	H.fire(box, "FocusLost", enter, H.input({}))
end
local function typeInto(box: any, text: string)
	box.Text = text
	lost(box, true)
end
-- a Drag field: click (press + release in place) opens its editor, then type and commit
local function clickType(box: any, text: string)
	box.CaptureFocus = function() end
	H.fire(box, "InputBegan", H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(0, 0, 0) }))
	UIS.InputEnded:Fire(
		H.input({
			UserInputType = Enum.UserInputType.MouseButton1,
			UserInputState = Enum.UserInputState.End,
			Position = Vector3.new(0, 0, 0),
		}),
		false
	)
	assert(box.TextEditable == true, "click opened the editor")
	box.Text = text
	lost(box, true)
end
local function f(row: any, name: string): any
	return H.find(row, name)
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

H.section("InputVector2: mount, per-component commit, round trip", function()
	local v = q.Source(Vector2.new(1, 2))
	local log: { Vector2 } = {}
	local row = Input.InputVector2({
		Text = "Offset",
		Value = v,
		OnChange = function(n)
			table.insert(log, n)
		end,
	})
	local x, y = f(row, "X"), f(row, "Y")
	assert(x.Text == "1.000" and y.Text == "2.000")
	assert((f(row, "Label") :: any).Text == "Offset")
	typeInto(x, "5")
	assert(v:Get() == Vector2.new(5, 2) and log[1] == Vector2.new(5, 2))
	-- an external write between two commits is not overwritten by a stale copy
	v:Set(Vector2.new(5, 9))
	assert(x.Text == "5.000" and y.Text == "9.000", "external :Set updates both fields")
	typeInto(x, "6")
	assert(v:Get() == Vector2.new(6, 9), "Y kept its newer value")
	typeInto(y, "-3.5")
	assert(v:Get() == Vector2.new(6, -3.5) and #log == 3)
	-- invalid text reverts, no write
	typeInto(y, "oops")
	assert(v:Get() == Vector2.new(6, -3.5) and y.Text == "-3.500" and #log == 3)
	-- the same value typed again: no OnChange
	typeInto(x, "6")
	assert(#log == 3)
	q.dispose(row)
	H.assertNoDebugOutput("vector2")
end)

H.section("InputVector2: Min/Max/Step apply to both components; Drag mode", function()
	local v = q.Source(Vector2.new(0, 0))
	local row = Input.InputVector2({ Value = v, Min = 0, Max = 10, Step = 1 })
	local x, y = f(row, "X"), f(row, "Y")
	assert(x.Text == "0", "integral step -> %d")
	typeInto(x, "99")
	typeInto(y, "-4")
	assert(v:Get() == Vector2.new(10, 0))
	typeInto(y, "3.4")
	assert(v:Get() == Vector2.new(10, 3))
	q.dispose(row)

	local base = conns()
	local d = q.Source(Vector2.new(0, 0))
	local drow = Input.InputVector2({ Value = d, Drag = true, Speed = 0.5 })
	local dx = f(drow, "X")
	assert(dx.Name == "X" and dx.TextEditable == false, "drag field")
	H.fire(dx, "InputBegan", down(0))
	UIS.InputChanged:Fire(move(20), false)
	assert(d:Get() == Vector2.new(10, 0), "20px * 0.5")
	UIS.InputEnded:Fire(up(20), false)
	assert(conns() == base)
	q.dispose(drow)
	H.assertNoDebugOutput("vector2 range")
end)

H.section("InputUDim2: four fields, scale %.3f / offset %d, whole value written back", function()
	local v = q.Source(UDim2.new(0.5, 10, 0.25, 20))
	local log = 0
	local row = Input.InputUDim2({
		Value = v,
		OnChange = function()
			log += 1
		end,
	})
	local sx, ox, sy, oy = f(row, "ScaleX"), f(row, "OffsetX"), f(row, "ScaleY"), f(row, "OffsetY")
	assert(sx.Text == "0.500" and ox.Text == "10" and sy.Text == "0.250" and oy.Text == "20")
	typeInto(sx, "1")
	assert(v:Get() == UDim2.new(1, 10, 0.25, 20))
	typeInto(ox, "12.7")
	assert(v:Get() == UDim2.new(1, 13, 0.25, 20), "offset is integral")
	typeInto(sy, "0.75")
	typeInto(oy, "-8")
	assert(v:Get() == UDim2.new(1, 13, 0.75, -8) and log == 4)
	v:Set(UDim2.new(0, 0, 0, 0))
	assert(sx.Text == "0.000" and oy.Text == "0")
	-- 4 fields + row + layout (+ per-field UICorner/UIPadding/UIStroke/UIFlex)
	assert(H.countDescendants(row) <= 22, `instances: {H.countDescendants(row)}`)
	q.dispose(row)
	H.assertNoDebugOutput("udim2")
end)

H.section("InputUDim2 Drag mode: scale speed 0.01, offset speed 1", function()
	local v = q.Source(UDim2.new(0, 0, 0, 0))
	local row = Input.InputUDim2({ Value = v, Drag = true })
	H.fire(f(row, "ScaleX"), "InputBegan", down(0))
	UIS.InputChanged:Fire(move(50), false)
	UIS.InputEnded:Fire(up(50), false)
	assert(v:Get().X.Scale == 0.5)
	H.fire(f(row, "OffsetY"), "InputBegan", down(0))
	UIS.InputChanged:Fire(move(7), false)
	UIS.InputEnded:Fire(up(7), false)
	assert(v:Get().Y.Offset == 7 and v:Get().X.Scale == 0.5)
	q.dispose(row)
	H.assertNoDebugOutput("udim2 drag")
end)

H.section("InputColor3: swatch, R/G/B fields, hex, round trip", function()
	local v = q.Source(Color3.fromRGB(255, 128, 0))
	local log: { Color3 } = {}
	local row = Input.InputColor3({
		Text = "Tint",
		Value = v,
		OnChange = function(c)
			table.insert(log, c)
		end,
	})
	local swatch, r, g, b, hex = f(row, "Swatch"), f(row, "R"), f(row, "G"), f(row, "B"), f(row, "Hex")
	assert(swatch.BackgroundColor3 == v:Get())
	assert(r.Text == "255" and g.Text == "128" and b.Text == "0" and hex.Text == "#ff8000", hex.Text)
	assert((f(row, "Label") :: any).Text == "Tint")
	-- typed channel
	clickType(g, "64")
	assert(v:Get() == Color3.fromRGB(255, 64, 0), `value {tostring(v:Get())}`)
	assert(hex.Text == "#ff4000", hex.Text)
	assert(swatch.BackgroundColor3 == v:Get())
	clickType(b, "999")
	assert(v:Get() == Color3.fromRGB(255, 64, 255), "clamped to 255")
	-- hex
	typeInto(hex, "#0a141e")
	assert(v:Get() == Color3.fromRGB(10, 20, 30) and r.Text == "10" and g.Text == "20" and b.Text == "30")
	typeInto(hex, "f80")
	assert(v:Get() == Color3.fromRGB(255, 136, 0), "3-digit hex")
	local n = #log
	typeInto(hex, "not a colour")
	assert(v:Get() == Color3.fromRGB(255, 136, 0) and hex.Text == "#ff8800" and #log == n, "invalid hex reverts")
	-- external write
	v:Set(Color3.fromRGB(1, 2, 3))
	assert(r.Text == "1" and hex.Text == "#010203" and swatch.BackgroundColor3 == v:Get())
	-- budget: row + layout + swatch(+UICorner/UIStroke) + 3 fields + hex + label
	assert(H.countDescendants(row) <= 28, `instances: {H.countDescendants(row)}`)
	q.dispose(row)
	H.assertNoDebugOutput("color")
end)

H.section("InputColor3: dragging a channel, Disabled, dispose baseline", function()
	local base = conns()
	local v = q.Source(Color3.fromRGB(10, 10, 10))
	local dis = q.Source(true)
	local row = Input.InputColor3({ Value = v, Disabled = dis })
	local r, hex = f(row, "R"), f(row, "Hex")
	assert(hex.TextEditable == false and r.TextEditable == false)
	H.fire(r, "InputBegan", down(0))
	UIS.InputChanged:Fire(move(30), false)
	UIS.InputEnded:Fire(up(30), false)
	assert(v:Get() == Color3.fromRGB(10, 10, 10), "disabled: no drag")
	dis:Set(false)
	H.fire(r, "InputBegan", down(0))
	UIS.InputChanged:Fire(move(30), false)
	assert(v:Get() == Color3.fromRGB(40, 10, 10))
	UIS.InputChanged:Fire(move(1000), false)
	assert(v:Get() == Color3.fromRGB(255, 10, 10), "clamped at 255")
	q.dispose(row) -- mid-drag
	assert(conns() == base and H.isDestroyed(row))
	H.assertNoDebugOutput("color drag")
end)

H.done()
