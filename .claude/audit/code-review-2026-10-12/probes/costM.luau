--!nocheck
local mock = require("./mock")
local q = mock.newQuad()
local function F() return mock.Instance.new("Frame") end
local function run(depth, n)
	local host = F()
	local top = q.Slot()
	local cur = top
	for _ = 2, depth do local c = q.Slot(); cur:Add(c); cur = c end
	q.Dispatch.drive(host, { top })
	local els = table.create(n)
	for i = 1, n do els[i] = F() end
	local t0 = os.clock()
	for i = 1, n do cur:Add(els[i]) end
	local t1 = os.clock()
	for i = n, 1, -1 do cur:Extract(i) end
	local t2 = os.clock()
	return (t1 - t0) / n * 1e6, (t2 - t1) / n * 1e6
end
for _, depth in { 1, 4, 8 } do
	local bestA, bestE = math.huge, math.huge
	for _ = 1, 7 do local a, e = run(depth, 2000); bestA = math.min(bestA, a); bestE = math.min(bestE, e) end
	print(string.format("depth %d  Add %.3f us  Extract %.3f us", depth, bestA, bestE))
end
