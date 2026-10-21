--!strict
-- Selection.modeFromKeys reads KeyCodes (Enum): under Lune with the mock; the pure rules are in spec.pure.selection.
local H = require("./support/harness")
local Selection = require("../src/Selection")

H.section("modeFromKeys: Shift -> Extend, Ctrl / Cmd -> Toggle, else Replace", function()
	local held: { [string]: boolean } = {}
	local service: any = {
		IsKeyDown = function(_self: any, key: any): boolean
			return held[key.Name] == true
		end,
	}
	assert(Selection.modeFromKeys(service) == "Replace")
	held.RightControl = true
	assert(Selection.modeFromKeys(service) == "Toggle")
	held.RightControl = nil
	held.LeftSuper = true
	assert(Selection.modeFromKeys(service) == "Toggle")
	held.LeftShift = true
	assert(Selection.modeFromKeys(service) == "Extend", "Shift wins")
end)

H.done()
