--!nocheck
local G = require("./gclib")
local H = require("./harness")
local q, D = H.q, H.D
local TR = { add = function() end }
local outer = q.Source({})
local oslot = q.Slot():List(outer, function(ctx)
	if ctx.Item == q.KeyGone then return nil end
	local inner = q.Source({ 1, 2 })
	local islot = q.Slot():List(inner, function(c2) if c2.Item == q.KeyGone then return nil end local e = D.Frame { LayoutOrder = c2.Offset }; TR.add(e, "innerElem"); return e end)
	TR.add(inner, "innerData"); TR.add(islot, "innerSlot")
	return D.Frame { islot, LayoutOrder = ctx.Offset }
end)
local host2 = D.Frame { oslot }
G.measure("c9b nested :List — inner Source/Slot/elements tracked", function(N, track)
	TR.add = track
	for i = 1, N do outer:Set({ "k" .. i, "j" .. i }) end
	outer:Set({})
	TR.add = function() end
end)
