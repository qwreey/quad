--!nocheck
-- E45: first reconcile throws INSIDE a CRUD on a mounted parent (rawAdd → attachSlot → _activateList)
local E = require("./env")
local mk, row, try, order = E.mk, E.row, E.try, E.order
for _, how in { "dup key", "updateFn throws", "Quad0156 element" } do
	local q = E.newQ()
	local outer = q.Slot({ mk("o1") })
	local p = E.I.new("Folder")
	q.Dispatch.drive(p, { outer })
	local other = q.Slot({ mk("X") }); q.Dispatch.drive(E.I.new("Folder"), { other })
	local inner = q.Slot()
	local data = q.Source(if how == "dup key" then { "a", "a" } else { "a" })
	inner:List(data, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		if how == "updateFn throws" then error("boom") end
		if how == "Quad0156 element" then return other:Get(1) end
		return mk(ctx.Item)
	end, function(x) return x end)
	local r1 = try(function() outer:Add(inner) end)
	local st = `materializing={tostring(outer._materializing)} outer.Len={outer.Length:Get()} elements={#outer._elements}`
	local r2 = try(function() outer:Add(mk("o2")) end)
	local r3 = try(function() outer:Remove(1) end)
	row("outer:Add(listed inner) — " .. how, `add={r1} {st} | next Add={r2} | Remove={r3} outer.Len={outer.Length:Get()} kids={E.kids(p)}`)
end
-- :List installed on an already-mounted empty Slot, first cycle throws
do
	local q = E.newQ()
	local s = q.Slot()
	local p = E.I.new("Folder")
	q.Dispatch.drive(p, { s })
	local data = q.Source({ "a", "a" })
	local r = try(function() s:List(data, function(ctx) if ctx.Item == q.KeyGone then return nil end return ctx.Prev or mk(ctx.Item) end, function(x) return x end) end)
	local r2 = try(function() data:Set({ "a", "b" }) end)
	row(":List on mounted Slot, first cycle dup", `list={r} listed={s._listed} | fixed Set={r2} [{order(s)}] Len={s.Length:Get()} kids={E.kids(p)}`)
end
