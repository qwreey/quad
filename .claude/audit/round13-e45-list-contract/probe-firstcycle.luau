--!nocheck
-- E45: what survives a throw in the FIRST reconcile (mount) vs a later one
local E = require("./env")
local mk, row, try, order = E.mk, E.row, E.try, E.order

local function case(label, first, second, keyFn, update)
	local q = E.newQ()
	local data = q.Source(first)
	local s = q.Slot()
	s:List(data, update(q), keyFn)
	local p = E.I.new("Folder")
	local r1 = try(function() q.Dispatch.drive(p, { s }) end)
	local st1 = `[{order(s)}] Len={s.Length:Get()} obs={s._listObserver ~= nil} act={s._listActivated == true}`
	local r2 = try(function() data:Set(second) end)
	local r3 = try(function() data:Set({ "p", "q" }) end)
	row(label, `mount={r1} {st1} | set2={r2} [{order(s)}] | set3={r3} [{order(s)}] Len={s.Length:Get()} kids={E.kids(p)}`)
end
local plain = function(q) return function(ctx) if ctx.Item == q.KeyGone then return nil end if ctx.Prev then return ctx.Prev end return mk(ctx.Item) end end
local id = function(x) return x end
case("first-cycle dup key", { "a", "a" }, { "a", "b" }, id, plain)
case("first-cycle nil key", { "a" }, { "a", "b" }, function() return nil end, plain)
case("later dup key", { "a" }, { "a", "a" }, id, plain)
case("first-cycle updateFn throw", { "a", "boom", "c" }, { "a", "c" }, id, function(q) return function(ctx)
	if ctx.Item == q.KeyGone then return nil end
	if ctx.Item == "boom" then error("user boom") end
	if ctx.Prev then return ctx.Prev end
	return mk(ctx.Item) end end)
case("later updateFn throw", { "a", "c" }, { "a", "boom", "c" }, id, function(q) return function(ctx)
	if ctx.Item == q.KeyGone then return nil end
	if ctx.Item == "boom" then error("user boom") end
	if ctx.Prev then return ctx.Prev end
	return mk(ctx.Item) end end)
case("first-cycle Quad0146 (returns KeyGone)", { "a" }, { "b" }, id, function(q) return function(ctx) return q.KeyGone end end)
