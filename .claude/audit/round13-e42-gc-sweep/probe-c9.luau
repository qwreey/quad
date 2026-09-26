--!nocheck
local G = require("./gclib")
local H = require("./harness")
local q, D = H.q, H.D
local mode = ...
local outer = q.Source({})
local oslot = q.Slot():List(outer, function(ctx)
	if ctx.Item == q.KeyGone then return nil end
	if mode == "flat" then return D.Frame { LayoutOrder = ctx.Offset } end
	local inner = q.Source({ 1, 2 })
	local islot = q.Slot():List(inner, function(c2) if c2.Item == q.KeyGone then return nil end return D.Frame { LayoutOrder = c2.Offset } end)
	return D.Frame { islot, LayoutOrder = ctx.Offset }
end)
local host2 = D.Frame { oslot }
G.rounds("c9 " .. tostring(mode) .. " rounds", function(N, track) for i = 1, N do outer:Set({ "k" .. i, "j" .. i }) end outer:Set({}) end, 1000, 10)
