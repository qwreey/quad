--!nocheck
local G = require("./gclib")
local H = require("./harness")
local q, D = H.q, H.D

-- (a) create + dispose
G.measure("a1 D.Frame{} + q.dispose", function(N, track)
	for i = 1, N do local f = D.Frame {}; track(f, "inst"); q.dispose(f) end
end)
G.measure("a2 D.Frame{} never disposed (contract: must Destroy)", function(N, track)
	for i = 1, N do local f = D.Frame {}; track(f, "inst") end
end)
G.measure("a3 D.Frame{} + :Destroy()", function(N, track)
	for i = 1, N do local f = D.Frame {}; track(f, "inst"); f:Destroy() end
end)

-- (b) parent destroy with a child carrying every value kind
local function build(i, track, dispose)
	local src = q.Source(i); track(src, "Source")
	local comp = src:Compute(function(s) return s:Get() + 1 end); track(comp, "Compute")
	local obs = src:Observer(function() end); track(obs, "Observer")
	local eff = q.Effect(function() return function() end end, src); track(eff, "Effect")
	local ref = q.Ref(); track(ref, "Ref")
	local tag = q.Tag("T" .. (i % 3)); track(tag, "Tag")
	local attr = q.Attr({ Hp = src }); track(attr, "Attr")
	local slot = q.Slot { D.Frame { Name = "inner" } }; track(slot, "Slot")
	local child = D.Frame {
		Name = "child",
		LayoutOrder = comp,
		Visible = src:Compute(function(s) return s:Get() > 0 end),
		obs, eff, ref, tag, attr, slot,
	}
	track(child, "child"); track(slot:Get(1), "slotElem")
	local parent = D.Frame { child }
	track(parent, "parent")
	src:Set(i + 1)
	if dispose then q.dispose(parent) else parent:Destroy() end
end
G.measure("b1 parent:Destroy() with rich child", function(N, track)
	for i = 1, N do build(i, track, false) end
end)
G.measure("b2 q.dispose(parent) with rich child", function(N, track)
	for i = 1, N do build(i, track, true) end
end)
