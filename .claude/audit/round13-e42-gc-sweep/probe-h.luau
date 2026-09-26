--!nocheck
local G = require("./gclib")
local H = require("./harness")
local q, D = H.q, H.D
local function scen(kind, drainAfter, leading)
	return function(N, track)
		for i = 1, N do
			local src = q.Source(0)
			local factory = (kind == "D" and q.Debounce or q.Throttle) { Time = 1, Leading = leading, MaxTime = kind == "D" and 3 or nil }
			local gated = src:Apply(factory)
			local f = D.Frame { LayoutOrder = gated }
			src:Set(1); src:Set(2) -- open a window, pending trailing timer
			track(src, "src"); track(gated, "gate"); track(f, "inst"); track(factory, "factory")
			f:Destroy()
		end
		if drainAfter then H.runTask(drainAfter) end
	end
end
G.measure("h1 Debounce pending at Destroy, no drain (timers queued)", scen("D", nil))
H.runTask(100)
G.measure("h2 Debounce pending at Destroy, drain 2xTime", scen("D", 2.01))
G.measure("h3 Debounce pending, drain 0.5 (still inside window)", scen("D", 0.5))
H.runTask(100)
G.measure("h4 Throttle Leading pending at Destroy, drain 2xTime", scen("T", 2.01, true))
G.measure("h5 Debounce MaxTime pending, drain 3.01", scen("D", 3.01))
-- long-lived factory broadcast
local fac = q.Debounce { Time = 1 }
G.measure("h6 long-lived factory, N gates made+dropped (factory weak-keys gates)", function(N, track)
	for i = 1, N do local s = q.Source(0); local g = s:Apply(fac); s:Set(1); track(g, "gate"); track(s, "src") end
	H.runTask(2.01)
end)
G.measure("h7 opts.Handle Ref, inst destroyed, Ref dropped", function(N, track)
	for i = 1, N do
		local r = q.Ref(); local s = q.Source(0); local g = s:Apply(q.Debounce { Time = 1, Handle = r })
		local f = D.Frame { LayoutOrder = g }; s:Set(1); track(r, "ref"); track(g, "gate"); track(f, "inst"); f:Destroy()
	end
	H.runTask(2.01)
end)
H.runTask(100)
G.measure("h5b Debounce MaxTime=3 pending, drain only 2.01 (doc bound 2xTime)", scen("D", 2.01))
H.runTask(100)
local function mk(maxT) return function(N, track)
	for i = 1, N do
		local src = q.Source(0)
		local g = src:Apply(q.Debounce { Time = 1, MaxTime = maxT })
		local f = D.Frame { LayoutOrder = g }
		src:Set(1)
		track(g, "gate")
		f:Destroy()
	end
	H.runTask(2.01)
end end
G.measure("h5c single signal, MaxTime=10, drain 2.01", mk(10))
H.runTask(100)
G.measure("h5d single signal, no MaxTime, drain 2.01", mk(nil))
