--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local RadioButton = require("../src/RadioButton")

local function dot(r: any): any
	return H.find(r, "Dot")
end

H.section("group: selected follows the shared Source", function()
	local pick = q.Source("a")
	local a = RadioButton<<string>>({ Text = "A", Value = pick, Option = "a" })
	local b = RadioButton<<string>>({ Text = "B", Value = pick, Option = "b" })
	assert(a.Text == "A" and a.Name == "RadioButton")
	assert(dot(a).Visible == true and dot(b).Visible == false)
	pick:Set("b")
	assert(dot(a).Visible == false and dot(b).Visible == true, "external write moves the dot")
	-- TextButton + Box + Dot + UIPadding + UIStroke + UICorner(shorthand) + dot UICorner
	assert(H.countDescendants(a) <= 7, `instances: {H.countDescendants(a)}`)
	q.dispose(a)
	q.dispose(b)
	H.assertNoDebugOutput("group")
end)

H.section("click selects; clicking the selected one is a no-op; OnChange once per change", function()
	local pick = q.Source(1)
	local log: { number } = {}
	local function mk(n: number): any
		return RadioButton<<number>>({
			Text = `#{n}`,
			Value = pick,
			Option = n,
			OnChange = function(o)
				table.insert(log, o)
			end,
		})
	end
	local r1, r2, r3 = mk(1), mk(2), mk(3)
	H.fire(r2, "Activated", H.input({}), 1)
	assert(pick:Get() == 2 and dot(r2).Visible == true and dot(r1).Visible == false)
	H.fire(r2, "Activated", H.input({}), 1)
	assert(#log == 1 and log[1] == 2, "re-click does nothing")
	H.fire(r3, "Activated", H.input({}), 1)
	assert(pick:Get() == 3 and #log == 2)
	for _, r in { r1, r2, r3 } do
		q.dispose(r)
	end
	H.assertNoDebugOutput("click")
end)

H.section("Disabled blocks selection; works for table options by identity", function()
	local optA, optB = { id = "A" }, { id = "B" }
	local pick = q.Source(optA)
	local dis = q.Source(true)
	local rb = RadioButton<<{ id: string }>>({ Text = "B", Value = pick, Option = optB, Disabled = dis })
	H.fire(rb, "Activated", H.input({}), 1)
	assert(pick:Get() == optA)
	dis:Set(false)
	H.fire(rb, "Activated", H.input({}), 1)
	assert(pick:Get() == optB and dot(rb).Visible == true)
	q.dispose(rb)
	H.assertNoDebugOutput("disabled")
end)

H.section("dispose destroys everything", function()
	local pick = q.Source("a")
	local rb = RadioButton<<string>>({ Text = "A", Value = pick, Option = "a" })
	local d = dot(rb)
	q.dispose(rb)
	assert(H.isDestroyed(rb) and H.isDestroyed(d))
	-- the Source outlives the widget and can still be written
	pick:Set("z")
	H.assertNoDebugOutput("dispose")
end)

H.done()
