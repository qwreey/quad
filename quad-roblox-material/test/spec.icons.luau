--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local D = q.Declaration
local Icons = require("../src/Icons")
local Chip = require("../src/Chip")
local Select = require("../src/Select")
local Overlay = require("../src/Overlay")
local DatePicker = require("../src/DatePicker")
local Calendar = require("../src/DatePicker/Calendar")
local ColorPicker = require("../src/ColorPicker")
local SplitButton = require("../src/Button/Split")
local Slider = require("../src/Slider")

-- Studio QA 2026-10-08 (9th): the edit glyph (U+270E) drew as a "?" box; the icons are images by default now (Material
-- Design Icons, baseline, IMAGE ids from the old IconPack dump — Icons.luau header), each name keeping a glyph fallback
local EXPECTED: { [string]: string } = {
	check = "rbxassetid://6031094667",
	close = "rbxassetid://6031094678",
	arrowDown = "rbxassetid://6031091004",
	arrowUp = "rbxassetid://6031090990",
	chevronLeft = "rbxassetid://6034818375",
	chevronRight = "rbxassetid://6034818365",
	chevronDown = "rbxassetid://6034818372", -- 10th: the split button's menu arrow (keyboard_arrow_down)
	edit = "rbxassetid://6034328955",
	calendar = "rbxassetid://6022668894",
	keyboard = "rbxassetid://6034818398", -- time picker mode toggle (Icons.Filled.Keyboard)
	schedule = "rbxassetid://6031260808", -- time picker mode toggle (Icons.Filled.Schedule)
	menu = "rbxassetid://6031097225", -- the navigation drawer's opener (baseline/navigation/menu)
}

H.section("defaults are Material icon images, each with a text glyph fallback; error stays a glyph", function()
	for _, name in { "check", "close", "arrowDown", "arrowUp", "chevronLeft", "chevronRight", "chevronDown", "edit", "calendar", "keyboard", "schedule", "menu", "error" } do
		assert(#Icons.glyph(name :: any) > 0, name .. ": glyph fallback")
		assert(Icons.asset(name :: any) == EXPECTED[name], name .. ": default image " .. tostring(Icons.asset(name :: any)))
		assert(Icons.Defaults[name] == EXPECTED[name], name .. ": Defaults table")
	end
	assert(table.isfrozen(Icons.Defaults), "Defaults is read-only")
	H.assertNoDebugOutput("defaults")
end)

H.section("glyph fallback: with the images overridden away every icon place draws its text glyph", function()
	local all: { [any]: string | false } = {}
	for name in EXPECTED do
		all[name] = false
	end
	Icons.override(all :: any)
	local chip: any = Chip.Filter({ Label = "F", Selected = q.Source(true) })
	assert(H.find(chip, "Check").ClassName == "TextLabel" and H.find(chip, "Check").Text == "\u{221A}", "chip check glyph")
	local input: any = Chip.Input({ Label = "I", OnRemove = function() end })
	assert(H.find(input, "Remove").ClassName == "TextButton" and H.find(input, "Remove").Text == "\u{00D7}", "chip remove glyph")
	local overlay = Overlay.new()
	local screen = D.Frame { overlay.Layer }
	local select: any = Select({ Label = "S", Options = { "a" }, Value = q.Source(nil :: string?), Overlay = overlay })
	assert(H.find(select, "TrailingIcon") == nil and H.find(select, "TrailingGlyph") ~= nil, "select arrow glyph")
	DatePicker.Modal.open({ Overlay = overlay, Today = Calendar.date(2026, 10, 8) })
	local toggle = H.find(screen, "ModeToggle")
	assert(toggle.ClassName == "TextButton" and toggle.Text == "\u{270E}", "modal toggle glyph")
	local prev = H.find(screen, "Prev")
	assert(prev.ClassName == "TextButton" and prev.Text == "\u{2039}", "month arrow glyph")
	local panel: any = ColorPicker.Panel({ Value = q.Source(Color3.fromRGB(255, 255, 255)) })
	local swatch = H.find(panel, "Swatch")
	assert(swatch.ClassName == "TextButton", "swatch check is the button's text")
	local split: any = SplitButton({ Label = "S" })
	local arrow = H.find(H.find(split, "Trailing"), "Icon")
	assert(arrow.ClassName == "TextLabel" and arrow.Text == "\u{25BC}", "split menu arrow glyph")
	q.dispose(split)
	q.dispose(chip)
	q.dispose(input)
	q.dispose(select)
	q.dispose(panel)
	q.dispose(screen)
	Icons.override(Icons.Defaults :: any)
	H.assertNoDebugOutput("glyph fallback")
end)

H.section("default images reach every icon place", function()
	local chip: any = Chip.Filter({ Label = "F", Selected = q.Source(true) })
	assert(H.find(chip, "Check").ClassName == "ImageLabel" and H.find(chip, "Check").Image == EXPECTED.check)
	local overlay = Overlay.new()
	local screen = D.Frame { overlay.Layer }
	local select: any = Select({ Label = "S", Options = { "a" }, Value = q.Source(nil :: string?), Overlay = overlay })
	assert(H.find(select, "TrailingIcon").Image == EXPECTED.arrowDown and H.find(select, "TrailingGlyph") == nil)
	DatePicker.Modal.open({ Overlay = overlay, Today = Calendar.date(2026, 10, 8) })
	local toggle = H.find(screen, "ModeToggle")
	assert(toggle.ClassName == "ImageButton" and H.find(toggle, "Icon").Image == EXPECTED.edit, "edit image")
	H.fire(toggle, "Activated", H.input({}), 1)
	assert(H.find(toggle, "Icon").Image == EXPECTED.calendar, "input mode: the calendar image")
	assert(H.find(H.find(screen, "Prev"), "Icon").Image == EXPECTED.chevronLeft and H.find(H.find(screen, "Next"), "Icon").Image == EXPECTED.chevronRight)
	q.dispose(chip)
	q.dispose(select)
	q.dispose(screen)
	H.assertNoDebugOutput("default images")
end)

H.section("Icons.resolve: a name -> its image (glyph without one), an asset URL -> image, other text -> glyph; imageOf", function()
	local k, v = Icons.resolve("check")
	assert(k == "Image" and v == EXPECTED.check)
	k, v = Icons.resolve("error")
	assert(k == "Glyph" and v == "!", "error has no image")
	for _, url in { "rbxassetid://5", "rbxasset://textures/x.png", "rbxthumb://type=Asset&id=1&w=150&h=150", "https://x.y/z.png", "http://www.roblox.com/asset/?id=6" } do
		k, v = Icons.resolve(url)
		assert(k == "Image" and v == url, url)
	end
	k, v = Icons.resolve("\u{266A}")
	assert(k == "Glyph" and v == "\u{266A}")
	Icons.override({ check = false })
	k, v = Icons.resolve("check")
	assert(k == "Glyph" and v == Icons.glyph("check"), "overridden away: the glyph")
	assert(Icons.imageOf("check") == "" and Icons.imageOf("close") == EXPECTED.close and Icons.imageOf("rbxassetid://5") == "rbxassetid://5")
	Icons.override({ check = EXPECTED.check })
	-- every icon prop goes through it: Button / SplitButton `Icon`, Slider `TrackIcon*`
	local s: any = Slider({ Size = "M", TrackIconActiveStart = "close" })
	assert(H.find(s, "TrackIconActiveStart").Image == EXPECTED.close)
	q.dispose(s)
	H.assertNoDebugOutput("resolve")
end)

H.section("override swaps in another image without touching components; false removes it", function()
	Icons.override({ check = "rbxassetid://11", close = "rbxassetid://12", arrowDown = "rbxassetid://13" })
	assert(Icons.asset("check") == "rbxassetid://11" and Icons.asset("close") == "rbxassetid://12")
	local chip: any = Chip.Filter({ Label = "F", Selected = q.Source(true) })
	assert(H.find(chip, "Check").ClassName == "ImageLabel" and H.find(chip, "Check").Image == "rbxassetid://11", "Chip check follows the registry")
	local input: any = Chip.Input({ Label = "I", OnRemove = function() end })
	assert(H.find(input, "Remove").ClassName == "ImageButton" and H.find(H.find(input, "Remove"), "Icon").Image == "rbxassetid://12")
	local own: any = Chip.Input({ Label = "I", OnRemove = function() end, RemoveIcon = "rbxassetid://99" })
	assert(H.find(H.find(own, "Remove"), "Icon").Image == "rbxassetid://99", "the chip's own prop wins")
	local overlay = Overlay.new()
	local screen = D.Frame { overlay.Layer }
	local select: any = Select({ Label = "S", Options = { "a" }, Value = q.Source(nil :: string?), Overlay = overlay })
	assert(H.find(select, "TrailingIcon") ~= nil and H.find(select, "TrailingIcon").Image == "rbxassetid://13" and H.find(select, "TrailingGlyph") == nil)
	Icons.override({ check = false, close = false, arrowDown = false })
	assert(Icons.asset("check") == nil and Icons.asset("close") == nil and Icons.glyph("check") ~= "")
	Icons.override(Icons.Defaults :: any)
	q.dispose(chip)
	q.dispose(input)
	q.dispose(own)
	q.dispose(select)
	q.dispose(screen)
	H.assertNoDebugOutput("override")
end)

H.done()
