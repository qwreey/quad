--!nocheck
-- E45 3(a): Offset subscription made inside updateFn (held strongly), sibling growth, throw → freeze
local E = require("./env")
local mk, row, try, order = E.mk, E.row, E.try, E.order
for _, variant in { "held", "unheld" } do -- held = :Subscribe() (strong keep), unheld = not subscribed (canExecute false)
	local q = E.newQ()
	local keep = {}
	local before = q.Slot({ mk("B1") })
	local data = q.Source({ "a" })
	local s = q.Slot()
	local fired, throwNow = 0, false
	s:List(data, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		if ctx.Prev then return ctx.Prev end
		local o = ctx.Offset:Observer(function() fired += 1; if throwNow then error("offset obs boom") end end)
		if variant == "held" then o:Subscribe() else table.insert(keep, o) end
		return mk(ctx.Item)
	end)
	local after = q.Slot({ mk("A1") })
	local p = E.I.new("Folder")
	q.Dispatch.drive(p, { before, s, after })
	local f0 = fired
	before:Add(mk("B2"))
	row(variant .. ": Offset observer fires on sibling growth", `fired mount={f0} after Add={fired} s.Offset={s.Offset:Get()} after.Offset={after.Offset:Get()}`)
	throwNow = true
	local r = try(function() before:Add(mk("B3")) end)
	throwNow = false
	local snap1 = `s.Offset={s.Offset:Get()} (true 3) after.Offset={after.Offset:Get()} (true 4)`
	local r2 = try(function() before:Add(mk("B4")) end)
	local snap2 = `s.Offset={s.Offset:Get()} (true 4) after.Offset={after.Offset:Get()} (true 5)`
	local r3 = try(function() data:Set({ "a", "b" }) end)
	local snap3 = `after.Offset={after.Offset:Get()} (true 6) s.Len={s.Length:Get()}`
	local r4 = try(function() after:Add(mk("A2")) end)
	row(variant .. ": Offset observer throws", `add={r} {snap1} | add={r2} {snap2} | data set={r3} {snap3} | after:Add={r4} after.Len={after.Length:Get()} kids={#p:GetChildren()} fired={fired}`)
end
