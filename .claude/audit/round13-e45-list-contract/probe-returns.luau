--!nocheck
-- E45 axis 2: updateFn return shapes × OwnsElements × cycle (first / recycle)
local E = require("./env")
local mk, row, try, order = E.mk, E.row, E.try, E.order

-- ret(q, ctx, env) -> result, ud ; env holds helpers made per run
local function run(label, owns, ret, cycles)
	local q = E.newQ()
	local env = { q = q, log = {} }
	env.other = q.Slot({ mk("otherEl") })
	env.otherHost = E.I.new("Folder")
	q.Dispatch.drive(env.otherHost, { env.other })
	env.deadInst = mk("dead"); env.deadInst:Destroy()
	env.foreign = E.mock.Instance.foreign and E.mock.Instance.foreign("Frame") or nil
	env.deadSlot = q.Slot(); q.dispose(env.deadSlot)
	env.state = q.Source(mk("stateEl"))
	env.nested = q.Slot({ mk("n1"), mk("n2") })
	local data = q.Source(cycles[1])
	local s = q.Slot()
	env.self = s
	s:List(data, function(ctx)
		local r, ud = ret(q, ctx, env)
		table.insert(env.log, `{ctx.Item == q.KeyGone and "KG" or tostring(ctx.Item)}:prev={ctx.Prev and (ctx.Prev.Name or "tbl") or "nil"},ud={tostring(ctx.UserData)},i={ctx.Index}`)
		return r, ud
	end, nil, if owns == nil then nil else { OwnsElements = owns })
	local p = E.I.new("Folder")
	local out = { try(function() q.Dispatch.drive(p, { s }) end) .. `[{order(s)}]L{s.Length:Get()}` }
	for c = 2, #cycles do
		local r = try(function() data:Set(cycles[c]) end)
		table.insert(out, r .. `[{order(s)}]L{s.Length:Get()}`)
	end
	row(label .. (owns == false and " (Owns=false)" or ""), table.concat(out, " -> ") .. " | kids=" .. E.kids(p) .. " | log " .. table.concat(env.log, " "))
	return env
end

local function base(q, ctx) if ctx.Item == q.KeyGone then return nil end if ctx.Prev then return ctx.Prev end return mk(ctx.Item) end
for _, owns in { true, false } do
	-- keep Prev / fresh each time (replace)
	local made = {}
	local env = run("fresh element every cycle", owns, function(q, ctx) if ctx.Item == q.KeyGone then return nil end local f = mk(ctx.Item .. "#" .. (#made + 1)); table.insert(made, f); return f end, { { "a" }, { "a" } })
	row("  replaced old destroyed?" .. tostring(owns), `old dead={E.dead(made[1])} old parent={tostring(made[1].Parent)}`)
	-- nil drop while item present
	local kept
	run("nil return for present item (2nd cycle)", owns, function(q, ctx, env) if ctx.Item == q.KeyGone then return nil end if env.drop then return nil end if ctx.Prev then return ctx.Prev end kept = mk(ctx.Item); env.drop = true; return kept end, { { "a" }, { "a" }, { "a" } })
	row("  dropped element dead?" .. tostring(owns), `dead={E.dead(kept)} parent={tostring(kept.Parent)}`)
	-- nil, ud
	run("(nil, ud) then (Prev?)", owns, function(q, ctx) if ctx.Item == q.KeyGone then return nil, "gone-ud" end if ctx.UserData == nil then return nil, "U1" end return (ctx.Prev or mk(ctx.Item)), "U2" end, { { "a" }, { "a" }, {}, { "a" } })
	-- None
	run("q.None return", owns, function(q, ctx) return q.None end, { { "a" }, { "a" } })
	-- Detach then reappear
	local held
	run("Detach via KeyGone, reappear", owns, function(q, ctx) if ctx.Item == q.KeyGone then return q.Detach, "held-ud" end if ctx.Prev then return ctx.Prev, ctx.UserData end held = mk(ctx.Item); return held, "ud0" end, { { "a" }, {}, { "a" } })
	row("  held element dead/parent " .. tostring(owns), `dead={E.dead(held)} parent={tostring(held.Parent)}`)
	-- Detach for present item, then return Prev
	run("Detach present item then Prev", owns, function(q, ctx, env) if ctx.Item == q.KeyGone then return nil end env.n = (env.n or 0) + 1 if env.n == 2 then return q.Detach end if ctx.Prev then return ctx.Prev end return mk(ctx.Item) end, { { "a" }, { "a" }, { "a" } })
	-- Detach, then NEW element on reappear (held destroyed?)
	local held2
	run("Detach then new element", owns, function(q, ctx, env) if ctx.Item == q.KeyGone then return q.Detach end env.n = (env.n or 0) + 1 local f = mk(ctx.Item .. env.n); if env.n == 1 then held2 = f end return f end, { { "a" }, {}, { "a" } })
	row("  held2 after new element " .. tostring(owns), `dead={E.dead(held2)} parent={tostring(held2.Parent)}`)
	-- Detach first cycle (no prev)
	run("Detach with no Prev", owns, function(q, ctx) return q.Detach end, { { "a" }, { "a" } })
	-- Detach held, then slot disposed
	do
		local q = E.newQ()
		local data = q.Source({ "a" })
		local s = q.Slot()
		local h
		s:List(data, function(ctx) if ctx.Item == q.KeyGone then return q.Detach end if ctx.Prev then return ctx.Prev end h = mk("h"); return h end, nil, { OwnsElements = owns })
		local p = E.I.new("Folder")
		q.Dispatch.drive(p, { s })
		data:Set({})
		local r = try(function() q.dispose(s) end)
		local r2 = try(function() p:Destroy() end)
		row("Detach held then dispose(slot) / host Destroy " .. tostring(owns), `dispose={r} host={r2} held dead={E.dead(h)}`)
	end
end

-- invalid returns (owned only; cycle 2 = recycle)
local invalid = {
	{ "plain table", function(q, ctx, env) return {} end },
	{ "number", function() return 42 end },
	{ "string", function() return "x" end },
	{ "KeyGone", function(q) return q.KeyGone end },
	{ "Observer", function(q) return q.Source(1):Observer(function() end) end },
	{ "destroyed Instance", function(q, ctx, env) return env.deadInst end },
	{ "foreign Instance", function(q, ctx, env) return env.foreign end },
	{ "destroyed Slot", function(q, ctx, env) return env.deadSlot end },
	{ "other Slot's element", function(q, ctx, env) return env.other:Get(1) end },
	{ "Slot mounted elsewhere", function(q, ctx, env) return env.other end },
	{ "own Slot (self)", function(q, ctx, env) return env.self end },
	{ "State element", function(q, ctx, env) if ctx.Item == q.KeyGone then return nil end return env.state end },
	{ "nested Slot", function(q, ctx, env) if ctx.Item == q.KeyGone then return nil end if ctx.Prev then return ctx.Prev end return env.nested end },
	{ "State<nil>", function(q, ctx) if ctx.Item == q.KeyGone then return nil end return q.Source(nil) end },
	{ "State<Slot>", function(q, ctx, env) if ctx.Item == q.KeyGone then return nil end return q.Source(q.Slot({ mk("inS") })) end },
	{ "State of plain table", function(q, ctx) if ctx.Item == q.KeyGone then return nil end return q.Source({}) end },
	{ "nil, ud then KeyGone->new element", function(q, ctx) if ctx.Item == q.KeyGone then return mk("x") end return mk("a") end },
}
for _, c in invalid do
	run("ret " .. c[1], nil, c[2], { { "a" }, {} })
end
