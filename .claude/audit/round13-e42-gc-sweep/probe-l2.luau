--!nocheck
local G = require("./gclib")
local H = require("./harness") -- installs shims on the shared quad-roblox handler envs
local Quad = H.Quad
local QuadRoblox = require("../../../quad-roblox/src").QuadRoblox
local mock = require("../../../quad-base/test/mock")
local function plugin(quad) return { hello = 1 } end
G.measure("l4 New()+AddPlugin(top-level fn)", function(N, track)
	for i = 1, N do local m = Quad.New(); m:AddPlugin(plugin); track(m, "module") end
end)
G.measure("l5 New()+AddPlugin(inline closure capturing m) — doc 01 L90 says pinned", function(N, track)
	for i = 1, N do local m = Quad.New(); m:AddPlugin(function(quad) local _ = m; return {} end); track(m, "module") end
end)
G.measure("l6 New()+AddPlugin(inline closure NOT capturing m)", function(N, track)
	for i = 1, N do local m = Quad.New(); m:AddPlugin(function(quad) return {} end); track(m, "module") end
end)
G.measure("l7 New()+RunInit(closure capturing m)", function(N, track)
	for i = 1, N do local m = Quad.New(); m:RunInit(function(quad) local _ = m end); track(m, "module") end
end)
G.measure("l8 New()+UseProvider(QuadRoblox)+Frame made & Destroyed", function(N, track)
	for i = 1, N do
		local m = Quad.New(); m:UseProvider(QuadRoblox)
		;(getfenv(m.Declaration.New)).Instance = { new = mock.Instance.new }
		m.Backend.isInst = mock.isMockInstance
		local f = m.Declaration.Frame { Name = m.Source("x") }
		f:Destroy()
		track(m, "module"); track(f, "inst")
	end
end, 200)
G.measure("l9 New()+UseProvider+Frame NOT destroyed (instance pins module?)", function(N, track)
	for i = 1, N do
		local m = Quad.New(); m:UseProvider(QuadRoblox)
		m.Backend.isInst = mock.isMockInstance
		local f = m.Declaration.Frame { Name = m.Source("x") }
		track(m, "module"); track(f, "inst")
	end
end, 200)
