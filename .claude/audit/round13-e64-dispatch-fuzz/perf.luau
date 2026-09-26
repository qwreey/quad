--!nocheck
-- axis (e): 50 user handlers x 1000 slots — process/reprocess/retract cost, vs 0 extra handlers
local E = require("./env")
local function run(nExtra, keyType)
	local q = E.newBase()
	local D = q.Dispatch
	local t0 = os.clock()
	for i = 1, nExtra do
		D.addHandler({ name = "X" .. i, priority = (i % 7) * 100 - 300, keyType = keyType,
			isHandlable = function(_, k, v) return v == i end, process = function() return q.Void end })
	end
	local tReg = os.clock() - t0
	D.addHandler({ name = "Leaf", priority = -2000, isHandlable = function(_, _, v) return type(v) == "string" end,
		process = function(inst, k) if type(k) == "number" then q.Bookkeeping.setEmpty(inst, k) end return q.Void end })
	local inst = E.mock.Instance.new("Frame")
	local keys = {}
	for i = 1, 1000 do keys[i] = "K" .. i end
	t0 = os.clock()
	for _, k in keys do D.process(inst, k, "a", 1) end
	for _, k in keys do D.process(inst, k, "b", 1) end
	for _, k in keys do D.retractFrom(inst, k, 1) end
	local tStr = os.clock() - t0
	local inst2 = E.mock.Instance.new("Frame")
	local props = {}
	for i = 1, 1000 do props[i] = "a" end
	t0 = os.clock()
	D.drive(inst2, props)
	local tDrive = os.clock() - t0
	return tReg, tStr, tDrive
end
for _, cfg in { { 0, nil }, { 50, nil }, { 50, "number" }, { 200, nil } } do
	local best = { math.huge, math.huge, math.huge }
	for _ = 1, 5 do
		local a, b, c = run(cfg[1], cfg[2])
		best = { math.min(best[1], a), math.min(best[2], b), math.min(best[3], c) }
	end
	print(string.format("extra=%3d keyType=%-6s addHandler total %.2f ms | 1000 string keys x (process+reprocess+retract) %.2f ms (%.2f us/op) | drive 1000 array slots %.2f ms",
		cfg[1], tostring(cfg[2]), best[1] * 1000, best[2] * 1000, best[2] * 1e6 / 3000, best[3] * 1000))
end
