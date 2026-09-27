--!nocheck
-- E77 perf attribution: plain D.Frame children (no attachments) under (a) a :List, (b) static numeric children,
-- (c) a manual Slot; dispose(root). Compare per-unit growth with out-perf-mock-baseline.txt.
local H = require("./harness")
local q, D = H.q, H.D
local function leaf(i) return D.Frame({ Name = "c" .. i, D.TextLabel({}), D.Frame({}) }) end
local shapes = {
	list = function(n) local keys = {}; for i = 1, n do keys[i] = i end
		return D.Frame({ q.Slot():List(q.Source(keys), function(ctx) if ctx.Item == q.KeyGone then return nil end return ctx.Prev or leaf(ctx.Item) end) }) end,
	static = function(n) local p = {}; for i = 1, n do p[i] = leaf(i) end; return D.Frame(p) end,
	slot = function(n) local els = {}; for i = 1, n do els[i] = leaf(i) end; return D.Frame({ q.Slot(els) }) end,
}
for _, name in { "static", "slot", "list" } do
	for _, n in { 100, 400, 1600, 6400 } do
		local ts = {}
		for _ = 1, 3 do
			collectgarbage("collect")
			local root = shapes[name](n)
			local t0 = os.clock(); q.dispose(root); table.insert(ts, os.clock() - t0)
		end
		table.sort(ts)
		print(string.format("%-6s n=%6d  dispose %8.2f ms  per unit %6.2f us", name, n, ts[2] * 1000, ts[2] * 1e6 / n))
	end
end
