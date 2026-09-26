--!nocheck
-- round13 E54 — Debounce/Throttle differential fuzzer vs a virtual-clock reference model (not a spec).
-- Run from repo root (after ./scripts/relink.sh):
--   luau .claude/audit/round13-e54-debounce-fuzz/fuzz.luau -a <seedStart> <seedCount> [verbose]
-- One quad instance from mock.newQuad() (one luau_packages set — typing-limits 8.34).
local mock = require("../../../quad-base/test/mock")
local q = mock.newQuad()
local Source, Debounce, Throttle, Ref, Blocker = q.Source, q.Debounce, q.Throttle, q.Ref, q.Blocker
local Instance = mock.Instance

local args = { ... }
local SEED0 = tonumber(args[1]) or 1
local NSEED = tonumber(args[2]) or 200
local VERBOSE = args[3] == "v"
local MUT = tonumber(args[4]) or 0 -- fault injection into the MODEL (detector sanity): 1..6

-- ── PRNG (Park–Miller, exact in doubles) ─────────────────────────────
local rs = 1
local function rnd(): number
	rs = (rs * 48271) % 2147483647
	return rs / 2147483647
end
local function ri(a, b)
	return a + math.floor(rnd() * (b - a + 1))
end
local function pick(t)
	return t[ri(1, #t)]
end
local GRID = 1 / 1024 -- dyadic grid: all clock arithmetic is exact

-- ══ reference model ═══════════════════════════════════════════════════
-- Rules (reference docs/reference/sugar/03-debounce-throttle.md, plan 1-1):
--  R1 sugar/03:34  Debounce: a signal restarts the window (reset bit)
--  R2 sugar/03:35  Throttle: window length fixed
--  R3 sugar/03:38  gate defers notification only; :Get() is the latest value
--  R4 sugar/03:94  Leading: first signal of an idle gate passes at once
--  R5 sugar/03:95  Trailing: withheld passes at window close; Trailing=false discards
--  R6 plan 1-1 (Throttle 1.0 row) pass reopens the window (min Time to the next pass)
--  R7 sugar/03:96,101 MaxTime: second timer armed on the next WITHHELD signal (Trailing only), never reset
--  R8 sugar/03:99  Leading=false&Trailing=false (after defaults) -> Quad0048
--  R9 sugar/03:100 Throttle MaxTime -> Quad0046
--  R10 sugar/03:102 Time/MaxTime sampled at each signal; running timer keeps its delay; reopen uses last sample
--  R11 sugar/03:121 bad State Time throws at :Set; the signal stays merged and rides the next pass
--  R12 sugar/03:158 Flush: withheld -> pass now + reopen window; nothing withheld -> true no-op
--  R13 sugar/03:164 Cancel: drop withheld, idle, no propagation
--  R14 sugar/03:47  timer-path pass whose downstream throws: window gone, blocker On -> next signal withheld (trailing after Time)
--  R15 sugar/03:180,184 factory broadcast = per-gate Flush/Cancel
--  Tie-break (mock.luau:552-557, not a doc rule): timers fire in (at, seq) order; a timer due at t fires
--  before a signal made at t (driver advances first).
local M = {}
M.__index = M

local function newModelWorld()
	return { now = 0, seq = 0, timers = {}, log = {}, srcValue = nil, dead = false, throwArmed = false, throws = 0, rev = 0, nodes = {} }
end

local function msched(W, delay, fn)
	W.seq += 1
	local t = { at = W.now + delay, seq = W.seq, fn = fn, live = true }
	W.timers[#W.timers + 1] = t
	return t
end
local function mcancel(W, t)
	if t and t.live then
		t.live = false
		local i = table.find(W.timers, t)
		if i then table.remove(W.timers, i) end
	end
end
local function mlive(W)
	return #W.timers
end
local function madvance(W, target)
	while true do
		local best, bi = nil, 0
		for i, t in W.timers do
			if t.at <= target and (best == nil or t.at < best.at or (t.at == best.at and t.seq < best.seq)) then
				best, bi = t, i
			end
		end
		if not best then break end
		table.remove(W.timers, bi)
		best.live = false
		W.now = best.at
		local ok = pcall(best.fn)
		if not ok then W.throws += 1 end
	end
	W.now = target
end

local function readVal(v)
	if type(v) == "table" then return v.v end
	return v
end

-- GateNode epoch rule (State.luau GateImpl._receive / _flush; gate-plan §4 rule 3 — not in sugar/03):
-- a gate swallows a signal whose revision it has already emitted (emit map, Synced with the LIVE
-- revision at flush) AND already seen (value map — refreshed by any :Get() through the node).
local function readAll(W)
	for _, n in W.nodes do n.vRev = W.rev end
end
local function nodeRecv(W, n) -- returns false = swallowed
	local vc = n.vRev ~= W.rev
	n.vRev = W.rev
	local ec = n.eRev ~= W.rev
	return vc or ec
end
local function modelSink(W)
	return {
		recv = function()
			if not W.dead then
				if not W.noRead then readAll(W) end -- the observer reads target:Get() (whole chain refreshes)
				W.log[#W.log + 1] = `{W.now}:{W.srcValue}`
				if W.throwArmed then
					W.throwArmed = false
					error("model boom")
				end
			end
		end,
	}
end

local function modelBlocker(W, down)
	local m = { on = false, P = false, vRev = 0, eRev = nil }
	W.nodes[#W.nodes + 1] = m
	function m.recv()
		if not nodeRecv(W, m) then return end
		m.P = true
		if not m.on then
			m.P = false; m.eRev = W.rev
			down.recv()
		end
	end
	function m.On() m.on = true end
	function m.Off()
		m.on = false
		if m.P then m.P = false; m.eRev = W.rev; down.recv() end
	end
	function m.OffWithoutEmit() m.on = false; m.P = false end
	return m
end

-- cfg: { reset, leading, trailing, time (number|{v}), maxTime (nil|number|{v}) }
local function modelGate(W, cfg, down)
	local m = { W = nil, C = nil, B = false, P = false, T = nil, vRev = 0, eRev = nil }
	W.nodes[#W.nodes + 1] = m
	local onW, onC
	local function commit()
		mcancel(W, m.W); m.W = nil
		mcancel(W, m.C); m.C = nil
		local had = m.P
		if had then
			m.P = false; m.eRev = W.rev
			down.recv() -- R14: a throw here aborts the rest (window nil, B stays On)
		end
		if had and MUT ~= 1 then
			m.W = msched(W, m.T, onW); m.B = true -- R6
		else
			m.B = false
		end
	end
	function onW()
		m.W = nil
		if cfg.trailing then
			commit() -- R5
		else
			if MUT ~= 4 then m.P = false end -- R5 discard
			mcancel(W, m.C); m.C = nil
			m.B = false
		end
	end
	function onC()
		m.C = nil
		commit() -- R7
	end
	function m.recv()
		if not nodeRecv(W, m) then return end
		m.P = true -- merged before the policy runs (R11)
		local T = readVal(cfg.time)
		if type(T) ~= "number" or T ~= T or T < 0 then error("model Quad0039") end
		if MUT ~= 6 or m.T == nil then m.T = T end -- R10
		local maxT = nil
		if cfg.maxTime ~= nil and cfg.trailing then
			maxT = readVal(cfg.maxTime)
			-- R11 for MaxTime; NOTE order (미정 in docs): Time's sample is already cached when MaxTime throws
			if type(maxT) ~= "number" or maxT ~= maxT or maxT < 0 then error("model Quad0039 MaxTime") end
		end
		local held = m.B or not cfg.leading
		if m.W == nil then
			if not cfg.leading then
				m.W = msched(W, T, onW); m.B = true
			else
				if not m.B then m.P = false; m.eRev = W.rev; down.recv() end -- R4
				if m.W == nil then m.W = msched(W, T, onW); m.B = true end
			end
		else
			if cfg.reset ~= (MUT == 2) then -- R1
				local old = m.W
				m.W = msched(W, T, onW)
				mcancel(W, old)
			end
		end
		if (held or MUT == 3) and maxT ~= nil and m.C == nil then m.C = msched(W, maxT, onC) end -- R7
	end
	function m.Flush() -- R12
		if m.P then
			m.P = false; m.eRev = W.rev
			down.recv()
			mcancel(W, m.W); m.W = nil
			mcancel(W, m.C); m.C = nil
			if m.T ~= nil then m.W = msched(W, m.T, onW); m.B = true end
		end
	end
	function m.Cancel() -- R13
		if MUT ~= 5 then m.P = false end
		mcancel(W, m.W); m.W = nil
		mcancel(W, m.C); m.C = nil
		m.B = false
	end
	return m
end

-- ══ scenario generation ═══════════════════════════════════════════════
local function genGateCfg(kindForced)
	local reset = if kindForced ~= nil then kindForced else rnd() < 0.5
	local time = if rnd() < 0.05 then 0 else ri(3, 128) / 64
	local lead = pick({ true, false, "nil" })
	local trail = pick({ true, false, "nil" })
	local cfg = {
		reset = reset,
		timeBase = time,
		timeState = rnd() < 0.3,
		leadOpt = if lead == "nil" then nil else lead,
		trailOpt = if trail == "nil" then nil else trail,
	}
	cfg.leading = if reset then cfg.leadOpt == true else cfg.leadOpt ~= false
	cfg.trailing = cfg.trailOpt ~= false
	if reset and rnd() < 0.45 then
		cfg.maxRatio = pick({ 0, 0.25, 0.5, 1, 1, 1.5, 2, 3, 4 })
		cfg.maxBase = time * cfg.maxRatio
		cfg.maxState = rnd() < 0.3
	end
	cfg.useFactory = rnd() < 0.25
	return cfg
end

local function genScenario(seed)
	rs = seed * 7919 % 2147483647
	if rs == 0 then rs = 1 end
	for _ = 1, 3 do rnd() end
	local sc = {}
	local r = rnd()
	sc.topo = if r < 0.6 then "T0" elseif r < 0.73 then "T1" elseif r < 0.86 then "T2" else "T3"
	sc.g1 = genGateCfg(nil)
	if sc.topo == "T3" then sc.g2 = genGateCfg(nil) end
	sc.hostBound = rnd() < 0.15
	sc.pure = rnd() < 0.2 -- sets only, T0, numeric options: doc-level invariants apply
	sc.noRead = rnd() < 0.25 -- nobody reads the gated State (observer ignores target; no :Get() oracle)
	if sc.pure then
		sc.topo = "T0"; sc.g2 = nil; sc.g1.timeState = false; sc.g1.maxState = false; sc.hostBound = false
	end
	sc.valueMode = pick({ "mono", "repeat" })
	local pattern = pick({ "poisson", "burst", "regular", "sametime", "mixed" })
	sc.pattern = pattern
	local T = sc.g1.timeBase
	local period = if T > 0 then T * pick({ 0.25, 0.5, 1, 1.5, 2 }) else 1 / 16
	local n = ri(4, 60)
	local t = 0
	local ev = {}
	local counter = 0
	local function gap()
		local p = pattern
		if p == "mixed" then p = pick({ "poisson", "burst", "regular", "sametime" }) end
		if p == "poisson" then
			local mean = math.max(T, 0.05) * pick({ 0.3, 1, 2 })
			return math.floor(-math.log(1 - rnd() * 0.999) * mean / GRID) * GRID
		elseif p == "burst" then
			if rnd() < 0.15 then return math.floor(rnd() * 3 / GRID) * GRID end
			return ri(0, 16) * GRID
		elseif p == "regular" then
			return period
		else
			return if rnd() < 0.6 then 0 else pick({ period, T, T * 2 })
		end
	end
	local anyState = sc.g1.timeState or sc.g1.maxState or (sc.g2 and (sc.g2.timeState or sc.g2.maxState))
	for _ = 1, n do
		t += gap()
		local x = if sc.pure then 0 else rnd()
		local e
		if x < 0.70 then
			counter += 1
			local v = if sc.valueMode == "mono" then counter else ri(1, 3)
			e = { kind = "set", v = v }
		elseif x < 0.75 then
			e = { kind = "flush", which = ri(1, if sc.topo == "T3" then 2 else 1) }
		elseif x < 0.79 then
			e = { kind = "cancel", which = ri(1, if sc.topo == "T3" then 2 else 1) }
		elseif x < 0.84 then
			if anyState then
				local tv = if rnd() < 0.08 then -1 elseif rnd() < 0.05 then 0 else ri(3, 128) / 64
				e = { kind = "timeset", which = ri(1, if sc.topo == "T3" then 2 else 1), field = pick({ "time", "max" }), v = tv }
			else
				e = { kind = "set", v = 0 }
			end
		elseif x < 0.91 then
			if sc.topo == "T1" or sc.topo == "T2" then
				e = { kind = "blk", op = pick({ "On", "On", "Off", "Off", "OffWithoutEmit" }) }
			else
				e = { kind = "set", v = -1 }
			end
		elseif x < 0.95 then
			e = { kind = "throw" }
		elseif x < 0.96 and sc.hostBound then
			e = { kind = "destroy" }
		else
			e = { kind = "set", v = 0 }
		end
		e.t = t
		ev[#ev + 1] = e
	end
	sc.events = ev
	sc.endT = t + 40 -- quiesce well past 2×max(Time,MaxTime)
	return sc
end

-- ══ build impl & model ════════════════════════════════════════════════
local function mkOpts(cfg, st)
	local o = { Time = if cfg.timeState then st.time else cfg.timeBase, Leading = cfg.leadOpt, Trailing = cfg.trailOpt }
	if cfg.maxBase ~= nil then o.MaxTime = if cfg.maxState then st.max else cfg.maxBase end
	return o
end

local function buildImpl(sc)
	local I = { log = {}, throwArmed = false, dead = false, gates = {} }
	local src = Source(0)
	I.src = src
	local function mkGate(state, cfg)
		local st = { time = Source(cfg.timeBase), max = Source(cfg.maxBase or 0) }
		local handle = Ref(nil)
		local opts = mkOpts(cfg, st)
		opts.Handle = handle
		local factory = (if cfg.reset then Debounce else Throttle)(opts)
		local g = state:Apply(factory)
		I.gates[#I.gates + 1] = { g = g, h = handle.Value, f = factory, cfg = cfg, st = st }
		return g
	end
	local node = src
	if sc.topo == "T1" then
		I.blk = Blocker(); node = node:Apply(I.blk)
	end
	node = mkGate(node, sc.g1)
	if sc.topo == "T2" then
		I.blk = Blocker(); node = node:Apply(I.blk)
	elseif sc.topo == "T3" then
		node = mkGate(node, sc.g2)
	end
	I.final = node
	local obs = node:Observer(function(target, _o, from)
		if from == nil then return end
		I.log[#I.log + 1] = `{mock.now()}:{if sc.noRead then I.src:Get() else target:Get()}`
		if I.throwArmed then
			I.throwArmed = false
			error("impl boom")
		end
	end)
	if sc.hostBound then
		I.inst = Instance.new("Frame")
		q.Backend.bindLifetime(I.inst, obs)
	else
		obs:Subscribe()
	end
	I.obs = obs
	return I
end

local function buildModel(sc)
	local W = newModelWorld()
	W.srcValue = 0
	W.noRead = sc.noRead
	local sink = modelSink(W)
	local cfgs = {}
	local function mcfg(cfg)
		local c = { reset = cfg.reset, leading = cfg.leading, trailing = cfg.trailing }
		c.timeCell = { v = cfg.timeBase }
		c.maxCell = { v = cfg.maxBase or 0 }
		c.time = if cfg.timeState then c.timeCell else cfg.timeBase
		if cfg.maxBase ~= nil then c.maxTime = if cfg.maxState then c.maxCell else cfg.maxBase end
		return c
	end
	local W_ = { world = W, gates = {} }
	local chain
	if sc.topo == "T0" then
		local c = mcfg(sc.g1); W_.gates[1] = { m = modelGate(W, c, sink), c = c }
		chain = W_.gates[1].m
	elseif sc.topo == "T1" then
		local c = mcfg(sc.g1); W_.gates[1] = { m = modelGate(W, c, sink), c = c }
		W_.blk = modelBlocker(W, W_.gates[1].m); chain = W_.blk
	elseif sc.topo == "T2" then
		W_.blk = modelBlocker(W, sink)
		local c = mcfg(sc.g1); W_.gates[1] = { m = modelGate(W, c, W_.blk), c = c }
		chain = W_.gates[1].m
	else
		local c2 = mcfg(sc.g2); local g2 = modelGate(W, c2, sink)
		local c1 = mcfg(sc.g1); local g1 = modelGate(W, c1, g2)
		W_.gates[1] = { m = g1, c = c1 }; W_.gates[2] = { m = g2, c = c2 }
		chain = g1
	end
	W_.chain = chain
	return W_
end

-- ══ run ═══════════════════════════════════════════════════════════════
local stats = { seeds = 0, events = 0, records = 0, diffs = 0, cfgErrors = 0, implThrows = 0, modelThrows = 0,
	fineDiffs = 0, invFail = 0, byTopo = {} }
local diffsOut = {}

local function implAdvanceTo(target, fine)
	local function adv(to)
		while true do
			local ok = pcall(mock.advanceTime, to - mock.now())
			if ok then break end
			stats.implThrows += 1
		end
	end
	if fine then
		local now = mock.now()
		local steps = ri(0, 5)
		local cuts = {}
		local span = math.floor((target - now) / GRID)
		for _ = 1, steps do
			if span > 0 then cuts[#cuts + 1] = now + ri(0, span) * GRID end
		end
		table.sort(cuts)
		for _, c in cuts do
			if c > mock.now() then adv(c) end
		end
	end
	adv(target)
end

local function cfgStr(c)
	if not c then return "-" end
	return `{c.reset and "Debounce" or "Throttle"}(Time={c.timeBase}{c.timeState and "[S]" or ""},Leading={tostring(c.leadOpt)},Trailing={tostring(c.trailOpt)},MaxTime={tostring(c.maxBase)}{c.maxState and "[S]" or ""},factory={tostring(c.useFactory)})`
end

local function scenarioStr(sc)
	local lines = { `topo={sc.topo} noRead={tostring(sc.noRead)} pure={tostring(sc.pure)} g1={cfgStr(sc.g1)} g2={cfgStr(sc.g2)} host={tostring(sc.hostBound)} pattern={sc.pattern}` }
	for _, e in sc.events do
		lines[#lines + 1] = `  {e.t} {e.kind} {e.v or e.op or ""} {e.which or ""} {e.field or ""}`
	end
	return table.concat(lines, "\n")
end

-- returns impl log, first divergence text (or nil), invariant ok flags
local function runOnce(sc, fine, withModel)
	mock.resetTimers()
	local cfgOk1 = sc.g1.leading or sc.g1.trailing
	local cfgOk2 = (not sc.g2) or sc.g2.leading or sc.g2.trailing
	if not (cfgOk1 and cfgOk2) then
		-- R8: construction must throw Quad0048
		local ok, err = pcall(buildImpl, sc)
		if ok or not string.find(tostring(err), "Quad0048", 1, true) then
			return nil, `R8 violated: {tostring(err)}`
		end
		return nil, nil, true
	end
	local I = buildImpl(sc)
	local Mw = withModel and buildModel(sc) or nil
	local W = Mw and Mw.world
	local diff = nil
	local function check(label)
		if Mw and not sc.noRead then readAll(W) end -- mirrors the :Get() oracle reads below (they refresh value maps)
		if diff or not Mw then return end
		-- records
		if #I.log ~= #W.log then
			diff = `{label}: record count impl {#I.log} model {#W.log}\n impl={table.concat(I.log, " ")}\n model={table.concat(W.log, " ")}`
			return
		end
		for i = 1, #I.log do
			if I.log[i] ~= W.log[i] then
				diff = `{label}: record #{i} impl {I.log[i]} model {W.log[i]}`
				return
			end
		end
		if mock.pendingTimers() ~= mlive(W) then
			diff = `{label}: pending timers impl {mock.pendingTimers()} model {mlive(W)} @ {mock.now()}`
			return
		end
		-- internal state oracles per gate
		for i, G in I.gates do
			local mg = Mw.gates[i].m
			local P = next(G.g._withheld) ~= nil
			if P ~= mg.P then diff = `{label}: gate{i} withheld impl {tostring(P)} model {tostring(mg.P)}`; return end
			if (G.h._window ~= nil) ~= (mg.W ~= nil) then diff = `{label}: gate{i} window impl {tostring(G.h._window ~= nil)} model {tostring(mg.W ~= nil)}`; return end
			if (G.h._cap ~= nil) ~= (mg.C ~= nil) then diff = `{label}: gate{i} cap impl {tostring(G.h._cap ~= nil)} model {tostring(mg.C ~= nil)}`; return end
		end
		if sc.noRead then return end
		-- R3: :Get() is always the latest
		for i, G in I.gates do
			if G.g:Get() ~= I.src:Get() then diff = `{label}: gate{i}:Get() {G.g:Get()} ~= src {I.src:Get()}`; return end
		end
		if I.final:Get() ~= I.src:Get() then diff = `{label}: final:Get() stale` end
	end
	for idx, e in sc.events do
		implAdvanceTo(e.t, fine)
		if W then madvance(W, e.t) end
		check(`ev{idx}@{e.t} pre`)
		local k = e.kind
		if k == "set" then
			local ok1 = pcall(I.src.Set, I.src, e.v)
			if not ok1 then stats.implThrows += 1 end
			if W then
				W.srcValue = e.v
				W.rev += 1
				local ok2 = pcall(Mw.chain.recv)
				if not ok2 then stats.modelThrows += 1 end
				if ok1 ~= ok2 and not diff then diff = `ev{idx} set throw mismatch impl ok={tostring(ok1)} model ok={tostring(ok2)}` end
			end
		elseif k == "flush" or k == "cancel" then
			local G = I.gates[e.which]
			local meth = if k == "flush" then "Flush" else "Cancel"
			local ok1
			if G.cfg.useFactory then ok1 = pcall(G.f[meth], G.f) else ok1 = pcall(G.h[meth], G.h) end
			if not ok1 then stats.implThrows += 1 end
			if W then
				local ok2 = pcall(Mw.gates[e.which].m[meth])
				if ok1 ~= ok2 and not diff then diff = `ev{idx} {meth} throw mismatch` end
			end
		elseif k == "timeset" then
			local G = I.gates[e.which]
			local stS = if e.field == "time" then G.st.time else G.st.max
			stS:Set(e.v)
			if W then
				local c = Mw.gates[e.which].c
				local cell = if e.field == "time" then c.timeCell else c.maxCell
				cell.v = e.v
			end
		elseif k == "blk" then
			local ok1 = pcall(I.blk[e.op], I.blk)
			if not ok1 then stats.implThrows += 1 end
			if W then
				local ok2 = pcall(Mw.blk[e.op])
				if ok1 ~= ok2 and not diff then diff = `ev{idx} blocker {e.op} throw mismatch` end
			end
		elseif k == "throw" then
			I.throwArmed = true
			if W then W.throwArmed = true end
		elseif k == "destroy" then
			if I.inst and not I.dead then
				I.inst:Destroy(); I.dead = true
				if W then W.dead = true; W.throwArmed = false end
				I.throwArmed = false
			end
		end
		stats.events += 1
		check(`ev{idx}@{e.t} {k}`)
	end
	if sc.pure and #sc.events > 0 then
		-- sugar/03:42 (plan 8, H-513): no timer survives 2×Time after the last signal (upstream quiet)
		local bound = sc.events[#sc.events].t + 2 * sc.g1.timeBase
		implAdvanceTo(bound, fine)
		if W then madvance(W, bound) end
		if mock.pendingTimers() ~= 0 and not diff then
			diff = `2xTime bound: {mock.pendingTimers()} timers alive at lastSignal+2T={bound}`
		end
	end
	implAdvanceTo(sc.endT, fine)
	if W then madvance(W, sc.endT) end
	check("end")
	if not diff and mock.pendingTimers() ~= 0 then
		-- only a MaxTime/Time mismatch would leave something; report
		diff = `end: {mock.pendingTimers()} timers still pending after quiesce`
	end
	return I.log, diff, false, I
end

-- ── doc-level invariants (independent of the model) ───────────────────
local function invariants(sc, log)
	-- only for simple T0 runs: fixed numeric Time, no flush/cancel/throw/timeset/destroy
	if sc.topo ~= "T0" or sc.g1.timeState or sc.g1.maxState then return nil end
	for _, e in sc.events do
		if e.kind ~= "set" then return nil end
	end
	local sets = {}
	for _, e in sc.events do sets[#sets + 1] = e end
	local recs = {}
	for _, s in log do
		local t, v = string.match(s, "^(.-):(.-)$")
		recs[#recs + 1] = { t = tonumber(t), v = tonumber(v) }
	end
	local c = sc.g1
	local T = c.timeBase
	local function valueAt(t) -- latest set at or before t (sets at t happen after timers at t)
		local v = 0
		for _, s in sets do if s.t <= t then v = s.v end end
		return v
	end
	local fails = {}
	-- INV-A (R3/plan 1-1 "0.3 시점의 값"): recorded value = latest source value at that instant
	-- (timer-path passes at t fire BEFORE the sets at t, so exclude same-time sets for timer passes — skip ambiguity by checking both)
	for _, r in recs do
		local before = 0
		for _, s in sets do if s.t < r.t then before = s.v end end
		if r.v ~= valueAt(r.t) and r.v ~= before then
			local ok = false
			for _, s in sets do if s.t == r.t and s.v == r.v then ok = true end end
			if not ok then fails[#fails + 1] = `INV-A value {r.v} at {r.t}` end
		end
	end
	-- INV-B (R5): Trailing=true -> the last signal is delivered (a record at/after it with its value)
	if c.trailing and #sets > 0 then
		local last = sets[#sets]
		local lr = recs[#recs]
		if not lr or lr.t < last.t or lr.v ~= last.v then fails[#fails + 1] = `INV-B last signal {last.t}:{last.v} not delivered (last rec {lr and (lr.t .. ":" .. lr.v) or "none"})` end
	end
	-- INV-C (R1): Debounce, Leading=false, no MaxTime: every pass at t has a signal at t-T and none in (t-T, t)
	if c.reset and not c.leading and c.maxBase == nil then
		for _, r in recs do
			local at, inside = false, false
			for _, s in sets do
				if s.t == r.t - T then at = true end
				if s.t > r.t - T and s.t < r.t then inside = true end
			end
			if not at or inside then fails[#fails + 1] = `INV-C pass at {r.t} (T={T}) at={tostring(at)} inside={tostring(inside)}` end
		end
	end
	-- INV-D (R2/R6): Throttle: consecutive passes >= T apart; Debounce w/o MaxTime too (pass reopens the window)
	if (not c.reset) or c.maxBase == nil or (c.maxBase and c.maxBase >= T) then
		for i = 2, #recs do
			if recs[i].t - recs[i - 1].t < T then
				fails[#fails + 1] = `INV-D gap {recs[i - 1].t}->{recs[i].t} < T={T}`
			end
		end
	end
	-- INV-E (R4): Leading gate, signal after >= 2T silence since last pass/signal -> passes at once
	if c.leading then
		local lastActivity = -math.huge
		for _, s in sets do
			if s.t - lastActivity > 2 * T + (c.maxBase or 0) and T > 0 then
				local ok = false
				for _, r in recs do if r.t == s.t then ok = true end end
				if not ok then fails[#fails + 1] = `INV-E leading signal at {s.t} not passed at once` end
			end
			lastActivity = s.t
		end
	end
	-- INV-F (R7): Debounce MaxTime (trailing): once something is withheld, a pass follows within MaxTime
	if c.reset and c.maxBase ~= nil and c.trailing then
		for _, s in sets do
			local ok = false
			for _, r in recs do if r.t >= s.t and r.t <= s.t + math.max(c.maxBase, 0) + 0 then ok = true end end
			-- signal passes leading at s.t or within MaxTime (window may end sooner)
			if not ok then
				-- could still be within T (window end) if T < MaxTime
				for _, r in recs do if r.t >= s.t and r.t <= s.t + T then ok = true end end
			end
			if not ok then fails[#fails + 1] = `INV-F signal {s.t} not passed within max(MaxTime,Time) ({c.maxBase},{T})` end
		end
	end
	return fails
end

local invChecked = 0
local t0 = os.clock()
for seed = SEED0, SEED0 + NSEED - 1 do
	local sc = genScenario(seed)
	stats.seeds += 1
	stats.byTopo[sc.topo] = (stats.byTopo[sc.topo] or 0) + 1
	local logC, diffC, cfgErr = runOnce(sc, false, true)
	if cfgErr then
		stats.cfgErrors += 1
	else
		if diffC then
			stats.diffs += 1
			diffsOut[#diffsOut + 1] = `seed {seed} [coarse]: {diffC}\n{scenarioStr(sc)}`
		end
		rs = (seed * 104729) % 2147483647 + 1 -- fine-step cuts: separate stream
		local logF, diffF = runOnce(sc, true, true)
		if diffF then
			stats.diffs += 1
			diffsOut[#diffsOut + 1] = `seed {seed} [fine]: {diffF}\n{scenarioStr(sc)}`
		end
		if logC and logF and table.concat(logC, " ") ~= table.concat(logF, " ") then
			stats.fineDiffs += 1
			diffsOut[#diffsOut + 1] = `seed {seed} coarse≠fine\n C={table.concat(logC, " ")}\n F={table.concat(logF, " ")}\n{scenarioStr(sc)}`
		end
		if logC then
			stats.records += #logC
			local fails = invariants(sc, logC)
			if fails then
				invChecked += 1
				if #fails > 0 then
					stats.invFail += 1
					diffsOut[#diffsOut + 1] = `seed {seed} INVARIANT: {table.concat(fails, "; ")}\n log={table.concat(logC, " ")}\n{scenarioStr(sc)}`
				end
			end
		end
	end
end
local dt = os.clock() - t0
print(`seeds={stats.seeds} events={stats.events} records={stats.records} cfgErrors(R8)={stats.cfgErrors} diffs={stats.diffs} coarse≠fine={stats.fineDiffs} invChecked={invChecked} invFail={stats.invFail} implThrows={stats.implThrows} modelThrows={stats.modelThrows} time={string.format("%.2f", dt)}s`)
local topo = {}
for k, v in stats.byTopo do topo[#topo + 1] = `{k}={v}` end
table.sort(topo)
print("topo: " .. table.concat(topo, " "))
for i, d in diffsOut do
	if i > (VERBOSE and 1000 or 8) then print(`... {#diffsOut - i + 1} more`); break end
	print("----")
	print(d)
end
