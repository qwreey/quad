--!nocheck
-- E48 reference model of the documented 2-pass Claim contract (rules R1..R20 in README.md).
-- Input: a mirror prefab tree (node = { cls, name, children = {node}, preclaimed, inst }) and a
-- mirror descriptor tree (d = { cls, key, desc (real object), items = {item}, reused = bool,
-- preFired = bool, propsNonTable = bool }), item = { kind = "map", d = d } | { kind = "new" } |
-- { kind = "none" } | { kind = "badkey", d = d, key = k }.
-- Output: { ok = true, claimed = {node}, mapping = {d -> node} } or { ok = false, id = "QuadNNNN" }.
-- Precedence (NOT documented — the model's reading of "DFS 해석"): pre-order; per node
-- 0027 → 0028 → 0029 → 0030; then items in array order: 0031 (non-positive/fractional key) →
-- lookup 0032 → recurse.
local M = {}

-- R8 lookup: FindFirstChild = first child in child order with that name (R13: duplicates are UB —
-- the model follows the mock's first-match so the diff is mock-level, and flags `dupTouched`);
-- class check = equality (mock `IsA`, no hierarchy — R20 cannot be modelled here).
local function find(node, key, cls, st)
	local hits = 0
	local first
	for _, c in node.children do
		if c.name == key then
			hits += 1
			first = first or c
		end
	end
	if hits > 1 then st.dupTouched = true end
	if first == nil then return nil end
	return first
end

function M.run(rootNode, rootD)
	local st = { seen = {}, claimed = {}, mapping = {}, dupTouched = false }
	local function resolve(node, d)
		if d.preFired or st.seen[d] then error({ id = "Quad0027" }) end -- R3
		st.seen[d] = true
		if st.seen[node] then error({ id = "Quad0028" }) end -- R4
		st.seen[node] = true
		if node.preclaimed then error({ id = "Quad0029" }) end -- R5
		if d.propsNonTable then error({ id = "Quad0030" }) end -- R6
		local ordered = {}
		for _, it in d.items do if it.kind ~= "badkey" then table.insert(ordered, it) end end
		for _, it in d.items do if it.kind == "badkey" then table.insert(ordered, it) end end -- hash part after array part
		for _, it in ordered do
			if it.kind == "map" or it.kind == "badkey" then
				if it.kind == "badkey" then error({ id = "Quad0031" }) end -- R7
				local child = find(node, it.d.key, it.d.cls, st)
				if child == nil then error({ id = "Quad0032" }) end -- R8
				resolve(child, it.d)
			end
		end
		table.insert(st.claimed, node)
		st.mapping[d] = node
	end
	local ok, e = pcall(resolve, rootNode, rootD)
	if not ok then
		if type(e) ~= "table" then error(e) end
		return { ok = false, id = e.id, dupTouched = st.dupTouched }
	end
	return { ok = true, claimed = st.claimed, mapping = st.mapping, dupTouched = st.dupTouched }
end

return M
