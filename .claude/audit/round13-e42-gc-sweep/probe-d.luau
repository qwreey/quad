--!nocheck
local G = require("./gclib")
local H = require("./harness")
local q, D = H.q, H.D
local up = q.Source(0)
G.measure("d1 up:Compute chain (depth 3), downstream dropped", function(N, track)
	for i = 1, N do
		local a = up:Compute(function(s) return s:Get() + 1 end)
		local b = a:Compute(function(s) return s:Get() * 2 end)
		local c = b:Compute(function(s) return s:Get() end)
		c:Get()
		track(a, "a"); track(b, "b"); track(c, "c")
	end
	up:Set(up:Get() + 1)
end)
print("up._subs entries after d1:", (function() local n = 0 for _ in up._subs do n += 1 end return n end)())
local other = q.Source(1)
G.measure("d2 multi-dep Compute(up, other) dropped", function(N, track)
	for i = 1, N do
		local x = q.Source(i)
		local c = up:Compute(function(s, o) return s:Get() + o:Get() end, other)
		track(c, "c"); track(x, "x")
	end
end)
G.measure("d3 Compute read into Observer (not subscribed) dropped", function(N, track)
	for i = 1, N do local c = up:Compute(function(s) return s:Get() end); local o = c:Observer(function() end); track(c, "c"); track(o, "obs") end
	up:Set(up:Get() + 1)
end)
G.measure("d4 Observer :WeakSubscribe then dropped", function(N, track)
	for i = 1, N do local o = up:Observer(function() end):WeakSubscribe(); track(o, "obs") end
	up:Set(up:Get() + 1)
end)
G.measure("d5 Observer :Subscribe (strong) then :Unsubscribe", function(N, track)
	for i = 1, N do local o = up:Observer(function() end):Subscribe(); track(o, "obs"); o:Unsubscribe() end
end)
G.measure("d6 Observer :Subscribe (strong) kept (contract: module-lifetime)", function(N, track)
	for i = 1, N do local o = up:Observer(function() end):Subscribe(); track(o, "obs") end
end)
G.measure("d7 Effect WeakSubscribe dropped", function(N, track)
	for i = 1, N do local e = q.Effect(function() return function() end end, up):WeakSubscribe(); track(e, "eff") end
	up:Set(up:Get() + 1)
end)
G.measure("d8 Effect Subscribe then Unsubscribe", function(N, track)
	for i = 1, N do local e = q.Effect(function() return function() end end, up):Subscribe(); track(e, "eff"); e:Unsubscribe() end
end)
G.measure("d9 Gate / Blocker chain dropped", function(N, track)
	local b = q.Blocker(); b:On()
	for i = 1, N do local g = up:Apply(b); track(g, "gate") end
	up:Set(up:Get() + 1)
end)
G.measure("d10 Effect with Ref dep, WeakSubscribe dropped", function(N, track)
	local r = q.Ref()
	for i = 1, N do local e = q.Effect(function() end, r):WeakSubscribe(); track(e, "eff") end
	r:Set(D.Frame{})
end)
G.measure("d11 downstream Compute of a Source that is itself dropped", function(N, track)
	for i = 1, N do local s = q.Source(i); local c = s:Compute(function(x) return x:Get() end); track(s, "s"); track(c, "c") end
end)
