-- bundle5 guard probe (Q93 (a) + Q98 (a″)) — scenarios the P-Q93/P-Q98 prototypes did not cover.
-- Copy into <tree>/quad-base/test/ and run `luau b5-probe.luau` there (tree = relinked copy).
-- Errors are reduced to their QuadNNNN code (or a short tail) so State.luau line shifts do not
-- show up as diffs. Gen numbers are generation indices (the counter runs bnot(-x): 0, 1, 2 …).
local MAIN = coroutine.running()
local function inCo(): boolean return coroutine.running() ~= MAIN end
local mock = require("./mock")
local q = mock.newQuad()
local Source = q.Source

local function T(name, f)
	mock.resetTimers()
	local ok, err = pcall(f)
	print(`--- {name}: {ok and "ok" or ("ERR " .. tostring(err))}`)
end
local function e(v): string
	local s = tostring(v)
	return s:match("(Quad%d+)") or s:match("(boom[%w%-]*)") or s:sub(-40)
end
local function r(ok, v): string
	if ok then return `ok {tostring(v)}` end
	return `ERR {e(v)}`
end
local function gi(x): string
	if x == nil then return "nil" end
	if x == -1 then return "none" end
	return tostring((-x) % 4294967296)
end
local function st(c): string
	return `curr={gi(c._cacheCurrCount)} target={gi(c._cacheTargetCount)} stamp={gi(c._computing)} cache={tostring(c._cache)}`
end
local function resume(co): string
	local ok, v = coroutine.resume(co)
	if coroutine.status(co) == "suspended" then return "PARKED" end
	return r(ok, v)
end

-- a yield-capable node: parks when `ctl.park` and the running thread can yield
local function mk(src, ctl, tag)
	return src:Compute(function(h, prev)
		local v = h:Get()
		ctl.runs += 1
		local who = inCo() and "co" or "main"
		table.insert(ctl.log, `{tag or ""}v={v} prev={tostring(prev)} {who}`)
		if ctl.park and inCo() then coroutine.yield() end
		if ctl.throwAt and ctl.throwAt[v] then
			if ctl.throwOnce then ctl.throwAt[v] = nil end
			error("boom")
		end
		if ctl.modAt and ctl.modAt[v] then return ctl.mod end
		return v * 10 + (ctl.mark and (who == "co" and 1 or 0) or 0)
	end)
end
local function newCtl() return { runs = 0, log = {}, park = true } end

-- ── N1 thrown fn + late return ──────────────────────────────────────
T("N1a A parks gen0; Set; B (main) throws at gen1 (always); A returns late", function()
	local s = Source(0); local ctl = newCtl(); ctl.throwAt = { [1] = true }
	local c = mk(s, ctl)
	local A = coroutine.create(function() return c:Get() end)
	print(" A1", resume(A), st(c))
	s:Set(1)
	ctl.park = false
	print(" B ", r(pcall(function() return c:Get() end)), st(c))
	print(" A2", resume(A), "runs", ctl.runs, st(c))
	print(" C ", r(pcall(function() return c:Get() end)), "runs", ctl.runs, st(c))
	s:Set(2)
	print(" D ", r(pcall(function() return c:Get() end)), "runs", ctl.runs, st(c))
	print(" log", table.concat(ctl.log, " | "))
end)

T("N1b same, but gen1 throw is TRANSIENT (throws once)", function()
	local s = Source(0); local ctl = newCtl(); ctl.throwAt = { [1] = true }; ctl.throwOnce = true
	local c = mk(s, ctl)
	local A = coroutine.create(function() return c:Get() end)
	print(" A1", resume(A))
	s:Set(1)
	ctl.park = false
	print(" B ", r(pcall(function() return c:Get() end)), st(c))
	print(" A2", resume(A), "runs", ctl.runs, st(c))
	print(" C ", r(pcall(function() return c:Get() end)), "runs", ctl.runs, st(c))
	s:Set(2)
	print(" D ", r(pcall(function() return c:Get() end)), "runs", ctl.runs, st(c))
	print(" log", table.concat(ctl.log, " | "))
end)

T("N1c A parks gen0 then THROWS late while B parked at gen1", function()
	local s = Source(0); local ctl = newCtl(); ctl.throwAt = { [0] = true }
	local c = mk(s, ctl)
	local A = coroutine.create(function() return c:Get() end)
	print(" A1", resume(A))
	s:Set(1)
	local B = coroutine.create(function() return c:Get() end)
	print(" B1", resume(B), st(c))
	ctl.park = false
	print(" A2", resume(A), st(c))
	print(" C ", r(pcall(function() return c:Get() end)), "runs", ctl.runs, st(c))
	print(" B2", resume(B), "runs", ctl.runs, st(c))
	print(" D ", r(pcall(function() return c:Get() end)), "runs", ctl.runs, st(c))
	print(" log", table.concat(ctl.log, " | "))
end)

-- ── N2 Modifier return + late return ────────────────────────────────
local MOD = {}
require("../luau_packages/quad_types") -- (no-op: keeps require graph identical to specs)
do
	local Brand = require("../src/Brand")
	pcall(function() Brand.ModifierBrand:Register(MOD) end)
end

T("N2a A parks gen0 and returns a Modifier late while B parked at gen1", function()
	local s = Source(0); local ctl = newCtl(); ctl.modAt = { [0] = true }; ctl.mod = MOD
	local c = mk(s, ctl)
	local A = coroutine.create(function() return c:Get() end)
	print(" A1", resume(A))
	s:Set(1)
	local B = coroutine.create(function() return c:Get() end)
	print(" B1", resume(B), st(c))
	ctl.park = false
	print(" A2", resume(A), st(c))
	print(" C ", r(pcall(function() return c:Get() end)), "runs", ctl.runs, st(c))
	print(" B2", resume(B), "runs", ctl.runs, st(c))
	print(" D ", r(pcall(function() return c:Get() end)), "runs", ctl.runs, st(c))
end)

T("N2b A parks gen0; Set; B (main) returns a Modifier at gen1; A returns late", function()
	local s = Source(0); local ctl = newCtl(); ctl.modAt = { [1] = true }; ctl.mod = MOD
	local c = mk(s, ctl)
	local A = coroutine.create(function() return c:Get() end)
	print(" A1", resume(A))
	s:Set(1)
	ctl.park = false
	print(" B ", r(pcall(function() return c:Get() end)), st(c))
	print(" A2", resume(A), "runs", ctl.runs, st(c))
	print(" C ", r(pcall(function() return c:Get() end)), "runs", ctl.runs, st(c))
end)

T("N2c defined path: Modifier return, no yield, then a Set recovers", function()
	local s = Source(0); local ctl = newCtl(); ctl.park = false; ctl.modAt = { [0] = true }; ctl.mod = MOD
	local c = mk(s, ctl)
	print(" G1", r(pcall(function() return c:Get() end)), st(c))
	print(" G2", r(pcall(function() return c:Get() end)), "runs", ctl.runs, st(c))
	s:Set(1)
	print(" G3", r(pcall(function() return c:Get() end)), "runs", ctl.runs, st(c))
	print(" log", table.concat(ctl.log, " | "))
end)

-- ── N3 closed Blocker drift + late return ───────────────────────────
T("N3 Blocker closed: drift branch opens gen1 (A) and gen2 (B), A returns late, then Off", function()
	local s = Source(0); local ctl = newCtl(); ctl.park = false
	local bl = q.Blocker()
	local g = s:Apply(bl)
	local c = mk(g, ctl)
	local seen = {}
	local o = c:Observer(function(st_) table.insert(seen, tostring(select(2, pcall(function() return st_:Get() end)))) end)
	o:Subscribe()
	bl:On()
	ctl.park = true
	s:Set(1)
	local A = coroutine.create(function() return c:Get() end)
	print(" A1", resume(A), st(c))
	s:Set(2)
	local B = coroutine.create(function() return c:Get() end)
	print(" B1", resume(B), st(c))
	ctl.park = false
	print(" A2", resume(A), "runs", ctl.runs, st(c))
	print(" B2", resume(B), "runs", ctl.runs, st(c))
	local okOff, errOff = pcall(function() bl:Off() end)
	print(" Off", r(okOff, errOff), "runs", ctl.runs, st(c))
	print(" D ", r(pcall(function() return c:Get() end)), "runs", ctl.runs, st(c))
	print(" observer saw", table.concat(seen, ","))
	print(" log", table.concat(ctl.log, " | "))
end)

T("N3b Blocker closed: B parked at drift gen2, A returns late, B ABANDONED, then Off / upstream Set", function()
	local s = Source(0); local ctl = newCtl(); ctl.park = false
	local bl = q.Blocker()
	local g = s:Apply(bl)
	local c = mk(g, ctl)
	print(" warm", r(pcall(function() return c:Get() end)))
	bl:On()
	ctl.park = true
	s:Set(1)
	local A = coroutine.create(function() return c:Get() end)
	print(" A1", resume(A))
	s:Set(2)
	local B = coroutine.create(function() return c:Get() end)
	print(" B1", resume(B))
	ctl.park = false
	print(" A2", resume(A), st(c))
	print(" C ", r(pcall(function() return c:Get() end)), st(c))
	local okOff, errOff = pcall(function() bl:Off() end)
	print(" Off", r(okOff, errOff))
	print(" D ", r(pcall(function() return c:Get() end)), "runs", ctl.runs, st(c))
	bl:On(); s:Set(3) -- withheld: the drift branch must still free the orphan stamp
	print(" E (gated Set)", r(pcall(function() return c:Get() end)), "runs", ctl.runs, st(c))
end)

-- ── N4 nested re-entry, three+ generations, same coroutine (UB: fn writes its own dep) ──
T("N4a nested: fn Sets own dep then reads self, 3 levels (gen0→gen1→gen2)", function()
	local s = Source(0); local runs, log = 0, {}
	local c
	c = s:Compute(function(h, prev)
		local v = h:Get(); runs += 1
		table.insert(log, `v={v} prev={tostring(prev)}`)
		if v < 2 then s:Set(v + 1); local inner = c:Get(); table.insert(log, `v={v} inner={inner}`) end
		return v * 10
	end)
	print(" Get", r(pcall(function() return c:Get() end)), "runs", runs, st(c))
	print(" log", table.concat(log, " | "))
	s:Set(5)
	print(" after Set(5)", r(pcall(function() return c:Get() end)), "runs", runs, st(c))
	print(" log", log[#log])
end)

T("N4b nested 3 levels; innermost (gen2) throws, middle pcall-swallows", function()
	local s = Source(0); local runs, log = 0, {}
	local c
	c = s:Compute(function(h, prev)
		local v = h:Get(); runs += 1
		table.insert(log, `v={v} prev={tostring(prev)}`)
		if v < 2 then s:Set(v + 1); local ok, x = pcall(function() return c:Get() end); table.insert(log, `v={v} inner={r(ok, x)}`) end
		if v == 2 then error("boom-inner") end
		return v * 10
	end)
	print(" Get", r(pcall(function() return c:Get() end)), "runs", runs, st(c))
	print(" Get2", r(pcall(function() return c:Get() end)), "runs", runs, st(c))
	s:Set(7)
	print(" after Set(7)", r(pcall(function() return c:Get() end)), "runs", runs, st(c))
	print(" log", table.concat(log, " | "))
end)

T("N4c nested via Observer (P14 shape, 3 gens): Compute clamps its dep twice, Observer reads inside", function()
	local s = Source(0); local runs, log = 0, {}
	local c = s:Compute(function(h, prev)
		local v = h:Get(); runs += 1
		table.insert(log, `v={v} prev={tostring(prev)}`)
		if v < 2 then s:Set(v + 1) end -- normalisation step (UB: writes own dep)
		return v
	end)
	local seen = {}
	local o = c:Observer(function(x) table.insert(seen, r(pcall(function() return x:Get() end))) end)
	o:Subscribe()
	print(" Get", r(pcall(function() return c:Get() end)), "runs", runs, st(c))
	print(" observer", table.concat(seen, ","))
	print(" log", table.concat(log, " | "))
end)

T("N4d three coroutines, three generations, return orders", function()
	for _, order in { { "C", "B", "A" }, { "B", "C", "A" }, { "A", "B", "C" }, { "B", "A", "C" } } do
		local s = Source(0); local ctl = newCtl()
		local c = mk(s, ctl)
		local co = {}
		co.A = coroutine.create(function() return c:Get() end); coroutine.resume(co.A)
		s:Set(1)
		co.B = coroutine.create(function() return c:Get() end); coroutine.resume(co.B)
		s:Set(2)
		co.C = coroutine.create(function() return c:Get() end); coroutine.resume(co.C)
		ctl.park = false
		local out = {}
		for _, k in order do table.insert(out, `{k}:{resume(co[k])}`) end
		table.insert(out, `M:{r(pcall(function() return c:Get() end))}`)
		print(` order {table.concat(order)}:`, table.concat(out, " "), "runs", ctl.runs, st(c))
	end
end)

-- ── N5 Compute chain, only the middle node yields ───────────────────
local function chain()
	local s = Source(0)
	local counts = { a = 0, b = 0, c = 0, d = 0 }
	local ctl = { park = true }
	local a = s:Compute(function(h) counts.a += 1; return h:Get() + 1 end)
	local b = a:Compute(function(h)
		local v = h:Get(); counts.b += 1
		if ctl.park and inCo() then coroutine.yield() end
		return v * 2
	end)
	local c = b:Compute(function(h) counts.c += 1; return h:Get() + 100 end)
	local d = c:Compute(function(h) counts.d += 1; return h:Get() * 3 end)
	local notes, vals = 0, {}
	local o = d:Observer(function(_, _, from) if from ~= nil then notes += 1 end end)
	o:Subscribe()
	local o2 = d:Observer(function(x) table.insert(vals, r(pcall(function() return x:Get() end))) end)
	o2:Subscribe()
	return s, a, b, c, d, counts, ctl, function() return notes end, vals, o2
end
local function cnt(k) return `a={k.a} b={k.b} c={k.c} d={k.d}` end

-- chain is warmed at gen0 by o2's install read (main). o2 is then unsubscribed so Sets do not
-- trigger main-thread reads; A parks inside b at gen1, B parks inside b at gen2.
local function raceChain()
	local s, a, b, c, d, k, ctl, notes, vals, o2 = chain()
	o2:Unsubscribe()
	s:Set(1)
	local A = coroutine.create(function() return d:Get() end)
	local a1 = resume(A)
	s:Set(2)
	local B = coroutine.create(function() return d:Get() end)
	local b1 = resume(B)
	ctl.park = false
	return s, b, c, d, k, notes, vals, o2, A, B, `A1={a1} B1={b1} {cnt(k)}`
end

T("N5a chain s→a→b(yields)→c→d: A parks gen1 inside b, B parks gen2; B finishes first; A returns", function()
	local s, b, c, d, k, notes, vals, o2, A, B, race = raceChain()
	print(" race", race)
	print(" B2", resume(B), cnt(k))
	print(" A2", resume(A), cnt(k))
	print(" M ", r(pcall(function() return d:Get() end)), cnt(k))
	print(" b", st(b), "| c", st(c), "| d", st(d))
	o2:Subscribe()
	s:Set(3)
	print(" after Set(3)", cnt(k), "vals", table.concat(vals, ","), "notes", notes())
end)

T("N5b chain: A returns first while B still parked inside b", function()
	local s, b, c, d, k, notes, vals, o2, A, B, race = raceChain()
	print(" race", race)
	print(" A2", resume(A), cnt(k))
	print(" b", st(b), "| c", st(c), "| d", st(d))
	print(" M1", r(pcall(function() return d:Get() end)), cnt(k))
	print(" B2", resume(B), cnt(k))
	print(" M2", r(pcall(function() return d:Get() end)), cnt(k), "d", st(d))
	o2:Subscribe()
	s:Set(3)
	print(" after Set(3)", cnt(k), "vals", table.concat(vals, ","), "notes", notes())
end)

T("N5c chain: B ABANDONED inside b after A returned (orphan stamp propagates down the chain?)", function()
	local s, b, c, d, k, notes, vals, o2, A, B, race = raceChain()
	print(" race", race)
	print(" A2", resume(A), cnt(k))
	print(" M1", r(pcall(function() return d:Get() end)), cnt(k))
	print(" c direct", r(pcall(function() return c:Get() end)), "b direct", r(pcall(function() return b:Get() end)))
	print(" b", st(b), "| c", st(c), "| d", st(d))
	s:Set(3)
	print(" M2 after Set(3)", r(pcall(function() return d:Get() end)), cnt(k))
end)


-- ── N6 consumer fate: Observer / Effect / StoreBind read at the gen a parked run owns ──
local function gatedRace(ctl, c, s, bl)
	bl:On()
	ctl.park = true
	s:Set(1)
	local A = coroutine.create(function() return c:Get() end)
	local a1 = resume(A)
	s:Set(2)
	local B = coroutine.create(function() return c:Get() end)
	local b1 = resume(B)
	ctl.park = false
	local a2 = resume(A)
	return A, B, `A1={a1} B1={b1} A2={a2}`
end

T("N6a Observer behind a Blocker reads the node while B is parked at the current gen", function()
	local s = Source(0); local ctl = newCtl(); ctl.park = false
	local c = mk(s, ctl)
	local bl = q.Blocker()
	local seen = {}
	local o = c:Apply(bl):Observer(function(x) table.insert(seen, tostring(x:Get())) end)
	o:Subscribe()
	local A, B, race = gatedRace(ctl, c, s, bl)
	print(" race", race, st(c))
	local okOff, errOff = pcall(function() bl:Off() end)
	print(" Off", r(okOff, errOff), "seen", table.concat(seen, ","), "running", tostring(o._running))
	print(" B2", resume(B), st(c))
	s:Set(3)
	print(" Set(3) seen", table.concat(seen, ","), "running", tostring(o._running), "runs", ctl.runs)
end)

T("N6b Effect behind a Blocker, same race", function()
	local s = Source(0); local ctl = newCtl(); ctl.park = false
	local c = mk(s, ctl)
	local bl = q.Blocker()
	local g = c:Apply(bl)
	local seen = {}
	local eff = q.Effect(function() table.insert(seen, tostring(c:Get())) end, g)
	local inst = mock.Instance.new("Frame")
	q.Backend.bindLifetime(inst, eff)
	local A, B, race = gatedRace(ctl, c, s, bl)
	print(" race", race)
	local okOff, errOff = pcall(function() bl:Off() end)
	print(" Off", r(okOff, errOff), "seen", table.concat(seen, ","))
	print(" B2", resume(B))
	local ok3, e3 = pcall(function() s:Set(3) end)
	print(" Set(3)", r(ok3, e3), "seen", table.concat(seen, ","), "runs", ctl.runs)
end)

T("N6c StoreBind (drive) behind a Blocker, same race", function()
	local s = Source(0); local ctl = newCtl(); ctl.park = false
	local c = mk(s, ctl)
	local bl = q.Blocker()
	local log = {}
	q.Dispatch.addHandler({
		name = "b5num",
		isHandlable = function(_i, _k, v) return type(v) == "number" end,
		priority = q.Dispatch.HANDLER_PRIORITY_NORMAL,
		process = function(inst, k, v, _index)
			table.insert(log, `set:{tostring(k)}={tostring(v)}`)
			return function() end
		end,
	})
	local inst = mock.Instance.new("Frame")
	q.Dispatch.drive(inst, { Title = c:Apply(bl) })
	print(" mounted log", table.concat(log, " | "))
	local A, B, race = gatedRace(ctl, c, s, bl)
	print(" race", race)
	local okOff, errOff = pcall(function() bl:Off() end)
	print(" Off", r(okOff, errOff), "log", table.concat(log, " | "))
	print(" B2", resume(B))
	local ok3, e3 = pcall(function() s:Set(3) end)
	print(" Set(3)", r(ok3, e3), "log", table.concat(log, " | "), "runs", ctl.runs)
end)

-- ── N7 previous: whose result becomes `previous` after a late return ─
T("N7a A parks gen0; Set; B (main) finishes gen1; A returns (rerun parks once more), Set, read", function()
	local s = Source(0); local ctl = newCtl(); ctl.mark = true
	local c = mk(s, ctl)
	local A = coroutine.create(function() return c:Get() end)
	print(" A1", resume(A))
	s:Set(1)
	print(" B ", r(pcall(function() return c:Get() end)), st(c))
	print(" A2", resume(A), st(c))
	ctl.park = false
	print(" A3", resume(A), st(c))
	s:Set(2)
	print(" M ", r(pcall(function() return c:Get() end)), st(c))
	print(" log", table.concat(ctl.log, " | "))
end)

T("N7b A parks gen0; Set; B (main) finishes gen1; A returns; NO read; Set; read", function()
	local s = Source(0); local ctl = newCtl(); ctl.mark = true
	local c = mk(s, ctl)
	local A = coroutine.create(function() return c:Get() end)
	print(" A1", resume(A))
	s:Set(1)
	print(" B ", r(pcall(function() return c:Get() end)))
	ctl.park = false
	print(" A2", resume(A), st(c))
	s:Set(2)
	print(" M ", r(pcall(function() return c:Get() end)), st(c))
	print(" log", table.concat(ctl.log, " | "))
end)

-- ── N8 Debounce gate (timer drift) + late return ─────────────────────
T("N8 Debounce: upstream moves inside the debounce window while a coroutine is parked", function()
	local s = Source(0); local ctl = newCtl(); ctl.park = false
	local dn = s:Apply(q.Debounce({ Time = 1 }))
	local c = mk(dn, ctl)
	local seen = {}
	local o = c:Observer(function(x) table.insert(seen, r(pcall(function() return x:Get() end))) end)
	o:Subscribe()
	ctl.park = true
	s:Set(1)
	local A = coroutine.create(function() return c:Get() end)
	print(" A1", resume(A), st(c))
	s:Set(2)
	local B = coroutine.create(function() return c:Get() end)
	print(" B1", resume(B), st(c))
	ctl.park = false
	print(" A2", resume(A), st(c))
	mock.advanceTime(2)
	print(" after timer seen", table.concat(seen, ","), st(c))
	print(" B2", resume(B), st(c))
	print(" M ", r(pcall(function() return c:Get() end)), "runs", ctl.runs, st(c))
end)

-- ── N9 re-entry at the SAME generation (cycle) swallowed by pcall — guard must be a no-op ──
T("N9 defined cycle error swallowed by fn (pcall), then fn returns normally", function()
	local s = Source(1); local runs = 0
	local c
	c = s:Compute(function(h)
		runs += 1
		local ok, err = pcall(function() return c:Get() end)
		return `{h:Get()} {r(ok, err)}`
	end)
	print(" Get", r(pcall(function() return c:Get() end)), "runs", runs, st(c))
	print(" Get2", r(pcall(function() return c:Get() end)), "runs", runs)
	s:Set(2)
	print(" Get3", r(pcall(function() return c:Get() end)), "runs", runs, st(c))
end)

-- ── N6d control: the same flush while A is STILL parked (before its late return) ──
T("N6d control: Effect behind a Blocker, Off while A and B are both still parked", function()
	local s = Source(0); local ctl = newCtl(); ctl.park = false
	local c = mk(s, ctl)
	local bl = q.Blocker()
	local g = c:Apply(bl)
	local seen = {}
	local eff = q.Effect(function() table.insert(seen, tostring(c:Get())) end, g)
	local inst = mock.Instance.new("Frame")
	q.Backend.bindLifetime(inst, eff)
	bl:On(); ctl.park = true
	s:Set(1)
	local A = coroutine.create(function() return c:Get() end); local a1 = resume(A)
	s:Set(2)
	local B = coroutine.create(function() return c:Get() end); local b1 = resume(B)
	ctl.park = false
	local okOff, errOff = pcall(function() bl:Off() end)
	print(" A1", a1, "B1", b1, "Off", r(okOff, errOff), "seen", table.concat(seen, ","))
	print(" A2", resume(A), "B2", resume(B))
	local ok3, e3 = pcall(function() s:Set(3) end)
	print(" Set(3)", r(ok3, e3), "seen", table.concat(seen, ","), "runs", ctl.runs)
end)

-- ── N10 Gate node (Blocker) itself sits on the parked path: gate's own _recompute nested ──
T("N10 reader parks INSIDE a gate node's passThrough (Blocker between c and reader)", function()
	local s = Source(0); local ctl = newCtl(); ctl.park = false
	local c = mk(s, ctl)
	local bl = q.Blocker()
	local g = c:Apply(bl)
	print(" warm", r(pcall(function() return g:Get() end)))
	ctl.park = true
	s:Set(1)
	local A = coroutine.create(function() return g:Get() end); print(" A1", resume(A), "g", st(g))
	s:Set(2)
	local B = coroutine.create(function() return g:Get() end); print(" B1", resume(B), "g", st(g))
	ctl.park = false
	print(" A2", resume(A), "g", st(g), "| c", st(c))
	print(" B2", resume(B), "g", st(g), "| c", st(c))
	print(" M ", r(pcall(function() return g:Get() end)), "runs", ctl.runs)
end)
