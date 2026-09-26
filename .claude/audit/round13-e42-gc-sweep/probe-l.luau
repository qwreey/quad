--!nocheck
local G = require("./gclib")
local H = require("./harness")
local Quad = H.Quad
local QuadRoblox = require("../../../quad-roblox/src").QuadRoblox
G.measure("l1 Quad.New() bare", function(N, track)
	for i = 1, N do local m = Quad.New(); track(m, "module"); track(m.Backend, "backend") end
end)
G.measure("l2 Quad.New()+UseProvider(QuadRoblox)", function(N, track)
	for i = 1, N do local m = Quad.New(); m:UseProvider(QuadRoblox); track(m, "module"); track(m.Declaration, "decl") end
end, 200)
G.measure("l3 Quad.New()+UseProvider+Frame+Destroy", function(N, track)
	for i = 1, N do local m = Quad.New(); m:UseProvider(QuadRoblox); track(m, "module") end
end, 200)
