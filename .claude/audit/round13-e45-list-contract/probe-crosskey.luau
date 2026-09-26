--!nocheck
-- E45 (c): an element handed to ANOTHER key; later-cycle quad-raised throws; ghost wrapper
local E = require("./env")
local mk, row, try, order = E.mk, E.row, E.try, E.order

-- 1) rename: new key returns the old key's element (captured), old key still in last cycle's set
do
	local q = E.newQ()
	local byName = {}
	local data = q.Source({ "a", "b" })
	local s = q.Slot()
	s:List(data, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		if ctx.Prev then return ctx.Prev end
		local stem = string.sub(ctx.Item, 1, 1)
		if byName[stem] then return byName[stem] end -- "rename" reuse
		local f = mk(ctx.Item); byName[stem] = f; return f
	end)  -- index keys? no: use identity keys
	-- (identity keyFn below)
end
local function mkList(q, data, fn, owns)
	local s = q.Slot()
	s:List(data, fn, function(x) return x end, owns ~= nil and { OwnsElements = owns } or nil)
	local p = E.I.new("Folder")
	q.Dispatch.drive(p, { s })
	return s, p
end
for _, owns in { true, false } do
	local q = E.newQ()
	local byStem = {}
	local data = q.Source({ "a", "b" })
	local s, p = mkList(q, data, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		if ctx.Prev then return ctx.Prev end
		local stem = string.sub(ctx.Item, 1, 1)
		if byStem[stem] then return byStem[stem] end
		local f = mk(ctx.Item); byStem[stem] = f; return f
	end, owns)
	local r = try(function() data:Set({ "a2", "b" }) end)
	local L1 = s.Length:Get()
	local r2 = try(function() data:Set({ "a2", "b", "c" }) end)
	row("rename reuse a->a2 (old key still live) owns=" .. tostring(owns), `set={r} Len={L1} [{order(s)}] | next set={r2} Len={s.Length:Get()} [{order(s)}] kids={E.kids(p)} aDead={E.dead(byStem.a)}`)
end

-- 2) rename via Detach first: a is Detached (held), then new key a2 returns the held element
for _, owns in { true, false } do
	local q = E.newQ()
	local store = {}
	local data = q.Source({ "a" })
	local s, p = mkList(q, data, function(ctx)
		if ctx.Item == q.KeyGone then return q.Detach end
		if ctx.Prev then return ctx.Prev end
		if store.a then return store.a end
		store.a = mk(ctx.Item); return store.a
	end, owns)
	data:Set({})
	local r = try(function() data:Set({ "a2" }) end)
	row("held(Detach) element returned under new key owns=" .. tostring(owns), `set={r} Len={s.Length:Get()} [{order(s)}] kids={E.kids(p)} dead={E.dead(store.a)}`)
end

-- 3) swap: key a returns b's element and b returns a's (same cycle)
do
	local q = E.newQ()
	local els = {}
	local swap = false
	local data = q.Source({ "a", "b" })
	local s, p = mkList(q, data, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		if not els[ctx.Item] then els[ctx.Item] = mk(ctx.Item) end
		if swap then return els[ctx.Item == "a" and "b" or "a"] end
		return els[ctx.Item]
	end)
	swap = true
	local r = try(function() data:Set({ "a", "b" }) end)
	local L = s.Length:Get()
	swap = false
	local r2 = try(function() data:Set({ "a", "b", "z" }) end)
	row("swap elements between keys", `set={r} Len={L} [{order(s)}]; after un-swap set={r2} Len={s.Length:Get()} [{order(s)}] kids={E.kids(p)} blocking={q.Bookkeeping and "?" or ""}`)
end

-- 4) later-cycle quad-raised throw: Length freeze doc claim (06-slot.md:386)
do
	local q = E.newQ()
	local other = q.Slot({ mk("O") }); q.Dispatch.drive(E.I.new("Folder"), { other })
	local data = q.Source({ "a" })
	local s, p = mkList(q, data, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		if ctx.Item == "bad" then return other:Get(1) end
		if ctx.Prev then return ctx.Prev end
		return mk(ctx.Item)
	end)
	local sib = q.Slot({ mk("S1") })
	local r = try(function() data:Set({ "a", "bad" }) end)
	local r2 = try(function() data:Set({ "a", "b", "c" }) end)
	row("later-cycle 0156 then good set", `set={r} then={r2} Len={s.Length:Get()} (elements {#s._elements}) [{order(s)}] kids={E.kids(p)}`)
end

-- 5) State with bad occupant at a later cycle: ghost wrapper?
do
	local q = E.newQ()
	local data = q.Source({ "a" })
	local s, p = mkList(q, data, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		if ctx.Item == "bad" then return q.Source({}) end
		if ctx.Prev then return ctx.Prev end
		return mk(ctx.Item)
	end)
	local r = try(function() data:Set({ "a", "bad" }) end)
	local st = `elements={#s._elements} [{order(s)}] Len={s.Length:Get()}`
	local r2 = try(function() data:Set({ "a" }) end)
	row("later-cycle State<table> return", `set={r} {st} | then set a={r2} elements={#s._elements} [{order(s)}] Len={s.Length:Get()} kids={E.kids(p)}`)
	-- compare CRUD path
	local s2 = q.Slot(); q.Dispatch.drive(E.I.new("Folder"), { s2 })
	local r3 = try(function() s2:Add(q.Source({})) end)
	row("CRUD Add(State<table>) same value", `add={r3} elements={#s2._elements}`)
end

-- 6) Prev of a State element returned as the State vs returning its occupant Instance
do
	local q = E.newQ()
	local st = q.Source(mk("occ"))
	local mode = "state"
	local data = q.Source({ "a" })
	local s, p = mkList(q, data, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		if ctx.Prev and mode == "state" then return ctx.Prev end
		if mode == "occupant" then return st:Get() end
		return st
	end)
	local prevType = "?"
	local r = try(function() data:Set({ "a" }) end)
	mode = "occupant"
	local r2 = try(function() data:Set({ "a" }) end)
	row("State element: return Prev(State) / then its occupant Instance", `keep={r} occupant={r2} Len={s.Length:Get()} [{order(s)}] kids={E.kids(p)}`)
end
