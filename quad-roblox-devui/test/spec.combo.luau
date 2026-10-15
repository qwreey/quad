--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local D = q.Declaration
local Overlay = require("../src/Overlay")
Overlay.warnUnmounted = false -- these specs open popups on a bare layer (no ScreenGui); the debug line has its own spec in spec.overlay
local Combo = require("../src/Combo")

local UIS = H.UserInputService
local function nBegan(): number
	return #(UIS.InputBegan :: any).connections
end
local function get(root: Instance, name: string): any
	local found = H.find(root, name)
	assert(found ~= nil, `missing {name}`)
	return found
end
local function options(layer: Instance): { any }
	return H.findAll(layer, function(i: any)
		return i.Name == "Option"
	end)
end
local function labelsOf(rows: { any }): { string }
	local out: { string } = {}
	for _, r in rows do
		table.insert(out, r.Text)
	end
	return out
end
local function escape(): any
	return H.input({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Escape })
end

H.section("mount: preview, label, no popup until clicked, nothing connected", function()
	local o = Overlay.new()
	local value = q.Source("b")
	local base = nBegan()
	local combo = Combo.Combo<<string>>({ Text = "Pick", Value = value, Options = { "a", "b", "c" }, Overlay = o })
	local box = get(combo, "Box")
	assert(box.Text == "b" and box.ClassName == "TextButton")
	assert(get(combo, "Text").Text == "Pick")
	assert(o.Count:Get() == 0 and nBegan() == base)
	value:Set("c")
	assert(box.Text == "c", "preview follows the Source")
	assert(H.countDescendants(combo) <= 10, `instance count {H.countDescendants(combo)}`)
	q.dispose(combo)
	q.dispose(o.Layer)
	H.assertNoDebugOutput("mount")
end)

H.section("open under the box, choose writes the Source and closes (cycles leave the layer empty)", function()
	local o = Overlay.new()
	local value = q.Source("a")
	local combo = Combo.Combo<<string>>({
		Text = "Pick",
		Value = value,
		Options = { "a", "b", "c" },
		Format = function(s: string)
			return s:upper()
		end,
		Overlay = o,
	})
	local box = get(combo, "Box")
	assert(box.Text == "A", "Format applies to the preview")
	H.setAbs(box, 30, 40, 200, 19)
	local base = nBegan()
	for cycle = 1, 3 do
		H.fire(box, "Activated", H.input({}), 1)
		assert(o.Count:Get() == 1 and nBegan() == base + 1)
		local list = get(o.Layer, "ComboList")
		assert(list.Size == UDim2.fromOffset(200, 0), "list is as wide as the box")
		local holder = get(o.Layer, "PopupHolder")
		assert(holder.Position == UDim2.fromOffset(30, 59), "under the box")
		local rows = options(o.Layer)
		assert(#rows == 3 and table.concat(labelsOf(rows), ",") == "A,B,C")
		local choice = rows[1 + cycle % 3]
		H.fire(choice, "Activated", H.input({}), 1)
		assert(value:Get() == ({ "a", "b", "c" })[1 + cycle % 3])
		assert(o.Count:Get() == 0 and #o.Layer:GetChildren() == 0, "layer back to baseline")
		assert(nBegan() == base, "escape connection closed")
		assert(box.Text == string.upper(value:Get()))
	end
	q.dispose(combo)
	q.dispose(o.Layer)
	H.assertNoDebugOutput("open/choose")
end)

H.section("the chosen option shows the selected look; Escape / click-outside / destroy close", function()
	local o = Overlay.new()
	local value = q.Source(2)
	local combo = Combo.Combo<<number>>({ Text = "n", Value = value, Options = { 1, 2, 3 }, Overlay = o })
	local box = get(combo, "Box")
	H.fire(box, "Activated", H.input({}), 1)
	local rows = options(o.Layer)
	assert(#rows == 3 and rows[2].BackgroundTransparency < 1 and rows[1].BackgroundTransparency == 1, "selected row is highlighted")
	value:Set(3)
	assert(rows[3].BackgroundTransparency < 1 and rows[2].BackgroundTransparency == 1, "highlight follows the Source")
	-- a non-escape key does nothing
	UIS.InputBegan:Fire(H.input({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.A }), false)
	assert(o.Count:Get() == 1)
	UIS.InputBegan:Fire(escape(), false)
	assert(o.Count:Get() == 0 and value:Get() == 3)

	H.fire(box, "Activated", H.input({}), 1)
	H.fire(get(o.Layer, "Catcher"), "Activated", H.input({}), 1)
	assert(o.Count:Get() == 0, "click outside closes")

	H.fire(box, "Activated", H.input({}), 1)
	assert(o.Count:Get() == 1)
	local base = nBegan()
	q.dispose(combo)
	assert(o.Count:Get() == 0 and nBegan() == base - 1, "destroying the combo closes its popup")
	q.dispose(o.Layer)
	H.assertNoDebugOutput("close paths")
end)

H.section("Options as a State updates the open list in place", function()
	local o = Overlay.new()
	local value = q.Source("x")
	local opts = q.Source({ "x", "y" })
	local combo = Combo.Combo<<string>>({ Text = "t", Value = value, Options = opts, Overlay = o })
	H.fire(get(combo, "Box"), "Activated", H.input({}), 1)
	assert(#options(o.Layer) == 2)
	opts:Set({ "x", "y", "z" })
	assert(table.concat(labelsOf(options(o.Layer)), ",") == "x,y,z")
	opts:Set({ "z" })
	assert(table.concat(labelsOf(options(o.Layer)), ",") == "z")
	o:CloseAll()
	assert(#o.Layer:GetChildren() == 0)
	q.dispose(combo)
	q.dispose(o.Layer)
	H.assertNoDebugOutput("state options")
end)

H.section("ComboArray: the Source holds the index; duplicates are fine", function()
	local o = Overlay.new()
	local index = q.Source(2)
	local combo = Combo.ComboArray<<string>>({ Text = "i", Index = index, Options = { "same", "other", "same" }, Overlay = o })
	local box = get(combo, "Box")
	assert(box.Text == "other")
	H.fire(box, "Activated", H.input({}), 1)
	local rows = options(o.Layer)
	assert(#rows == 3)
	H.fire(rows[3], "Activated", H.input({}), 1)
	assert(index:Get() == 3 and box.Text == "same" and o.Count:Get() == 0)
	index:Set(9)
	assert(box.Text == "", "out-of-range index previews empty")
	q.dispose(combo)
	q.dispose(o.Layer)
	H.assertNoDebugOutput("array")
end)

H.section("ComboEnum: Enum items by name", function()
	local o = Overlay.new()
	local value = q.Source<<EnumItem>>(Enum.EasingStyle.Quad)
	local combo = Combo.ComboEnum({ Text = "e", Value = value, Enum = Enum.EasingStyle, Overlay = o })
	local box = get(combo, "Box")
	assert(box.Text == "Quad")
	H.fire(box, "Activated", H.input({}), 1)
	local rows = options(o.Layer)
	assert(#rows == #Enum.EasingStyle:GetEnumItems() and #rows > 3)
	for _, r in rows do
		if r.Text == "Linear" then
			H.fire(r, "Activated", H.input({}), 1)
			break
		end
	end
	assert(value:Get() == Enum.EasingStyle.Linear and box.Text == "Linear")
	q.dispose(combo)
	q.dispose(o.Layer)
	H.assertNoDebugOutput("enum")
end)

H.section("dispose: everything gone, connections at baseline", function()
	local o = Overlay.new()
	local base = nBegan()
	local value = q.Source("a")
	local combo = Combo.Combo<<string>>({ Text = "t", Value = value, Options = { "a", "b" }, Overlay = o })
	local screen = D.ScreenGui({ combo, o.Layer })
	H.fire(get(combo, "Box"), "Activated", H.input({}), 1)
	q.dispose(screen)
	assert(H.isDestroyed(combo) and nBegan() == base)
	H.assertNoDebugOutput("dispose")
end)

H.section("OnChange reports user picks only; Disabled blocks opening", function()
	local o = Overlay.new()
	local value = q.Source("a")
	local picked: { string } = {}
	local off = q.Source(false)
	local combo = Combo.Combo<<string>>({
		Text = "Pick",
		Value = value,
		Options = { "a", "b", "c" },
		Overlay = o,
		Disabled = off,
		OnChange = function(v: string)
			table.insert(picked, v)
		end,
	})
	local box = get(combo, "Box")
	H.fire(box, "Activated", H.input({}), 1)
	H.fire(options(o.Layer)[2], "Activated", H.input({}), 1)
	assert(value:Get() == "b" and picked[1] == "b" and #picked == 1 and o.Count:Get() == 0)
	value:Set("c")
	assert(#picked == 1, "an outside :Set is not reported")
	H.fire(box, "Activated", H.input({}), 1)
	H.fire(options(o.Layer)[3], "Activated", H.input({}), 1) -- the current value again
	assert(#picked == 1, "re-picking the current option is not a change")
	off:Set(true)
	H.fire(box, "Activated", H.input({}), 1)
	assert(o.Count:Get() == 0, "disabled: does not open")
	q.dispose(combo)

	local idx = q.Source(1)
	local got: { string } = {}
	local arr = Combo.ComboArray<<string>>({
		Text = "i",
		Index = idx,
		Options = { "x", "y" },
		Overlay = o,
		OnChange = function(i: number, item: string)
			table.insert(got, `{i}:{item}`)
		end,
	})
	H.fire(get(arr, "Box"), "Activated", H.input({}), 1)
	H.fire(options(o.Layer)[2], "Activated", H.input({}), 1)
	assert(idx:Get() == 2 and got[1] == "2:y")
	q.dispose(arr)
	q.dispose(o.Layer)
	H.assertNoDebugOutput("onchange/disabled")
end)

H.section("the layer dying with the list open: popup closed, Escape listener back to baseline, reopening is quiet", function()
	local o = Overlay.new()
	local gui = D.ScreenGui({ o.Layer })
	local value = q.Source("a")
	local combo = Combo.Combo<<string>>({ Text = "Pick", Value = value, Options = { "a", "b" }, Overlay = o })
	local box = get(combo, "Box")
	local base = nBegan()
	H.fire(box, "Activated", H.input({}), 1)
	assert(o.Count:Get() == 1 and nBegan() == base + 1)
	q.dispose(gui)
	assert(o.Count:Get() == 0 and nBegan() == base)
	H.fire(box, "Activated", H.input({}), 1) -- dead overlay: nothing, no error
	assert(nBegan() == base)
	q.dispose(combo)
	H.assertNoDebugOutput("layer death")
end)


H.section("closing the window the combo is in (an ANCESTOR hidden) closes the open list; watchers only while open", function()
	local o = Overlay.new()
	local win = D.Frame({})
	local inner = D.Frame({})
	inner.Parent = win
	local combo = Combo.Combo<<number>>({ Text = "n", Value = q.Source(1), Options = { 1, 2 }, Overlay = o })
	combo.Parent = inner
	local box = get(combo, "Box")
	local winVisible = (win :: any):GetPropertyChangedSignal("Visible")
	local idle = #winVisible.connections
	H.fire(box, "Activated", H.input({}), 1)
	assert(o.Count:Get() == 1 and #winVisible.connections == idle + 1, "open: the ancestors are watched")
	-- an unrelated property or Visible = true does nothing
	win.Visible = true
	assert(o.Count:Get() == 1)
	win.Visible = false
	assert(o.Count:Get() == 0 and #winVisible.connections == idle, "hidden ancestor closed the list; watchers dropped")
	win.Visible = true
	-- the box itself hidden, and a closed list leaves nothing behind either way
	H.fire(box, "Activated", H.input({}), 1)
	box.Visible = false
	assert(o.Count:Get() == 0, "box hidden")
	box.Visible = true
	-- the ScreenGui disabled
	local gui = D.ScreenGui({ ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
	win.Parent = gui
	H.fire(box, "Activated", H.input({}), 1)
	gui.Enabled = false
	assert(o.Count:Get() == 0, "ScreenGui disabled")
	-- a hidden window does not stop the list from opening again once shown
	gui.Enabled = true
	H.fire(box, "Activated", H.input({}), 1)
	assert(o.Count:Get() == 1)
	H.fire(get(o.Layer, "Catcher"), "Activated", H.input({}), 1)
	assert(o.Count:Get() == 0 and #winVisible.connections == idle)
	q.dispose(gui)
	q.dispose(o.Layer)
	H.assertNoDebugOutput("ancestor hidden")
end)

H.done()
