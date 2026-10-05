--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Checkbox = require("../src/Checkbox")
local Style = require("../src/Style")

local function conns(): number
	local UIS = H.UserInputService
	local function n(sig: any): number
		return #sig.connections
	end
	return n(UIS.InputChanged) + n(UIS.InputEnded) + n(UIS.WindowFocusReleased)
end

local function box(cb: any): any
	return H.find(cb, "Box")
end
local function check(cb: any): any
	return H.find(cb, "Check")
end

H.section("mount: one button, box and check; label text; instance budget", function()
	local cb = Checkbox({ Text = "Enable" })
	assert(cb.Text == "Enable" and cb.Name == "Checkbox")
	assert(cb.TextXAlignment == Enum.TextXAlignment.Left and cb.AutomaticSize == Enum.AutomaticSize.XY)
	assert(box(cb) ~= nil and check(cb) ~= nil)
	assert(check(cb).Visible == false, "unchecked: mark hidden")
	assert(check(cb).Image == Style.default.Icons.CheckMark)
	-- TextButton + Box + Check + UIPadding + UICorner + UIStroke (no decorative frames)
	assert(H.countDescendants(cb) <= 6, `instances: {H.countDescendants(cb)}`)
	q.dispose(cb)
	H.assertNoDebugOutput("mount")
end)

H.section("click toggles the Source, OnChange reports user changes only", function()
	local v = q.Source(false)
	local seen: { boolean } = {}
	local cb = Checkbox({
		Text = "x",
		Value = v,
		OnChange = function(c)
			table.insert(seen, c)
		end,
	})
	H.fire(cb, "Activated", H.input({}), 1)
	assert(v:Get() == true and check(cb).Visible == true and seen[1] == true)
	H.fire(cb, "Activated", H.input({}), 1)
	assert(v:Get() == false and check(cb).Visible == false and seen[2] == false and #seen == 2)
	-- external write updates the UI without OnChange
	v:Set(true)
	assert(check(cb).Visible == true and #seen == 2)
	q.dispose(cb)
	H.assertNoDebugOutput("toggle")
end)

H.section("uncontrolled: internal Source works", function()
	local cb = Checkbox({ Text = "x" })
	H.fire(cb, "Activated", H.input({}), 1)
	assert(check(cb).Visible == true)
	q.dispose(cb)
end)

H.section("Disabled (boolean and State): no toggle, dim text; re-enabling works", function()
	local v = q.Source(false)
	local cb = Checkbox({ Text = "x", Value = v, Disabled = true })
	assert(cb.TextColor3 == Color3.fromRGB(128, 128, 128), "dim token")
	H.fire(cb, "Activated", H.input({}), 1)
	assert(v:Get() == false)
	q.dispose(cb)

	local dis = q.Source(true)
	local cb2 = Checkbox({ Text = "x", Value = v, Disabled = dis })
	H.fire(cb2, "Activated", H.input({}), 1)
	assert(v:Get() == false)
	dis:Set(false)
	assert(cb2.TextColor3 == Color3.fromRGB(255, 255, 255))
	H.fire(cb2, "Activated", H.input({}), 1)
	assert(v:Get() == true)
	q.dispose(cb2)
	H.assertNoDebugOutput("disabled")
end)

H.section("hover colours on the box; theme switch repaints", function()
	local s = Style.new()
	local cb = Checkbox({ Text = "x", Style = s })
	local b = box(cb)
	local rest = b.BackgroundColor3
	H.fire(cb, "MouseEnter", 1, 1)
	assert(b.BackgroundColor3 ~= rest, "hover repaints the box")
	H.fire(cb, "MouseLeave")
	assert(b.BackgroundColor3 == rest)
	s:SetScheme("Light")
	assert(b.BackgroundColor3 == Color3.fromRGB(255, 255, 255))
	q.dispose(cb)
	H.assertNoDebugOutput("hover")
end)

H.section("State label follows; dispose destroys everything and leaks no connection", function()
	local base = conns()
	local label = q.Source("a")
	local cb = Checkbox({ Text = label })
	label:Set("b")
	assert(cb.Text == "b")
	local b, c = box(cb), check(cb)
	q.dispose(cb)
	assert(H.isDestroyed(cb) and H.isDestroyed(b) and H.isDestroyed(c))
	assert(conns() == base)
	H.assertNoDebugOutput("dispose")
end)

H.done()
