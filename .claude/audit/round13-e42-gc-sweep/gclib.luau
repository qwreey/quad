--!nocheck
-- E42 GC sweep helpers: weak trackers + stabilised full collection.
local M = {}
function M.fullgc()
	local prev = -1
	for i = 1, 12 do
		collectgarbage("collect")
		local c = collectgarbage("count")
		if i >= 3 and math.abs(c - prev) < 0.5 then return c end
		prev = c
	end
	return collectgarbage("count")
end
function M.tracker(mode)
	local t = setmetatable({}, { __mode = mode or "k" })
	local self = {}
	function self.add(obj, label) if obj ~= nil and (type(obj) == "table" or type(obj) == "function" or type(obj) == "userdata" or type(obj) == "thread") then t[obj] = label or true end end
	function self.count()
		M.fullgc()
		local n, by = 0, {}
		for _, lab in t do n += 1; local l = tostring(lab); by[l] = (by[l] or 0) + 1 end
		return n, by
	end
	function self.fmt()
		local n, by = self.count()
		local parts = {}
		for k, v in by do table.insert(parts, k .. "=" .. v) end
		table.sort(parts)
		return n, table.concat(parts, ",")
	end
	return self
end
-- run scenario(N, track) for N=0 and N, report residue and KB delta (vs N=0)
function M.measure(name, scenario, N)
	N = N or 1000
	local base0 = M.fullgc()
	local tr0 = M.tracker("k")
	scenario(0, tr0.add)
	local after0 = M.fullgc()
	local tr = M.tracker("k")
	local before = M.fullgc()
	scenario(N, tr.add)
	local after = M.fullgc()
	local n, by = tr.fmt()
	local delta = (after - before) - (after0 - base0)
	print(string.format("[%s] N=%d residue=%d {%s} dKB=%.1f (N0 dKB=%.1f)", name, N, n, by, delta, after0 - base0))
	return n, delta
end
-- rounds: run the scenario R times at N, report KB after each round (monotone growth = leak of untracked objects)
function M.rounds(name, scenario, N, R)
	N = N or 1000; R = R or 4
	local start = M.fullgc()
	local out = {}
	local lastRes = 0
	for r = 1, R do
		local tr = M.tracker("k")
		scenario(N, tr.add)
		local c = M.fullgc()
		lastRes = tr.count()
		table.insert(out, string.format("%+.0f", c - start))
	end
	print(string.format("[%s] N=%d x%d cumulative dKB: %s ; last-round residue=%d", name, N, R, table.concat(out, " "), lastRes))
end
return M
