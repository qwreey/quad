--!nocheck
-- round13 forDebug prototype: dynamic toggle, repeat suppression, registration gate, a debug-only REAL handler.
-- usage (repo root, after relink): luau .claude/audit/round13-fordebug-proto/probe-toggle.luau
local H = require("../round13-e44-ref-statemachine/harness")
local q, D = H.q, H.D

-- capture the filters' print: every filter's isHandlable lives in DebugKeyFilter.luau, so one env
local captured = {}
local filter
for _, h in q.Dispatch.listHandlers() do
	if h.name == "RefStringKeyDebugFilter" then filter = h end
end
assert(filter and filter.forDebug == true, "filter registered with forDebug = true")
local realPrint = print
getfenv(filter.isHandlable).print = function(...) table.insert(captured, table.concat({ ... }, " ")) end
local function count() return #captured end
local function check(label, cond, extra)
	realPrint((if cond then "PASS " else "FAIL ") .. label .. (if extra then "  [" .. tostring(extra) .. "]" else ""))
end
local made = {}
local function frame(props) local f = D.Frame(props); table.insert(made, f); return f end

-- 1. debug off: misuse is silent (HEAD behavior), no line
q.debug = false
do
	local r = q.Ref(nil); local f = frame { Size = r }
	check("1 off: no warning, value still assigned (HEAD behavior)", count() == 0 and f.Size == r, count())
end
-- 2. turn on: same misuse warns once, behavior identical
q.debug = true
do
	local r = q.Ref(nil); local f = frame { Size = r }
	check("2 on: one warning, value still assigned", count() == 1 and f.Size == r, captured[#captured])
end
-- 3. repeat suppression: the same (inst, key) re-emitted by a State prints once
do
	local before = count()
	local s = q.Source(q.Ref(nil)); local f = frame { Size = s }
	for _ = 1, 50 do s:Set(q.Ref(nil)) end
	check("3 on: 51 emits at one (inst, key) -> one line", count() - before == 1, count() - before)
	-- another key on the same instance is a separate line
	local s2 = q.Source(q.Tag("t")); f2 = frame { Name = "x" }
	before = count()
	local g = frame { Visible = s2 }
	check("3b on: another (inst, key) -> its own line", count() - before == 1, count() - before)
end
-- 4. toggle off while a bound State keeps emitting: no lines, behavior unchanged
do
	local s = q.Source(q.Ref(nil)); local f = frame { Size = s }
	local before = count()
	q.debug = false
	for _ = 1, 10 do s:Set(q.Ref(nil)) end
	local last = q.Ref(nil); s:Set(last)
	check("4 toggled off mid-life: no lines, value tracks", count() == before and f.Size == last, count() - before)
	-- 5. back on: the next emit on a NEW key is scanned with the debug buckets again (read at call time)
	q.debug = true
	local s3 = q.Source(1); local f3 = frame { Size = s3 }
	before = count()
	s3:Set(q.Effect(function() end))
	check("5 toggled on again: the next emit warns", count() - before == 1, captured[#captured])
end
-- 6. number keys are never inspected (the filters declare keyType = "string")
do
	local before = count()
	local r = q.Ref(nil); local f = frame { r, q.Tag("a"), q.Attr({ a = 1 }), q.Slot(), q.Source(1):Observer(function() end) }
	check("6 on: number keys -> no line", count() == before and r.Value == f, count() - before)
end
-- 7. registration gate: forDebug must be boolean or nil
do
	local ok, e = pcall(q.Dispatch.addHandler, { isHandlable = function() return false end, priority = 0,
		process = function() return q.Void end, forDebug = "yes" })
	check("7 forDebug = \"yes\" rejected with Quad0266", not ok and tostring(e):find("Quad0266") ~= nil, (tostring(e):gsub("\n.*", "")))
end
-- 8. a debug-only REAL handler (returns true): takes a key only while debug is on
do
	local hits = 0
	q.Dispatch.addHandler({ name = "ProbeDebugOnlyReal", forDebug = true, keyType = "string",
		isHandlable = function(_i, k) return k == "DbgOnly" end, priority = q.Dispatch.HANDLER_PRIORITY_NORMAL + 5,
		process = function() hits += 1; return q.Void end })
	q.debug = true
	local ok1 = pcall(function() frame { DbgOnly = 1 } end)
	q.debug = false
	local ok2, e2 = pcall(function() frame { DbgOnly = 1 } end)
	check("8 debug-only real handler: on -> handled, off -> no match", ok1 and hits == 1 and not ok2,
		(tostring(e2):match("Quad%d+") or tostring(e2)))
end
-- 9. tie print: a provider registering at the filters' priority while debug is on sees the tie line
do
	q.debug = true
	local lines = {}
	local env = getfenv(q.Dispatch.addHandler)
	local old = env.print
	-- Dispatch's own print is in Dispatch/init.luau's env (addHandler is tagged, not wrapped)
	env.print = function(...) table.insert(lines, table.concat({ ... }, " ")) end
	q.Dispatch.addHandler({ name = "ProbeAtFilterPriority", keyType = "string", isHandlable = function() return false end,
		priority = q.Dispatch.HANDLER_PRIORITY_NORMAL + 2, process = function() return q.Void end })
	env.print = old
	check("9 provider tie with a debug filter is reported in debug", #lines == 1, lines[1])
	q.debug = false
end
-- 10. listHandlers shows the debug handlers with their field
do
	local n = 0
	for _, h in q.Dispatch.listHandlers() do if h.forDebug then n += 1 end end
	check("10 listHandlers includes forDebug handlers", n == 7, n) -- six filters + ProbeDebugOnlyReal
end
realPrint("captured lines:")
for _, l in captured do realPrint("  " .. l) end
for _, f in made do f:Destroy() end
