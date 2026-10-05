--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Plot = require("../src/Plot")
local Style = require("../src/Style")
local style = Style.default

local function find(root: Instance, name: string): { any }
	return H.findAll(root, function(i: any)
		return i.Name == name
	end)
end
local function sortedBy(list: { any }): { any }
	table.sort(list, function(a: any, b: any)
		return (a.LayoutOrder or 0) < (b.LayoutOrder or 0)
	end)
	return list
end
local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

H.section("PlotHistogram: bars keyed by index, heights follow the series, auto range", function()
	local values = q.Source({ 1, 2, 3, 4 })
	local plot = Plot.PlotHistogram({ Values = values, Height = 60, Text = "fps" })
	local root = plot :: any
	assert(root.Name == "PlotHistogram" and root.Size == UDim2.new(1, 0, 0, 60) and root.ClipsDescendants == true)
	assert(H.find(plot, "Overlay") ~= nil and (H.find(plot, "Overlay") :: any).Text == "fps")
	local bars = sortedBy(find(plot, "Bar"))
	assert(#bars == 4)
	-- auto range 1..4: heights 0, 1/3, 2/3, 1; width 1/4 minus the 1px gap
	assert(near(bars[1].Size.Y.Scale, 0) and near(bars[2].Size.Y.Scale, 1 / 3) and near(bars[4].Size.Y.Scale, 1))
	assert(near(bars[1].Size.X.Scale, 0.25) and bars[1].Size.X.Offset == -1)
	local firstBar = bars[1]
	local count0 = H.countDescendants(plot)

	-- grow: only the new bar is created, old bars survive and re-size for the new count
	values:Set({ 1, 2, 3, 4, 5 })
	bars = sortedBy(find(plot, "Bar"))
	assert(#bars == 5 and bars[1] == firstBar, "bars recycled by index")
	assert(near(bars[1].Size.X.Scale, 0.2) and near(bars[5].Size.Y.Scale, 1) and near(bars[4].Size.Y.Scale, 0.75))
	assert(H.countDescendants(plot) == count0 + 1)

	-- shrink: trailing bars die
	values:Set({ 5, 1 })
	bars = sortedBy(find(plot, "Bar"))
	assert(#bars == 2 and bars[1] == firstBar and near(bars[1].Size.Y.Scale, 1) and near(bars[2].Size.Y.Scale, 0))
	values:Set({})
	assert(#find(plot, "Bar") == 0)
	q.dispose(plot)
	assert(H.isDestroyed(plot))
	H.assertNoDebugOutput("histogram")
end)

H.section("PlotHistogram: fixed Min/Max clamp, flat series", function()
	local values = q.Source({ 5, 50, 500 })
	local plot = Plot.PlotHistogram({ Values = values, Min = 0, Max = 100 })
	local bars = sortedBy(find(plot, "Bar"))
	assert(near(bars[1].Size.Y.Scale, 0.05) and near(bars[2].Size.Y.Scale, 0.5) and near(bars[3].Size.Y.Scale, 1), "clamped above Max")
	q.dispose(plot)
	local flat = Plot.PlotHistogram({ Values = q.Source({ 7, 7, 7 }) })
	for _, bar in find(flat, "Bar") do
		assert(near((bar :: any).Size.Y.Scale, 0), "flat series pads to a unit range, bars at the floor")
	end
	assert((flat :: any).Size == UDim2.new(1, 0, 0, 80), "default height 80")
	q.dispose(flat)
	H.assertNoDebugOutput("histogram range")
end)

H.section("PlotHistogram: capped at MaxPoints, instance count stays bounded", function()
	local big: { number } = {}
	for i = 1, 500 do
		big[i] = i
	end
	local values = q.Source(big)
	local plot = Plot.PlotHistogram({ Values = values })
	assert(#find(plot, "Bar") == Plot.MaxPoints, `drawn {#find(plot, "Bar")}`)
	local count = H.countDescendants(plot)
	-- rolling window: push a value, drop the oldest (the array keeps growing)
	for i = 501, 520 do
		big = table.clone(big)
		big[#big + 1] = i
		values:Set(big)
	end
	assert(#find(plot, "Bar") == Plot.MaxPoints and H.countDescendants(plot) == count, "stable instance count")
	-- the LAST values are the drawn ones: with an auto range of 321..520 the last bar is full height
	local bars = sortedBy(find(plot, "Bar"))
	assert(near(bars[#bars].Size.Y.Scale, 1) and near(bars[1].Size.Y.Scale, 0))
	q.dispose(plot)
	H.assertNoDebugOutput("histogram cap")
end)

H.section("PlotLines: segments between points follow size, range and series", function()
	local values = q.Source({ 0, 10, 0 })
	local plot = Plot.PlotLines({ Values = values, Height = 100 })
	assert((plot :: any).Name == "PlotLines")
	assert(#find(plot, "Segment") == 2, "n points -> n-1 segments")
	-- before layout (size 0): zero-length segments
	local segs = find(plot, "Segment")
	for _, s in segs do
		assert((s :: any).Size == UDim2.fromOffset(0, 1))
	end
	H.setAbs(plot, 0, 0, 200, 100)
	;(plot :: any).AbsoluteSize = Vector2.new(200, 100) -- fire the changed signal like a layout pass
	segs = find(plot, "Segment")
	table.sort(segs, function(a: any, b: any)
		return a.Position.X.Offset < b.Position.X.Offset
	end)
	local s1, s2 = segs[1] :: any, segs[2] :: any
	-- points: (0,100) (100,0) (200,100); first segment centre (50,50), length hypot(100,100), rotation -45
	assert(near(s1.Position.X.Offset, 50) and near(s1.Position.Y.Offset, 50), `{s1.Position}`)
	assert(math.abs(s1.Size.X.Offset - math.sqrt(20000)) <= 1 and near(s1.Rotation, -45), `{s1.Size} {s1.Rotation}`)
	assert(near(s2.Position.X.Offset, 150) and near(s2.Rotation, 45))

	local first = s1
	values:Set({ 0, 10, 0, 10 })
	segs = find(plot, "Segment")
	assert(#segs == 3 and table.find(segs, first) ~= nil, "segments recycled by index")
	values:Set({ 3 })
	assert(#find(plot, "Segment") == 0, "one point draws nothing")
	values:Set({})
	assert(#find(plot, "Segment") == 0)
	q.dispose(plot)
	assert(H.isDestroyed(plot))
	H.assertNoDebugOutput("lines")
end)

H.section("PlotLines: cap, scheme repaint, Overlay", function()
	local big: { number } = {}
	for i = 1, 300 do
		big[i] = i % 7
	end
	local plot = Plot.PlotLines({ Values = q.Source(big), Text = q.Source("x") })
	assert(#find(plot, "Segment") == Plot.MaxPoints - 1)
	style:SetScheme("Light")
	assert((find(plot, "Segment")[1] :: any).BackgroundColor3 == style.Color.PlotLines:Get())
	style:SetScheme("Dark")
	assert((H.find(plot, "Overlay") :: any).Text == "x")
	q.dispose(plot)
	H.assertNoDebugOutput("lines cap")
end)

H.done()
