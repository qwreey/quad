--!nocheck
-- round13 forDebug prototype cost bench. Two trees in ONE process, modes alternated per round:
--   HEAD      = an untouched c973d9fb tree (exported with `git archive`, pesde install + relink there)
--   off       = this tree, q.debug = false  (production path: one extra field read + branch in getHandler)
--   on        = this tree, q.debug = true   (debug buckets: six string-key filters scanned)
-- Cases are round13-q135-priority/bench.luau's, without its guard-placement hacks.
-- usage (repo root, after relink in BOTH trees):
--   luau -O2 .claude/audit/round13-fordebug-proto/bench.luau -a <relpath-to-HEAD-tree-e66-env-dir> [modes] [rounds]
--   relpath is relative to THIS file, e.g. ../../../../<…>/headtree/.claude/audit/round13-e66-handlers-fuzz
-- Memory: every Instance a case creates is Destroyed after its timing window, the module instance is
-- dropped and a full GC runs between cases (the first q135 bench leaked mock Frames and was OOM-killed).
-- Run under `ulimit -v`.
local args = { ... }
local HEAD_ENV = assert(args[1], "pass the relative path to the HEAD tree's round13-e66-handlers-fuzz dir")
local MODES = string.split(args[2] or "HEAD,off,on", ",")
local ROUNDS = tonumber(args[3]) or 5

local ENVS = {
	HEAD = require(HEAD_ENV .. "/env"),
	off = require("../round13-e66-handlers-fuzz/env"),
}
ENVS.on = ENVS.off
local function newModule(mode)
	local q = ENVS[mode].newProv()
	q.debug = (mode == "on")
	return q
end

local cases = {}
local function case(name, n, setup) table.insert(cases, { name = name, n = n, setup = setup }) end
case("mount Frame, 5 string props", 4000, function(q, D, keep)
	return function() table.insert(keep, D.Frame({ Name = "a", Size = 1, Visible = true, ZIndex = 2, Position = 3 })) end
end)
case("mount Frame, 5 props + 4 inst children", 1000, function(q, D, keep)
	return function()
		table.insert(keep, D.Frame({ D.Frame({}), D.Frame({}), D.Frame({}), D.Frame({}), Name = "a", Size = 1, Visible = true, ZIndex = 2, Position = 3 }))
	end
end)
case("mount Frame, 3 State string props", 4000, function(q, D, keep)
	local a, b, c = q.Source("n"), q.Source(1), q.Source(true)
	return function() table.insert(keep, D.Frame({ Name = a, Size = b, Visible = c })) end
end)
case("emit: Name Source:Set (string key)", 20000, function(q, D, keep)
	local s = q.Source("a"); table.insert(keep, D.Frame({ Name = s }))
	local i = 0
	return function() i += 1; s:Set(if i % 2 == 0 then "a" else "b") end
end)
case("emit: Text on 8 frames (string key)", 4000, function(q, D, keep)
	local s = q.Source("a")
	for _ = 1, 8 do table.insert(keep, D.TextButton({ Text = s })) end
	local i = 0
	return function() i += 1; s:Set(if i % 2 == 0 then "a" else "b") end
end)
case("emit: Event Activated swap (fn value)", 20000, function(q, D, keep)
	local f1, f2 = function() end, function() end
	local s = q.Source(f1); table.insert(keep, D.TextButton({ Activated = s }))
	local i = 0
	return function() i += 1; s:Set(if i % 2 == 0 then f1 else f2) end
end)
case("emit: table value at string key (Size)", 20000, function(q, D, keep)
	-- a plain table stands in for engine table-ish values: passes the filters' type(v) prefilter
	local t1, t2 = { 1 }, { 2 }
	local s = q.Source(t1); table.insert(keep, D.Frame({ Size = s }))
	local i = 0
	return function() i += 1; s:Set(if i % 2 == 0 then t1 else t2) end
end)
case("emit: InstanceChild swap (number key)", 20000, function(q, D, keep)
	local a, b = D.Frame({}), D.Frame({})
	local s = q.Source(a); local p = D.Frame({ s })
	table.insert(keep, a); table.insert(keep, b); table.insert(keep, p)
	local i = 0
	return function() i += 1; s:Set(if i % 2 == 0 then a else b) end
end)
case("emit: OnChange swap (number key)", 20000, function(q, D, keep)
	local f1, f2 = function() end, function() end
	local s = q.Source(q.OnChange("Text", f1)); table.insert(keep, D.TextButton({ s }))
	local i = 0
	return function() i += 1; s:Set(q.OnChange("Text", if i % 2 == 0 then f1 else f2)) end
end)
case("emit: Tag swap (number key, FALLBACK)", 20000, function(q, D, keep)
	local t1, t2 = q.Tag("x"), q.Tag("y")
	local s = q.Source(t1); table.insert(keep, D.Frame({ s }))
	local i = 0
	return function() i += 1; s:Set(if i % 2 == 0 then t1 else t2) end
end)
case("emit: Ref swap (number key, HIGH)", 20000, function(q, D, keep)
	local r1, r2 = q.Ref(nil), q.Ref(nil)
	local s = q.Source(r1); table.insert(keep, D.Frame({ s }))
	local i = 0
	return function() i += 1; s:Set(if i % 2 == 0 then r1 else r2) end
end)

local results = {}
for _, c in cases do
	results[c.name] = {}
	for _, m in MODES do results[c.name][m] = {} end
end
for r = 1, ROUNDS do
	for mi = 1, #MODES do
		local mode = MODES[((mi + r - 2) % #MODES) + 1] -- rotate the order per round
		for _, c in cases do
			local q = newModule(mode)
			local keep = {}
			local step = c.setup(q, q.Declaration, keep)
			for _ = 1, 100 do step() end
			local t0 = os.clock()
			for _ = 1, c.n do step() end
			table.insert(results[c.name][mode], (os.clock() - t0) / c.n * 1e6)
			for _, inst in keep do inst:Destroy() end
			keep, step, q = nil, nil, nil
			collectgarbage("collect")
		end
	end
	print(`-- round {r} done, heap {math.floor(collectgarbage("count"))} KB`)
end
local function median(t) table.sort(t); return t[(#t + 1) // 2] end
local header = string.format("%-42s", `case (us/op, median of {ROUNDS})`)
for _, m in MODES do header ..= string.format(" %8s", m) end
for i = 2, #MODES do header ..= string.format(" %8s", MODES[i] .. "/" .. MODES[1]) end
print(header)
for _, c in cases do
	local line = string.format("%-42s", c.name)
	local base = median(results[c.name][MODES[1]])
	for _, m in MODES do line ..= string.format(" %8.3f", median(results[c.name][m])) end
	for i = 2, #MODES do line ..= string.format(" %8.3f", median(results[c.name][MODES[i]]) / base) end
	print(line)
end
