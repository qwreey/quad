--!nocheck
-- obs-eff-unify cost bench: best-of-9 per-op microseconds (obs-eff-root bench + derived-dep rows).
local mock = require("./mock")
local q = mock.newQuad()
local Source, Effect = q.Source, q.Effect
local function best(N, f)
	local b = math.huge
	for _ = 1, 9 do
		local t0 = os.clock(); f(N); local dt = (os.clock() - t0) / N
		if dt < b then b = dt end
	end
	return string.format("%.3f", b * 1e6)
end
local out = {}
local function rec(name, v) table.insert(out, name .. "=" .. v) end
local s = Source(0)
local keep = {}
rec("obs_install", best(20000, function(N) for i = 1, N do keep[i] = s:Observer(function(st) st:Get() end) end end))
table.clear(keep)
local cs = Source(0)
local cc = cs:Compute(function(v) return v:Get() end)
rec("obs_install_on_compute", best(20000, function(N) for i = 1, N do keep[i] = cc:Observer(function(st) st:Get() end) end end))
table.clear(keep)
local h = Source(0)
local hold = {}
for i = 1, 200 do hold[i] = h:Observer(function() end) end
rec("set_200_unbound_obs", best(2000, function(N) for i = 1, N do h:Set(i) end end))
local x = Source(0)
local subs = {}
for i = 1, 200 do subs[i] = x:Observer(function() end):Subscribe() end
rec("set_200_subscribed_obs_on_source", best(2000, function(N) for i = 1, N do x:Set(i) end end))
local y = Source(0)
local yc = y:Compute(function(v) return v:Get() end)
local subs2 = {}
for i = 1, 200 do subs2[i] = yc:Observer(function() end):Subscribe() end
rec("set_200_subscribed_obs_on_compute", best(2000, function(N) for i = 1, N do y:Set(i) end end))
local a, b, c = Source(0), Source(0), Source(0)
local effs = {}
for i = 1, 100 do effs[i] = Effect(function() a:Get(); b:Get(); c:Get() end, a, b, c):Subscribe() end
rec("set_100_effects_3_source_deps", best(2000, function(N) for i = 1, N do a:Set(i) end end))
local ca, cb = a:Compute(function(v) return v:Get() end), b:Compute(function(v) return v:Get() end)
local effs2 = {}
for i = 1, 100 do effs2[i] = Effect(function() ca:Get(); cb:Get() end, ca, cb):Subscribe() end
rec("set_100_effects_2_compute_deps", best(2000, function(N) for i = 1, N do b:Set(i) end end))
rec("effect_install_3_deps", best(5000, function(N) for i = 1, N do keep[i] = Effect(function() end, a, b, c) end end))
table.clear(keep)
rec("effect_install_2_compute_deps", best(5000, function(N) for i = 1, N do keep[i] = Effect(function() end, ca, cb) end end))
table.clear(keep)
collectgarbage("collect")
local m0 = collectgarbage("count")
for i = 1, 5000 do keep[i] = s:Observer(function() end) end
rec("obs_kb_per_1000", string.format("%.1f", (collectgarbage("count") - m0) / 5))
table.clear(keep); collectgarbage("collect")
m0 = collectgarbage("count")
for i = 1, 5000 do keep[i] = Effect(function() end, a, b, ca) end
rec("eff3_kb_per_1000", string.format("%.1f", (collectgarbage("count") - m0) / 5))
table.clear(keep)
print(table.concat(out, "  "))
