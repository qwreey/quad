--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local D = q.Declaration
local Select = require("../src/Select")
local Overlay = require("../src/Overlay")
local Tokens = require("../src/Tokens")

local L = Tokens.Color.Light

local function setup()
	local overlay = Overlay.new()
	local screen = D.Frame { overlay.Layer }
	H.setAbs(overlay.Layer, 0, 0, 800, 600)
	return overlay, screen
end

local function items(screen: any): { any }
	return H.findAll(screen, function(c: any)
		return c.Name == "Item"
	end)
end

local function click(container: any)
	H.fire(container, "InputBegan", H.input({}))
	H.fire(container, "InputEnded", H.input({}))
end

H.section("mount: read-only field showing the formatted value, arrow, label", function()
	local overlay, screen = setup()
	local v = q.Source(nil :: string?)
	local sel = Select({ Label = "Fruit", Options = { "Apple", "Pear" }, Value = v, Overlay = overlay })
	sel.Parent = screen
	assert(sel.Name == "TextField")
	local box = H.find(sel, "Input")
	assert(box.Text == "" and box.Interactable == false and box.TextEditable == false)
	-- the Material arrow_drop_down image (Icons default; the "▼" glyph fallback is in spec.icons)
	assert(H.find(sel, "TrailingGlyph") == nil and H.find(sel, "TrailingIcon").Image == "rbxassetid://6031091004", "dropdown arrow image")
	assert(H.find(sel, "Label").TextSize == 16, "empty: label at rest")
	local count = H.countDescendants(sel)
	print("Select descendants: " .. count .. " (+1 host = " .. (count + 1) .. ")")
	H.resetOutput()
	q.dispose(screen)
	H.assertNoDebugOutput("mount")
end)

H.section("round trip: open, highlight, pick, value + field text, reopen highlights pick", function()
	local overlay, screen = setup()
	local v = q.Source(nil :: string?)
	local sel = Select({ Label = "Fruit", Options = { "Apple", "Pear", "Plum" }, Value = v, Overlay = overlay })
	sel.Parent = screen
	local container = H.find(sel, "Container")
	H.setAbs(container, 50, 20, 240, 56)
	click(container)
	assert(overlay.Count:Get() == 1)
	H.finishTweens()
	local menu = H.find(screen, "Menu")
	assert(menu.Position == UDim2.fromOffset(170, 76) and menu.Size.X.Offset == 240, "menu under the container, field width")
	assert(H.find(sel, "Indicator").BackgroundColor3 == L.Primary and H.find(sel, "Label").TextSize == 12, "focused look while open")
	local its = items(screen)
	assert(#its == 3 and H.find(its[2], "Label").Text == "Pear")
	for _, it in its do
		assert(it.BackgroundTransparency == 1, "nothing selected yet")
	end
	H.fire(its[2], "Activated", H.input({}), 1)
	assert(v:Get() == "Pear", "value written")
	H.advance(0.3)
	H.finishTweens()
	assert(H.find(sel, "Input").Text == "Pear", "field shows the choice")
	assert(overlay.Count:Get() == 0 and #overlay.Layer:GetChildren() == 0, "menu closed, overlay empty")
	assert(H.find(sel, "Indicator").BackgroundColor3 == L.OnSurfaceVariant, "focused look gone")
	-- reopen: pick highlighted
	click(container)
	local again = items(screen)
	assert(again[2].BackgroundTransparency == 0 and again[1].BackgroundTransparency == 1, "chosen option highlighted")
	-- outside click keeps the value
	H.fire(H.find(screen, "Scrim"), "Activated", H.input({}), 1)
	H.advance(0.3)
	assert(v:Get() == "Pear" and overlay.Count:Get() == 0)
	-- source -> field
	v:Set("Plum")
	assert(H.find(sel, "Input").Text == "Plum")
	q.dispose(screen)
	H.assertNoDebugOutput("roundtrip")
end)

H.section("State options + Format on objects; second click while open is ignored", function()
	local overlay, screen = setup()
	type Unit = { Name: string, Id: number }
	local a: Unit, b: Unit = { Name = "Metre", Id = 1 }, { Name = "Foot", Id = 2 }
	local opts = q.Source({ a, b })
	local v = q.Source(a :: Unit?)
	local sel = Select({
		Variant = "Outlined",
		Label = "Unit",
		Options = opts,
		Value = v,
		Format = function(u: Unit)
			return u.Name
		end,
		Overlay = overlay,
	})
	sel.Parent = screen
	assert(H.find(sel, "Input").Text == "Metre")
	local container = H.find(sel, "Container")
	click(container)
	assert(items(screen)[1].BackgroundTransparency == 0 and H.find(items(screen)[2], "Label").Text == "Foot")
	click(container) -- under the scrim in a real tree; here the guard must hold
	assert(overlay.Count:Get() == 1)
	H.fire(items(screen)[2], "Activated", H.input({}), 1)
	assert(v:Get() == b and H.find(sel, "Input").Text == "Foot")
	H.advance(0.3)
	opts:Set({ b })
	click(container)
	assert(#items(screen) == 1, "options State read at open")
	H.fire(H.find(screen, "Scrim"), "Activated", H.input({}), 1)
	H.advance(0.3)
	q.dispose(screen)
	H.assertNoDebugOutput("state options")
end)

H.section("disabled select never opens", function()
	local overlay, screen = setup()
	local v = q.Source(nil :: string?)
	local sel = Select({ Label = "X", Options = { "a" }, Value = v, Disabled = true, Overlay = overlay })
	sel.Parent = screen
	click(H.find(sel, "Container"))
	assert(overlay.Count:Get() == 0)
	q.dispose(screen)
	H.assertNoDebugOutput("disabled")
end)

H.section("dispose with the menu open: everything destroyed, connection baseline", function()
	local u = H.UserInputService :: any
	local base = #u.InputChanged.connections + #u.InputEnded.connections + #u.WindowFocusReleased.connections
	local overlay, screen = setup()
	local sel = Select({ Label = "X", Options = { "a", "b" }, Value = q.Source(nil :: string?), Overlay = overlay })
	sel.Parent = screen
	click(H.find(sel, "Container"))
	local all = H.findAll(screen, function()
		return true
	end)
	q.dispose(screen)
	for _, i in all do
		assert(H.isDestroyed(i))
	end
	assert(#u.InputChanged.connections + #u.InputEnded.connections + #u.WindowFocusReleased.connections == base)
	H.advance(1)
	H.assertNoDebugOutput("dispose")
end)

H.section("A-H2 select: the open look resets when the overlay layer dies under the menu", function()
	local overlay, screen = setup()
	local v = q.Source(nil :: string?)
	local sel = Select({ Label = "Fruit", Options = { "Apple" }, Value = v, Overlay = overlay })
	local selHost = D.Frame {}
	sel.Parent = selHost
	local container = H.find(sel, "Container")
	H.setAbs(container, 50, 20, 240, 56)
	click(container)
	H.finishTweens()
	assert(H.find(sel, "Label").TextSize == 12, "open: focused look")
	q.dispose(screen)
	H.finishTweens()
	assert(H.find(sel, "Label").TextSize == 16, "layer died: the field is no longer 'open'")
	local ok = pcall(function()
		click(container) -- the dead overlay errors loudly from Open ...
	end)
	assert(not ok)
	H.finishTweens()
	assert(H.find(sel, "Label").TextSize == 16, "... and the field does not get stuck 'open'")
	q.dispose(selHost)
	H.assertNoDebugOutput("select death")
end)

H.section("D10 gamepad focus on a read-only field draws the focused look and hides the engine box", function()
	local overlay, screen = setup()
	local sel = Select({ Label = "Fruit", Options = { "Apple" }, Value = q.Source(nil :: string?), Overlay = overlay })
	sel.Parent = screen
	local container = H.find(sel, "Container")
	assert(container.SelectionImageObject ~= nil, "engine selection box replaced")
	H.fire(container, "SelectionGained")
	H.finishTweens()
	assert(H.find(sel, "Indicator").BackgroundColor3 == L.Primary and H.find(sel, "Label").TextSize == 12, "focused look on selection")
	H.fire(container, "SelectionLost")
	H.finishTweens()
	assert(H.find(sel, "Label").TextSize == 16)
	q.dispose(screen)
	H.assertNoDebugOutput("select focus")
end)

H.section("the menu matches the field's width (exposed dropdown), not its options' width", function()
	local overlay, screen = setup()
	local sel = Select({ Label = "Wide", Options = { "A", "B" }, Value = q.Source(nil :: string?), Overlay = overlay })
	sel.Parent = screen
	local container = H.find(sel, "Container")
	H.setAbs(container, 20, 20, 400, 56)
	click(container)
	local menu = H.find(screen, "Menu")
	assert(menu.Size.X.Offset == 400 and menu.Position == UDim2.fromOffset(220, 76), "field width, centered pivot: " .. tostring(menu.Position))
	assert(menu.AutomaticSize == Enum.AutomaticSize.None, "a fixed width, not fitted to the options")
	H.fire(items(screen)[1], "Activated", H.input({}), 1)
	H.advance(0.3)
	-- a field not laid out yet (0 wide) still gets a fixed width: the M3 minimum
	H.setAbs(container, 20, 20, 0, 56)
	click(container)
	local m2 = H.find(screen, "Menu")
	assert(m2.Size.X.Offset == 112 and m2.AutomaticSize == Enum.AutomaticSize.None, "unmeasured field: 112 fixed")
	H.fire(items(screen)[1], "Activated", H.input({}), 1)
	H.advance(0.3)
	q.dispose(screen)
	H.assertNoDebugOutput("select wide")
end)

H.done()
