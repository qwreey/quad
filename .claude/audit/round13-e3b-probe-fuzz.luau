-- round13 E3-2 fuzzers. Copy to quad-base/test/, ./scripts/relink.sh, luau quad-base/test/<this file> -a <blk|tim|timre> <seeds>
--   mode "blk": Blocker-only graphs with On/Off/OffWithoutEmit — exact notification model for single-source chains
--               (fire count + last value), value invariant everywhere, "first Set after a discard is observed" for all
--   mode "tim": chains of Blocker / Debounce / Throttle stages (random Leading/Trailing/Time/MaxTime, handle Flush/Cancel,
--               advanceTime boundaries 0/.25/.5/1/1.25) — observed (time, value) list vs an independent event model
local mock = require("./mock")
local q = mock.newQuad()
local Source, Blocker, Ref = q.Source, q.Blocker, q.Ref
local args = { ... }
local MODE = args[1] or "blk"
local SEEDS = tonumber(args[2]) or 3000

-- ───────────────────────────── blk ─────────────────────────────
local function runBlk(seed)
	math.randomseed(seed)
	mock.resetTimers()
	local R = math.random
	local nB = R(1, 3)
	local blockers, blocked = {}, {}
	for i = 1, nB do blockers[i] = Blocker(); blocked[i] = false end
	local chains = {} -- per source: { src, sval, nodes = { {obj, kind, b, pending, mul, obs = {rec...}} } }
	local allObs = {}
	for c = 1, R(1, 4) do
		local src = Source(R(0, 9))
		local ch = { src = src, nodes = {}, rev = 0 }
		local cur = src
		ch.nodes[1] = { obj = src, kind = "S", mul = 1, vrev = 0, erev = 0 }
		local mul = 1
		for _ = 1, R(1, 5) do
			if R() < 0.65 then
				local bi = R(1, nB)
				cur = cur:Apply(blockers[bi])
				ch.nodes[#ch.nodes + 1] = { obj = cur, kind = "G", b = bi, pending = false, mul = mul, vrev = 0, erev = 0 }
			else
				cur = cur:Compute(function(h) return h:Get() * 2 end)
				mul *= 2
				ch.nodes[#ch.nodes + 1] = { obj = cur, kind = "M", mul = mul, vrev = 0, erev = 0 }
			end
		end
		for _, n in ch.nodes do
			n.obs = {}
			if R() < 0.6 then
				local rec = { fires = 0, last = nil, expFires = 0, expLast = nil, node = n, chain = c }
				rec.o = n.obj:Observer(function(st, _, from)
					if from ~= nil then rec.fires += 1; rec.last = st:Get() end
				end):Subscribe()
				rec.last = n.obj:Get(); rec.expLast = rec.last
				n.obs[#n.obs + 1] = rec
				allObs[#allObs + 1] = rec
			end
		end
		chains[c] = ch
	end
	-- merged computes over two chain tails (value + refresh checks only)
	local merged = {}
	for _ = 1, R(0, 2) do
		if #chains >= 2 then
			local a, b = R(1, #chains), R(1, #chains)
			if a ~= b then
				local ta, tb = chains[a].nodes[#chains[a].nodes].obj, chains[b].nodes[#chains[b].nodes].obj
				local m = ta:Compute(function(h, _, hb) return h:Get() + hb:Get() end, tb)
				if R() < 0.5 then m = m:Apply(blockers[R(1, nB)]) end
				local rec = { fires = 0, last = m:Get() }
				rec.o = m:Observer(function(st, _, from) if from ~= nil then rec.fires += 1; rec.last = st:Get() end end):Subscribe()
				merged[#merged + 1] = { obj = m, rec = rec, a = a, b = b, ta = ta, tb = tb }
			end
		end
	end
	local log = {}
	-- model propagation (rule 3: a node swallows a revision it has both seen (value map, refreshed by any Get)
	-- and sent (emit map; a gate Syncs it at flush, a discard does not))
	local function refreshUpTo(ch, k)
		for i = 1, k do ch.nodes[i].vrev = ch.rev end
	end
	local function fire(ch, n, i)
		for _, rec in n.obs do rec.expFires += 1; rec.expLast = ch.src:Get() * n.mul; refreshUpTo(ch, i) end
	end
	-- deliver the current revision to node i, then onward; `fromGate` = node i is the flushing gate itself
	local function flow(ch, k, flushing)
		for i = k, #ch.nodes do
			local n = ch.nodes[i]
			if not (flushing and i == k) and n.kind ~= "S" then
				local vc, ec = n.vrev ~= ch.rev, n.erev ~= ch.rev
				n.vrev = ch.rev
				if not (vc or ec) then return end
				if n.kind == "G" then
					if blocked[n.b] then n.pending = true; return end
				else
					n.erev = ch.rev
				end
			end
			if n.kind == "G" then n.erev = ch.rev; n.pending = false end -- a pass flushes the whole withheld set
			fire(ch, n, i)
		end
	end
	local function flowFromSource(ch)
		ch.rev += 1
		ch.nodes[1].vrev = ch.rev
		flow(ch, 1, false)
	end
	local function check(tag)
		local e = nil
		for _, rec in allObs do
			if rec.fires ~= rec.expFires or rec.last ~= rec.expLast then
				local desc = {}
				for _, n in chains[rec.chain].nodes do desc[#desc + 1] = n.kind .. (n.b or "") .. (if n == rec.node then "*" else "") end
				return `{tag}: chain {rec.chain} [{table.concat(desc, ">")}] node {rec.node.kind} fires {rec.fires}/{rec.expFires} last {rec.last}/{rec.expLast}; log {table.concat(log, " ")}`
			end
		end
		for _, ch in chains do
			for _, n in ch.nodes do
				if n.obj:Get() ~= ch.src:Get() * n.mul then return `{tag}: value` end
			end
		end
		for _, m in merged do
			if m.obj:Get() ~= m.ta:Get() + m.tb:Get() then return `{tag}: merged value` end
		end
		for _, ch in chains do refreshUpTo(ch, #ch.nodes) end -- the value reads above refreshed every node
		return nil
	end
	for step = 1, R(5, 40) do
		local op = R(1, 10)
		if op <= 4 then
			local c = R(1, #chains)
			local v = if R() < 0.2 then chains[c].src:Get() else R(0, 9) -- same-value Set too
			chains[c].src:Set(v)
			log[#log + 1] = `s{c}={v}`
			flowFromSource(chains[c])
		elseif op <= 6 then
			local bi = R(1, nB)
			blockers[bi]:On(); blocked[bi] = true
			log[#log + 1] = `on{bi}`
		elseif op <= 8 then
			local bi = R(1, nB)
			blockers[bi]:Off(); blocked[bi] = false
			log[#log + 1] = `off{bi}`
			-- model: every pending gate of bi flushes (order irrelevant for a linear chain)
			for _, ch in chains do
				for k, n in ch.nodes do
					if n.kind == "G" and n.b == bi and n.pending then n.pending = false; flow(ch, k, true) end
				end
			end
		else
			local bi = R(1, nB)
			blockers[bi]:OffWithoutEmit(); blocked[bi] = false
			log[#log + 1] = `drop{bi}`
			for _, ch in chains do
				for _, n in ch.nodes do
					if n.kind == "G" and n.b == bi then n.pending = false end
				end
			end
		end
		local e = check(`step {step}`)
		if e then return false, e end
	end
	-- all Off (flush) — exact
	for bi = 1, nB do
		blockers[bi]:Off(); blocked[bi] = false
		for _, ch in chains do
			for k, n in ch.nodes do
				if n.kind == "G" and n.b == bi and n.pending then n.pending = false; flow(ch, k, true) end
			end
		end
	end
	local e = check("final Off")
	if e then return false, e end
	-- discard-survivor check: every source Set once (same value) → every observer (incl. merged) is current
	for c, ch in chains do ch.src:Set(ch.src:Get()); flowFromSource(ch) end
	e = check("refresh")
	if e then return false, e end
	for i, m in merged do
		if m.rec.last ~= m.obj:Get() then return false, `refresh merged {i}: last {m.rec.last} now {m.obj:Get()}; log {table.concat(log, " ")}` end
	end
	return true
end

-- ───────────────────────────── tim ─────────────────────────────
local function runTim(seed)
	math.randomseed(seed)
	mock.resetTimers()
	local R = math.random
	local src = Source(0)
	local cur = src
	local stages = {}
	local nStages = R(1, 3)
	for i = 1, nStages do
		local st = {}
		local k = R(1, 3)
		if k == 1 then
			st.kind = "B"; st.real = Blocker(); st.blocked = false; st.pending = false
			cur = cur:Apply(st.real)
		else
			st.kind = if k == 2 then "D" else "T"
			st.reset = k == 2
			st.Time = ({ 0, 0.5, 1 })[R(1, 3)]
			local L, Tr
			repeat L = R() < 0.5; Tr = R() < 0.75 until L or Tr
			st.leading, st.trailing = L, Tr
			if st.reset and R() < 0.4 then st.MaxTime = ({ 0.5, 1, 1.5, 2 })[R(1, 4)] end
			st.handle = Ref()
			local opts = { Time = st.Time, Leading = L, Trailing = Tr, MaxTime = st.MaxTime, Handle = st.handle }
			cur = cur:Apply(if st.reset then q.Debounce(opts) else q.Throttle(opts))
			st.pending = false
		end
		stages[i] = st
	end
	local seen = {}
	local REENTER = MODE == "timre" and R() < 0.7
	local rb, mb = 0, 0
	local o = cur:Observer(function(s, _, from)
		if from == nil then return end
		local v = s:Get()
		seen[#seen + 1] = `{v}@{mock.now()}`
		if REENTER and rb > 0 then rb -= 1; src:Set(v + 1) end
	end):Subscribe()
	local mval = 0
	-- ── model ──
	local clock, seq, rev = 0, 0, 0
	for _, st in stages do st.vrev = 0; st.erev = 0 end
	local mt = {} -- model timers
	local expect = {}
	local signal -- forward decl: signal(i) delivers to stage i (i > n → observer)
	local function sched(fn, d)
		seq += 1
		local t = { at = clock + d, seq = seq, fn = fn, live = true }
		mt[#mt + 1] = t
		return t
	end
	local function clr(t) if t then t.live = false end end
	local function emitFrom(i) stages[i].erev = rev; signal(i + 1) end
	local openWindow, commitIdle
	function openWindow(i)
		local st = stages[i]
		st.window = sched(function() -- onWindowEnd
			st.window = nil
			if st.trailing then commitIdle(i) else st.pending = false; clr(st.cap); st.cap = nil; st.open = false end
		end, st.Time)
		st.open = true
	end
	function commitIdle(i)
		local st = stages[i]
		clr(st.window); st.window = nil
		clr(st.cap); st.cap = nil
		local had = st.pending
		st.pending = false
		if had then emitFrom(i) end
		if st.window ~= nil then return end
		if not st.open then return end
		if had then openWindow(i) else st.open = false end
	end
	function signal(i)
		if i > #stages then
			expect[#expect + 1] = `{mval}@{clock}`
			for _, x in stages do x.vrev = rev end -- the observer's Get refreshed the chain
			if REENTER and mb > 0 then mb -= 1; mval += 1; rev += 1; signal(1) end
			return
		end
		local st = stages[i]
		local vc, ec = st.vrev ~= rev, st.erev ~= rev
		st.vrev = rev
		if not (vc or ec) then return end -- rule 3: swallowed before the policy
		if st.kind == "B" then
			if st.blocked then st.pending = true else emitFrom(i) end
			return
		end
		local held = st.open or not st.leading
		if st.window == nil then
			if not st.leading then
				openWindow(i); st.pending = true
			else
				if st.open then st.pending = true else emitFrom(i) end
				if st.window == nil then openWindow(i) end
			end
		else
			st.pending = true
			if st.reset then
				local old = st.window
				openWindow(i)
				clr(old)
			end
		end
		if held and st.MaxTime and st.trailing and st.cap == nil then
			st.cap = sched(function() st.cap = nil; commitIdle(i) end, st.MaxTime)
		end
	end
	local function madvance(dt)
		local target = clock + dt
		while true do
			local best, bi
			for j, t in mt do
				if t.live and t.at <= target and (best == nil or t.at < best.at or (t.at == best.at and t.seq < best.seq)) then best, bi = t, j end
			end
			if not best then break end
			table.remove(mt, bi)
			best.live = false
			clock = best.at
			best.fn()
		end
		clock = target
	end
	local log = {}
	for step = 1, R(5, 45) do
		local op = R(1, 14)
		if op <= 5 then
			local v = R(0, 99)
			rb, mb = 2, 2
			src:Set(v); log[#log + 1] = `set{v}`
			mval = v
			rev += 1
			signal(1)
		elseif op <= 9 then
			local dt = ({ 0, 0.25, 0.5, 1, 1.25 })[R(1, 5)]
			rb = 2; mock.advanceTime(dt); mb = 2; madvance(dt); log[#log + 1] = `adv{dt}`
		else
			local i = R(1, #stages)
			local st = stages[i]
			if st.kind == "B" then
				local k = R(1, 3)
				if k == 1 then st.real:On(); st.blocked = true; log[#log + 1] = `on{i}`
				elseif k == 2 then
					st.real:Off(); st.blocked = false; log[#log + 1] = `off{i}`
					if st.pending then st.pending = false; emitFrom(i) end
				else
					st.real:OffWithoutEmit(); st.blocked = false; st.pending = false; log[#log + 1] = `drop{i}`
				end
			else
				if R() < 0.6 then
					rb, mb = 2, 2
					st.handle.Value:Flush(); log[#log + 1] = `flush{i}`
					if st.pending then
						st.pending = false
						emitFrom(i)
						clr(st.window); st.window = nil; clr(st.cap); st.cap = nil
						openWindow(i)
					end
				else
					st.handle.Value:Cancel(); log[#log + 1] = `cancel{i}`
					st.pending = false
					clr(st.window); st.window = nil; clr(st.cap); st.cap = nil; st.open = false
				end
			end
		end
		if clock ~= mock.now() then return false, "clock drift" end
		local a, b = table.concat(seen, ","), table.concat(expect, ",")
		if a ~= b then
			local desc = {}
			for _, st in stages do desc[#desc + 1] = if st.kind == "B" then "B" else `{st.kind}(T={st.Time},L={st.leading},Tr={st.trailing},Max={st.MaxTime})` end
			return false, `step {step} [{table.concat(desc, ">")}]\n   got  {a}\n   want {b}\n   log  {table.concat(log, " ")}`
		end
	end
	-- drain: release blockers, long quiet
	for i, st in stages do
		if st.kind == "B" then st.real:Off(); st.blocked = false; if st.pending then st.pending = false; emitFrom(i) end end
	end
	mock.advanceTime(20); madvance(20)
	if table.concat(seen, ",") ~= table.concat(expect, ",") then return false, "drain mismatch" end
	if mock.pendingTimers() ~= 0 then return false, `timer leak {mock.pendingTimers()}` end
	-- eventual consistency when every timed stage trails: last seen == current (unless last op dropped/cancelled)
	local _ = o
	return true
end

local run = if MODE == "tim" or MODE == "timre" then runTim else runBlk
local fails = 0
for seed = 1, SEEDS do
	local ok, ok2, msg = pcall(run, seed)
	if not ok then
		fails += 1
		if fails <= 5 then print("seed", seed, "ERR", ok2) end
	elseif not ok2 then
		fails += 1
		if fails <= 6 then print("seed", seed, msg) end
	end
end
print(MODE, "seeds", SEEDS, "fails", fails)
