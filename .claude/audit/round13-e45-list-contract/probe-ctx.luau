--!nocheck
-- E45 axis 3: ctx.Index / ctx.Offset values & subscription; Offset observer throw; ctx freshness; Single; opts
local E = require("./env")
local mk, row, try, order = E.mk, E.row, E.try, E.order

-- Index values with a sibling before, nested Slot elements, nil-returning items
do
	local q = E.newQ()
	local data = q.Source({ "a", "N", "skip", "b" })
	local s = q.Slot()
	local seen, ctxs = {}, {}
	local nested = q.Slot({ mk("n1"), mk("n2"), mk("n3") })
	s:List(data, function(ctx)
		table.insert(ctxs, ctx)
		table.insert(seen, `{ctx.Item == q.KeyGone and "KG" or ctx.Item}:I{ctx.Index}:O{ctx.Offset:Get()}:isState={q.isState(ctx.Offset)}:same={ctx.Offset == s.Offset}`)
		if ctx.Item == q.KeyGone or ctx.Item == "skip" then return nil end
		if ctx.Prev then return ctx.Prev end
		if ctx.Item == "N" then return nested end
		return mk(ctx.Item)
	end, function(x) return x end)
	local before = q.Slot({ mk("B1"), mk("B2") })
	local p = E.I.new("Folder")
	q.Dispatch.drive(p, { before, s })
	row("Index/Offset first cycle", table.concat(seen, " "))
	table.clear(seen)
	data:Set({ "b", "N", "a" })
	row("Index/Offset reorder", table.concat(seen, " "))
	table.clear(seen)
	data:Set({ "b", "a" })
	row("Index/Offset drop N (KeyGone)", table.concat(seen, " "))
	row("ctx fresh per call", `distinct={ctxs[1] ~= ctxs[2]} firstItemStill={ctxs[1].Item}`)
	-- stale Index: nested grows between cycles, no reconcile
	table.clear(seen)
	local nested2 = q.Slot({ mk("m1") })
	local data2 = q.Source({ "x", "M", "y" })
	local s2 = q.Slot()
	local lastIndex = {}
	s2:List(data2, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		lastIndex[ctx.Item] = ctx.Index
		if ctx.Prev then return ctx.Prev end
		if ctx.Item == "M" then return nested2 end
		return mk(ctx.Item)
	end, function(x) return x end)
	q.Dispatch.drive(E.I.new("Folder"), { s2 })
	local y1 = lastIndex.y
	nested2:Add(mk("m2"))
	row("Index is a snapshot (nested grows, no cycle)", `y Index at cycle={y1}, y actual pos now={s2.Offset:Get() + 1 + 2} (Index not updated, number={type(lastIndex.y) == "number"})`)
end

-- Offset subscription fires when a sibling before grows; throwing observer freezes parent
do
	local q = E.newQ()
	local before = q.Slot({ mk("B1") })
	local data = q.Source({ "a" })
	local s = q.Slot()
	local fired, throwNow = 0, false
	s:List(data, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		if ctx.Prev then return ctx.Prev end
		ctx.Offset:Observer(function(o) fired += 1; if throwNow then error("offset obs boom") end end)
		return mk(ctx.Item)
	end)
	local after = q.Slot({ mk("A1") })
	local p = E.I.new("Folder")
	q.Dispatch.drive(p, { before, s, after })
	local f0 = fired
	before:Add(mk("B2"))
	row("Offset observer fires on sibling growth", `fired before={f0} after Add={fired} Offset={s.Offset:Get()} afterOffset={after.Offset:Get()}`)
	throwNow = true
	local r = try(function() before:Add(mk("B3")) end)
	throwNow = false
	local r2 = try(function() before:Add(mk("B4")) end)
	row("Offset observer throws (core/06:129)", `add={r} then add={r2} s.Offset={s.Offset:Get()} (expect 4) after.Offset={after.Offset:Get()} (expect 5) before.Len={before.Length:Get()}`)
end

-- :Single representative cells
do
	local q = E.newQ()
	local cur = q.Source("x")
	local s = q.Slot()
	local log, made = {}, 0
	s:Single(cur, function(ctx)
		table.insert(log, `{ctx.Item == q.KeyGone and "KG" or tostring(ctx.Item)}:prev={ctx.Prev and ctx.Prev.Name or "nil"}:ud={tostring(ctx.UserData)}:I{ctx.Index}`)
		if ctx.Item == q.KeyGone then return q.Detach, "held" end
		if ctx.Prev then ctx.Prev.Name = ctx.Item; return ctx.Prev, "u" end
		made += 1
		return mk(ctx.Item), "u0"
	end)
	local p = E.I.new("Folder")
	q.Dispatch.drive(p, { s })
	cur:Set("y"); cur:Set(nil); cur:Set(q.None); cur:Set("z")
	row(":Single keep/KeyGone/Detach/return", `made={made} [{order(s)}] log {table.concat(log, " ")}`)
	-- identity Single: replacement ("통째로 교체")
	local q2 = E.newQ()
	local a, b = mk("A"), mk("B")
	local c2 = q2.Source(a)
	local s2 = q2.Slot():Single(c2)
	q2.Dispatch.drive(E.I.new("Folder"), { s2 })
	c2:Set(b)
	row(":Single identity swap", `A dead={E.dead(a)} B mounted={s2:Get(1) == b}`)
	-- identity Single same instance re-set
	local r = try(function() c2:Set(b) end)
	row(":Single identity Set same value", r)
end

-- opts
do
	local q = E.newQ()
	for _, o in { { OwnsElements = "false" }, { OwnsElements = 0 }, { OwnsElements = nil }, { Owned = false }, {} } do
		local data = q.Source({ "a" })
		local s = q.Slot()
		local made
		s:List(data, function(ctx) if ctx.Item == q.KeyGone then return nil end made = made or mk("a"); return ctx.Prev or made end, nil, o)
		q.Dispatch.drive(E.I.new("Folder"), { s })
		data:Set({})
		local k = next(o)
		row("opts " .. tostring(k) .. "=" .. tostring(o[k or ""]), `owned flag={tostring(s._owned)} element destroyed on KeyGone={E.dead(made)}`)
	end
	q.debug = true
	local s = q.Slot()
	s:List({}, function() end, nil, { Owned = false, ownsElements = false })
	q.debug = false
end
