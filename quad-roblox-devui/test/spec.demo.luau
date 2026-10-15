--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local D = q.Declaration
local Demo = require("../gallery")
local Style = require("../src/Style")
local Plot = require("../src/Plot")

local UIS = H.UserInputService
local Heartbeat = H.RunService.Heartbeat :: any
local function beats(): number
	return #Heartbeat.connections
end
local function uis(): number
	return #(UIS.InputChanged :: any).connections + #(UIS.InputEnded :: any).connections + #(UIS.InputBegan :: any).connections
end
local function byName(root: Instance, name: string): { any }
	return H.findAll(root, function(i: any)
		return i.Name == name
	end)
end
local function boxes(root: Instance): { any }
	return H.findAll(root, function(i: any)
		return i.ClassName == "TextBox"
	end)
end
local function byText(root: Instance, text: string): any
	local hits = H.findAll(root, function(i: any)
		return i.Text == text
	end)
	assert(#hits >= 1, `no instance with Text "{text}"`)
	return hits[1]
end
local function click(inst: any)
	H.fire(inst, "Activated", H.input({}), 1)
end
local function visibleWindows(gui: Instance): { string }
	local out: { string } = {}
	for _, w in byName(gui, "Window") do
		if (w :: any).Visible then
			table.insert(out, (H.find(w, "Title") :: any).Text)
		end
	end
	return out
end
local function windowOf(gui: Instance, title: string): any
	for _, w in byName(gui, "Window") do
		if (H.find(w, "Title") :: any).Text == title then
			return w
		end
	end
	error(`no window "{title}"`)
end

local baseBeats, baseUis = beats(), uis()
local parent = Instance.new("Folder")
local gui = Demo.mount(parent) :: any
-- the window manager's ONE press listener (press-to-front) is open while it has windows; everything else is opened
-- only during a drag / while a popup is open
local idleUis = baseUis + 1
local layer = H.find(gui, "OverlayLayer") :: any
local total = H.countDescendants(gui)
print(`[demo] mounted: {total} instances, {#byName(gui, "Window")} windows`)

H.section("mount: ScreenGui settings, three windows (tools closed), only the open window's ticker connected", function()
	assert(gui.Parent == parent and gui.ResetOnSpawn == false and gui.ZIndexBehavior == Enum.ZIndexBehavior.Sibling)
	assert(layer ~= nil and layer.Parent == gui, "popup layer in the ScreenGui")
	local vis = visibleWindows(gui)
	assert(#byName(gui, "Window") == 3 and #vis == 1 and vis[1] == "quad devui — Demo", table.concat(vis, ","))
	assert(beats() == baseBeats + 1, `heartbeat connections (the plot ticker only; tools are closed): {beats() - baseBeats}`)
	assert(uis() == idleUis, "no input connection until a drag/popup (but the manager's press listener)")
	H.assertNoDebugOutput("mount")
end)

H.section("counter button feeds a label; reset; checkbox drives a label", function()
	local up = byText(gui, "Count up")
	assert(up.ClassName == "TextButton")
	click(up)
	click(up)
	assert(byText(gui, "Clicked 2 times") ~= nil)
	click(byText(gui, "reset"))
	assert(byText(gui, "Clicked 0 times") ~= nil)
	assert(byText(gui, "the checkbox is ON") ~= nil)
	click(byText(gui, "Enable the thing"))
	assert(byText(gui, "the checkbox is off") ~= nil)
	click(byText(gui, "mint"))
	assert(byText(gui, "flavor = mint") ~= nil)
	click(byText(gui, "beta"))
	assert(byText(gui, "selected row = beta") ~= nil)
	H.assertNoDebugOutput("basic")
end)

H.section("inputs: text box <-> shared Source, slider -> progress", function()
	local all = boxes(gui)
	local nameBox: any = nil
	for _, b in all do
		if (b :: any).Text == "quad" then
			nameBox = b
			break
		end
	end
	assert(nameBox ~= nil)
	nameBox.Text = "hello"
	assert(byText(gui, 'name = "hello", volume = 40, tint = #4296fa, count = 3') ~= nil, "readout follows the box")
	local track = byName(gui, "Track")[1]
	H.setAbs(track, 100, 0, 200, 20)
	H.fire(track, "InputBegan", H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(200, 0, 0) }))
	UIS.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1, UserInputState = Enum.UserInputState.End }), false)
	local fill = byName(gui, "Fill")[1]
	assert(math.abs(fill.Size.X.Scale - 0.5) < 0.02, `progress fill {fill.Size.X.Scale}`)
	assert(uis() == idleUis, "slider drag closed its connections")
	H.assertNoDebugOutput("inputs")
end)

H.section("table: add / remove rows, damage updates cell texts in place", function()
	local tbl = byName(gui, "Table")[1]
	local rows = function()
		return byName(H.find(tbl, "Rows") :: any, "Row")
	end
	assert(#rows() == 3 and byText(gui, "3 rows") ~= nil)
	local firstRow = rows()[1]
	click(byText(gui, "Add row"))
	assert(#rows() == 4 and byText(gui, "4 rows") ~= nil and rows()[1] == firstRow, "survivors keep their instance")
	click(byText(gui, "Damage all"))
	assert(byText(tbl, "90") ~= nil and byText(tbl, "60") ~= nil and byText(tbl, "30") ~= nil, "Hp cells updated")
	click(byText(gui, "Remove last"))
	assert(#rows() == 3)
	-- per-row delete button
	click(byText(tbl, "x"))
	assert(#rows() == 2 and byText(gui, "2 rows") ~= nil)
	H.assertNoDebugOutput("table")
end)

H.section("tree + tabs", function()
	local toggle = byText(gui, "Toggle Node A from outside")
	click(toggle)
	assert(byText(gui, "Node A is open (a Source you can set from outside)") ~= nil)
	click(toggle)
	assert(byText(gui, "Node A is closed") ~= nil)
	click(byText(gui, "Name")) -- tab header (also the label of nothing else with this exact Text)
	H.assertNoDebugOutput("trees")
end)

H.section("menu toggles: scheme / density / tool windows", function()
	local function openMenu(title: string)
		local bars = byName(gui, "Menu")
		for _, m in bars do
			if (m :: any).Text == title then
				click(m)
				return
			end
		end
		error("no menu " .. title)
	end
	local function items(): { any }
		local out = byName(layer, "MenuItem")
		for _, t in byName(layer, "MenuToggle") do
			table.insert(out, t)
		end
		return out
	end
	local function itemText(i: any): string
		return if i.Text ~= "" then i.Text else (H.find(i, "Label") :: any).Text
	end
	local function pick(label: string)
		for _, i in items() do
			if itemText(i) == label then
				click(i)
				return
			end
		end
		error("no item " .. label)
	end
	local dark = Style.default.Color.WindowBg:Get()
	openMenu("Style")
	pick("Light scheme")
	assert(Style.default.Scheme:Get() == "Light" and Style.default.Color.WindowBg:Get() ~= dark, "scheme switched")
	openMenu("Style")
	pick("Light scheme")
	assert(Style.default.Scheme:Get() == "Dark" and Style.default.Color.WindowBg:Get() == dark)
	openMenu("Style")
	pick("Clear density")
	assert(Style.default.Density:Get() == "Clear")
	openMenu("Style")
	pick("Clear density")
	assert(Style.default.Density:Get() == "Default")
	openMenu("Windows")
	pick("Style Editor")
	openMenu("Windows")
	pick("Runtime Info")
	local vis = visibleWindows(gui)
	assert(#vis == 3, table.concat(vis, ","))
	assert(beats() == baseBeats + 3, `opening the Runtime Info window connects its two tickers: {beats() - baseBeats}`)
	assert(#layer:GetChildren() == 0, "popups closed")
	-- the editor's radios drive the shared style the other way round
	local editor = windowOf(gui, "Style Editor")
	click(byText(editor, "Light"))
	assert(Style.default.Scheme:Get() == "Light")
	click(byText(editor, "Dark"))
	assert(Style.default.Scheme:Get() == "Dark")
	H.assertNoDebugOutput("menus")
end)

H.section("style editor: preview is rebuilt per change, shared style untouched", function()
	local editor = windowOf(gui, "Style Editor")
	local host = H.find(editor, "PreviewHost") :: any
	local rounding0 = Style.default.Metrics.FrameRounding:Get()
	local before = H.find(host, "Preview") :: any
	assert(before ~= nil and before.Name == "Preview")
	local drag = boxes(editor)
	-- the FrameRounding DragNum field: type a value
	local field: any = nil
	for _, b in drag do
		if (b :: any).Text == "3" then
			field = b
			break
		end
	end
	assert(field ~= nil, "FrameRounding field")
	H.fire(field, "InputBegan", H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(100, 0, 0) }))
	UIS.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(105, 0, 0) }), false)
	UIS.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1, UserInputState = Enum.UserInputState.End, Position = Vector3.new(105, 0, 0) }), false)
	assert(H.find(host, "Preview") == before, "debounced: the old preview stays while the value is still moving")
	H.advance(0.2)
	local after = H.find(host, "Preview") :: any
	assert(after ~= nil and after ~= before and H.isDestroyed(before), "old preview destroyed, new one mounted")
	assert(Style.default.Metrics.FrameRounding:Get() == rounding0, "shared style untouched")
	H.assertNoDebugOutput("style editor")
end)

H.section("plot ticks at 10 Hz from Heartbeat, window is bounded; pause stops it", function()
	local hist = byName(gui, "PlotHistogram")[1]
	local function bars(): number
		return #byName(hist, "Bar")
	end
	local n0 = bars()
	for _ = 1, 3 do
		H.advance(0.1)
	end
	assert(bars() == n0 + 3, `bars {n0} -> {bars()}`)
	for _ = 1, 80 do
		H.advance(0.1)
	end
	assert(bars() == 60, `rolling window caps at 60 (got {bars()}, widget cap {Plot.MaxPoints})`)
	local count = H.countDescendants(gui)
	H.advance(0.1)
	assert(H.countDescendants(gui) == count, "steady state: no instance growth")
	click(byText(gui, "pause sampling"))
	H.advance(0.5)
	assert(bars() == 60)
	-- frame-rate / instance counters in the runtime window
	local info = windowOf(gui, "Runtime Info")
	H.advance(1)
	assert(byText(info, "1") ~= nil, "fps readout updated (one 1 s frame = 1 fps)")
	local big = H.findAll(info, function(i: any)
		return i.ClassName == "TextLabel" and tonumber(i.Text) ~= nil and (tonumber(i.Text) :: number) > 100
	end)
	assert(#big == 1, "instance counter label")
	local counted = tonumber((big[1] :: any).Text)
	assert(counted ~= nil and math.abs(counted - H.countDescendants(gui)) <= 2, `instance counter {counted} vs {H.countDescendants(gui)}`)
	assert(byText(info, q.Version) ~= nil, "quad version shown")
	H.assertNoDebugOutput("plots")
end)

H.section("dispose: instances destroyed, Heartbeat and input connections back to baseline", function()
	Style.default:SetScheme("Dark")
	q.dispose(gui)
	assert(H.isDestroyed(gui))
	assert(beats() == baseBeats, `heartbeat connections left: {beats() - baseBeats}`)
	assert(uis() == baseUis)
	H.advance(0.5) -- tickers are gone: must not throw
	H.assertNoDebugOutput("dispose")
end)

H.section("DemoWindow alone: default overlay, own Sources, dispose", function()
	local win = Demo.DemoWindow()
	assert((win :: any).Name == "Window")
	local screen = D.ScreenGui({ win })
	local n = H.countDescendants(screen)
	print(`[demo] DemoWindow alone: {n} instances`)
	H.resetOutput()
	assert(beats() == baseBeats + 1, "one plot ticker")
	q.dispose(screen)
	assert(beats() == baseBeats)
	H.assertNoDebugOutput("demo window")
end)

H.section("a hidden demo window has no Heartbeat connection; showing it connects again", function()
	local open = q.Source(false)
	local win = Demo.DemoWindow({ Open = open })
	local screen = D.ScreenGui({ win })
	assert(beats() == baseBeats, "closed window: its ticker is idle")
	open:Set(true)
	assert(beats() == baseBeats + 1)
	open:Set(false)
	assert(beats() == baseBeats)
	q.dispose(screen)
	assert(beats() == baseBeats)
	H.assertNoDebugOutput("hidden window")
end)

H.section("style editor: dragging a field many times rebuilds the preview once (instance churn bounded)", function()
	local Context = Demo.Context
	local ctx = Context.new(Style.new(), nil)
	local editor = Demo.StyleEditorWindow({ Context = ctx })
	local screen = D.ScreenGui({ editor })
	local host = H.find(editor, "PreviewHost") :: any
	local first = H.find(host, "Preview") :: any
	assert(first ~= nil)
	local field: any = nil
	for _, b in boxes(editor) do
		if (b :: any).Text == "3" then
			field = b
			break
		end
	end
	assert(field ~= nil)
	H.fire(field, "InputBegan", H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(100, 0, 0) }))
	local seen: { [any]: boolean } = {}
	for step = 1, 12 do
		UIS.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(100 + step, 0, 0) }), false)
		local cur = H.find(host, "Preview")
		seen[cur] = true
		H.advance(0.005) -- 0.06 s in all: inside one 0.15 s debounce window (the field clamps at 12)
	end
	UIS.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1, UserInputState = Enum.UserInputState.End, Position = Vector3.new(112, 0, 0) }), false)
	assert(H.find(host, "Preview") == first and not H.isDestroyed(first), "no rebuild while the value is still moving (about 9 distinct values were dragged through)")
	H.advance(0.3)
	local after = H.find(host, "Preview") :: any
	assert(after ~= nil and after ~= first and H.isDestroyed(first), "one rebuild once it settled")
	local n = 0
	for _ in seen do
		n += 1
	end
	assert(n == 1, `the same preview instance stood through the whole drag ({n})`)
	q.dispose(screen)
	H.assertNoDebugOutput("style editor churn")
end)

H.done()
