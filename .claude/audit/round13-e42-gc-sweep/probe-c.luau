--!nocheck
local G = require("./gclib")
local H = require("./harness")
local q, D = H.q, H.D

-- one long-lived host; churn elements
local slot = q.Slot()
local host = D.Frame { slot }
G.measure("c1 Slot:Add + Remove(1) on a live host", function(N, track)
	for i = 1, N do local e = D.Frame { Name = "e" .. i }; track(e, "elem"); slot:Add(e); slot:Remove(1) end
end)
G.rounds("c1 rounds", function(N, track) for i = 1, N do slot:Add(D.Frame {}); slot:Remove(1) end end, 1000, 4)
G.measure("c1b Slot:Add x N then Clear", function(N, track)
	for i = 1, N do local e = D.Frame {}; track(e, "elem"); slot:Add(e) end
	slot:Clear()
end)
G.measure("c1c Add then Extract (alive, dropped — contract: must dispose)", function(N, track)
	for i = 1, N do local e = D.Frame {}; track(e, "elem"); slot:Add(e); slot:Extract(1) end
end)
G.measure("c1d Add then Extract then q.dispose", function(N, track)
	for i = 1, N do local e = D.Frame {}; track(e, "elem"); slot:Add(e); q.dispose(slot:Extract(1)) end
end)
G.measure("c1e Add(q.Source(frame)) then Remove — State-held element survives (doc 06 L404)", function(N, track)
	for i = 1, N do local e = D.Frame {}; local s = q.Source(e); track(e, "elem"); track(s, "src"); slot:Add(s); slot:Remove(1) end
end)
G.measure("c1f nested Slot element Add/Remove", function(N, track)
	for i = 1, N do local inner = q.Slot { D.Frame {} }; track(inner, "innerSlot"); track(inner:Get(1), "innerElem"); slot:Add(inner); slot:Remove(1) end
end)
print("host slot length", slot.Length:Get())

-- :List data replacement
local data = q.Source({})
local lslot = q.Slot()
local seen = G.tracker("k")
lslot:List(data, function(ctx)
	if ctx.Item == q.KeyGone then return nil end
	local e = D.Frame { Name = tostring(ctx.Item), LayoutOrder = ctx.Offset }
	return e
end)
local lhost = D.Frame { lslot }
G.measure("c2 :List data replace (new keys each time, 3 items)", function(N, track)
	for i = 1, N do
		data:Set({ "a" .. i, "b" .. i, "c" .. i })
		for j = 1, lslot.Length:Get() do track(lslot:Get(j), "elem") end
	end
	data:Set({})
end)
G.rounds("c2 rounds", function(N, track)
	for i = 1, N do data:Set({ "a" .. i, "b" .. i, "c" .. i }) end
	data:Set({})
end, 1000, 4)
G.measure("c3 :List data replace, same keys reused (re-render)", function(N, track)
	for i = 1, N do data:Set({ "x", "y", "z" .. (i % 2) }); for j = 1, lslot.Length:Get() do track(lslot:Get(j), "elem") end end
	data:Set({})
end)

-- whole host churn: slot+list host destroyed
G.measure("c4 host with :List Slot destroyed", function(N, track)
	for i = 1, N do
		local d = q.Source({ 1, 2, 3 }); local s = q.Slot(); s:List(d, function(ctx) if ctx.Item == q.KeyGone then return nil end return D.Frame {} end)
		local h = D.Frame { s }
		track(d, "data"); track(s, "slot"); track(h, "host"); track(s:Get(1), "elem")
		h:Destroy()
	end
end)
G.measure("c5 host with :List Slot q.dispose(host)", function(N, track)
	for i = 1, N do
		local d = q.Source({ 1, 2, 3 }); local s = q.Slot(); s:List(d, function(ctx) if ctx.Item == q.KeyGone then return nil end return D.Frame {} end)
		local h = D.Frame { s }
		track(d, "data"); track(s, "slot"); track(h, "host"); track(s:Get(1), "elem")
		q.dispose(h)
	end
end)
G.measure("c6 unmounted Slot with elements, q.dispose(slot)", function(N, track)
	for i = 1, N do local s = q.Slot { D.Frame {}, D.Frame {} }; track(s, "slot"); track(s:Get(1), "elem"); q.dispose(s) end
end)
G.measure("c7 unmounted Slot with elements, dropped (never disposed)", function(N, track)
	for i = 1, N do local s = q.Slot { D.Frame {} }; track(s, "slot"); track(s:Get(1), "elem") end
end)
