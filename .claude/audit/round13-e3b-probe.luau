-- round13 E3-2 probe (gate/timer reentrancy, yield). Copy to quad-base/test/, ./scripts/relink.sh, luau quad-base/test/<this file>
local mock = require("./mock")
local q = mock.newQuad()
local Source, Effect, Blocker, Ref = q.Source, q.Effect, q.Blocker, q.Ref
local adv = mock.advanceTime
local function T(name, f)
	mock.resetTimers()
	local ok, err = pcall(f)
	print(`--- {name}: {ok and "ok" or ("ERR " .. tostring(err))}`)
end
local function obs(st)
	local rec = { seen = {} }
	rec.o = st:Observer(function(s, _, from)
		if from ~= nil or rec.installed then rec.seen[#rec.seen + 1] = `{s:Get()}@{mock.now()}` end
	end):Subscribe()
	rec.installed = true
	return rec
end
local function S(rec) return table.concat(rec.seen, ",") end

-- ── B: yield in Compute / multiple coroutines ─────────────────────────
T("B1 gen1 yields, upstream Set (gen2), B runs gen2 and yields, A returns, C reads", function()
	local s = Source(0)
	local runs = {}
	local park = true
	local c = s:Compute(function(h)
		local v = h:Get()
		runs[#runs + 1] = `run v={v} co={tostring(coroutine.running()):sub(-6)}`
		if park and coroutine.isyieldable() then coroutine.yield() end
		return v * 10
	end)
	local A = coroutine.create(function() return c:Get() end)
	print(" A resume", coroutine.resume(A), coroutine.status(A))
	s:Set(1)
	local B = coroutine.create(function() return c:Get() end)
	print(" B resume", coroutine.resume(B), coroutine.status(B))
	print(" _computing", c._computing, "target", c._cacheTargetCount)
	park = false
	print(" A finish", coroutine.resume(A))
	print(" after A: _computing", c._computing, "curr", c._cacheCurrCount, "target", c._cacheTargetCount)
	local ok, v = pcall(function() return c:Get() end)
	print(" C main-thread Get", ok, v)
	print(" B finish", coroutine.resume(B))
	print(" runs:", #runs)
	for _, r in runs do print("  ", r) end
end)

T("B2 same, but upstream behind a closed Blocker (drift path, H-540 branch)", function()
	local s = Source(0)
	local bl = Blocker()
	local g = s:Apply(bl)
	local runs = 0
	local park = true
	local c = g:Compute(function(h)
		local v = h:Get()
		runs += 1
		if park and coroutine.isyieldable() then coroutine.yield() end
		return v
	end)
	local A = coroutine.create(function() return c:Get() end)
	coroutine.resume(A)
	bl:On()
	s:Set(5)
	local B = coroutine.create(function() return c:Get() end)
	print(" B resume", coroutine.resume(B), coroutine.status(B), "runs", runs)
	park = false
	print(" A finish", coroutine.resume(A))
	local ok, v = pcall(function() return c:Get() end)
	print(" C Get", ok, v, "runs", runs)
	print(" B finish", coroutine.resume(B), "runs", runs)
	bl:Off()
end)

T("B3 reader while gen1 yields and NO drift -> Quad0184 (documented)", function()
	local s = Source(0)
	local park = true
	local c = s:Compute(function(h) local v = h:Get(); if park and coroutine.isyieldable() then coroutine.yield() end; return v end)
	local A = coroutine.create(function() return c:Get() end)
	coroutine.resume(A)
	local ok, e = pcall(function() return c:Get() end)
	print(" C", ok, tostring(e):sub(1, 60))
	park = false
	print(" A", coroutine.resume(A))
	print(" after", pcall(function() return c:Get() end))
end)

T("B4 Effect fn yields; dep Set from main + Rerun from another coroutine; runs/pending", function()
	local s = Source(0)
	local log = {}
	local park = true
	local e = Effect(function()
		local v = s:Get()
		log[#log + 1] = `fn {v}`
		if park and v == 1 and coroutine.isyieldable() then coroutine.yield() end
		log[#log + 1] = `fn-end {v}`
		return function() log[#log + 1] = `cl {v}` end
	end, s):Subscribe()
	local A = coroutine.create(function() s:Set(1) end)
	coroutine.resume(A)
	s:Set(2)
	s:Set(3)
	local B = coroutine.create(function() e:Rerun() end)
	coroutine.resume(B)
	park = false
	print(" A", coroutine.resume(A), coroutine.status(A))
	print(" log", table.concat(log, " | "))
	print(" _running", e._running, "_pending", e._pending)
end)

T("B5 Observer fn yields; second Set runs fn overlapped (doc'd: stale last)", function()
	local s = Source(0)
	local log = {}
	local park = true
	local o = s:Observer(function(st, _, from)
		if from == nil then return end
		local v = st:Get()
		if park and v == 1 and coroutine.isyieldable() then coroutine.yield() end
		log[#log + 1] = v
	end):Subscribe()
	local A = coroutine.create(function() s:Set(1) end)
	coroutine.resume(A)
	s:Set(2)
	park = false
	coroutine.resume(A)
	print(" handled order", table.concat(log, ","), "(stale-last is documented)")
	local _ = o
end)

-- ── A: OffWithoutEmit directed ─────────────────────────────────────────
T("A1 discard then same-tick Set is observed; discard of a Compute sibling", function()
	local a, b = Source(0), Source(0)
	local bl = Blocker()
	local ga = a:Apply(bl)
	local c = ga:Compute(function(h, _, hb) return h:Get() + hb:Get() end, b)
	local r = obs(c)
	bl:On(); a:Set(5); bl:OffWithoutEmit()
	print(" after discard seen", S(r), "c", c:Get())
	b:Set(1)
	print(" after b:Set(1) seen", S(r))
	bl:On(); a:Set(7); bl:OffWithoutEmit(); a:Set(7)
	print(" after discard + a:Set(same 7) seen", S(r))
end)

T("A2 OffWithoutEmit inside an Off flush (another gate's observer discards the batch mid-walk)", function()
	local a, b = Source(0), Source(0)
	local bl = Blocker()
	local ga, gb = a:Apply(bl), b:Apply(bl)
	local ra = { seen = {} }
	local oa = ga:Observer(function(s, _, from) if from ~= nil then ra.seen[#ra.seen + 1] = s:Get(); bl:On(); bl:OffWithoutEmit() end end):Subscribe()
	local rb = obs(gb)
	bl:On(); a:Set(1); b:Set(2); bl:Off()
	print(" a seen", table.concat(ra.seen, ","), "b seen", S(rb), "(one of the two dropped depending on order)")
	b:Set(3)
	print(" after b:Set(3) b seen", S(rb))
	local _ = oa
end)

T("A3 On/Off toggled N times while gate withholds: one notification at the latest value", function()
	local s = Source(0)
	local bl = Blocker()
	local r = obs(s:Apply(bl))
	bl:On(); s:Set(1); bl:On(); s:Set(2); bl:OffWithoutEmit(); bl:On(); s:Set(3); bl:On(); bl:Off(); bl:Off()
	print(" seen", S(r))
end)

-- ── C: Debounce/Throttle reentrancy ──────────────────────────────────
T("C1 downstream Cancel during the LEADING pass (idle leading Debounce)", function()
	local s = Source(0)
	local h = Ref()
	local g = s:Apply(q.Debounce({ Time = 1, Leading = true, Handle = h }))
	local seen = {}
	local o = g:Observer(function(st, _, from) if from ~= nil then seen[#seen + 1] = `{st:Get()}@{mock.now()}`; h.Value:Cancel() end end):Subscribe()
	s:Set(1)
	print(" pending timers", mock.pendingTimers and mock.pendingTimers() or "?")
	s:Set(2)
	adv(1)
	s:Set(3)
	adv(5)
	print(" seen", table.concat(seen, ","))
	local _ = o
end)

T("C2 downstream Flush inside trailing flush; Cancel inside Flush", function()
	local s = Source(0)
	local h = Ref()
	local g = s:Apply(q.Debounce({ Time = 1, Handle = h }))
	local seen = {}
	local n = 0
	local o = g:Observer(function(st, _, from)
		if from == nil then return end
		seen[#seen + 1] = `{st:Get()}@{mock.now()}`
		n += 1
		if n == 1 then s:Set(10); h.Value:Flush() end
		if n == 2 then s:Set(20); h.Value:Cancel() end
	end):Subscribe()
	s:Set(1)
	adv(1)
	adv(5)
	print(" seen", table.concat(seen, ","), "value", g:Get(), "blocking", "pending", mock.pendingTimers and mock.pendingTimers())
	s:Set(30)
	adv(5)
	print(" after Set(30) seen", table.concat(seen, ","))
	local _ = o
end)

T("C3 Set from inside a timer callback path (observer Sets source during commit) — leading/trailing four", function()
	for _, cfg in { { false, true }, { true, true }, { true, false }, { false, false } } do
		for _, name in { "Debounce", "Throttle" } do
			mock.resetTimers()
			local ok, err = pcall(function()
				local s = Source(0)
				local g = s:Apply(q[name]({ Time = 1, Leading = cfg[1], Trailing = cfg[2] }))
				local seen = {}
				local k = 0
				local o = g:Observer(function(st, _, from)
					if from == nil then return end
					seen[#seen + 1] = `{st:Get()}@{mock.now()}`
					k += 1
					if k <= 2 then s:Set(st:Get() + 100) end
				end):Subscribe()
				s:Set(1)
				adv(0.5)
				s:Set(2)
				for _ = 1, 10 do adv(1) end
				print(`  {name} L={cfg[1]} T={cfg[2]} seen {table.concat(seen, ",")} val {g:Get()} src {s:Get()} timers {mock.pendingTimers()}`)
				local _ = o
			end)
			if not ok then print(`  {name} L={cfg[1]} T={cfg[2]} ERR {err}`) end
		end
	end
end)

T("C4 Time State changed inside the flush (Q55 cache: next window one signal later)", function()
	local s = Source(0)
	local t = Source(1)
	local g = s:Apply(q.Throttle({ Time = t }))
	local seen = {}
	local o = g:Observer(function(st, _, from) if from ~= nil then seen[#seen + 1] = `{st:Get()}@{mock.now()}`; t:Set(3) end end):Subscribe()
	s:Set(1) -- leading pass @0, window uses cached 1
	s:Set(2)
	adv(1) -- trailing 2@1, reopen with cached 1 (not 3)
	s:Set(3)
	adv(10)
	print(" seen", table.concat(seen, ","))
	local _ = o
end)

T("C5 factory broadcast Flush: flushing gate1 Sets gate2's source mid-walk", function()
	local f = q.Debounce({ Time = 1 })
	local a, b = Source(0), Source(0)
	local ga, gb = a:Apply(f), b:Apply(f)
	local sa, sb = {}, {}
	local oa = ga:Observer(function(st, _, from) if from ~= nil then sa[#sa + 1] = st:Get(); b:Set(b:Get() + 1) end end):Subscribe()
	local ob = gb:Observer(function(st, _, from) if from ~= nil then sb[#sb + 1] = st:Get() end end):Subscribe()
	a:Set(1); b:Set(5)
	f:Flush()
	print(" after Flush a", table.concat(sa, ","), "b", table.concat(sb, ","), "b now", b:Get(), "timers", mock.pendingTimers())
	adv(3)
	print(" after adv a", table.concat(sa, ","), "b", table.concat(sb, ","))
	local _ = { oa, ob }
end)

T("C6 Cancel called from an upstream observer BEFORE the gate hears the same Set", function()
	local s = Source(0)
	local h = Ref()
	-- observer on s registered first so it may run before the gate in the snapshot
	local pre = s:Observer(function(_, _, from) if from ~= nil and h.Value then h.Value:Cancel() end end):Subscribe()
	local g = s:Apply(q.Debounce({ Time = 1, Handle = h }))
	local r = obs(g)
	s:Set(1); adv(0.5); s:Set(2); adv(2)
	print(" seen", S(r), "g", g:Get())
	local _ = pre
end)

T("C7 MaxTime tie with window; Time=0 same-tick; advanceTime(0)", function()
	local s = Source(0)
	local g = s:Apply(q.Debounce({ Time = 1, MaxTime = 1 }))
	local r = obs(g)
	s:Set(1); adv(1)
	s:Set(2); adv(0.5); s:Set(3); adv(0.5)
	adv(5)
	print(" tie seen", S(r), "timers", mock.pendingTimers())
	mock.resetTimers()
	local s2 = Source(0)
	local g2 = s2:Apply(q.Throttle({ Time = 0 }))
	local r2 = obs(g2)
	s2:Set(1); s2:Set(2); s2:Set(3)
	print(" T0 before adv", S(r2), "timers", mock.pendingTimers())
	adv(0)
	print(" T0 after adv0", S(r2), "timers", mock.pendingTimers())
end)

T("C8 Blocker->Debounce->Throttle: Blocker Off exactly at window expiry tick", function()
	local s = Source(0)
	local bl = Blocker()
	local chain = s:Apply(bl):Apply(q.Debounce({ Time = 1 })):Apply(q.Throttle({ Time = 1 }))
	local r = obs(chain)
	s:Set(1); adv(1) -- debounce trailing 1@1 -> throttle leading pass 1@1
	bl:On(); s:Set(2); adv(1) -- throttle window ends @2 (nothing withheld)
	bl:Off() -- @2: debounce opens
	adv(1) -- @3 debounce trailing -> throttle idle leading pass
	bl:On(); s:Set(3); bl:OffWithoutEmit(); adv(5)
	print(" seen", S(r), "val", chain:Get(), "timers", mock.pendingTimers())
	s:Set(4); adv(5)
	print(" after Set(4)", S(r))
end)
