-- round13 E3 probe (reactive core). Run: copy to quad-base/test/, ./scripts/relink.sh, luau quad-base/test/<this file>
local mock = require("./mock")
local collectgarbage = (_G :: any).collectgarbage
local q = mock.newQuad()
local Source, Effect, Blocker, Store, Ref = q.Source, q.Effect, q.Blocker, q.Store, q.Ref
local Operator = q.Operator
local function T(name, f)
	local ok, err = pcall(f)
	print(`--- {name}: {ok and "ok" or ("ERR " .. tostring(err))}`)
end

T("P1 revision sequence", function()
	local r = 0
	local seen = {}
	for i = 1, 5 do r = bit32.bnot(-r); print(" rev", r) end
	r = 2; for i = 1, 4 do r = bit32.bnot(-r); print(" rev", r) end
end)

T("P2 observer install fire misses Set made by another observer triggered in install", function()
	local s = Source(0)
	local other = Source(0)
	-- a pre-existing observer on `other` bumps s
	local o1 = other:Observer(function(st, _, from)
		if from ~= nil then s:Set(s:Get() + 1) end
	end):Subscribe()
	local seen = {}
	local o2 = s:Observer(function(st)
		seen[#seen + 1] = st:Get()
		if #seen == 1 then other:Set(1) end -- side effect during install
	end)
	print(" seen", table.concat(seen, ","), "s now", s:Get(), "rerunReq", o2._rerunRequired)
	o2:Subscribe()
	print(" after Subscribe seen", table.concat(seen, ","))
	s:Set(10)
	print(" after Set(10) seen", table.concat(seen, ","))
	local _ = o1
end)

T("P3 effect install fire sees own-set via pending", function()
	local s = Source(0)
	local seen = {}
	local e = Effect(function()
		seen[#seen + 1] = s:Get()
		if s:Get() == 0 then s:Set(1) end
	end, s)
	print(" seen", table.concat(seen, ","))
end)

T("P4 compute reads Get of downstream during fn (not cycle)", function()
	local a = Source(1)
	local b = Source(1)
	local c
	c = a:Compute(function(h) b:Set(h:Get()) return h:Get() * 2 end)
	local bo = b:Observer(function() end)
	print(" c", c:Get())
end)

T("P5 one blocker, two gated nodes, derived over both: notification count/order", function()
	local a, b = Source(0), Source(0)
	local bl = Blocker()
	local ga, gb = a:Apply(bl), b:Apply(bl)
	local c = ga:Compute(function(h, _, hb) return h:Get() + hb:Get() end, gb)
	local log = {}
	local o = c:Observer(function(st, _, from) log[#log + 1] = tostring(st:Get()) end):Subscribe()
	bl:On(); a:Set(1); b:Set(2); bl:Off()
	print(" log", table.concat(log, ","))
end)

T("P6 blocker Off inside a flush toggles On then Off (nested)", function()
	local a, b = Source(0), Source(0)
	local bl = Blocker()
	local ga, gb = a:Apply(bl), b:Apply(bl)
	local log = {}
	local toggled = false
	local oa = ga:Observer(function(st, _, from)
		if from == nil then return end
		log[#log + 1] = "a" .. st:Get()
		if not toggled then toggled = true; bl:On(); b:Set(99); bl:Off() end
	end):Subscribe()
	local ob = gb:Observer(function(st, _, from) if from ~= nil then log[#log + 1] = "b" .. st:Get() end end):Subscribe()
	bl:On(); a:Set(1); b:Set(2); bl:Off()
	print(" log", table.concat(log, ","))
end)

T("P7 effect cleanup dying at 4 sites + cleanup throwing", function()
	local s = Source(0)
	local log = {}
	local e = Effect(function()
		local v = s:Get()
		return function(dying) log[#log + 1] = `c{v}:{tostring(dying)}` end
	end, s)
	e:Subscribe()
	s:Set(1) -- rerun site
	e:Unsubscribe() -- unsubscribe site
	print(" log", table.concat(log, " "))
	-- bind to instance and destroy
	local inst = mock.Instance.new("Frame")
	local e2 = Effect(function()
		local v = s:Get()
		return function(dying) log[#log + 1] = `d{v}:{tostring(dying)}` end
	end, s)
	q.Backend.bindLifetime(inst, e2)
	s:Set(2)
	inst:Destroy()
	print(" log", table.concat(log, " "))
end)

T("P8 cleanup throws on rerun -> effect state", function()
	local s = Source(0)
	local runs = 0
	local e = Effect(function()
		runs += 1
		return function() if s:Get() == 1 then error("boom") end end
	end, s):Subscribe()
	local ok, err = pcall(function() s:Set(1) end)
	print(" set1", ok, err and string.sub(tostring(err), 1, 60))
	s:Set(2)
	print(" runs", runs, "running", e._running, "cleanupRunning", e._cleanupRunning)
	local ok2, err2 = pcall(function() e:Unsubscribe() end)
	print(" unsub", ok2, err2)
end)

local function countSubs(s) local n = 0 for _ in s._subs do n += 1 end return n end
T("P9 GC: unsubscribed observer, weak-subscribed dropped, gate dropped -> blocker handles", function()
	local s = Source(0)
	do
		local big = mock.Instance.new("Frame")
		local o = s:Observer(function() local _ = big end)
		local o2 = s:Observer(function() end):WeakSubscribe()
	end
	local bl = Blocker()
	do local g = s:Apply(bl) end
	local db = q.Debounce({ Time = 1 })
	do local g2 = s:Apply(db) end
	collectgarbage(); collectgarbage()
	local hn = 0 for _ in bl._handles do hn += 1 end
	local dn = 0 for _ in db._instances do dn += 1 end
	print(" subs", countSubs(s), "blocker handles", hn, "debounce instances", dn)
end)

T("P10 GC: Effect weak-subscribed dropped; strongly subscribed kept", function()
	local s = Source(0)
	local runs = 0
	do Effect(function() runs += 1 end, s):WeakSubscribe() end
	collectgarbage(); collectgarbage()
	s:Set(1)
	print(" runs after drop", runs, "subs", countSubs(s))
end)

T("P11 GC: debounce with pending timer and handle", function()
	mock.resetTimers()
	local s = Source(0)
	local db = q.Debounce({ Time = 1 })
	do local g = s:Apply(db); s:Set(1) end
	collectgarbage()
	print(" subs(before timer)", countSubs(s))
	mock.advanceTime(3)
	collectgarbage(); collectgarbage()
	print(" subs(after timers)", countSubs(s), "pending", mock.pendingTimers())
end)

T("P12 Store edge", function()
	local st = Store({ a = Source(1) })
	local ok, e = pcall(function() return st:Of("__x") end)
	print(" __x", ok, e and string.sub(tostring(e),1,80))
	st.Of = nil -- raw write nil
	print(" Of still method", pcall(function() return st:Of("b") end))
	local ok2, e2 = pcall(function() st.Names = 5; return st:Names() end)
	print(" Names shadowed", ok2, e2 and string.sub(tostring(e2), 1, 100))
	print(" tostring", pcall(tostring, st))
end)

T("P13 Operator nil/type boundaries", function()
	local a = Source(1)
	local n = Source(nil)
	local r = a:Apply(Operator.Sum(n))
	print(" sum nil arg", pcall(function() return r:Get() end))
	n:Set(2)
	print(" sum after set", pcall(function() return r:Get() end))
	local nn = Source(nil)
	local r2 = nn:Apply(Operator.Not)
	print(" Not nil", r2:Get())
	local x = Source(2^31)
	print(" Bnot 2^31", x:Apply(Operator.Bnot):Get(), "Shl(1)", x:Apply(Operator.Shl(1)):Get())
	print(" Band float", Source(3.7):Apply(Operator.Band(1)):Get(), "neg", Source(-1):Apply(Operator.Band(255)):Get())
	print(" Band NaN", pcall(function() return Source(0/0):Apply(Operator.Band(1)):Get() end))
	print(" Shl State nil", pcall(function() return Source(1):Apply(Operator.Shl(Source(nil))):Get() end))
	print(" Min NaN", Source(0/0):Apply(Operator.Min(1)):Get(), Source(1):Apply(Operator.Min(0/0)):Get())
	print(" Alternative false", Source(false):Apply(Operator.Alternative(true)):Get())
	print(" Indexed nil value", pcall(function() return Source(nil):Apply(Operator.Indexed("x")):Get() end))
end)

T("P14 Compute normalizes its own dep once (converging self-Set)", function()
	local a = Source(5)
	local calls = 0
	local c = a:Compute(function(h) calls += 1; if h:Get() > 10 then a:Set(10) end return h:Get() end)
	local seen = {}
	local o = c:Observer(function(st) seen[#seen + 1] = st:Get() end):Subscribe()
	a:Set(50)
	print(" c", c:Get(), "a", a:Get(), "seen", table.concat(seen, ","), "calls", calls)
end)

T("P15 Effect destroys its own host inside fn", function()
	local s = Source(0)
	local inst = mock.Instance.new("Frame")
	local log = {}
	local e = Effect(function()
		local v = s:Get()
		if v == 1 then inst:Destroy() end
		return function(dying) log[#log + 1] = `c{v}:{tostring(dying)}` end
	end, s)
	q.Backend.bindLifetime(inst, e)
	s:Set(1)
	s:Set(2)
	print(" log", table.concat(log, " "), "rerunReq", e._rerunRequired)
end)

T("P16 cleanup Set in Unsubscribe then resubscribe", function()
	local s = Source(0)
	local runs = {}
	local e = Effect(function()
		runs[#runs + 1] = s:Get()
		return function() if s:Get() == 0 then s:Set(7) end end
	end, s):Subscribe()
	e:Unsubscribe()
	print(" after unsub runs", table.concat(runs, ","), "rerunReq", e._rerunRequired)
	e:Subscribe()
	print(" after resub runs", table.concat(runs, ","))
end)

T("P17 Revision boundary with Depend/Compute", function()
	local a, b = Source(1), Source(2)
	a.Revision = 1; b.Revision = 0xFFFFFFFF
	local d = a:Depend(b)
	local c = d:Compute(function(h) return h:Get() * 10 end)
	local n = 0
	local o = c:Observer(function() n += 1 end):Subscribe()
	a:Set(3); print(" c", c:Get(), "rev", a.Revision)
	a:Set(4); print(" c", c:Get(), "rev", a.Revision)
	b:Set(9); print(" c", c:Get(), "revb", b.Revision, "fires", n)
end)

T("P18 gate setup calls emit synchronously / returns emit", function()
	local a = Source(1)
	local g = a:Gate(function(emit) print(" emit in setup ->", emit()); return function() emit() end end)
	local n = 0
	local o = g:Observer(function() n += 1 end):Subscribe()
	a:Set(2)
	print(" fires", n, "g", g:Get())
end)

-- P19 (Compute that Sets its own dep on every pass): hangs in State.Get loop — documented UB, removed

T("P20 Debounce/Throttle zero time & cancel-reschedule", function()
	mock.resetTimers()
	for _, cfg in { { "D", { Time = 0 } }, { "D", { Time = 0, Leading = true } }, { "T", { Time = 0 } }, { "T", { Time = 0, Trailing = false } } } do
		local s = Source(0)
		local f = if cfg[1] == "D" then q.Debounce(cfg[2]) else q.Throttle(cfg[2])
		local g = s:Apply(f)
		local seen = {}
		local o = g:Observer(function(st, _, from) if from then seen[#seen + 1] = st:Get() end end):Subscribe()
		s:Set(1); s:Set(2); s:Set(3)
		local before = table.concat(seen, ",")
		mock.advanceTime(0)
		local mid = table.concat(seen, ",")
		f:Cancel(); s:Set(4); f:Cancel(); s:Set(5)
		mock.advanceTime(0); mock.advanceTime(0)
		print(" ", cfg[1], cfg[2].Leading, cfg[2].Trailing, "sameTick", before, "adv0", mid, "final", table.concat(seen, ","), "pending", mock.pendingTimers(), "blocking?", g._withheld and next(g._withheld) ~= nil)
		o:Unsubscribe()
	end
end)

T("P21 GC: observer/effect bound to destroyed instance, capturing it", function()
	local s = Source(0)
	local weak = setmetatable({}, { __mode = "k" })
	do
		local inst = mock.Instance.new("Frame")
		local o = s:Observer(function() local _ = inst end)
		local e = Effect(function() local _ = inst end, s)
		q.Backend.bindLifetime(inst, o); q.Backend.bindLifetime(inst, e)
		weak[inst] = true; weak[o] = true; weak[e] = true
		inst:Destroy()
	end
	collectgarbage(); collectgarbage(); collectgarbage()
	local n = 0 for _ in weak do n += 1 end
	print(" survivors", n, "subs", countSubs(s))
	-- not destroyed, just dropped (no Destroy) — held by gchold while the inst lives
	do
		local inst = mock.Instance.new("Frame")
		local o = s:Observer(function() local _ = inst end)
		q.Backend.bindLifetime(inst, o)
		weak[o] = true
	end
	collectgarbage(); collectgarbage()
	n = 0 for _ in weak do n += 1 end
	print(" survivors(dropped undestroyed)", n, "subs", countSubs(s))
end)
