--!nocheck
local G = require("./gclib")
local H = require("./harness")
local q, D = H.q, H.D
G.measure("g1 Store created/dropped (fields bound to an inst, inst destroyed)", function(N, track)
	for i = 1, N do
		local st = q.Store({ hp = q.Source(i), name = q.Source("x") })
		local f = D.Frame { Name = st.name, LayoutOrder = st.hp }
		st:Of("mp"):Set(3)
		track(st, "store"); track(st.hp, "hp"); track(f, "inst")
		f:Destroy()
	end
end)
local longStore = q.Store({ hp = q.Source(0) })
local host = D.Frame { LayoutOrder = longStore.hp }
G.measure("g2 long-lived Store, field values swapped N times", function(N, track)
	for i = 1, N do local v = { i }; longStore.hp:Set(i); track(v, "val") end
end)
G.measure("g3 long-lived Store :Of new names N times (grows by design)", function(N, track)
	for i = 1, N do local s = longStore:Of("k" .. i .. "_" .. math.random(1, 1e9)); track(s, "src") end
end)
G.measure("g4 Context bag + Provider per iteration, dropped", function(N, track)
	for i = 1, N do
		local P = q.Context.Provider("P" .. i); local ctx = q.Context(); local val = { i }
		ctx:Set(P, val)
		local f = D.Frame { Name = tostring(ctx:Get(P)[1]) }
		track(P, "provider"); track(ctx, "ctx"); track(val, "val"); f:Destroy()
	end
end)
local P = q.Context.Provider("Theme")
local ctx = q.Context()
G.measure("g5 long-lived ctx, value swapped N times under one Provider", function(N, track)
	for i = 1, N do local v = { i }; ctx:Set(P, v); track(v, "val") end
	ctx:Set(P, { 0 })
end)
G.measure("g6 long-lived ctx, N new Providers Set then dropped (bag holds strongly — by design)", function(N, track)
	for i = 1, N do local p = q.Context.Provider(); ctx:Set(p, { i }); track(p, "provider") end
end)
G.measure("g7 Context value is a Source bound to a component inst, inst destroyed", function(N, track)
	local T = q.Context.Provider("S"); local c = q.Context(); c:Set(T, q.Source(1))
	for i = 1, N do local f = D.Frame { LayoutOrder = c:Get(T):Compute(function(s) return s:Get() end) }; track(f, "inst"); f:Destroy() end
end)
