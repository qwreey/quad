--!nocheck
-- round13 E20 probe D — GC of Observer/Effect handles by lifetime path. Run from repo root.
local mock = require("../../quad-base/test/mock")
local Instance = mock.Instance
local q = mock.newQuad()
local B = q.Backend
local function gc() for _ = 1, 4 do collectgarbage("collect") end end
local function subsCount(s) local n = 0 for _ in s._subs do n += 1 end return n end
local tracked = setmetatable({}, { __mode = "k" })
local function alive(tag) gc(); local n = 0 for _, t in tracked do if t == tag then n += 1 end end return n end

print("== D1 weak-subscribed Observer/Effect dropped → collected, _subs shrinks")
do
	local src = q.Source(0)
	do
		local o = src:Observer(function() end):WeakSubscribe(); tracked[o] = "d1o"
		local e = q.Effect(function() return function() tracked.cleanupRan = true end end, src):WeakSubscribe(); tracked[e] = "d1e"
	end
	print("   before gc subs:", subsCount(src))
	print("   alive o/e:", alive("d1o"), alive("d1e"), "subs after gc:", subsCount(src), "weak Effect cleanup ran on collection?", tracked.cleanupRan == true)
end

print("== D2 strong-subscribed Observer holds its upstream (source not collected while subscribed)")
do
	local o
	do local src = q.Source(0); tracked[src] = "d2s"; o = src:Observer(function() end):Subscribe() end
	print("   source alive while strong:", alive("d2s"))
	o:Unsubscribe(); o = nil
	print("   source alive after Unsubscribe+drop:", alive("d2s"))
end

print("== D3 strong-subscribed Effect that threw (dead) — Unsubscribe releases upstream")
do
	local e
	do
		local src = q.Source(0); tracked[src] = "d3s"
		e = q.Effect(function() if src:Get() == 1 then error("x") end end, src):Subscribe()
		pcall(function() src:Set(1) end)
	end
	print("   dead+strong: source alive", alive("d3s"), "running", e._running)
	e:Unsubscribe(); e = nil
	print("   after Unsubscribe+drop:", alive("d3s"))
end

print("== D4 tree-bound handles: host destroyed + dropped → collected (Immediate mock)")
do
	local src = q.Source(0)
	do
		local host = Instance.new("Frame")
		local o = src:Observer(function() end); tracked[o] = "d4o"
		local e = q.Effect(function() end, src); tracked[e] = "d4e"
		q.Dispatch.drive(host, { o, e })
		host:Destroy()
	end
	print("   alive o/e after host Destroy+drop:", alive("d4o"), alive("d4e"), "src subs:", subsCount(src))
end

print("== D5 tree-bound, host destroyed but host variable still referenced")
do
	local src = q.Source(0)
	local host = Instance.new("Frame")
	do
		local o = src:Observer(function() end); tracked[o] = "d5o"
		local e = q.Effect(function() end, src); tracked[e] = "d5e"
		q.Dispatch.drive(host, { o, e })
	end
	host:Destroy()
	print("   alive o/e (host still referenced, destroyed):", alive("d5o"), alive("d5e"))
	host = nil
	print("   alive after host dropped:", alive("d5o"), alive("d5e"))
end

print("== D6 Deferred Destroying (queue shim): bound Effect collected only after the queued callback runs")
do
	local orig = B.onDestroying
	local queue = {}
	B.onDestroying = function(inst, fn) return orig(inst, function() table.insert(queue, fn) end) end
	local src = q.Source(0)
	local cl = {}
	do
		local host = Instance.new("Frame")
		local e = q.Effect(function() return function(d) table.insert(cl, tostring(d)) end end, src); tracked[e] = "d6e"
		q.Dispatch.drive(host, { e })
		host:Destroy()
	end
	print("   before flush alive:", alive("d6e"), "cleanups", table.concat(cl, ","))
	local qq = queue; queue = {}; for _, f in qq do f() end; qq = nil
	print("   after flush alive:", alive("d6e"), "cleanups", table.concat(cl, ","))
	B.onDestroying = orig
end

print("== D7 bound handle whose host is never destroyed but dropped (unparented) — mock")
do
	local src = q.Source(0)
	do
		local host = Instance.new("Frame")
		local e = q.Effect(function() return function() tracked.d7cl = true end end, src); tracked[e] = "d7e"
		q.Dispatch.drive(host, { e })
	end
	print("   alive (mock, unparented host dropped):", alive("d7e"), "cleanup ran:", tracked.d7cl == true)
end

print("== D8 weak Effect: .Subscribed remains true on a handle that is still referenced while its deps are dropped? (deps held by _deps)")
do
	local e
	do local src = q.Source(0); tracked[src] = "d8s"; e = q.Effect(function() end, src):WeakSubscribe() end
	print("   dep alive while weak effect referenced:", alive("d8s"), "Sub", e.Subscribed)
	e = nil
	print("   dep alive after effect dropped:", alive("d8s"))
end

print("== D9 Unsubscribed-but-referenced Observer keeps receiving _rerunRequired (stays in _subs), upstream held")
do
	local src = q.Source(0)
	local o = src:Observer(function() end):Subscribe()
	o:Unsubscribe()
	for i = 1, 3 do src:Set(i) end
	print("   in _subs:", src._subs[o] == true, "held:", o._rerunRequired)
end
