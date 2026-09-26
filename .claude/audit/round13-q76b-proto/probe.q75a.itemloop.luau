--!nocheck
-- p-q76b: the Q75 (a) stale-extract entrance that A1+A1b does NOT close — the ITEM loop drops (updateFn
-- returns nil for a key still in the data) a Slot/State element after an earlier row changed length in
-- the same batch. Uses the E1 offset-validating backend (probe.e1.harness.luau).
local H = require("./probe.e1.harness")
local q, Instance, Slot, dispatch = H.q, H.Instance, H.Slot, H.dispatch
local function F(n) local f = Instance.new("Frame"); f.Name = n; return f end
local function show(label, parent)
	print(label, H.names(H.P(parent)), "known:", table.concat(H.known, " | "), "viol:", table.concat(H.violations, " | "))
	table.clear(H.known); table.clear(H.violations)
end
for _, variant in { "earlier-drop", "earlier-insert" } do
	print("== " .. variant .. " then State element dropped by updateFn (not KeyGone) ==")
	local parent = Instance.new("Folder")
	local st = q.Source(F("k2st"))
	local drop = {}
	local data = q.Source({ { id = 1 }, { id = 2 } })
	local root = Slot():List(data, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		local id = ctx.Item.id
		if drop[id] then return nil end
		if id == 2 then return st end
		return ctx.Prev or F("k" .. id)
	end, function(it) return it.id end)
	dispatch.drive(parent, { "L", root, "T" })
	show("before", parent)
	drop[2] = true
	if variant == "earlier-drop" then drop[1] = true; data:Set({ { id = 1 }, { id = 2 } })
	else data:Set({ { id = 3 }, { id = 1 }, { id = 2 } }) end
	show("after ", parent)
end
