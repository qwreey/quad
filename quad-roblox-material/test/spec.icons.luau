--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local D = q.Declaration
local Icons = require("../src/Icons")
local Chip = require("../src/Chip")
local Select = require("../src/Select")
local Overlay = require("../src/Overlay")

H.section("defaults are text glyphs from one table; no asset until one is registered", function()
	for _, name in { "check", "close", "arrowDown", "arrowUp", "chevronLeft", "chevronRight", "edit", "calendar", "error" } do
		assert(#Icons.glyph(name :: any) > 0 and Icons.asset(name :: any) == nil, name)
	end
	H.assertNoDebugOutput("defaults")
end)

H.section("override swaps in an image asset without touching components; false removes it", function()
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
	q.dispose(chip)
	q.dispose(input)
	q.dispose(own)
	q.dispose(select)
	q.dispose(screen)
	H.assertNoDebugOutput("override")
end)

H.done()
