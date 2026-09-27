--!nocheck
-- E72 perf 2: width sweep with the mock's own (offset-ignoring) native ops, best of 5 — is the top-level shift
-- superlinear in the number of seat Slots? Also D=1 (flat seats) and "seat Slots inside ONE wrapper Slot".
local E = require("./env")
local I = E.mock.Instance
local function leaf() return I.new("Frame") end
local function chain(q, D)
	local child
	for d = D, 1, -1 do
		local items = { leaf(), leaf() }
		if child then table.insert(items, child) end
		child = q.Slot(items)
	end
	return child
end
local function run(W, D, wrap)
	local q = E.newBase({ plainNative = true })
	local host = I.new("Frame")
	local front = q.Slot({ leaf() })
	local seats = {}
	for w = 1, W do seats[w] = chain(q, D) end
	local props = { front }
	if wrap then table.insert(props, q.Slot(seats)) else for _, s in ipairs(seats) do table.insert(props, s) end end
	collectgarbage("collect")
	local t0 = os.clock(); q.Dispatch.drive(host, props); local tm = os.clock() - t0
	local best = math.huge
	for _ = 1, 5 do
		collectgarbage("collect")
		local t1 = os.clock(); front:Add(leaf(), 1); best = math.min(best, os.clock() - t1)
	end
	return tm, best
end
print("# frontAdd best-of-5 (us) and per-Slot cost (ns) — mock native ops (offsets ignored)")
for _, cfg in ipairs({ { 1, false }, { 6, false }, { 6, true } }) do
	local D, wrap = cfg[1], cfg[2]
	print(`## D={D} {if wrap then "(W chains inside ONE wrapper Slot)" else "(W chains as host seats)"}`)
	for _, W in ipairs({ 16, 64, 256, 1024, 2048 }) do
		local tm, tf = run(W, D, wrap)
		print(`W={W} slots={W * D} mount {string.format("%.1f", tm * 1e3)} ms | frontAdd {string.format("%.0f", tf * 1e6)} us = {string.format("%.0f", tf * 1e9 / (W * D))} ns/slot`)
	end
end
