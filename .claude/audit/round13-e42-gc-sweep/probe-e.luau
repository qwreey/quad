--!nocheck
local G = require("./gclib")
local H = require("./harness")
local q, D = H.q, H.D
local up = q.Source(0)
local KEEP = {}
local ref = q.Ref()
local function cnt(t) local n = 0 for _ in t do n += 1 end return n end
G.measure("e1 Observer on long-lived up bound to inst, inst:Destroy()", function(N, track)
	for i = 1, N do
		local cleanupRan = false
		local o = up:Observer(function() end)
		local e = q.Effect(function() return function() cleanupRan = true end end, up, ref)
		local f = D.Frame { o, e, LayoutOrder = up:Compute(function(s) return s:Get() end) }
		track(o, "obs"); track(e, "eff"); track(f, "inst")
		f:Destroy()
	end
	up:Set(up:Get() + 1)
end)
print("up._subs after e1:", cnt(up._subs), " ref.Callbacks:", cnt(ref.Callbacks), " ref.WeakCallbacks:", cnt(ref.WeakCallbacks))
G.measure("e2 same but q.dispose(inst)", function(N, track)
	for i = 1, N do
		local o = up:Observer(function() end)
		local e = q.Effect(function() return function() end end, up, ref)
		local f = D.Frame { o, e }
		track(o, "obs"); track(e, "eff"); track(f, "inst")
		q.dispose(f)
	end
end)
print("up._subs after e2:", cnt(up._subs), " ref.Callbacks:", cnt(ref.Callbacks), " ref.WeakCallbacks:", cnt(ref.WeakCallbacks))
G.measure("e3 Effect strong Subscribe with Ref dep then Unsubscribe", function(N, track)
	for i = 1, N do local e = q.Effect(function() end, ref, up):Subscribe(); track(e, "eff"); e:Unsubscribe() end
end)
print("ref.Callbacks after e3:", cnt(ref.Callbacks), " WeakCallbacks:", cnt(ref.WeakCallbacks))
G.measure("e4 Effect that threw (dies) bound to inst, inst destroyed", function(N, track)
	for i = 1, N do
		local armed = false
		local e = q.Effect(function() if armed then error("boom") end end, up)
		local f = D.Frame { e }; track(f, "inst"); track(e, "eff")
		armed = true
		pcall(function() e:Rerun() end)
		f:Destroy()
	end
end)
G.measure("e5 State<Observer?> seat swapped then inst destroyed", function(N, track)
	local seat = q.Source(nil)
	local f = D.Frame { seat }
	for i = 1, N do local o = up:Observer(function() end); track(o, "obs"); seat:Set(o) end
	seat:Set(nil)
	f:Destroy()
end)
G.measure("e6 State<Effect?> seat swapped on a live inst (old effects must drop)", function(N, track)
	local seat = q.Source(nil)
	local f = D.Frame { seat }
	for i = 1, N do local e = q.Effect(function() return function() end end, up); track(e, "eff"); seat:Set(e) end
	seat:Set(nil)
	KEEP.f = f
end)
KEEP.f:Destroy(); KEEP.f = nil
G.measure("e7 OnDestroyed/OnCreated/OnRendered hooks + Destroy", function(N, track)
	for i = 1, N do
		local a, b, c = q.OnCreated(function() end), q.OnRendered(function() end), q.OnDestroyed(function() end)
		local f = D.Frame { a, b, c }; track(f, "inst"); track(a, "h1"); track(b, "h2"); track(c, "h3")
		f:Destroy()
	end
end)
G.measure("e8 PreRef/PostRef + Destroy", function(N, track)
	for i = 1, N do local a, b = q.PreRef(), q.PostRef(); local f = D.Frame { a, b }; track(f, "inst"); track(a, "pre"); track(b, "post"); f:Destroy() end
end)
