--!nocheck
-- E40 directed probes for the separate axes: (a) recompute counts, (b) `previous`, (c) throwing fns,
-- (d) reentrancy, plus the order-dependence and pre-creation-epoch observations the fuzzer surfaced.
-- Run from the repo root: luau .claude/audit/round13-e40-reactive-fuzz/probe.e40.axes.luau
local Quad = require("../../../quad-base/src")
local function mk()
	local q = Quad.New()
	q.Backend.isHeld = function() return false end
	q.Backend.isHeldBy = function() return false end
	return q
end
local function errOf(f)
	local ok, e = pcall(f)
	return if ok then "ok" else string.match(tostring(e), "Quad%d%d%d%d") or tostring(e)
end

print("== P1 (a) diamond lattice: fn runs per Set, per node (width w, depth d, every node reads all parents)")
for _, wd in { { 2, 1 }, { 2, 4 }, { 4, 4 }, { 8, 6 } } do
	local q = mk()
	local w, d = wd[1], wd[2]
	local A = q.Source(0)
	local calls = {}
	local layer = { A }
	local all = {}
	for L = 1, d do
		local nxt = {}
		for k = 1, w do
			local id = `{L}.{k}`
			calls[id] = 0
			local deps = table.clone(layer)
			local recv = table.remove(deps, 1)
			nxt[k] = recv:Compute(function(s, _prev, ...)
				calls[id] += 1
				local acc = s:Get()
				for _, h in { ... } do
					acc += h:Get()
				end
				return acc
			end, table.unpack(deps))
			all[#all + 1] = id
		end
		layer = nxt
	end
	local bottom = layer[1]:Compute(function(s, _p, ...)
		calls.bottom = (calls.bottom or 0) + 1
		local acc = s:Get()
		for _, h in { ... } do
			acc += h:Get()
		end
		return acc
	end, table.unpack(layer, 2))
	local fires = 0
	local o = bottom:Observer(function(t) fires += 1; t:Get() end):Subscribe()
	for id in calls do
		calls[id] = 0
	end
	fires = 0
	local sets = 5
	for i = 1, sets do
		A:Set(i)
	end
	local maxc, minc = 0, math.huge
	for _, c in calls do
		maxc = math.max(maxc, c)
		minc = math.min(minc, c)
	end
	print(`  w={w} d={d}: {sets} Sets → per-node fn runs min {minc} max {maxc} (want {sets}/{sets}); bottom observer fires {fires} (want {sets}); value {bottom:Get()}`)
	o:Unsubscribe()
end

print("== P1b (a) laziness: no reader → 0 runs; two Gets in one generation → 1 run")
do
	local q = mk()
	local A = q.Source(1)
	local n = 0
	local B = A:Compute(function(s) n += 1; return s:Get() * 2 end)
	A:Set(2); A:Set(3)
	local before = n
	B:Get(); B:Get()
	A:Set(3) -- same value: revision still moves (docs core/02:78) → one recompute on next read
	B:Get(); B:Get()
	print(`  runs before any read {before} (want 0); after 2 reads {n - 0} total after same-value Set + 2 reads (want 2)`)
end

print("== P2 (b) previous: first call nil, then the last SUCCESSFUL result; a throw does not move it")
do
	local q = mk()
	local A = q.Source(1)
	local seen = {}
	local B = A:Compute(function(s, prev)
		seen[#seen + 1] = tostring(prev)
		local v = s:Get()
		if v < 0 then error("neg") end
		return v * 10
	end)
	B:Get() -- prev nil → 10
	A:Set(2); B:Get() -- prev 10 → 20
	A:Set(-1); pcall(B.Get, B) -- prev 20 → throws
	A:Set(3); B:Get() -- prev 20 (last successful) → 30
	print(`  previous sequence: {table.concat(seen, ", ")} (want nil, 10, 20, 20)`)
	-- Depend/Gate pass-through nodes have no previous (docs core/03:119) — not probed
end

print("== P3 (c) throwing Compute: same-generation re-read, recovery on next Set, recovery behind a closed Blocker (H-540)")
do
	local q = mk()
	local A = q.Source(0)
	local runs = 0
	local B = A:Compute(function(s) runs += 1; if s:Get() == 1 then error("bad") end; return s:Get() end)
	local C = B:Compute(function(s) return s:Get() + 100 end)
	A:Set(1)
	local e1 = errOf(function() return C:Get() end)
	local e2 = errOf(function() return C:Get() end)
	local e3 = errOf(function() return B:Get() end)
	A:Set(1) -- same bad value again: new generation → fn runs again → throws again
	local r0 = runs
	local e4 = errOf(function() return C:Get() end)
	A:Set(2)
	print(`  first read {e1}, re-read C {e2}, read B {e3} (want Quad0184 for re-reads); after same-value Set fn ran again: {runs > r0} → {e4}; after fix: C={C:Get()} (want 102)`)
	-- behind a closed Blocker
	local q2 = mk()
	local S = q2.Source(0)
	local b = q2.Blocker()
	local G = S:Apply(b)
	local X = G:Compute(function(s) if s:Get() == 1 then error("bad") end; return s:Get() end)
	S:Set(1)
	local x1 = errOf(function() return X:Get() end)
	b:On()
	S:Set(5) -- X hears nothing (gate closed); H-540 drift branch must let fn run again
	local x2 = X:Get()
	b:Off()
	print(`  behind closed Blocker: before {x1}, after fix while blocked X={x2} (want 5)`)
end

print("== P4 cycle: fn reads its own node through a downstream State")
do
	local q = mk()
	local A = q.Source(1)
	local C
	local B = A:Compute(function(s) if C then return s:Get() + C:Get() end; return s:Get() end)
	C = B:Compute(function(s) return s:Get() + 1 end)
	A:Set(2)
	print(`  B:Get() → {errOf(function() return B:Get() end)} (want Quad0184); after that B → {errOf(function() return B:Get() end)}; A:Set then B → {errOf(function() A:Set(3); return B:Get() end)}`)
end

print("== P5 (d) reentrancy: Effect fn Sets its own dep (deferred rerun), cleanup Sets (one cycle), Observer Sets own target (recursion)")
do
	local q = mk()
	local A = q.Source(0)
	local log = {}
	local e = q.Effect(function()
		local v = A:Get()
		log[#log + 1] = `fn{v}`
		if v == 1 then A:Set(2) end
		return function() log[#log + 1] = "cl" end
	end, A):Subscribe()
	log = {}
	A:Set(1)
	print(`  Effect fn Sets own dep: {table.concat(log, " ")} (docs core/05:231 — one deferred rerun)`)
	e:Unsubscribe()
	local B = q.Source(0)
	local log2 = {}
	local flag = true
	local e2 = q.Effect(function()
		log2[#log2 + 1] = `fn{B:Get()}`
		return function()
			log2[#log2 + 1] = "cl"
			if flag then flag = false; B:Set(9) end
		end
	end, B):Subscribe()
	log2 = {}
	B:Set(1)
	print(`  cleanup Sets dep: {table.concat(log2, " ")} (docs core/05:225 — the fn after the cleanup reads the new value, one cycle)`)
	e2:Unsubscribe()
	local S = q.Source(0)
	local reads = {}
	local o = S:Observer(function(t)
		local v = t:Get()
		reads[#reads + 1] = v
		if v > 0 and v < 4 then t:Set(v + 1) end
	end):Subscribe()
	reads = {}
	S:Set(1)
	print(`  Observer Sets own target (docs core/05:107 recursion): reads {table.concat(reads, ",")} — last read {reads[#reads]} = final {S:Get()}`)
	o:Unsubscribe()
end

print("== P6 Observer has no value dedup: a same-value re-Set fires it (docs core/02:78, core/05:101-103)")
do
	local q = mk()
	local A = q.Source(5)
	local n = 0
	local o = A:Observer(function() n += 1 end):Subscribe()
	n = 0
	A:Set(5); A:Set(5)
	local D = A:Compute(function(s) return s:Get() % 2 end) -- derived value stays 1
	local m = 0
	local o2 = D:Observer(function() m += 1 end):Subscribe()
	m = 0
	A:Set(7)
	print(`  Source observer after 2 same-value Sets: {n} fires; derived value unchanged (1→1) observer: {m} fire(s)`)
	o:Unsubscribe(); o2:Unsubscribe()
end

print("== P7 order dependence: Effect/Observer fire count for ONE blocker:Off() varies with unspecified subscriber/handle order")
do
	local effHist, obsHist = {}, {}
	for trial = 1, 300 do
		local q = mk()
		local S1, S2 = q.Source(0), q.Source(0)
		local b = q.Blocker()
		local G = S2:Apply(b) -- gate 1
		local A = G:Compute(function(s) return s:Get() end)
		local C = G:Compute(function(s) return s:Get() end)
		local H = C:Depend(S1):Apply(b) -- gate 2, downstream of gate 1 AND of S1
		local runs = 0
		local e = q.Effect(function() runs += 1; A:Get(); H:Get() end, A, H):Subscribe()
		local fires = 0
		local o = H:Observer(function() fires += 1 end):Subscribe()
		runs, fires = 0, 0
		b:On()
		S1:Set(1) -- H withholds {S1}
		S2:Set(1) -- G withholds {S2}
		b:Off()
		effHist[runs] = (effHist[runs] or 0) + 1
		obsHist[fires] = (obsHist[fires] or 0) + 1
		e:Unsubscribe(); o:Unsubscribe()
	end
	local function fmt(h)
		local t = {}
		for k, v in h do t[#t + 1] = `{k}×{v}` end
		table.sort(t)
		return table.concat(t, " ")
	end
	print(`  300 fresh graphs, same ops: Effect(fn, A, H) runs per Off: {fmt(effHist)}; Observer on H fires per Off: {fmt(obsHist)}`)
end

print("== P8 a node created after a withheld Set re-announces it at Off (emit map starts empty — state-epoch-plan §4)")
do
	local q = mk()
	local S = q.Source(0)
	local b = q.Blocker()
	local G = S:Apply(b)
	b:On()
	S:Set(1)
	local D = G:Compute(function(s) return s:Get() end) -- created after the withheld Set
	local reads = {}
	local o = D:Observer(function(t) reads[#reads + 1] = t:Get() end):Subscribe()
	local r = 0
	local e = q.Effect(function() r += 1; D:Get() end, D):Subscribe()
	b:Off()
	print(`  Observer on D reads {table.concat(reads, ",")} (install, then Off with the SAME value); Effect runs {r} (Effect seeds live — no rerun)`)
	o:Unsubscribe(); e:Unsubscribe()
end
