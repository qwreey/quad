--!nocheck
-- E45 axis 1: keyFn key types × cycles (first / reorder / key move / dup / KeyGone)
local E = require("./env")
local mk, row, try, order = E.mk, E.row, E.try, E.order

local function run(label, items1, items2, keyFn)
	local q = E.newQ()
	local data = q.Source(items1)
	local s = q.Slot()
	local built, gone, calls = 0, 0, {}
	s:List(data, function(ctx)
		if ctx.Item == q.KeyGone then gone += 1; return nil end
		if ctx.Prev then return ctx.Prev end
		built += 1
		return mk(tostring(ctx.Item.n))
	end, keyFn)
	local p = E.I.new("Folder")
	local r1 = try(function() q.Dispatch.drive(p, { s }) end)
	local o1 = order(s)
	local r2 = try(function() data:Set(items2) end)
	row(label, `mount={r1} [{o1}] -> set={r2} [{order(s)}] built={built} gone={gone} Len={s.Length:Get()}`)
end

local function it(n, k) return { n = n, k = k } end
local byK = function(item) return item.k end
local T1, T2 = {}, {}
local q0 = E.newQ()
local inst1, inst2 = mk("k1"), mk("k2")
local fn1 = function() end
local fn2 = function() end

run("string reorder", { it(1, "a"), it(2, "b") }, { it(2, "b"), it(1, "a") }, byK)
run("number reorder", { it(1, 10), it(2, 20) }, { it(2, 20), it(1, 10) }, byK)
run("number 0 vs -0 dup", { it(1, 0), it(2, -0) }, { it(1, 0) }, byK)
run("number 1 vs string '1'", { it(1, 1), it(2, "1") }, { it(2, "1"), it(1, 1) }, byK)
run("boolean true/false", { it(1, true), it(2, false) }, { it(2, false), it(1, true) }, byK)
run("table keys", { it(1, T1), it(2, T2) }, { it(2, T2), it(1, T1) }, byK)
run("Instance keys", { it(1, inst1), it(2, inst2) }, { it(2, inst2), it(1, inst1) }, byK)
run("function keys", { it(1, fn1), it(2, fn2) }, { it(2, fn2), it(1, fn1) }, byK)
run("q.None key (other module None)", { it(1, q0.None), it(2, "x") }, { it(2, "x"), it(1, q0.None) }, byK)
run("NaN key", { it(1, 0 / 0) }, { it(1, 0 / 0) }, byK)
run("nil key", { it(1, nil) }, { it(1, nil) }, byK)
run("dup key first cycle", { it(1, "a"), it(2, "a") }, { it(1, "a") }, byK)
run("dup key recycle", { it(1, "a") }, { it(1, "a"), it(2, "a") }, byK)
run("key move a->a2 same item", { it(1, "a"), it(2, "b") }, { it(1, "a2"), it(2, "b") }, byK)
run("KeyGone remove a", { it(1, "a"), it(2, "b") }, { it(2, "b") }, byK)
run("default index key reorder", { it(1), it(2) }, { it(2), it(1) }, nil)
run("default index key shrink", { it(1), it(2) }, { it(2) }, nil)
run("keyFn returns float 1.5", { it(1, 1.5), it(2, 2.5) }, { it(2, 2.5), it(1, 1.5) }, byK)
run("keyFn returns inf", { it(1, math.huge) }, { it(1, math.huge) }, byK)
run("keyFn returns vector/userdata(newproxy)", { it(1, newproxy()) }, { it(1, newproxy()) }, byK)

-- data items that are sentinels
do
	local q = E.newQ()
	for _, case in { { "KeyGone item (index key)", q.KeyGone }, { "None item", q.None }, { "Detach item", q.Detach } } do
		local data = q.Source({ "x", case[2], "y" })
		local s = q.Slot()
		local seen = {}
		s:List(data, function(ctx)
			table.insert(seen, (ctx.Item == q.KeyGone and "KG" or ctx.Item == q.None and "None" or ctx.Item == q.Detach and "Detach" or tostring(ctx.Item)) .. "@" .. ctx.Index)
			if ctx.Item == q.KeyGone then return nil end
			if ctx.Prev then return ctx.Prev end
			if type(ctx.Item) ~= "string" then return nil end
			return mk(ctx.Item)
		end)
		local p = E.I.new("Folder")
		local r = try(function() q.Dispatch.drive(p, { s }) end)
		row(case[1], `mount={r} [{order(s)}] updateFn saw: {table.concat(seen, " ")}`)
	end
	-- KeyGone item with an id keyFn
	local data = q.Source({ { id = "x" }, q.KeyGone })
	local s = q.Slot()
	s:List(data, function(ctx) if ctx.Item == q.KeyGone then return nil end return mk("x") end, function(item) return item.id end)
	row("KeyGone item with id keyFn", try(function() q.Dispatch.drive(E.I.new("Folder"), { s }) end))
end

-- keyFn throws / non-deterministic
do
	local q = E.newQ()
	local boom = false
	local data = q.Source({ "a", "b" })
	local s = q.Slot()
	s:List(data, function(ctx) if ctx.Item == q.KeyGone then return nil end if ctx.Prev then return ctx.Prev end return mk(ctx.Item) end,
		function(item) if boom and item == "b" then error("keyFn boom") end return item end)
	local p = E.I.new("Folder")
	q.Dispatch.drive(p, { s })
	boom = true
	local r = try(function() data:Set({ "b", "a", "c" }) end)
	local after = order(s)
	boom = false
	local r2 = try(function() data:Set({ "b", "c" }) end)
	row("keyFn throws mid-cycle", `set={r} after=[{after}] Len={s.Length:Get()} then good set={r2} [{order(s)}] Len={s.Length:Get()} kids={E.kids(p)}`)
end
do
	local q = E.newQ()
	local n = 0
	local data = q.Source({ "a", "b" })
	local s = q.Slot()
	local built, gone = 0, 0
	s:List(data, function(ctx) if ctx.Item == q.KeyGone then gone += 1 return nil end if ctx.Prev then return ctx.Prev end built += 1 return mk(ctx.Item) end,
		function(item) n += 1 return item .. n end)
	local p = E.I.new("Folder")
	q.Dispatch.drive(p, { s })
	data:Set({ "a", "b" })
	data:Set({ "a", "b" })
	row("non-deterministic keyFn (3 cycles, same data)", `built={built} gone={gone} [{order(s)}] kids={E.kids(p)}`)
end
