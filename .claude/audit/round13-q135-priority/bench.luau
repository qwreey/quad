--!nocheck
-- Q135 cost bench: one module-instance shape under several guard placements, alternated in one process.
--   before = string-key guards at FALLBACK (HEAD 644dfbd1 shape)
--   A      = guards at HIGH - 1, k-agnostic (all three buckets)          — "우선순위만"
--   B      = guards at HIGH - 1, keyType "string" (string bucket only)   — "우선순위 + 키 조건" (perf shape)
--   F      = (filter tree only) the one EarlyGuardFilter at HIGH - 1; guards stay at FALLBACK
-- Placement is applied by editing the LIVE registry entries' priority/keyType and forcing a re-sort with a
-- never-matching dummy handler (addHandler re-sorts + rebuilds the buckets), so the source tree's own choice
-- does not matter for before/A/B. In the filter tree, "before" also sinks the filter below everything.
-- Usage (repo root, after relink):  luau -O2 bench.luau -a [modes,comma,separated] [rounds]
-- ⚠️ 2026-10-01: the first version leaked every mounted mock Frame (quad's lifetime hold keeps an
-- undestroyed Instance alive) across 210 fresh module instances and was OOM-killed. Now every Instance a
-- case creates is Destroyed after its timing window, the module is dropped and a full GC runs between cases;
-- N is smaller. Run under `ulimit -v` anyway.
local E = require("../round13-e66-handlers-fuzz/env")
local args = { ... }
local MODES = string.split(args[1] or "before,A,B", ",")
local ROUNDS = tonumber(args[2]) or 5

local GUARDS = {
	RefDynamicPathGuard = true, PreRefDynamicPathGuard = true, PostRefDynamicPathGuard = true,
	ObserverDynamicPathGuard = true, EffectDynamicPathGuard = true, SlotDynamicPathGuard = true,
	TagDynamicPathGuard = true, AttrDynamicPathGuard = true, -- present only in the T variant of the tree
}
local FILTER = "EarlyGuardFilter" -- present only in the F tree

local function place(q, mode)
	local d = q.Dispatch
	for _, h in d.listHandlers() do
		if h.name == FILTER then
			h.priority = if mode == "before" then d.HANDLER_PRIORITY_FALLBACK - 2 else d.HANDLER_PRIORITY_HIGH - 1
		elseif GUARDS[h.name] and mode ~= "F" then
			if h._origKeyType == nil then h._origKeyType = h.keyType or false end
			if h._origPriority == nil then h._origPriority = h.priority end
			if mode == "before" then
				h.priority = d.HANDLER_PRIORITY_FALLBACK
				h.keyType = h._origKeyType or nil
			elseif mode == "A" then
				h.priority = d.HANDLER_PRIORITY_HIGH - 1
				h.keyType = h._origKeyType or nil
			elseif mode == "B" then
				h.priority = d.HANDLER_PRIORITY_HIGH - 1
				h.keyType = "string"
			end
		end
	end
	d.addHandler({ name = "bench-dummy", keyType = "number", isHandlable = function() return false end,
		priority = d.HANDLER_PRIORITY_FALLBACK - 10, process = function() return function() end end })
end

local cases = {}
local function case(name, n, setup) table.insert(cases, { name = name, n = n, setup = setup }) end
-- setup(q, D, keep) returns step(); every Instance it makes goes into `keep` (destroyed after timing)
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
case("emit: Event Activated swap (NORMAL-1)", 20000, function(q, D, keep)
	local f1, f2 = function() end, function() end
	local s = q.Source(f1); table.insert(keep, D.TextButton({ Activated = s }))
	local i = 0
	return function() i += 1; s:Set(if i % 2 == 0 then f1 else f2) end
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
			local q = E.newProv()
			place(q, mode)
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
local header = string.format("%-44s", `case (us/op, median of {ROUNDS})`)
for _, m in MODES do header ..= string.format(" %9s", m) end
for i = 2, #MODES do header ..= string.format(" %8s", MODES[i] .. "/" .. MODES[1]) end
print(header)
for _, c in cases do
	local line = string.format("%-44s", c.name)
	local base = median(results[c.name][MODES[1]])
	for _, m in MODES do line ..= string.format(" %9.3f", median(results[c.name][m])) end
	for i = 2, #MODES do line ..= string.format(" %8.3f", median(results[c.name][MODES[i]]) / base) end
	print(line)
end
