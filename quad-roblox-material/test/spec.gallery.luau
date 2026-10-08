--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local D = q.Declaration
local Gallery = require("../gallery")
local Theme = require("../src/Theme")
local Tokens = require("../src/Tokens")

local UIS = H.UserInputService
local Heartbeat = H.RunService.Heartbeat :: any

local function inputConns(): number
	return #(UIS.InputChanged :: any).connections + #(UIS.InputEnded :: any).connections + #(UIS.InputBegan :: any).connections
end
local function beats(): number
	return #Heartbeat.connections
end
local function click(inst: any)
	H.fire(inst, "Activated", H.input({}), 1)
end
local function named(root: any, name: string): { any }
	return H.findAll(root, function(i: any)
		return i.Name == name
	end)
end
local function byText(root: any, text: string): any
	local hits = H.findAll(root, function(i: any)
		return i.Text == text
	end)
	assert(#hits >= 1, `no instance with Text "{text}"`)
	return hits[1]
end
-- the TextButton that holds (or is) the instance showing `text`
local function button(root: any, text: string): any
	local node: any = byText(root, text)
	while node ~= nil and node.ClassName ~= "TextButton" do
		node = node.Parent
	end
	assert(node ~= nil, `no button around "{text}"`)
	return node
end
local function tabButton(root: any, text: string): any
	for _, b in named(root, "Tab") do
		if H.find(b, "Label").Text == text then
			return b
		end
	end
	error(`no tab "{text}"`)
end
local function visibleSection(gui: any): string
	local page = H.find(gui, "Page") :: any
	local kids = page:GetChildren()
	local out: { string } = {}
	for _, k in kids do
		if (k :: any).ClassName == "Frame" then
			table.insert(out, (k :: any).Name)
		end
	end
	return table.concat(out, ",")
end

local baseInput, baseBeats = inputConns(), beats()
local parent = Instance.new("Folder")
local gui = Gallery.mount(parent) :: any
local layer = H.find(gui, "Overlay") :: any
local counts: { [string]: number } = {}

H.section("mount: ScreenGui settings, own overlay layer, first section only", function()
	assert(gui.Parent == parent and gui.ResetOnSpawn == false and gui.ZIndexBehavior == Enum.ZIndexBehavior.Sibling)
	assert(layer ~= nil and layer.Parent == gui, "overlay layer in the ScreenGui")
	assert(gui.DisplayOrder > 0 and gui.IgnoreGuiInset == false)
	assert(visibleSection(gui) == "Buttons", visibleSection(gui))
	local scroll = H.find(gui, "Scroller") :: any
	assert(scroll.ClassName == "ScrollingFrame" and scroll.AutomaticCanvasSize == Enum.AutomaticSize.Y)
	counts.Buttons = H.countDescendants(gui)
	print(`[gallery] mounted: {counts.Buttons} instances (Buttons section)`)
	H.resetOutput()
	H.assertNoDebugOutput("mount")
end)

H.section("buttons: click counter, disable switch drives the disabled buttons", function()
	click(button(gui, "Filled"))
	click(button(gui, "Tonal"))
	assert(byText(gui, "Clicked 2 times") ~= nil)
	local filled = H.find(gui, "Switch") :: any
	click(filled)
	H.finishTweens()
	local disabledButtons = H.findAll(gui, function(i: any)
		return i.ClassName == "TextButton" and i.Interactable == false
	end)
	local dis = #disabledButtons
	assert(dis >= 15, `disabled buttons after the switch: {dis}`)
	click(filled)
	H.finishTweens()
	H.assertNoDebugOutput("buttons")
end)

local order = { "Selection", "Text", "Surfaces", "Overlays", "Chips", "Pickers", "Theme" }
local sectionNames: { [string]: string } = {
	Selection = "Selection",
	Text = "TextInput",
	Surfaces = "Surfaces",
	Overlays = "Overlays",
	Chips = "ChipsTabsProgress",
	Pickers = "Pickers",
	Theme = "Theme",
}

H.section("every tab: only the selected section exists; switching destroys the previous one", function()
	for _, tab in order do
		click(tabButton(gui, tab))
		H.finishTweens()
		assert(visibleSection(gui) == sectionNames[tab], `{tab}: {visibleSection(gui)}`)
		counts[tab] = H.countDescendants(gui)
		print(`[gallery] {tab}: {counts[tab]} instances total`)
		H.resetOutput()
		H.assertNoDebugOutput(tab)
	end
	click(tabButton(gui, "Buttons"))
	H.finishTweens()
	assert(visibleSection(gui) == "Buttons")
	assert(H.countDescendants(gui) == counts.Buttons, `back to the first section: {H.countDescendants(gui)} vs {counts.Buttons}`)
	H.assertNoDebugOutput("back")
end)

H.section("section state survives leaving and re-entering (Memo)", function()
	click(tabButton(gui, "Selection"))
	click(button(gui, "Pear"))
	assert(byText(gui, "Fruit: pear") ~= nil)
	click(button(gui, "Apple"))
	assert(byText(gui, "Fruit: apple") ~= nil)
	click(tabButton(gui, "Buttons"))
	click(tabButton(gui, "Selection"))
	assert(byText(gui, "Fruit: apple") ~= nil, "memoized Source kept the choice")
	click(tabButton(gui, "Buttons"))
	H.assertNoDebugOutput("memo")
end)

H.section("theme switch: the Switch toggles Theme.default and every swatch follows", function()
	click(tabButton(gui, "Theme"))
	H.finishTweens()
	local before = Theme.default.Scheme:Get()
	assert(before == "light")
	local sw = H.find(gui, "Switch") :: any
	click(sw)
	H.finishTweens()
	assert(Theme.default.Scheme:Get() == "dark", "switch wrote the scheme")
	assert(H.find(sw, "Halo").Position == UDim2.fromOffset(36, 16), "controlled form: the handle shows the derived `Checked` (on)")
	assert(H.find(gui, "SchemeBridge") == nil, "no bridge frame / Effect any more")
	local primary = named(gui, "Primary")
	assert(#primary >= 1 and primary[1].BackgroundColor3 == Tokens.Color.Dark.Primary, "swatch follows the scheme")
	assert(H.find(gui, "Page") ~= nil)
	click(button(gui, "Toggle"))
	H.finishTweens()
	assert(Theme.default.Scheme:Get() == "light", "Toggle button flips it back")
	assert(H.find(sw, "Halo").Position == UDim2.fromOffset(16, 16), "...and the Switch follows without any Effect (off)")
	assert(sw.ClassName == "TextButton")
	H.assertNoDebugOutput("theme")
	click(tabButton(gui, "Buttons"))
end)

H.section("overlays: one of each kind opens and closes through the panel's own overlay", function()
	click(tabButton(gui, "Overlays"))
	H.finishTweens()
	local count = function(): number
		return #layer:GetChildren()
	end
	local base = count()
	-- dialog
	click(button(gui, "Confirm"))
	assert(count() > base, "dialog opened in the gallery's overlay layer")
	click(button(gui, "Cancel"))
	H.finishTweens()
	H.advance(0.5)
	assert(count() == base, `dialog closed: {count()} vs {base}`)
	assert(byText(gui, "Last dialog result: cancelled") ~= nil)
	-- snackbar
	click(button(gui, "With action"))
	assert(count() > base, "snackbar shown")
	H.finishTweens()
	click(button(gui, "Undo"))
	H.finishTweens()
	H.advance(0.5)
	assert(count() == base, "snackbar gone after its action")
	assert(byText(gui, "Last snackbar: undo pressed") ~= nil)
	-- menu
	click(button(gui, "Actions"))
	assert(count() > base, "menu opened")
	click(button(gui, "Rename"))
	H.finishTweens()
	H.advance(0.5)
	assert(count() == base, "menu closed by an item")
	assert(byText(gui, "Last menu item: rename") ~= nil)
	-- tooltip: hover shows after the delay
	local target = button(gui, "Hover me")
	H.fire(target, "MouseEnter", 0, 0)
	H.advance(0.6)
	H.finishTweens()
	assert(count() > base, "tooltip shown")
	H.fire(target, "MouseLeave", 0, 0)
	H.finishTweens()
	H.advance(0.5)
	assert(count() == base, "tooltip hidden")
	H.assertNoDebugOutput("overlays")
	click(tabButton(gui, "Buttons"))
end)

local function fireAncestry(root: any)
	local all = H.findAll(root, function(_: any): boolean
		return true
	end)
	for _, d in all do
		local anyD: any = d
		anyD.AncestryChanged:Fire(d, root)
	end
end

H.section("indeterminate progress: Heartbeat connected only while its section is up", function()
	assert(beats() == baseBeats, "no loop while another section is shown")
	click(tabButton(gui, "Chips"))
	-- the mock does not fire AncestryChanged when the section is parented into the ScreenGui; the engine does
	fireAncestry(gui)
	H.advance(0.1)
	-- linear + circular indeterminate, two loading indicators, the wavy bar's travelling wave
	assert(beats() == baseBeats + 5, `five progress loops: {beats() - baseBeats}`)
	click(tabButton(gui, "Buttons"))
	assert(beats() == baseBeats, "loops gone with the section")
	H.assertNoDebugOutput("progress")
end)

H.section("dispose: overlay, connections and timers back to baseline", function()
	click(tabButton(gui, "Pickers"))
	click(button(gui, "Pick a date (en)"))
	assert(#layer:GetChildren() > 0)
	q.dispose(gui)
	H.advance(1)
	assert(inputConns() == baseInput, `input connections: {inputConns()} vs {baseInput}`)
	assert(beats() == baseBeats, "heartbeat connections")
	assert(H.pendingTimers() == 0, `pending timers: {H.pendingTimers()}`)
	H.assertNoDebugOutput("dispose")
end)

H.section("GalleryPanel without an Overlay brings its own layer and works inside a plain host", function()
	local host = D.Frame { Size = UDim2.fromOffset(800, 600), Gallery.GalleryPanel({}) }
	assert(#named(host, "Overlay") == 1, "own overlay layer inside the panel")
	click(tabButton(host, "Overlays"))
	click(button(host, "Alert"))
	assert(byText(host, "Saved") ~= nil, "alert opened in the panel's own layer")
	q.dispose(host)
	H.advance(1)
	assert(inputConns() == baseInput and H.pendingTimers() == 0)
	H.assertNoDebugOutput("panel")
end)

print("[gallery] instance counts:")
for _, k in { "Buttons", "Selection", "Text", "Surfaces", "Overlays", "Chips", "Pickers", "Theme" } do
	print(`  {k}: {counts[k]}`)
end
H.done()
