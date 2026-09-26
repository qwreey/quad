--!nocheck
local G = require("./gclib")
local H = require("./harness")
local q, D = H.q, H.D
local base = D.Modifier.Frame({ BackgroundTransparency = 0.5 })
G.measure("k1 1000 Modifiers via setter chain (static field names)", function(N, track)
	for i = 1, N do local m = base:Size(i):Position(i):LayoutOrder(function(o) return (o or 0) + 1 end); track(m, "mod") end
end)
G.rounds("k1 rounds", function(N, track) for i = 1, N do local m = base:Size(i):Position(i) end end, 1000, 4)
G.measure("k2 Modifier factory :Apply to Frames, Destroy", function(N, track)
	local src = q.Source(1)
	for i = 1, N do
		local m = base:LayoutOrder(src:Compute(function(s) return s:Get() + i end))
		local f = D.Frame { m }
		track(m, "mod"); track(f, "inst"); f:Destroy()
	end
end)
G.measure("k3 computed setter names (documented unbounded cache, ROADMAP backlog)", function(N, track)
	for i = 1, N do local m = base["Field" .. i](base, i); track(m, "mod") end
end)
G.rounds("k3 rounds", function(N, track) for i = 1, N do local m = base["F" .. i .. "_" .. math.random(1, 1e9)](base, i) end end, 1000, 3)
G.measure("k4 TypedFactory with fresh names (class registry — module-level, by design)", function(N, track)
	for i = 1, N do local ctor = q.Modifier.TypedFactory("Cls" .. i .. "_" .. math.random(1, 1e9)); track(ctor, "ctor") end
end)
