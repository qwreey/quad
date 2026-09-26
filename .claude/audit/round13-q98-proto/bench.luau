--!nocheck
-- P-Q98 cost bench: best-of-7 per-op microseconds.
local mock = require("./mock")
local q = mock.newQuad()
local Source = q.Source
local function best(N, f)
	local b = math.huge
	for _ = 1, 7 do
		local t0 = os.clock(); f(N); local dt = (os.clock() - t0) / N
		if dt < b then b = dt end
	end
	return string.format("%.3f", b * 1e6)
end
local s = Source(0)
local keep = {}
print("obs_install_no_emit", best(20000, function(N) for i = 1, N do keep[i] = s:Observer(function(st) st:Get() end) end end), "us")
table.clear(keep)
-- held path: many UNBOUND observers on one source; each Set hits _receive's hold branch per observer
local h = Source(0)
local hold = {}
for i = 1, 200 do hold[i] = h:Observer(function() end) end
print("set_with_200_unbound_obs", best(2000, function(N) for i = 1, N do h:Set(i) end end), "us")
-- executing path: 200 subscribed observers
local x = Source(0)
local subs = {}
for i = 1, 200 do subs[i] = x:Observer(function() end):Subscribe() end
print("set_with_200_subscribed_obs", best(2000, function(N) for i = 1, N do x:Set(i) end end), "us")
-- Compute recompute path (Q93/Q98 lines): Set + Get on a 10-deep Compute chain
local a = Source(0)
local c = a
for _ = 1, 10 do c = c:Compute(function(hh) return hh:Get() + 1 end) end
print("set+get_compute_chain10", best(20000, function(N) for i = 1, N do a:Set(i); c:Get() end end), "us")
