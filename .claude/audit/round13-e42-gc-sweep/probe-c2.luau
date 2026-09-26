--!nocheck
local G = require("./gclib")
local H = require("./harness")
local q, D = H.q, H.D
local cur = q.Source(nil)
local single = q.Slot():Single(cur, function(ctx) if ctx.Item == q.KeyGone then return nil end return D.TextLabel { Text = ctx.Item, LayoutOrder = ctx.Offset } end)
local host = D.Frame { single }
G.measure("c8 :Single item swapped N times on a live host", function(N, track)
	for i = 1, N do cur:Set("v" .. i); track(single:Get(1), "elem") end
	cur:Set(nil)
end)
local outer = q.Source({})
local oslot = q.Slot():List(outer, function(ctx)
	if ctx.Item == q.KeyGone then return nil end
	local inner = q.Source({ 1, 2 })
	local islot = q.Slot():List(inner, function(c2) if c2.Item == q.KeyGone then return nil end return D.Frame { LayoutOrder = c2.Offset } end)
	return D.Frame { islot, LayoutOrder = ctx.Offset }
end)
local host2 = D.Frame { oslot }
G.measure("c9 nested :List in :List, outer keys replaced N times", function(N, track)
	for i = 1, N do outer:Set({ "k" .. i, "j" .. i }); track(oslot:Get(1), "outerElem") end
	outer:Set({})
end)
G.rounds("c9 rounds", function(N, track) for i = 1, N do outer:Set({ "k" .. i, "j" .. i }) end outer:Set({}) end, 1000, 4)
G.measure("c10 :List with OwnsElements=false, keys dropped (elements survive by design)", function(N, track)
	local d = q.Source({})
	local s = q.Slot():List(d, function(ctx) if ctx.Item == q.KeyGone then return nil end return D.Frame {} end, nil, { OwnsElements = false })
	local h = D.Frame { s }
	for i = 1, N do d:Set({ i }); track(s:Get(1), "elem") end
	d:Set({})
	h:Destroy()
end)
