--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local ProgressBar = require("../src/Progress").ProgressBar
local Style = require("../src/Style")
local style = Style.default

local function get(root: Instance, name: string): any
	local found = H.find(root, name)
	assert(found ~= nil, `missing {name}`)
	return found
end

H.section("ProgressBar: fill + percent label follow a State, clamped", function()
	local v = q.Source(0.25)
	local bar = ProgressBar({ Value = v })
	local fill, label = get(bar, "Fill"), get(bar, "Label")
	assert(fill.Size == UDim2.new(0.25, 0, 1, 0) and label.Text == "25%")
	v:Set(0.426)
	assert(fill.Size == UDim2.new(0.426, 0, 1, 0) and label.Text == "43%")
	v:Set(1.7)
	assert(fill.Size == UDim2.new(1, 0, 1, 0) and label.Text == "100%", "clamped high")
	v:Set(-3)
	assert(fill.Size == UDim2.new(0, 0, 1, 0) and label.Text == "0%", "clamped low")
	assert((bar :: any).Size == UDim2.new(1, 0, 0, style.FrameHeight:Get()))
	assert(H.countDescendants(bar) == 3, `instance count {H.countDescendants(bar)}`)
	q.dispose(bar)
	H.assertNoDebugOutput("progress state")
end)

H.section("ProgressBar: static value, custom text (static and State)", function()
	local bar = ProgressBar({ Value = 0.5, Text = "half" })
	assert(get(bar, "Fill").Size == UDim2.new(0.5, 0, 1, 0) and get(bar, "Label").Text == "half")
	q.dispose(bar)
	local txt = q.Source("3/10")
	local bar2 = ProgressBar({ Value = q.Source(0.3), Text = txt })
	assert(get(bar2, "Label").Text == "3/10")
	txt:Set("4/10")
	assert(get(bar2, "Label").Text == "4/10")
	-- scheme switch repaints the fill
	style:SetScheme("Light")
	assert(get(bar2, "Fill").BackgroundColor3 == style.Color.PlotHistogram:Get())
	style:SetScheme("Dark")
	q.dispose(bar2)
	assert(H.isDestroyed(bar2))
	H.assertNoDebugOutput("progress static")
end)

H.done()
