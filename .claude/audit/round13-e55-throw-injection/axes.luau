--!nocheck
-- E55 directed probes: the separate axes (a)~(d) + the sites the fuzzer's tree cannot reach observably.
-- usage: luau axes.luau
local H = require("./harness")
local mockM = require("../../../quad-base/test/mock")
local q, D = H.q, H.D
local Op = q.Operator

-- engine-like handler isolation (same as fuzz.luau)
local handlerErrs = {}
do
	local probe = mockM.Instance.new("Frame")
	local SignalMT = getmetatable(probe.Destroying)
	SignalMT.Fire = function(self, ...)
		local snapshot = table.clone(self.connections)
		for i = #snapshot, 1, -1 do
			local conn = snapshot[i]
			if conn.Connected then
				local ok, e = pcall(conn.fn, ...)
				if not ok then table.insert(handlerErrs, H.first(e)) end
			end
		end
	end
	probe:Destroy()
end

local function norm(e)
	local s = H.first(e):gsub("^[^:]*%.luau:%d+: ", "")
	return s:match("^(Quad%d%d%d%d)") or s:sub(1, 90)
end
local function try(f) local ok, e = pcall(f); return ok and "ok" or norm(e) end
local function say(...) print(...) end

-- ── P1 Compute throw read by an Effect / Observer / List: Compute recovers, the reader follows ITS contract ──
say("== P1 transient Compute throw, who absorbs it")
do
	local a = q.Source(1)
	local bad = false
	local c = a:Compute(function(s) local v = s:Get(); if bad then error("C-throw") end return v * 10 end)
	local effRuns, effLast = 0, nil
	local obsLast = nil
	local host = D.Frame({
		q.Effect(function() effRuns += 1; effLast = c:Get() end, c),
		c:Observer(function(s) obsLast = s:Get() end),
	})
	say("  before: effRuns", effRuns, "effLast", effLast, "obsLast", obsLast)
	bad = true
	say("  a:Set(2) with throwing fn:", try(function() a:Set(2) end))
	bad = false
	say("  reread same gen:", try(function() return c:Get() end))
	say("  a:Set(3):", try(function() a:Set(3) end), "c:Get()", try(function() return c:Get() end) == "ok" and c:Get())
	say("  after: effRuns", effRuns, "effLast", effLast, "obsLast", obsLast)
	say("  (which reader absorbed the throw depends on subscriber iteration order; the Effect, if it was first, is dead:)")
	a:Set(4)
	say("  a:Set(4): effRuns", effRuns, "effLast", effLast, "obsLast", obsLast)
	host:Destroy()
end
-- Operator.Clamp documented as "recovers next generation" (sugar/02:158) — read by an Effect
do
	local lo, v = q.Source(0), q.Source(5)
	local hi = q.Source(10)
	local cl = v:Apply(Op.Clamp(lo, hi))
	local effLast, effRuns = nil, 0
	local host = D.Frame({ q.Effect(function() effRuns += 1; effLast = cl:Get() end, cl) })
	say("  Clamp: first run", effRuns, effLast)
	say("  lo:Set(20) (lo > hi):", try(function() lo:Set(20) end))
	say("  lo:Set(1):", try(function() lo:Set(1) end), "cl:Get()", cl:Get(), "effect saw", effLast, "runs", effRuns)
	v:Set(7)
	say("  v:Set(7): cl", cl:Get(), "effect saw", effLast, "runs", effRuns, " (dead Effect -> stays)")
	host:Destroy()
end
-- the same with the reader being a :List updateFn (new element reads the poisoned generation)
do
	local a = q.Source(1)
	local bad = false
	local c = a:Compute(function(s) local v = s:Get(); if bad then error("C-throw") end return v end)
	local items = q.Source({ 1 })
	local sib = q.Slot({ D.Frame({ Name = "sib" }) })
	local sl = q.Slot():List(items, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		return ctx.Prev or D.Frame({ Name = "i" .. ctx.Item, ZIndex = c })
	end)
	local root = D.Frame({ sl, sib })
	say("  List: initial sl.Length", sl.Length:Get(), "sib.Offset", sib.Offset:Get())
	bad = true
	say("  List: a:Set(2) throwing (read by i1's ZIndex binding):", try(function() a:Set(2) end))
	bad = false
	say("  items:Set({1,2}) in the same generation:", try(function() items:Set({ 1, 2 }) end))
	a:Set(3)
	items:Set({ 1, 2, 3 })
	say("  after a:Set(3), items {1,2,3}: sl.Length", sl.Length:Get(), "sib.Offset", sib.Offset:Get(), "(want 3 / 4)")
	root:Destroy()
end

-- ── P2 axis (a): side effects done BEFORE the throw stay ──
say("== P2 side effects before the throw")
do
	local a, other = q.Source(1), q.Source(0)
	local s = q.Slot()
	local host = D.Frame({ s })
	local o = a:Observer(function(st)
		if st:Get() == 2 then other:Set(99); s:Add(D.Frame({ Name = "pre" })); error("after-side-effects") end
	end)
	o:Subscribe()
	say("  a:Set(2):", try(function() a:Set(2) end), "other", other:Get(), "slot Length", s.Length:Get())
	o:Unsubscribe()
	host:Destroy()
end
do -- updateFn that Sets another source then throws on the 2nd item
	local items, other = q.Source({ 1 }), q.Source(0)
	local sl = q.Slot():List(items, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		if ctx.Item == 2 then other:Set(7); error("upd") end
		return ctx.Prev or D.Frame({ Name = "i" .. ctx.Item })
	end)
	local host = D.Frame({ sl })
	say("  updateFn: items {1,2,3}:", try(function() items:Set({ 1, 2, 3 }) end), "other", other:Get(), "children",
		#host:GetChildren(), "Length", sl.Length:Get())
	items:Set({ 3, 1 })
	say("  next cycle {3,1}: children", #host:GetChildren(), "Length", sl.Length:Get(), "(Length frozen per core/06:400)")
	host:Destroy()
end

-- ── P3 axis (b): two throwing subscribers in one wave ──
say("== P3 two throwers in one wave")
do
	local a = q.Source(0)
	local log = {}
	local obs = {}
	for i = 1, 4 do
		local o = a:Observer(function(st)
			local v = st:Get()
			table.insert(log, i .. ":" .. v)
			if v == 1 then error("T" .. i) end
		end)
		o:Subscribe()
		obs[i] = o
	end
	table.clear(log)
	say("  a:Set(1):", try(function() a:Set(1) end), "ran:", table.concat(log, " "))
	table.clear(log)
	a:Set(2)
	table.sort(log)
	say("  a:Set(2) (next wave):", table.concat(log, " "), "— all four run again")
	for _, o in obs do
		say("   handle", tostring(o), "WeakSubscribe after:", try(function() o:WeakSubscribe() end))
		o:Unsubscribe()
	end
end
do -- Effect + Observer + a Compute chain behind them, the wave cut in the middle of a chain
	local a = q.Source(0)
	local mid = a:Compute(function(s) return s:Get() + 100 end)
	local seen = {}
	local hs = {}
	hs[1] = mid:Observer(function(s) seen.m1 = s:Get(); if s:Get() == 101 then error("M1") end end):Subscribe()
	hs[2] = mid:Observer(function(s) seen.m2 = s:Get() end):Subscribe()
	hs[3] = a:Observer(function(s) seen.a1 = s:Get() end):Subscribe()
	local ok = pcall(function() a:Set(1) end)
	say("  chain: after a:Set(1) seen m1/m2/a1 =", seen.m1, seen.m2, seen.a1, "(some subscribers missed the cut wave)")
	a:Set(2)
	say("  a:Set(2): m1/m2/a1 =", seen.m1, seen.m2, seen.a1)
	for _, h in hs do h:Unsubscribe() end
end

-- ── P4 axis (c): Traceback blame, synchronous sites inside the component call ──
say("== P4 Traceback: does the trace name the throwing user line?")
do
	local THIS = "axes.luau"
	local function case(name, build)
		local line
		local Comp = function()
			return build(function(tag) line = debug.info(2, "l"); error("boom:" .. tag) end)
		end
		local got
		local Safe = q.Traceback(Comp, function(err, trace)
			got = { err = tostring(err), trace = trace }
			return D.Frame({ Name = "fallback" })
		end)
		local ok = pcall(Safe)
		if not got then say(("  %-14s NOT CAUGHT (ok=%s)"):format(name, tostring(ok))); return end
		local errLine = tonumber(got.err:match(THIS .. ":(%d+):"))
		local traceHas = got.trace:find(THIS .. ":" .. tostring(line), 1, true) ~= nil
		local depth = 0
		for _ in got.trace:gmatch("\n") do depth += 1 end
		say(("  %-14s err prefix line %s | trace has the callback line %s: %s | trace lines %d"):format(name, tostring(errLine), tostring(line), tostring(traceHas), depth))
	end
	local a = q.Source(1)
	case("compute", function(boom) return D.Frame({ ZIndex = a:Compute(function() boom("c") end) }) end)
	case("observer", function(boom) return D.Frame({ a:Observer(function() boom("o") end) }) end)
	case("effectFn", function(boom) return D.Frame({ q.Effect(function() boom("e") end) }) end)
	case("preRef", function(boom) local r = q.PreRef(nil); r:Callback(function(v) if v then boom("pre") end end); return D.Frame({ r }) end)
	case("postRef", function(boom) local r = q.PostRef(nil); r:Callback(function(v) if v then boom("post") end end); return D.Frame({ r }) end)
	case("onCreated", function(boom) return D.Frame({ q.OnCreated(function() boom("oc") end) }) end)
	case("onRendered", function(boom) return D.Frame({ q.OnRendered(function() boom("or") end) }) end)
	case("updateFn", function(boom) return D.Frame({ q.Slot():List({ 1 }, function() boom("u") end) }) end)
	case("keyFn", function(boom) return D.Frame({ q.Slot():List({ 1 }, function(ctx) return D.Frame({}) end, function() boom("k") end) }) end)
	case("modFn", function(boom) return D.Frame({ D.Modifier.Frame():ZIndex(3):ZIndex(function() boom("m") end) }) end)
	case("tweenStarted", function(boom) return D.Frame({ BackgroundTransparency = q.Tween({ Value = 0.5, Time = 1, Started = function() boom("ts") end }) }) end)
	case("Offset obs", function(boom) local s = q.Slot(); return D.Frame({ s, s.Offset:Observer(function(st) if st:Get() then boom("off") end end) }) end)
	-- later sites: the throw surfaces at the Set line, outside any boundary the component had
	local caughtLater = "n/a"
	local src = q.Source(1)
	local Safe = q.Traceback(function()
		return D.Frame({ src:Observer(function(s) if s:Get() == 2 then error("late") end end) })
	end, function() caughtLater = "caught by boundary"; return D.Frame({}) end)
	local inst = Safe()
	local r = try(function() src:Set(2) end)
	say(("  later Observer throw after mount: boundary %s, Set line got %s"):format(caughtLater, r))
	inst:Destroy()
end

-- ── P5 axis (d): GC residue after throws ──
say("== P5 GC residue")
do
	local function gc() for _ = 1, 4 do collectgarbage("collect") end end
	local weak = setmetatable({}, { __mode = "v" })
	local a = q.Source(1)
	-- (1) Observer that threw on a destroyed host
	do
		local o = a:Observer(function(s) if s:Get() == 2 then error("x") end end)
		local h = D.Frame({ o })
		pcall(function() a:Set(2) end)
		h:Destroy()
		weak.obsThrown = o
	end
	-- (2) Effect whose fn threw, bound to a destroyed host
	do
		local b = q.Source(1)
		local e = q.Effect(function() if b:Get() == 2 then error("e") end end, b)
		local h = D.Frame({ e })
		pcall(function() b:Set(2) end)
		h:Destroy()
		weak.effThrown = e
	end
	-- (3) Effect whose fn threw while STRONGLY subscribed, then dropped (doc: stays for the module lifetime)
	do
		local b = q.Source(1)
		local e = q.Effect(function() if b:Get() == 2 then error("e") end end, b):Subscribe()
		pcall(function() b:Set(2) end)
		weak.effStrongDead = e
	end
	-- (4) Slot whose :List updateFn threw (gate stuck), host destroyed
	do
		local items = q.Source({ 1 })
		local sl = q.Slot():List(items, function(ctx) if ctx.Item == 2 then error("u") end; if ctx.Item == q.KeyGone then return nil end return ctx.Prev or D.Frame({}) end)
		local h = D.Frame({ sl })
		pcall(function() items:Set({ 1, 2 }) end)
		h:Destroy()
		weak.stuckSlot = sl
		weak.stuckHost = h
	end
	-- (5) half-built instance from a Declaration that threw (not returned; parent of a Ref)
	do
		local r = q.Ref(nil)
		pcall(function() return D.Frame({ r, q.OnRendered(function() error("r") end) }) end)
		weak.halfBuilt = r.Value
		weak.halfRef = r
	end
	-- (6) Tween record whose Started threw on a destroyed host
	do
		local h = D.Frame({ BackgroundTransparency = 0 })
		local st = q.Source(0)
		local h2 = D.Frame({ BackgroundTransparency = st })
		pcall(function() st:Set(q.Tween({ Value = 0.5, Time = 1, Started = function() error("ts") end, Completed = function() end })) end)
		h2:Destroy()
		weak.tweenHost = h2
		h:Destroy()
	end
	-- (6b) the same without the throw (control)
	do
		local st = q.Source(0)
		local h2 = D.Frame({ BackgroundTransparency = st })
		st:Set(q.Tween({ Value = 0.5, Time = 1, Started = function() end, Completed = function() end }))
		h2:Destroy()
		weak.tweenHostCtl = h2
	end
	-- (7) Offset subscriber that threw: parent bookkeeping frozen, host destroyed
	do
		local s1, s2 = q.Slot(), q.Slot()
		local h = D.Frame({ s1, s2, s2.Offset:Observer(function(st) if st:Get() == 2 then error("off") end end) })
		pcall(function() s1:Add(D.Frame({})) end)
		h:Destroy()
		weak.offHost = h
	end
	gc()
	for _, k in { "obsThrown", "effThrown", "effStrongDead", "stuckSlot", "stuckHost", "halfBuilt", "halfRef", "tweenHost", "tweenHostCtl", "offHost" } do
		say(("  %-14s %s"):format(k, weak[k] ~= nil and "ALIVE" or "collected"))
	end
end

-- ── P6 attach window: first-cycle updateFn throw when mounting into an already-mounted Slot ──
say("== P6 attach window (H-554 / Quad0167)")
do
	local S1 = q.Slot()
	local root = D.Frame({ S1 })
	local items = q.Source({ 1, 2 })
	local lst = q.Slot():List(items, function(ctx)
		if ctx.Item == 2 then error("first-cycle") end
		if ctx.Item == q.KeyGone then return nil end
		return ctx.Prev or D.Frame({})
	end)
	-- build the frame WITHOUT mounting the list first: an unmounted Slot activates on mount
	local holder = q.Slot({ D.Frame({ Name = "keep" }) })
	local fr = D.Frame({ Name = "fr" })
	say("  S1:Add(frame carrying an unmounted list slot) -> ", try(function() S1:Add(D.Frame({ Name = "L", lst })) end))
	say("  S1:Add(another) after -> ", try(function() S1:Add(D.Frame({ Name = "next" })) end), "S1.Length", S1.Length:Get())
	say("  items:Set({1}) -> ", try(function() items:Set({ 1 }) end), "lst.Length", lst.Length:Get())
	root:Destroy()
end
do -- H-554 shape: the list Slot itself is the element (nested Slot), first cycle throws inside S1:Add
	local S1 = q.Slot()
	local root = D.Frame({ S1 })
	local items = q.Source({ 1, 2 })
	local lst = q.Slot():List(items, function(ctx)
		if ctx.Item == 2 then error("first-cycle") end
		if ctx.Item == q.KeyGone then return nil end
		return ctx.Prev or D.Frame({})
	end)
	say("  nested: S1:Add(listSlot) -> ", try(function() S1:Add(lst) end))
	say("  nested: S1:Add(frame) after -> ", try(function() S1:Add(D.Frame({})) end), "S1.Length", S1.Length:Get())
	say("  nested: items:Set({1}) -> ", try(function() items:Set({ 1 }) end), "lst.Length", lst.Length:Get())
	say("  nested: q.dispose(root) -> ", try(function() q.dispose(root) end))
end
do -- same but the list is built directly in the D.Frame literal (activation at construction)
	local items = q.Source({ 1, 2 })
	local lst = q.Slot():List(items, function(ctx)
		if ctx.Item == 2 then error("first-cycle") end
		if ctx.Item == q.KeyGone then return nil end
		return ctx.Prev or D.Frame({})
	end)
	local r = try(function() return D.Frame({ lst }) end)
	say("  D.Frame{ list } first cycle throws:", r)
	say("  items:Set({1}) afterwards:", try(function() items:Set({ 1 }) end), "lst.Length", lst.Length:Get(), "(Q132: no subscription)")
	say("  reuse lst in a new frame:", try(function() return D.Frame({ lst }) end))
end

-- ── P7 Tween Started throw: next value, teardown ──
say("== P7 Tween callbacks throwing")
do
	mockM.resetTweenLog()
	local st = q.Source(0)
	local log = {}
	local h = D.Frame({ BackgroundTransparency = st })
	local function T(v, throwStart, throwCancel)
		return q.Tween({ Value = v, Time = 1,
			Started = function() table.insert(log, "S" .. v); if throwStart then error("S") end end,
			Completed = function() table.insert(log, "C" .. v) end,
			Cancelled = function() table.insert(log, "X" .. v); if throwCancel then error("X") end end })
	end
	say("  Set(T .5, Started throws):", try(function() st:Set(T(0.5, true)) end), "plays", #mockM.tweenLog)
	say("  Set(T .7):", try(function() st:Set(T(0.7)) end), "log", table.concat(log, " "))
	say("  Set(T .9, prev Cancelled throws? no; this one's Cancelled throws later)", try(function() st:Set(T(0.9, false, true)) end))
	say("  Set(T .3) -> cancels .9 whose Cancelled throws:", try(function() st:Set(T(0.3)) end), "log", table.concat(log, " "))
	local playing = 0
	for _, e in mockM.tweenLog do if e.tween.PlaybackState == "Playing" then playing += 1 end end
	say("  engine tweens still Playing:", playing, "(.3 was created before the throw but never played/recorded?)")
	say("  Set(T .1):", try(function() st:Set(T(0.1)) end), "log", table.concat(log, " "))
	h:Destroy()
end
do -- Started throw on a plain (non-State) prop at mount: the Declaration throws; retractor slot NOOP
	mockM.resetTweenLog()
	local r = q.Ref(nil)
	local res = try(function() return D.Frame({ r, BackgroundTransparency = 0 }) end)
	-- (snap path: first set is a snap, Started+Completed fire synchronously inside process)
	local r2 = q.Ref(nil)
	local res2 = try(function() return D.Frame({ r2, BackgroundTransparency = q.Tween({ Value = 0.5, Started = function() error("snapStart") end }) }) end)
	say("  snap Started throw in a literal:", res2, "(the frame is half built — sugar/05:34)")
end

-- ── P8 Debounce: timer passing -> downstream throws (sugar/03:47) ──
say("== P8 Debounce leading lost")
do
	local a = q.Source(0)
	local g = a:Apply(q.Debounce({ Time = 0.3, Leading = true }))
	local seen = {}
	local throwOn = 2
	local o = g:Observer(function(s) table.insert(seen, s:Get()); if s:Get() == throwOn then error("deb-down") end end):Subscribe()
	table.clear(seen)
	a:Set(1) -- leading passes
	a:Set(2) -- withheld
	H.runTask(0.5) -- trailing 2 passes -> downstream throws inside the timer
	a:Set(3) -- should be leading again (doc: it is withheld once)
	local afterSet = table.concat(seen, ",")
	H.runTask(0.5)
	say("  seen after Set(3):", afterSet, "| after 0.5s:", table.concat(seen, ","), "(doc: 3 arrives as trailing, not leading)")
	a:Set(4)
	say("  a:Set(4) later:", table.concat(seen, ","), "(doc: back to normal — 4 leading)")
	o:Unsubscribe()
end

-- ── P9 Blocker:Off with a throwing downstream ──
say("== P9 Blocker:Off, downstream throw")
do
	local b = q.Blocker()
	local x, y = q.Source(0), q.Source(0)
	local gx, gy = x:Apply(b), y:Apply(b)
	local seen = {}
	local ox = gx:Observer(function(s) seen.x = s:Get(); if s:Get() == 1 then error("gx-down") end end):Subscribe()
	local oy = gy:Observer(function(s) seen.y = s:Get(); if s:Get() == 1 then error("gy-down") end end):Subscribe()
	b:On()
	x:Set(1); y:Set(1)
	say("  Off():", try(function() b:Off() end), "Blocking", b.Blocking, "seen x/y", seen.x, seen.y)
	say("  second Off():", try(function() b:Off() end), "seen x/y", seen.x, seen.y)
	y:Set(2); x:Set(2)
	say("  next Sets (blocker open):", "seen x/y", seen.x, seen.y)
	ox:Unsubscribe(); oy:Unsubscribe()
end

-- ── P10 module-level: UseProvider / RunInit / AddPlugin throws (core/01) ──
say("== P10 module-level install throws")
do
	local Quad = H.Quad
	local m = Quad.New and Quad.New() or nil
	if m then
		local n = 0
		local initFn = function() n += 1; if n == 1 then error("init") end end
		say("  RunInit throw:", try(function() m:RunInit(initFn) end), "retry:", try(function() m:RunInit(initFn) end), "ran", n, "(doc: no-op on retry)")
		local p = 0
		local plug = function() p += 1; if p == 1 then error("plug") end return { X = 1 } end
		say("  AddPlugin throw:", try(function() m:AddPlugin(plug) end), "retry:", try(function() m:AddPlugin(plug) end), "ran", p, "X", m.X)
		local pr = 0
		local prov = function(mm) pr += 1; if pr == 1 then error("prov") end return {} end
		say("  UseProvider throw:", try(function() m:UseProvider(prov) end), "retry:", try(function() m:UseProvider(prov) end), "ran", pr)
	else
		say("  (no Quad.New)")
	end
end

-- ── P11 Claim: apply-stage throw leaves the claim (roblox/04:109) ──
say("== P11 Claim apply-stage throw")
do
	local tpl = mockM.Instance.foreign("Frame")
	tpl.Name = "tpl"
	local child = mockM.Instance.foreign("TextLabel")
	child.Name = "Title"
	child.Parent = tpl
	local M = D.Mapper
	local r = try(function()
		q.Claim(tpl, M.Frame(M.Root)({ M.TextLabel("Title")({ q.OnRendered(function() error("claim-apply") end) }) }))
	end)
	say("  Claim with throwing OnRendered in a child:", r, "root claimed", q.Backend.isClaimed(tpl), "child claimed", q.Backend.isClaimed(child))
	say("  re-Claim:", try(function() q.Claim(tpl, M.Frame(M.Root)({})) end))
end

-- ── P12 cleanup that throws at each of the four exits ──
say("== P12 cleanup throw by exit")
do
	local function mk(label, exit)
		local dep = q.Source(0)
		local runs, cleans = 0, 0
		local e = q.Effect(function() runs += 1; return function(dying) cleans += 1; error("cl-" .. label) end end, dep)
		local h = D.Frame({ e })
		local r = try(function() exit(e, h, dep) end)
		local hErr = #handlerErrs
		pcall(function() dep:Set(dep:Get() + 100) end)
		say(("  %-12s exit -> %s | runs %d cleans %d | WeakSubscribe %s | Unsubscribe %s"):format(label, r, runs, cleans,
			try(function() e:WeakSubscribe() end), try(function() e:Unsubscribe() end)))
		pcall(function() h:Destroy() end)
	end
	mk("rerun", function(e, h, dep) dep:Set(1) end)
	mk("destroy", function(e, h, dep) table.clear(handlerErrs); h:Destroy(); if #handlerErrs > 0 then error(handlerErrs[1]) end end)
end

say("== done")
