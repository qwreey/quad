--!nocheck
local H = require("./harness")
local mockM = require("../../../quad-base/test/mock")
local q, D = H.q, H.D
local log = {}
local function L(s) table.insert(log, s) end
local function flush(title) print(title .. ": " .. table.concat(log, " ")) table.clear(log) end
local function eff(tag) return q.Effect(function() return function(d) L(tag .. "C(" .. tostring(d) .. ")") end end) end
local function od(tag) return q.OnDestroyed(function() L(tag .. "D") end) end
local function try(f) local ok, e = pcall(f) if not ok then L("ERR[" .. H.first(e) .. "]") end end

print("=== A. order ===")
do
	local root = D.Frame { eff("P1"), od("P2"), D.Frame { eff("c1"), D.Frame { eff("g1") } }, D.Frame { eff("c2") }, eff("P3") }
	root:Destroy(); flush("A1 Destroy P{P1,P2,c1{g1},c2,P3}")
	local root2 = D.Frame { eff("P"), D.Frame { eff("c") } }
	q.dispose(root2); flush("A2 dispose")
	local s = q.Slot({ D.Frame { eff("e1") }, D.Frame { eff("e2") }, D.Frame { eff("e3") } })
	local host = D.Frame { s }
	s:Clear(); flush("A3 Clear e1,e2,e3")
	local s2 = q.Slot({ D.Frame { eff("u1") }, D.Frame { eff("u2") } })
	q.dispose(s2); flush("A4 dispose(unmounted slot)")
	local data = q.Source({ 1, 2, 3 })
	local host3 = D.Frame { q.Slot():List(data, function(ctx) if ctx.Item == q.KeyGone then return nil end return ctx.Prev or D.Frame { eff("k" .. ctx.Item) } end) }
	data:Set({}); flush("A5 List all KeyGone (index keys)")
	host:Destroy(); host3:Destroy(); flush("A5b cleanup hosts")
end

print("=== A6. wave fires across hosts (mock Immediate, pre-order Destroying) ===")
do
	local pulse = q.Source(0)
	local P = D.Frame {
		pulse:Observer(function() L("P.obs") end),
		q.Effect(function() pulse:Get() L("P.effFn") return function(d) L("P.effC(" .. tostring(d) .. ")") end end, pulse),
		D.Frame { q.OnDestroyed(function() L("C.OD->Set") pulse:Set(pulse:Get() + 1) end) },
	}
	table.clear(log)
	P:Destroy(); flush("A6a child OnDestroyed Sets during parent Destroy")
	local P2 = D.Frame {
		q.OnDestroyed(function() L("P.OD->Set") pulse:Set(pulse:Get() + 1) end),
		D.Frame { pulse:Observer(function() L("C.obs") end), q.Effect(function() pulse:Get() L("C.effFn") return function(d) L("C.effC(" .. tostring(d) .. ")") end end, pulse) },
	}
	table.clear(log)
	P2:Destroy(); flush("A6b parent OnDestroyed Sets; child not yet destroying")
	local sib1obs
	local P3 = D.Frame {
		D.Frame { q.OnDestroyed(function() L("S1.OD->Set") pulse:Set(pulse:Get() + 1) end) },
		D.Frame { pulse:Observer(function() L("S2.obs") end) },
	}
	table.clear(log)
	P3:Destroy(); flush("A6c sibling (reverse child order in mock)")
end

print("=== B. dying per path ===")
do
	local e1 = eff("seatEff")
	local seat = q.Source(e1)
	local host = D.Frame { seat }
	seat:Set(nil); flush("B1 State<Effect?> seat -> nil")
	seat:Set(eff("seatEff2")); seat:Set(eff("seatEff3")); flush("B1b seat Effect -> other Effect")
	host:Destroy(); flush("B1c host Destroy with seatEff3")

	local child = D.Frame { eff("ch"), od("ch") }
	local cs = q.Source(child)
	local host2 = D.Frame { cs }
	cs:Set(nil); flush("B2 State<Instance?> seat -> nil (child detached)")
	host2:Destroy(); flush("B2b host destroyed, detached child alive")
	q.dispose(child); flush("B2c dispose(detached child)")

	local ex = D.Frame { eff("ex"), od("ex") }
	local s = q.Slot({ ex })
	local host3 = D.Frame { s }
	local got = s:Extract(1)
	flush("B3 Extract")
	got = nil; ex = nil
	for _ = 1, 5 do collectgarbage("collect") end
	flush("B3b drop extracted + GC")

	local data = q.Source({ "a" })
	local host4 = D.Frame { q.Slot():List(data, function(ctx) if ctx.Item == q.KeyGone then return nil end return ctx.Prev or D.Frame { eff("uo") } end, nil, { OwnsElements = false }) }
	data:Set({}); flush("B4 OwnsElements=false KeyGone(nil)")
	local data2 = q.Source({ "a" })
	local host5 = D.Frame { q.Slot():List(data2, function(ctx) if ctx.Item == q.KeyGone then return q.Detach end return ctx.Prev or D.Frame { eff("uoD") } end, nil, { OwnsElements = false }) }
	data2:Set({}); flush("B4b OwnsElements=false KeyGone(Detach)")

	local data3 = q.Source({ "a" })
	local held
	local s6 = q.Slot():List(data3, function(ctx) if ctx.Item == q.KeyGone then return q.Detach end if ctx.Prev then return ctx.Prev end held = D.Frame { eff("held"), od("held") } return held end)
	local host6 = D.Frame { s6 }
	data3:Set({}); flush("B5 owned Detach (held, unparented)")
	host6:Destroy(); flush("B5b host Destroy while element held by the mounted Slot")
	print("   held destroyed?", mockM.isDestroyed(held), "held parent", held.Parent)
	local ok, e = pcall(function() q.dispose(held) end); print("   dispose(held) after host destroyed:", ok, ok or H.first(e))
	local ok2, e2 = pcall(function() q.dispose(s6) end); print("   dispose(slot) after host destroyed:", ok2, ok2 or H.first(e2)); flush("B5c")

	local data7 = q.Source({ "a" })
	local host7 = D.Frame { q.Slot():List(data7, function(ctx) if ctx.Item == q.KeyGone then return nil end return ctx.Prev or D.Frame { eff("uoHost") } end, nil, { OwnsElements = false }) }
	host7:Destroy(); flush("B6 OwnsElements=false, host Destroy")

	local s8 = q.Slot({ D.Frame { eff("old") } })
	local host8 = D.Frame { s8 }
	s8:Replace(1, D.Frame { eff("new") }); flush("B7 Replace")

	local ue = eff("unbound")
	local host9 = D.Frame { ue }
	q.Backend.unbindLifetime(ue); host9:Destroy(); flush("B8 unbindLifetime then Destroy")

	local s10 = q.Slot({ D.Frame { eff("wrapped") } })
	local ws = q.Source(s10)
	local host10 = D.Frame { ws }
	ws:Set(nil); flush("B10 State<Slot?> seat -> nil (slot unmounted)")
	host10:Destroy(); flush("B10b host destroyed; unmounted slot keeps element")
	q.dispose(s10); flush("B10c dispose(unmounted slot)")
end

print("=== B9. H-590 yield window ===")
do
	local dep = q.Source(0)
	local yieldNow = false
	local E = q.Effect(function()
		dep:Get()
		if yieldNow then L("fn:yield") coroutine.yield() L("fn:resumed") end
		return function(d) L("C(" .. tostring(d) .. ")") end
	end, dep)
	local host = D.Frame { E }
	yieldNow = true
	local co = coroutine.create(function() dep:Set(1) end)
	coroutine.resume(co)
	host:Destroy()
	L("[destroyed]")
	yieldNow = false
	coroutine.resume(co); flush("B9a destroy during yield")
	local dep2 = q.Source(0)
	local y2 = false
	local E2 = q.Effect(function()
		dep2:Get()
		if y2 then coroutine.yield() end
		return function(d) L("C2(" .. tostring(d) .. ")") end
	end, dep2)
	local seat = q.Source(E2)
	local host2 = D.Frame { seat }
	y2 = true
	local co2 = coroutine.create(function() dep2:Set(1) end)
	coroutine.resume(co2)
	seat:Set(nil); L("[seat nil]")
	y2 = false
	coroutine.resume(co2); flush("B9b seat nil during yield")
end

print("=== C. late signals ===")
do
	local up = q.Source(0)
	local deb = up:Apply(q.Debounce({ Time = 1 }))
	local thr = up:Apply(q.Throttle({ Time = 1 }))
	local host = D.Frame { deb:Observer(function() L("deb") end), thr:Observer(function() L("thr") end) }
	table.clear(log)
	up:Set(1); up:Set(2)
	flush("C1 pre")
	host:Destroy()
	H.runTask(5); flush("C1 after destroy + timers")
	local src = q.Source(1)
	local f = D.Frame { Size = src }
	src:Set(q.Tween({ Value = 2, Time = 1, Completed = function() L("completed") end, Cancelled = function() L("cancelled") end }))
	local tw = mockM.tweenLog[#mockM.tweenLog].tween
	f:Destroy(); flush("C2 destroy with running tween")
	tw:simulateCompleted(); flush("C2b late engine Completed")
	local src3 = q.Source(1)
	local g = D.Frame { Size = src3 }
	src3:Set(q.Tween({ Value = 2, Time = 1, Completed = function() L("completed") end, Cancelled = function() L("cancelled") end }))
	src3:Set(nil); flush("C3 property seat retract (nil) with running tween")
	g:Destroy()
end

print("=== D. module instance drop ===")
do
	local QuadRoblox = require("../../../quad-roblox/src").QuadRoblox
	local q2 = H.Quad.New():UseProvider(QuadRoblox)
	q2.Backend.isInst = mockM.isMockInstance
	local f = q2.Declaration.Frame { q2.Effect(function() return function(d) L("q2C(" .. tostring(d) .. ")") end end), q2.OnDestroyed(function() L("q2D") end) }
	local wq = setmetatable({ q2 }, { __mode = "v" })
	q2 = nil
	for _ = 1, 5 do collectgarbage("collect") end
	flush("D1 module ref dropped, tree alive: q2 collected=" .. tostring(wq[1] == nil))
	f:Destroy(); flush("D1b then Destroy tree")
	local q3 = H.Quad.New():UseProvider(QuadRoblox)
	q3.Backend.isInst = mockM.isMockInstance
	local g = q3.Declaration.Frame { q3.Effect(function() return function(d) L("q3C(" .. tostring(d) .. ")") end end) }
	local wg = setmetatable({ g }, { __mode = "v" })
	q3 = nil; g = nil
	for _ = 1, 5 do collectgarbage("collect") end
	flush("D2 module + tree both dropped without Destroy: tree collected=" .. tostring(wg[1] == nil))
end

print("=== B11. OnDestroyed in a State seat (sugar/04:90) ===")
do
	local h = q.OnDestroyed(function() L("OD") end)
	local seat = q.Source(h)
	local host = D.Frame { seat }
	seat:Set(q.None); flush("B11a seat -> None (host alive)")
	host:Destroy(); flush("B11b host destroyed while hook out of seat")
	local h2 = q.OnDestroyed(function() L("OD2") end)
	local seat2 = q.Source(h2)
	local host2 = D.Frame { seat2 }
	seat2:Set(q.None); seat2:Set(h2); flush("B11c out and back in")
	host2:Destroy(); flush("B11d host destroyed after re-seat")
end
