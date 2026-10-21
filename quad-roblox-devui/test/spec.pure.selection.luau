--!strict
-- Selection (multi-selection rules), ported from devplorer `Rows/Select` with its spec (2026-10-21).
local Selection = require("../src/Selection")

local function join(list: { any }): string
	local parts: { string } = {}
	for _, key in list do
		table.insert(parts, tostring(key))
	end
	return table.concat(parts, ",")
end

local order = { "a", "b", "c", "d", "e" }

local function run(test: (string, () -> ()) -> ())
	test("Replace: the clicked key alone, and the anchor", function()
		local nextList, anchor = Selection.apply({ "a", "b" }, "a", order, 3, "Replace")
		assert(join(nextList) == "c" and anchor == "c")
	end)

	test("Toggle adds then removes and moves the anchor", function()
		local first, anchor1 = Selection.apply({ "a" }, "a", order, 4, "Toggle")
		assert(join(first) == "a,d" and anchor1 == "d")
		local second, anchor2 = Selection.apply(first, anchor1, order, 1, "Toggle")
		assert(join(second) == "d" and anchor2 == "a")
	end)

	test("Extend: from the anchor in shown order, both directions; the anchor stays", function()
		local down, anchorDown = Selection.apply({ "b" }, "b", order, 4, "Extend")
		assert(join(down) == "b,c,d" and anchorDown == "b")
		local up, anchorUp = Selection.apply({ "d" }, "d", order, 2, "Extend")
		assert(join(up) == "b,c,d" and anchorUp == "d")
	end)

	test("Extend with no anchor, or one not shown, acts as Replace", function()
		local a, anchorA = Selection.apply({}, nil, order, 2, "Extend")
		assert(join(a) == "b" and anchorA == "b")
		local b, anchorB = Selection.apply({ "z" }, "z", order, 5, "Extend")
		assert(join(b) == "e" and anchorB == "e")
	end)

	test("an index outside order changes nothing", function()
		local current = { "a" }
		local nextList, anchor = Selection.apply(current, "a", order, 9, "Replace")
		assert(nextList == current and anchor == "a")
	end)

	test("prune drops rejected keys; unchanged returns the same table", function()
		local current = { "a", "b", "c" }
		local same, changed = Selection.prune(current, function()
			return true
		end)
		assert(same == current and changed == false)
		local pruned, changed2 = Selection.prune(current, function(key)
			return key ~= "b"
		end)
		assert(join(pruned) == "a,c" and changed2 == true)
	end)

	test("toSet", function()
		local set = Selection.toSet({ "a", "c" })
		assert(set.a == true and set.c == true and set.b == nil)
	end)

end

run(function(name: string, fn: () -> ())
	fn()
	print("PASS " .. name)
end)
