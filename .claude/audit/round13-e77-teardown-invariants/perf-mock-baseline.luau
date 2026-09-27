--!nocheck
-- E77 perf control: the mock alone (no quad) — parent with n children (each with 2 grandchildren), Destroy.
-- Separates the mock's own O(n) sibling `table.find` on unparenting from quad's teardown cost.
local H = require("./harness")
local mock = H.mock
for _, n in { 100, 400, 1600, 6400 } do
	local ts = {}
	for _ = 1, 3 do
		collectgarbage("collect")
		local root = mock.Instance.new("Frame")
		for i = 1, n do
			local c = mock.Instance.new("Frame"); c.Parent = root
			local g1 = mock.Instance.new("TextLabel"); g1.Parent = c
			local g2 = mock.Instance.new("Frame"); g2.Parent = c
		end
		local t0 = os.clock(); root:Destroy(); table.insert(ts, os.clock() - t0)
	end
	table.sort(ts)
	print(string.format("mock-only Destroy n=%6d  %8.2f ms  per unit %6.2f us", n, ts[2] * 1000, ts[2] * 1e6 / n))
end
