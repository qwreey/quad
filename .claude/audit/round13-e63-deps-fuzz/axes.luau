--!nocheck
-- E63 axis probes: deps-set contract of q.Effect / :Observer / :Depend / :Compute trailing deps.
local H = require("./harness")
local q, D = H.q, H.D
local function first(e) return (tostring(e):gsub("\n.*", ""):gsub("^.-(Quad%d%d%d%d)", "%1")) end
local function try(label, f) local ok, e = pcall(f); print(label, ok and "OK" or first(e)) end
local function hdr(s) print("\n== " .. s) end

hdr("A1 diamond: Effect(fn, a, a:Compute(id), a:Depend()) — one Set")
do
	local a = q.Source(1); local n = 0
	local c = a:Compute(function(s) return s:Get() * 2 end)
	local e = q.Effect(function() n += 1; local _ = c:Get() end, a, c, a:Depend()):Subscribe()
	a:Set(2); a:Set(2); print("runs(install+2 sets)=", n)
end

hdr("A2 duplicate deps")
do
	local a = q.Source(1); local n, cl = 0, 0
	local e = q.Effect(function() n += 1; return function() cl += 1 end end, a, a, a):Subscribe()
	a:Set(5); print("Effect(a,a,a): runs", n, "cleanups", cl)
	local args
	local c = a:Compute(function(s, prev, x, y) args = { s == a, x == a, y == a, select("#", x, y) }; return s:Get() + x:Get() + y:Get() end, a, a)
	print("a:Compute(fn,a,a) value", c:Get(), "args", table.concat({ tostring(args[1]), tostring(args[2]), tostring(args[3]) }, ","))
	local nc = 0; local cc = a:Compute(function(s, _, x, y) nc += 1; return s:Get() + x:Get() + y:Get() end, a, a)
	local o = 0; local ob = cc:Observer(function() o += 1 end):Subscribe()
	a:Set(7); print("dup-dep Compute value", cc:Get(), "fn runs total", nc, "observer", o)
	local dd = a:Depend(a, a); local od = 0; dd:Observer(function() od += 1 end):Subscribe(); a:Set(8)
	print("a:Depend(a,a) value", dd:Get(), "observer", od)
end

hdr("A3 Ref dep")
do
	local r = q.Ref(); local n, cl, dy = 0, 0, {}
	local e = q.Effect(function() n += 1; return function(dying) cl += 1; table.insert(dy, tostring(dying)) end end, r):Subscribe()
	print("install runs", n)
	r:Set(1); r:Set(1); r:Set(nil); r:Set(nil)
	print("after Set 1,1,nil,nil: runs", n, "cleanups", cl)
	local f = D.Frame { r }
	print("after placing in D.Frame: runs", n, "ref.Value is frame", r.Value == f)
	f:Destroy()
	print("after frame:Destroy(): runs", n, "ref.Value still frame", r.Value == f)
end

hdr("A3b Ref dep retract via State<Ref?> seat")
do
	local r = q.Ref(); local n = 0
	local e = q.Effect(function() n += 1 end, r):Subscribe()
	local seat = q.Source(r)
	local f = D.Frame { seat }
	local afterPlace = n
	seat:Set(nil)
	print("place→", afterPlace, "retract→", n, "value nil", r.Value == nil)
end

hdr("A4 Depend(a,b): value self, emits on either")
do
	local a, b = q.Source("x"), q.Source(1)
	local d = a:Depend(b); local o, n = 0, 0
	d:Observer(function() o += 1 end):Subscribe()
	q.Effect(function() n += 1 end, d):Subscribe()
	b:Set(2); a:Set("y"); b:Set(2)
	print("value", d:Get(), "observer(install+3)", o, "effect(install+3)", n)
	local dd = d:Depend(q.Source(0)); print("Depend of Depend value", dd:Get())
	local s3 = q.Source(0); local dd2 = d:Depend(s3); local o2 = 0; dd2:Observer(function() o2 += 1 end):Subscribe()
	s3:Set(1); b:Set(9); a:Set("z"); print("DoD observer (install+3)", o2, dd2:Get())
end

hdr("A5 Compute trailing dep unread")
do
	local a, b = q.Source(1), q.Source(100); local runs = 0
	local c = a:Compute(function(s) runs += 1; return s:Get() end, b)
	local o = 0; c:Observer(function(t) o += 1; t:Get() end):Subscribe()
	local r0 = runs; b:Set(101)
	print("unread trailing dep: observer", o, "fn runs delta", runs - r0, "value", c:Get())
end

hdr("A7 invalid deps")
do
	local a = q.Source(1)
	local fn = function() end
	try("Effect(fn, 5)", function() q.Effect(fn, 5) end)
	try("Effect(fn, a, {})", function() q.Effect(fn, a, {}) end)
	try("Effect(fn, a, nil)", function() q.Effect(fn, a, nil) end)
	try("Effect(fn, nil, a)", function() q.Effect(fn, nil, a) end)
	try("Effect(fn, Slot)", function() q.Effect(fn, q.Slot()) end)
	try("Effect(fn, Tag)", function() q.Effect(fn, q.Tag("x")) end)
	try("Effect(fn, Blocker)", function() q.Effect(fn, q.Blocker()) end)
	try("Effect(fn, Observer)", function() q.Effect(fn, a:Observer()) end)
	try("Effect(fn, Effect)", function() q.Effect(fn, q.Effect(fn)) end)
	try("Effect(fn, PreRef)", function() q.Effect(fn, q.PreRef()) end)
	try("Effect(fn, PostRef)", function() q.Effect(fn, q.PostRef()) end)
	try("Effect(fn, Store)", function() q.Effect(fn, q.Store({ x = q.Source(1) })) end)
	try("Effect(fn, {__quadState=true})", function() q.Effect(fn, { __quadState = true }) end)
	try("Effect(fn, Instance)", function() q.Effect(fn, D.Frame {}) end)
	try("a:Compute(fn, Ref)", function() a:Compute(fn, q.Ref()) end)
	try("a:Compute(fn, a, nil)", function() a:Compute(fn, a, nil) end)
	try("a:Compute(fn, 5)", function() a:Compute(fn, 5) end)
	try("a:Depend(nil)", function() a:Depend(nil) end)
	try("a:Depend(Ref)", function() a:Depend(q.Ref()) end)
	try("a:Depend(a, Slot)", function() a:Depend(a, q.Slot()) end)
	try("Effect(5)", function() q.Effect(5, a) end)
	try("a:Observer(5)", function() a:Observer(5) end)
	try("a:Observer(fn, b) (extra arg)", function() local o = a:Observer(function() end, q.Source(0)) end)
	local st = q.Store({ x = q.Source(1) })
	try("Effect(fn, store.x)", function() q.Effect(fn, st.x) end)
	try("Effect(fn, a:Gate(...))", function() q.Effect(fn, a:Gate(function(emit) return function() end end)) end)
end

hdr("A8 subscribe lifecycle keeps deps")
do
	local a, b = q.Source(0), q.Source(0); local n, cl = 0, 0
	local e = q.Effect(function() n += 1; return function() cl += 1 end end, a, b)
	a:Set(1); b:Set(1); print("unsubscribed, 2 sets: runs", n)
	e:Subscribe(); print("after Subscribe: runs", n)
	e:Unsubscribe(); print("after Unsubscribe: runs", n, "cl", cl)
	e:Subscribe(); print("resubscribe with no change: runs", n)
	b:Set(2); print("b:Set: runs", n)
	e:Unsubscribe(); e:WeakSubscribe(); print("strong→weak resub: runs", n)
	e:WeakUnsubscribe(); e:WeakSubscribe(); print("weak unsub/resub no change: runs", n)
	a:Set(3); print("a:Set: runs", n, "cl", cl)
end

hdr("A9 Blocker-gated dep")
do
	local a, b = q.Source(0), q.Source(0); local bl = q.Blocker(); local n = 0; local seen = {}
	local ga = a:Apply(bl)
	q.Effect(function() n += 1; table.insert(seen, ga:Get()) end, ga, b):Subscribe()
	bl:On(); a:Set(1); a:Set(2); print("blocked: runs", n)
	b:Set(1); print("b:Set during block: runs", n, "read", seen[#seen])
	bl:Off(); print("Off: runs", n, "read", seen[#seen])
	bl:On(); a:Set(3); bl:OffWithoutEmit(); print("OffWithoutEmit: runs", n)
	a:Set(4); print("next set: runs", n, seen[#seen])
	-- effect on both a and gated a
	local n2 = 0; q.Effect(function() n2 += 1 end, a, ga):Subscribe()
	bl:On(); a:Set(5); local mid = n2; bl:Off(); print("Effect(a, a|blocker): during block", mid, "after Off", n2)
end

hdr("A10 re-entry: fn Sets a dep")
do
	local a, b = q.Source(0), q.Source(0); local log = {}
	local e = q.Effect(function() table.insert(log, "fn" .. a:Get() .. "/" .. b:Get()); if a:Get() == 1 and b:Get() == 0 then b:Set(1) end
		return function() table.insert(log, "cl") end end, a, b):Subscribe()
	a:Set(1); print(table.concat(log, " "))
	log = {}
	local e2 = q.Effect(function() table.insert(log, "fn" .. a:Get()); if a:Get() < 3 then a:Set(a:Get() + 1) end return function() table.insert(log, "cl") end end, a):Subscribe()
	print("self-dep ladder:", table.concat(log, " "))
end

hdr("A11 dep order irrelevant; Compute arg order")
do
	local a, b, c = q.Source("a"), q.Source("b"), q.Source("c")
	local x = a:Compute(function(s, _, p, r) return s:Get() .. p:Get() .. r:Get() end, c, b)
	print("a:Compute(fn, c, b) =", x:Get())
	local l1, l2 = {}, {}
	local e1 = q.Effect(function(self) table.insert(l1, typeof(self) .. tostring(self == nil)) end, a, b)
	print("Effect fn args: self only?", l1[1])
end

hdr("A12 Depend/Compute node lifetime under GC")
do
	local a, b = q.Source(0), q.Source(0); local n, o = 0, 0
	local e = q.Effect(function() n += 1 end, a:Depend(b)):WeakSubscribe()
	local ob = a:Depend(b):Observer(function() o += 1 end):WeakSubscribe()
	collectgarbage("collect"); collectgarbage("collect")
	b:Set(1)
	print("weak Effect over inline Depend (handle kept): runs", n, " weak Observer over inline Depend: fires", o)
	local n3 = 0
	local f = D.Frame { q.Effect(function() n3 += 1 end, a:Depend(b)) }
	collectgarbage("collect"); collectgarbage("collect")
	b:Set(2); print("bound Effect over inline Depend (frame kept): runs", n3)
	f:Destroy(); b:Set(3); print("after frame destroy: runs", n3)
	local _keep = { e, ob, f }
end

hdr("A13 Effect bound to instance destroyed; Slot element removal")
do
	local a = q.Source(0); local n, dy = 0, {}
	local f = D.Frame { q.Effect(function() n += 1; return function(d) table.insert(dy, tostring(d)) end end, a) }
	a:Set(1); f:Destroy(); a:Set(2)
	print("runs", n, "cleanups", table.concat(dy, ","))
	local items = q.Source({ "k1", "k2" }); local runs = {}; local cls = {}
	local slot = q.Slot():List(items, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		if ctx.Prev then return ctx.Prev end
		local k = ctx.Item
		return D.Frame { q.Effect(function() runs[k] = (runs[k] or 0) + 1; return function(d) cls[k] = (cls[k] or "") .. tostring(d) .. ";" end end, a) }
	end)
	local host = D.Frame { slot }
	a:Set(3)
	items:Set({ "k1" })
	a:Set(4)
	print("k1 runs", runs.k1, "k2 runs", runs.k2, "k1 cl", cls.k1, "k2 cl", cls.k2)
	host:Destroy(); a:Set(5); print("after host destroy k1 runs", runs.k1, "k1 cl", cls.k1)
end

hdr("A14 Effect created on a node downstream of a CLOSED gate (seeding)")
do
	local a = q.Source(0); local bl = q.Blocker(); local g = a:Apply(bl)
	local n1 = g:Compute(function(s) return s:Get() end)
	local _ = n1:Get()
	bl:On(); a:Set(1)
	local n, seen = 0, {}
	local e = q.Effect(function() n += 1; table.insert(seen, n1:Get()) end, n1):Subscribe()
	bl:Off()
	print("Effect over pre-existing node behind gate: runs", n, "values", table.concat(seen, ","))
	-- Observer variant
	local a2 = q.Source(0); local bl2 = q.Blocker(); local g2 = a2:Apply(bl2); local m2 = g2:Compute(function(s) return s:Get() end); local _ = m2:Get()
	bl2:On(); a2:Set(1); local on, ov = 0, {}
	m2:Observer(function(t) on += 1; table.insert(ov, t:Get()) end):Subscribe(); bl2:Off()
	print("Observer same setup: fires", on, "values", table.concat(ov, ","))
	-- control: Effect directly on the gate node
	local a3 = q.Source(0); local bl3 = q.Blocker(); local g3 = a3:Apply(bl3)
	bl3:On(); a3:Set(1); local n3, s3 = 0, {}
	q.Effect(function() n3 += 1; table.insert(s3, g3:Get()) end, g3):Subscribe(); bl3:Off()
	print("control Effect on gate itself: runs", n3, "values", table.concat(s3, ","))
end
