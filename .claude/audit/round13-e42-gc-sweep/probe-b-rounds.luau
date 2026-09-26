--!nocheck
local G = require("./gclib")
local H = require("./harness")
local q, D = H.q, H.D
local function build(i, track, dispose)
	local src = q.Source(i); track(src, "Source")
	local comp = src:Compute(function(s) return s:Get() + 1 end)
	local obs = src:Observer(function() end)
	local eff = q.Effect(function() return function() end end, src)
	local child = D.Frame { Name = "child", LayoutOrder = comp, obs, eff, q.Ref(), q.Tag("T"), q.Attr({ Hp = src }), q.Slot { D.Frame {} } }
	local parent = D.Frame { child }
	if dispose then q.dispose(parent) else parent:Destroy() end
end
G.rounds("b1 Destroy rounds", function(N, track) for i = 1, N do build(i, track, false) end end, 1000, 5)
G.rounds("b2 dispose rounds", function(N, track) for i = 1, N do build(i, track, true) end end, 1000, 5)
G.rounds("a3 bare Frame Destroy rounds", function(N, track) for i = 1, N do local f = D.Frame{}; f:Destroy() end end, 1000, 5)
