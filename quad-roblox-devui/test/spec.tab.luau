--!strict
local H = require("./support/harness")
local Quad = require("../src/Quad")
local q = H.attach(Quad)
q.debug = true
local TabModule = require("../src/Tab")
local Text = require("../src/Text")
local Layout = require("../src/Layout")
local Style = require("../src/Style")
local Tab, TabBar = TabModule.Tab, TabModule.TabBar
local Kids = Layout.Kids
local style = Style.default

local UIS = H.UserInputService
local function conns(): number
	return #(UIS.InputChanged :: any).connections + #(UIS.InputEnded :: any).connections + #(UIS.WindowFocusReleased :: any).connections
end
local function get(root: Instance, name: string): any
	local found = H.find(root, name)
	assert(found ~= nil, `missing {name}`)
	return found
end

local function build(selected: Quad.Source<string>?): Frame
	return TabBar<<string>>({
		Selected = selected,
		Tabs = {
			Tab<<string>>({ Key = "a", Text = "Alpha", Children = Kids(Text.Text({ Text = "page a" })) }),
			Tab<<string>>({ Key = "b", Text = q.Source("Beta"), Children = Kids(Text.Text({ Text = "page b" })) }),
			Tab<<string>>({ Key = "c", Text = "Gamma" }),
		},
	})
end

H.section("TabBar: first tab selected by default, only its page visible", function()
	local base = conns()
	local bar = build()
	local pa, pb, pc = get(bar, "Page:a"), get(bar, "Page:b"), get(bar, "Page:c")
	assert(pa.Visible == true and pb.Visible == false and pc.Visible == false)
	assert(get(bar, "Tab:b").Text == "Beta" and get(bar, "Tab:a").Text == "Alpha")
	assert(get(bar, "Tab:a").BackgroundColor3 == style.Color.TabActive:Get(), "selected header = TabActive")
	assert(get(bar, "Tab:b").BackgroundColor3 == style.Color.Tab:Get())
	assert(get(pb, "Text").Text == "page b" and get(pb, "Text").Parent == pb, "hidden pages stay mounted")
	local count = H.countDescendants(bar)
	H.fire(get(bar, "Tab:b"), "Activated", H.input({}), 1)
	assert(pa.Visible == false and pb.Visible == true and pc.Visible == false)
	assert(get(bar, "Tab:b").BackgroundColor3 == style.Color.TabActive:Get() and get(bar, "Tab:a").BackgroundColor3 == style.Color.Tab:Get())
	H.fire(get(bar, "Tab:c"), "Activated", H.input({}), 1)
	assert(pc.Visible == true and pb.Visible == false)
	assert(H.countDescendants(bar) == count, "switching creates nothing")
	q.dispose(bar)
	assert(H.isDestroyed(bar) and conns() == base)
	H.assertNoDebugOutput("tabbar default")
end)

H.section("TabBar NoPages: bar and underline only; a Tab with Children is an error; corners from TabRounding", function()
	local sel = q.Source("x")
	local seenA: any, seenB: any = nil, nil
	local hookA = q.PostRef(nil :: TextButton?):Callback(function(inst: TextButton?)
		seenA = inst
	end)
	local hookB = q.PostRef(nil :: TextButton?):Callback(function(inst: TextButton?)
		seenB = inst
	end)
	local bar = TabBar<<string>>({
		Selected = sel,
		NoPages = true,
		Tabs = {
			Tab<<string>>({ Key = "x", Text = "X" }),
			-- Hooks go on the header button, all of them
			Tab<<string>>({ Key = "y", Text = "Y", Hooks = { hookA, hookB } }),
		},
	})
	assert(seenA == get(bar, "Tab:y") and seenB == get(bar, "Tab:y"), "tab Hooks")
	assert(H.find(bar, "Pages") == nil and H.find(bar, "Bar") ~= nil and H.find(bar, "Underline") ~= nil)
	H.fire(get(bar, "Tab:y"), "Activated", H.input({}), 1)
	assert(sel:Get() == "y", "the strip still selects")
	local corner = H.findAll(get(bar, "Tab:x"), function(i: any)
		return i.ClassName == "UICorner"
	end)[1] :: any
	assert(corner ~= nil and corner.CornerRadius == UDim.new(0, style.Metrics.TabRounding:Get()))
	q.dispose(bar)
	local ok, err = pcall(function()
		TabBar<<string>>({ NoPages = true, Tabs = { Tab<<string>>({ Key = "x", Text = "X", Children = Kids(Text.Text({ Text = "p" })) }) } })
	end)
	assert(not ok and string.find(tostring(err), "NoPages", 1, true) ~= nil, tostring(err))
	H.assertNoDebugOutput("NoPages")
end)

H.section("TabBar: Selected Source round trip", function()
	local sel = q.Source("c")
	local bar = build(sel)
	assert(get(bar, "Page:c").Visible == true and get(bar, "Page:a").Visible == false, "starts from the Source")
	sel:Set("a")
	assert(get(bar, "Page:a").Visible == true and get(bar, "Page:c").Visible == false)
	H.fire(get(bar, "Tab:b"), "Activated", H.input({}), 1)
	assert(sel:Get() == "b" and get(bar, "Page:b").Visible == true)
	sel:Set("nope")
	assert(get(bar, "Page:a").Visible == false and get(bar, "Page:b").Visible == false and get(bar, "Page:c").Visible == false, "unknown key: no page")
	-- hover on an unselected header
	H.fire(get(bar, "Tab:a"), "MouseEnter", 1, 1)
	assert(get(bar, "Tab:a").BackgroundColor3 == style.Color.TabHovered:Get())
	q.dispose(bar)
	H.assertNoDebugOutput("tabbar source")
end)

H.section("TabBar: numeric keys, empty tab list is rejected", function()
	local bar = TabBar<<number>>({ Tabs = { Tab<<number>>({ Key = 1, Text = "one" }), Tab<<number>>({ Key = 2, Text = "two" }) } })
	assert(get(bar, "Page:1").Visible == true)
	H.fire(get(bar, "Tab:2"), "Activated", H.input({}), 1)
	assert(get(bar, "Page:2").Visible == true and get(bar, "Page:1").Visible == false)
	q.dispose(bar)
	assert(not pcall(function()
		TabBar<<string>>({ Tabs = {} })
	end))
	H.assertNoDebugOutput("tabbar numeric")
end)

H.section("TabBar: OnChange reports a user switch to a different tab only", function()
	local sel = q.Source("a")
	local log: { string } = {}
	local bar = TabBar<<string>>({
		Selected = sel,
		OnChange = function(k: string)
			table.insert(log, k)
		end,
		Tabs = { Tab<<string>>({ Key = "a", Text = "A" }), Tab<<string>>({ Key = "b", Text = "B" }) },
	})
	H.fire(get(bar, "Tab:a"), "Activated", H.input({}), 1) -- already selected
	H.fire(get(bar, "Tab:b"), "Activated", H.input({}), 1)
	sel:Set("a") -- outside
	assert(#log == 1 and log[1] == "b" and sel:Get() == "a")
	q.dispose(bar)
	H.assertNoDebugOutput("tab onchange")
end)


H.done()
