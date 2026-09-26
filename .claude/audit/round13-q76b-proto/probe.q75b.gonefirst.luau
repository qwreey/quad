--!nocheck
-- p-q76b: does A1 (KeyGone first) create NEW Q75 (b) cases? updateFn CRUDs its ctx.Prev row Slot after a
-- gone key BEFORE that row was already removed in the same batch (recompute blocked → row.Offset stale).
local H = require("./probe.e1.harness")
local q, Instance, Slot, dispatch = H.q, H.Instance, H.Slot, H.dispatch
local function F(n) local f = Instance.new("Frame"); f.Name = n; return f end
local function show(label, parent)
	print(label, H.names(H.P(parent)), "known:", table.concat(H.known, " | "), "viol:", table.concat(H.violations, " | "))
	table.clear(H.known); table.clear(H.violations)
end
for _, owns in { true, false } do
	print("== gone row before a kept row that grows in its updateFn (OwnsElements=" .. tostring(owns) .. ") ==")
	local parent = Instance.new("Folder")
	local rows = {}
	local data = q.Source({ { id = 1, n = 1 }, { id = 2, n = 1 } })
	local root = Slot():List(data, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		local it = ctx.Item
		local row = ctx.Prev
		if row == nil then row = Slot(); rows[it.id] = row end
		while #row._elements < it.n do row:Add(F(`r{it.id}_{#row._elements + 1}`)) end
		return row
	end, function(it) return it.id end, if owns then nil else { OwnsElements = false })
	dispatch.drive(parent, { "L", root, "T" })
	show("before", parent)
	data:Set({ { id = 2, n = 2 } })
	show("after ", parent)
	print("  row2 Offset", rows[2].Offset:Get(), "root Length", root.Length:Get(), "phys count", #H.P(parent))
end
