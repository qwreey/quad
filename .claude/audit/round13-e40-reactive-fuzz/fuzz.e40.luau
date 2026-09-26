--!nocheck
-- E40 — reference-model differential fuzzer for the quad-base reactive graph
-- (Source / :Compute / :Depend / :Gate (manual policy) / Blocker / Observer / Effect).
--
-- Run (from the repo root, after ./scripts/relink.sh):
--   luau .claude/audit/round13-e40-reactive-fuzz/fuzz.e40.luau -a <from> <count> [flags] [verboseSeed]
-- flags (comma list): throw (throwing Compute fns), reent (callbacks Set other Sources — UB-ish axis (d)),
--   gate-rule1 (model gates with the implementation's value-map rule 1, see README), late (nodes created mid-sequence),
--   shrink (minimize the first failing seed and write repros/<seed>.luau), quiet
--
-- The MODEL is written independently of State.luau: values are recomputed from scratch in topological order
-- after every primitive mutation (the glitch-free answer), and notifications are propagated by a forward
-- topological sweep over the static graph with a per-node "notified (source, revision)" set — the contract
-- of docs/quadnomicon/01 §3.2 rules 1~3 + state-epoch-plan §4/§5 + gate-plan 4번 (citations: README.md).
-- It never reads quad internals except (1) the Blocker handle iteration order (unspecified by contract —
-- read from `blocker._handles` so the model flushes gates in the same order) and (2) nothing else.

local ARGS = { ... }
local FROM, COUNT = tonumber(ARGS[1]) or 1, tonumber(ARGS[2]) or 200
local FLAGS = {}
for f in string.gmatch(ARGS[3] or "", "[^,]+") do
	FLAGS[f] = true
end
local VERBOSE = tonumber(ARGS[4]) or 0

local Quad = require("../../../quad-base/src")

-- ── deterministic RNG ─────────────────────────────────────────────────────
local function newRng(seed)
	local s = (seed * 7919 + 12345) % 2147483647
	if s <= 0 then
		s += 2147483646
	end
	return function(n) -- 1..n
		s = (s * 48271) % 2147483647
		return s % n + 1
	end
end

-- ── shared pure node function (user code; identical on both sides) ─────────
local ERRV = setmetatable({}, { __tostring = function() return "ERR" end })
local function toNum(v)
	if type(v) == "number" then
		return v
	end
	return (tonumber(string.sub(v, 2)) or 0) + 7
end
local function evalNode(spec, get)
	local x = toNum(get(1))
	if spec.thr and x % spec.thr == 1 then
		error("E40BOOM", 0)
	end
	local acc = spec.a * x + spec.c
	for j = 2, spec.nd do
		if not (spec.cond and x % 2 == 0 and j == spec.nd) then
			acc += spec.b[j] * toNum(get(j))
		end
	end
	acc %= 9973
	if spec.str then
		return "s" .. acc
	end
	return acc
end

-- ── graph + op generation (pure data; replayable / shrinkable) ────────────
local function genCase(seed)
	local R = newRng(seed)
	local n = 2 + R(11) -- 3..13 → clamp
	if n > 12 then
		n = 12
	end
	local nBlockers = R(2)
	local nodes = {}
	local nSrc = 1 + (R(3) - 1) -- 1..3
	for i = 1, n do
		local nd
		if i <= nSrc or (i > 1 and R(10) == 1) then
			nd = { kind = "src", init = R(13) - 1 }
		else
			local k = R(10)
			local recv
			if R(3) == 1 then
				recv = i - 1 -- long chains
			else
				recv = R(i - 1)
			end
			if k <= 5 then
				local ndeps = R(3) -- receiver + 0..2 trailing
				local deps = { recv }
				for _ = 2, ndeps do
					deps[#deps + 1] = R(i - 1)
				end
				local spec = { a = R(5), c = R(9), b = {}, nd = #deps, cond = R(4) == 1, str = R(5) == 1 }
				for j = 2, #deps do
					spec.b[j] = R(7)
				end
				if FLAGS.throw and R(3) == 1 then
					spec.thr = 3 + R(4)
				end
				nd = { kind = "compute", deps = deps, spec = spec }
			elseif k <= 7 then
				local deps = { recv }
				for _ = 1, R(2) do
					deps[#deps + 1] = R(i - 1)
				end
				nd = { kind = "depend", deps = deps }
			elseif k <= 9 then
				nd = { kind = "gate", deps = { recv }, gk = "blocker", blocker = R(nBlockers) }
			else
				nd = { kind = "gate", deps = { recv }, gk = "manual", open0 = R(2) == 1 }
			end
		end
		nodes[i] = nd
	end
	local lateFrom = n + 1
	if FLAGS.late and R(2) == 1 and n > 3 then
		lateFrom = 2 + R(n - 2)
		if nodes[1].kind ~= "src" then
			lateFrom = n + 1
		end
	end
	local nOps = 29 + R(51) -- 30..80
	local ops = {}
	for s = 1, nOps do
		local w = R(100)
		local kind
		if w <= 28 then
			kind = "set"
		elseif w <= 33 then
			kind = "setsame"
		elseif w <= 36 then
			kind = "emit"
		elseif w <= 42 then
			kind = "bon"
		elseif w <= 48 then
			kind = "boff"
		elseif w <= 50 then
			kind = "boffx"
		elseif w <= 54 then
			kind = "mopen"
		elseif w <= 57 then
			kind = "mclose"
		elseif w <= 58 then
			kind = "mdiscard"
		elseif w <= 64 then
			kind = "obs"
		elseif w <= 67 then
			kind = "obssub"
		elseif w <= 70 then
			kind = "obsunsub"
		elseif w <= 75 then
			kind = "eff"
		elseif w <= 78 then
			kind = "effsub"
		elseif w <= 81 then
			kind = "effunsub"
		elseif w <= 83 then
			kind = "effrerun"
		elseif w <= 90 then
			kind = "get"
		elseif w <= 96 then
			kind = "batch2"
		else
			kind = "late"
		end
		ops[s] = { kind, R(1000), R(1000), R(1000), R(13) - 1, R(13) - 1 }
	end
	return { seed = seed, nodes = nodes, nBlockers = nBlockers, lateFrom = lateFrom, ops = ops }
end

-- ── one run: build both sides, replay ops, compare ─────────────────────────
local STATS = {
	steps = 0, calls = 0, callHist = {}, spurious = 0, prevBad = 0, diamondNodes = 0,
	diamondSetSteps = 0, diamondCalls = 0, obsFires = 0, effRuns = 0, throwsSeen = 0, recoveries = 0,
	fromChecks = 0, reentSets = 0, gateDiffs = 0, multiPayload = 0, installWindowLoss = 0, installWindowStale = 0,
}

local function run(case, verbose)
	local q = Quad.New()
	-- minimal lifetime hold ops: nothing is ever instance-bound here, so isHeld is always false
	q.Backend.isHeld = function() return false end
	q.Backend.isHeldBy = function() return false end
	q.Backend.holdLifetime = function() error("E40: no instances") end
	q.Backend.releaseLifetime = function() end

	local N = #case.nodes
	local violations = {}
	local curStep = 0
	local function viol(msg)
		if #violations < 20 then
			violations[#violations + 1] = `step {curStep}: {msg}`
		end
	end
	local function log(...)
		if verbose then
			print(...)
		end
	end

	-- model state
	local M = {
		active = {}, value = {}, rev = {}, emitSeen = {}, gvalSeen = {}, withheld = {}, mopen = {},
		blocking = {}, upSrc = {}, children = {},
	}
	-- quad state
	local Qn = {} -- node handles
	local blockers = {}
	local handleGate = {} -- blocker handle closure -> node index
	local srcIndexOf = {}
	local observers = {} -- { node, h, mode ("none"/"strong"/"weak"), m = {count, pending}, q = {count, lastRead} }
	local effects = {}
	local nodeRuntime = {} -- per compute node: lastResult, snap, lastThrew

	-- fault injection (self-test of the harness): FLAGS.inj1 = no diamond swallow; inj2 = Get without Refresh;
	-- inj3 = gate ignores Peek (always accepts); inj4 = Effect ignores its epoch map
	if FLAGS.inj1 or FLAGS.inj2 or FLAGS.inj3 then
		local probe = q.Source(0):Compute(function() return 0 end)
		local StateImpl = getmetatable(probe)
		if FLAGS.inj1 then
			local emitDown = StateImpl._emitDown
			StateImpl._receive = function(self, from)
				if self._valueEpochMap:Update(from) then
					self:_invalidate()
				end
				self._emitEpochMap:Update(from)
				emitDown(self, from)
			end
		end
		if FLAGS.inj2 then
			StateImpl.Get = function(self)
				if self._cacheCurrCount ~= self._cacheTargetCount then
					self:_recompute()
				end
				return self._cache
			end
		end
		if FLAGS.inj3 then
			local gprobe = q.Source(0):Gate(function(emit) return function() emit() end end)
			local GateImpl = getmetatable(gprobe)
			GateImpl._receive = function(self, from)
				if self._valueEpochMap:Update(from) then
					self:_invalidate()
				end
				local w = self._withheld
				if q.isEpoch(from) then
					w[from] = true
				else
					for e in from do
						w[e] = true
					end
				end
				self._onUpstreamEmit()
			end
		end
	end
	for b = 1, case.nBlockers do
		blockers[b] = q.Blocker()
		M.blocking[b] = false
	end

	-- upstream source sets (static)
	for i = 1, N do
		local nd = case.nodes[i]
		local up = {}
		if nd.kind == "src" then
			up[i] = true
		else
			for _, d in nd.deps do
				for s in M.upSrc[d] do
					up[s] = true
				end
			end
		end
		M.upSrc[i] = up
		M.children[i] = {}
		if nd.deps then
			local seen = {}
			for _, d in nd.deps do
				if not seen[d] then
					seen[d] = true
					table.insert(M.children[d], i)
				end
			end
		end
	end
	local isDiamond = {}
	for i = 1, N do
		local nd = case.nodes[i]
		if nd.kind ~= "src" then
			-- diamond bottom: two distinct deps sharing an upstream source
			local ds = {}
			for _, d in nd.deps do
				ds[d] = true
			end
			local list = {}
			for d in ds do
				list[#list + 1] = d
			end
			for x = 1, #list do
				for y = x + 1, #list do
					for s in M.upSrc[list[x]] do
						if M.upSrc[list[y]][s] then
							isDiamond[i] = true
						end
					end
				end
			end
		end
	end

	-- model: glitch-free values, full topological recompute
	local expected = {}
	local function recomputeModel()
		local vals = {}
		for i = 1, N do
			if M.active[i] then
				local nd = case.nodes[i]
				if nd.kind == "src" then
					vals[i] = M.value[i]
				elseif nd.kind == "compute" then
					local ok, r = pcall(evalNode, nd.spec, function(j)
						local v = vals[nd.deps[j]]
						if v == ERRV then
							error("E40BOOM", 0)
						end
						return v
					end)
					vals[i] = if ok then r else ERRV
				else -- depend / gate: pass-through of the receiver
					vals[i] = vals[nd.deps[1]]
				end
			end
		end
		expected = vals
	end

	local function readQ(h)
		local ok, r = pcall(h.Get, h)
		if ok then
			return r
		end
		local msg = tostring(r)
		if string.find(msg, "E40BOOM", 1, true) or string.find(msg, "Quad0184", 1, true) then
			return ERRV
		end
		viol("unexpected error on Get: " .. msg)
		return ERRV
	end

	local function same(a, b)
		return a == b
	end

	-- emitFrom expectation for Observer callbacks
	local EXPECT_FROM = nil -- nil = don't check; { kind = "epoch", src = i } | { kind = "batch", sets = {...} }
	local function checkFrom(o, from)
		if EXPECT_FROM == nil then
			return
		end
		STATS.fromChecks += 1
		if from == nil then
			viol(`obs#{o.id}: emitFrom nil inside a wave`)
			return
		end
		if EXPECT_FROM.kind == "epoch" then
			if srcIndexOf[from] ~= EXPECT_FROM.src then
				-- a Set wave may also be carried through an open gate → then it is a set containing the source
				if q.isEpoch(from) then
					viol(`obs#{o.id}: emitFrom is a different epoch`)
				else
					local only = true
					for e in from do
						if srcIndexOf[e] ~= EXPECT_FROM.src then
							only = false
						end
					end
					if not only then
						viol(`obs#{o.id}: gate batch in a Set wave carries other sources`)
					end
				end
			end
		else
			if q.isEpoch(from) then
				viol(`obs#{o.id}: expected a batch, got an epoch`)
				return
			end
			local keys = {}
			for e in from do
				keys[srcIndexOf[e] or -1] = true
			end
			local okAny = false
			for _, set in EXPECT_FROM.sets do
				local eq = true
				for k in keys do
					if not set[k] then
						eq = false
					end
				end
				for k in set do
					if not keys[k] then
						eq = false
					end
				end
				if eq then
					okAny = true
				end
			end
			if not okAny then
				viol(`obs#{o.id}: batch keys do not match any flushed batch`)
			end
		end
	end

	-- ── model notification machinery ──────────────────────────────────────
	local function newer(seenMap, P)
		for e in P do
			if seenMap[e] ~= M.rev[e] then
				return true
			end
		end
		return false
	end
	local function stamp(seenMap, P)
		for e in P do
			seenMap[e] = M.rev[e]
		end
	end
	local function modelNotifyObservers(i)
		for _, o in observers do
			if o.node == i then
				if o.mode ~= "none" then
					o.m.count += 1
				else
					o.m.pending = true
				end
			end
		end
	end
	local function modelEffRun(e)
		if e.m.stored then
			e.m.cleanups += 1
		end
		e.m.stored = e.retCleanup
		e.m.runs += 1
		e.m.pending = false
	end
	local function modelEffRerun(e)
		if e.mode ~= "none" then
			modelEffRun(e)
		else
			e.m.pending = true
		end
	end
	local flushGate -- forward decl
	-- a wave starting at node `origin` (already "forwarded") carrying payload P (set of source indices).
	-- Each node forwards a payload; a plain node forwards what it received, a gate forwards its swapped batch.
	local function effectsHear(i, P)
		for _, e in effects do
			if e.depSet[i] then
				if newer(e.m.seen, P) then
					stamp(e.m.seen, P)
					modelEffRerun(e)
				else
					stamp(e.m.seen, P)
				end
			end
		end
	end
	local function wave(origin, P)
		local outs = { [origin] = { P } }
		modelNotifyObservers(origin)
		effectsHear(origin, P)
		for i = origin + 1, N do
			if M.active[i] and case.nodes[i].deps then
				local nd = case.nodes[i]
				local arrivals, seenP = {}, {}
				for _, d in nd.deps do
					if outs[d] then
						for _, p in outs[d] do
							local key = {}
							for e in p do
								key[#key + 1] = e
							end
							table.sort(key)
							key = table.concat(key, ",")
							if not seenP[key] then
								seenP[key] = true
								arrivals[#arrivals + 1] = p
							end
						end
					end
				end
				if #arrivals > 1 then
					STATS.multiPayload += 1
				end
				for _, Pa in arrivals do
					local out = nil
					if nd.kind == "gate" then
						local accept = newer(M.emitSeen[i], Pa)
						if FLAGS["gate-rule1"] then
							accept = accept or newer(M.gvalSeen[i], Pa)
							stamp(M.gvalSeen[i], Pa)
						end
						if accept then
							for e in Pa do
								M.withheld[i][e] = true
							end
							local open = if nd.gk == "blocker" then not M.blocking[nd.blocker] else M.mopen[i]
							if open then
								local batch = M.withheld[i]
								M.withheld[i] = {}
								stamp(M.emitSeen[i], batch)
								out = batch
							end
						end
					else
						if newer(M.emitSeen[i], Pa) then
							out = Pa
						end
						stamp(M.emitSeen[i], Pa)
					end
					if out then
						outs[i] = outs[i] or {}
						table.insert(outs[i], out)
						modelNotifyObservers(i)
						effectsHear(i, out)
					end
				end
			end
		end
	end
	-- DFS variant (flag `dfs`): same per-node rules, but walked recursively in quad's own `_subs` iteration
	-- order (read, not modified) — isolates "unspecified subscriber order" effects from real differences.
	local subKind = setmetatable({}, { __mode = "k" })
	local dfsEmit
	local function dfsReceive(i, P)
		local nd = case.nodes[i]
		local out = nil
		if nd.kind == "gate" then
			local accept = newer(M.emitSeen[i], P)
			if FLAGS["gate-rule1"] then
				accept = accept or newer(M.gvalSeen[i], P)
				stamp(M.gvalSeen[i], P)
			end
			if accept then
				for e in P do
					M.withheld[i][e] = true
				end
				local open = if nd.gk == "blocker" then not M.blocking[nd.blocker] else M.mopen[i]
				if open then
					local batch = M.withheld[i]
					M.withheld[i] = {}
					stamp(M.emitSeen[i], batch)
					out = batch
				end
			end
		else
			if FLAGS["gate-rule1"] then
				stamp(M.gvalSeen[i], P)
			end
			if newer(M.emitSeen[i], P) then
				out = P
			end
			stamp(M.emitSeen[i], P)
		end
		if out then
			dfsEmit(i, out)
		end
	end
	dfsEmit = function(i, P)
		local snap = {}
		for sub in Qn[i]._subs do
			snap[#snap + 1] = sub
		end
		for _, sub in snap do
			local k = subKind[sub]
			if k == nil then
				-- not ours (should not happen)
			elseif k.t == "node" then
				dfsReceive(k.i, P)
			elseif k.t == "obs" then
				local o = k.o
				if o.mode ~= "none" then
					o.m.count += 1
				else
					o.m.pending = true
				end
			else
				local e = k.e
				if newer(e.m.seen, P) then
					stamp(e.m.seen, P)
					modelEffRerun(e)
				else
					stamp(e.m.seen, P)
				end
			end
		end
	end
	flushGate = function(i, commit)
		local batch = M.withheld[i]
		if next(batch) == nil then
			return nil
		end
		M.withheld[i] = {}
		if not commit then
			return nil
		end
		stamp(M.emitSeen[i], batch)
		if FLAGS.dfs then
			dfsEmit(i, batch)
		else
			wave(i, batch)
		end
		return batch
	end

	-- ── node creation (both sides) ─────────────────────────────────────────
	local function createNode(i)
		local nd = case.nodes[i]
		M.active[i] = true
		M.emitSeen[i] = {}
		M.gvalSeen[i] = {}
		for s in M.upSrc[i] do -- value map seeded live (§4)
			if s ~= i then
				M.gvalSeen[i][s] = M.rev[s]
			end
		end
		M.withheld[i] = {}
		if nd.kind == "src" then
			M.value[i] = nd.init
			M.rev[i] = 0
			local h = q.Source(nd.init)
			Qn[i] = h
			srcIndexOf[h] = i
		elseif nd.kind == "compute" then
			local rt = { lastResult = nil, snap = nil, lastThrew = false, calls = 0 }
			nodeRuntime[i] = rt
			local spec = nd.spec
			local fn = function(selfH, previous, ...)
				local hs = { selfH, ... }
				STATS.calls += 1
				rt.calls += 1
				-- dirty judgement from MODEL revisions (lockstep with quad's Sets)
				local cur = {}
				local dirty = rt.snap == nil or rt.lastThrew
				for s in M.upSrc[i] do
					cur[s] = M.rev[s]
					if rt.snap and rt.snap[s] ~= M.rev[s] then
						dirty = true
					end
				end
				if not dirty then
					STATS.spurious += 1
					viol(`node {i}: Compute fn ran although no upstream revision moved since its last successful run`)
				end
				if previous ~= rt.lastResult then
					STATS.prevBad += 1
					viol(`node {i}: previous={tostring(previous)} expected {tostring(rt.lastResult)}`)
				end
				local ok, r = pcall(evalNode, spec, function(j)
					return hs[j]:Get()
				end)
				if ok then
					if rt.lastThrew then
						STATS.recoveries += 1
					end
					rt.lastResult = r
					rt.snap = cur
					rt.lastThrew = false
					return r
				end
				STATS.throwsSeen += 1
				rt.lastThrew = true
				error(r, 0)
			end
			local deps = {}
			for j = 2, #nd.deps do
				deps[#deps + 1] = Qn[nd.deps[j]]
			end
			Qn[i] = Qn[nd.deps[1]]:Compute(fn, table.unpack(deps))
		elseif nd.kind == "depend" then
			local deps = {}
			for j = 2, #nd.deps do
				deps[#deps + 1] = Qn[nd.deps[j]]
			end
			Qn[i] = Qn[nd.deps[1]]:Depend(table.unpack(deps))
		elseif nd.gk == "blocker" and false then
			local b = blockers[nd.blocker]
			local before = {}
			for h in b._handles do
				before[h] = true
			end
			Qn[i] = Qn[nd.deps[1]]:Apply(b)
			for h in b._handles do
				if not before[h] then
					handleGate[h] = i
				end
			end
		elseif nd.gk == "blocker" then
			local b = blockers[nd.blocker]
			local before = {}
			for h in b._handles do
				before[h] = true
			end
			Qn[i] = Qn[nd.deps[1]]:Apply(b)
			for h in b._handles do
				if not before[h] then
					handleGate[h] = i
				end
			end
		else
			M.mopen[i] = nd.open0
			local g = { open = nd.open0 }
			Qn[i] = Qn[nd.deps[1]]:Gate(function(emit)
				g.emit = emit
				return function()
					if g.open then
						emit()
					end
				end
			end)
			Qn[i]._e40 = g
		end
		subKind[Qn[i]] = { t = "node", i = i }
		if nd.kind == "gate" then
			local h = Qn[i]
			local impl = getmetatable(h)
			rawset(h, "Get", function(self)
				for s2 in M.upSrc[i] do
					M.gvalSeen[i][s2] = M.rev[s2]
				end
				return impl.Get(self)
			end)
		end
	end

	-- ── callbacks ──────────────────────────────────────────────────────────
	local REENT_BUDGET = 0
	local srcList = {}
	for i = 1, N do
		if case.nodes[i].kind == "src" then
			srcList[#srcList + 1] = i
		end
	end
	local doSet -- forward
	local function maybeReent(ownerNode, seedv)
		if not FLAGS.reent or REENT_BUDGET <= 0 then
			return
		end
		-- Set a Source that is not the observed node itself
		local s = srcList[(seedv % #srcList) + 1]
		if s == ownerNode or not M.active[s] then
			return
		end
		if (seedv // 7) % 3 ~= 0 then
			return
		end
		REENT_BUDGET -= 1
		STATS.reentSets += 1
		if VERBOSE ~= 0 then
			print(`      reent: from {ownerNode} Set src {s} = {(seedv // 3) % 13}`)
		end
		doSet(s, (seedv // 3) % 13, true)
	end

	local function newObserver(i, mode, id, noread)
		local o = { noread = noread, id = id, node = i, mode = "none", m = { count = 1, pending = false }, q = { count = 0, lastRead = nil } }
		observers[#observers + 1] = o
		o.installing = true
		local h = Qn[i]:Observer(function(target, _self, from)
			o.q.count += 1
			STATS.obsFires += 1
			if o.noread then
				if not FLAGS.reent then
					checkFrom(o, from)
				end
				return
			end
			local v = readQ(target)
			o.q.lastRead = v
			o.staleOk = false
			if o.installing then
				o.reentAtInstall = STATS.reentSets
			end
			if VERBOSE ~= 0 and FLAGS.reent then
				print(`      obs#{o.id} fired, read {tostring(v)}`)
			end
			if not FLAGS.reent then
				if o.installing or o.replaying then
					if from ~= nil then
						viol(`obs#{o.id}: emitFrom not nil on install/replay`)
					end
				else
					checkFrom(o, from)
				end
				if not same(v, expected[i]) then
					viol(`obs#{o.id} on node {i}: read {tostring(v)} expected {tostring(expected[i])} (glitch)`)
				end
			end
			maybeReent(i, (o.q.count * 31 + id * 17) % 1000)
		end)
		o.installing = false
		if FLAGS.reent and o.reentAtInstall and STATS.reentSets > o.reentAtInstall then
			-- a Set reached during our own install fire after we read: documented to NOT come back to us
			-- (docs core/05:102, "ORDER IS THE CONTRACT"); the Q73 family — excluded from the eventual check
			o.staleOk = true
			STATS.installWindowLoss += 1
		end
		o.h = h
		subKind[h] = { t = "obs", o = o }
		return o
	end
	local function obsSub(o, mode)
		o.mode = mode
		if o.m.pending then
			o.m.count += 1
			o.m.pending = false
		end
		o.replaying = true
		if mode == "strong" then
			o.h:Subscribe()
		else
			o.h:WeakSubscribe()
		end
		o.replaying = false
	end
	local function obsUnsub(o)
		if o.mode == "strong" then
			o.h:Unsubscribe()
		else
			o.h:WeakUnsubscribe()
		end
		o.mode = "none"
	end

	local function newEffect(depIdx, retCleanup, id)
		local e = {
			id = id, deps = depIdx, depSet = {}, retCleanup = retCleanup, mode = "none",
			m = { runs = 1, cleanups = 0, stored = retCleanup, pending = false, seen = {} },
			q = { runs = 0, cleanups = 0, lastReads = {} },
		}
		for _, d in depIdx do
			e.depSet[d] = true
			for s in M.upSrc[d] do
				e.m.seen[s] = M.rev[s] -- seeded live (effect-plan: Sync / TrackFrom)
			end
		end
		effects[#effects + 1] = e
		log(`   eff#{id} deps={table.concat(depIdx, ",")} cleanup={retCleanup}`)
		local hs = {}
		for _, d in depIdx do
			hs[#hs + 1] = Qn[d]
		end
		e.h = q.Effect(function(_self)
			e.q.runs += 1
			STATS.effRuns += 1
			for k, d in depIdx do
				local v = readQ(hs[k])
				e.q.lastReads[k] = v
				if not FLAGS.reent and not same(v, expected[d]) then
					viol(`eff#{e.id} dep node {d}: read {tostring(v)} expected {tostring(expected[d])} (glitch)`)
				end
			end
			maybeReent(-1, (e.q.runs * 13 + id * 29) % 1000)
			if retCleanup then
				return function()
					e.q.cleanups += 1
				end
			end
			return nil
		end, table.unpack(hs))
		for _, inner in e.h._deps do
			if type(inner) == "table" then
				subKind[inner] = { t = "eff", e = e }
			end
		end
		return e
	end
	local function effSub(e, mode)
		e.mode = mode
		if e.m.pending then
			modelEffRun(e)
		end
		if mode == "strong" then
			e.h:Subscribe()
		else
			e.h:WeakSubscribe()
		end
	end
	local function effUnsub(e)
		if e.mode == "strong" then
			-- consume: cleanup once, then "must install again" (effect-plan `_consumeCleanup`, gate-plan 계약 절)
			if e.m.stored then
				e.m.cleanups += 1
				e.m.stored = false
			end
			e.m.pending = true
			e.mode = "none"
			e.h:Unsubscribe()
		else
			e.mode = "none"
			e.h:WeakUnsubscribe()
		end
	end

	-- ── mutations ─────────────────────────────────────────────────────────
	local primMutations = 0
	doSet = function(s, v, nested)
		primMutations += 1
		if v ~= nil then
			M.value[s] = v
		end
		M.rev[s] += 1
		recomputeModel()
		local saved = EXPECT_FROM
		EXPECT_FROM = { kind = "epoch", src = s }
		if not nested then
			if FLAGS.dfs then
				dfsEmit(s, { [s] = true })
			else
				wave(s, { [s] = true })
			end
		end
		if v ~= nil then
			Qn[s]:Set(v)
		else
			Qn[s]:Emit()
		end
		EXPECT_FROM = saved
	end

	local function blockerOff(b, commit)
		M.blocking[b] = false
		-- quad's snapshot order of handles (unspecified by contract; read to align the model)
		local order = {}
		for h in blockers[b]._handles do
			local gi = handleGate[h]
			if gi then
				order[#order + 1] = gi
			end
		end
		local batches = {}
		for _, gi in order do
			if next(M.withheld[gi]) ~= nil then
				local copy = {}
				for k in M.withheld[gi] do
					copy[k] = true
				end
				batches[#batches + 1] = copy
			end
		end
		-- a flush can reach another gate of the same blocker downstream: its batch then grows (union);
		-- accept any union of the listed batches as a legal payload
		local unions = {}
		for mask = 1, (2 ^ #batches) - 1 do
			local u = {}
			for k = 1, #batches do
				if bit32.band(mask, bit32.lshift(1, k - 1)) ~= 0 then
					for x in batches[k] do
						u[x] = true
					end
				end
			end
			unions[#unions + 1] = u
		end
		for _, gi in order do
			flushGate(gi, commit)
		end
		EXPECT_FROM = { kind = "batch", sets = unions }
		if commit then
			blockers[b]:Off()
		else
			blockers[b]:OffWithoutEmit()
		end
		EXPECT_FROM = nil
	end

	-- ── compare everything after an op ────────────────────────────────────
	local function compareCounts(tag)
		for _, o in observers do
			if o.m.count ~= o.q.count then
				viol(`{tag}: obs#{o.id} on node {o.node} ({case.nodes[o.node].kind}) fired {o.q.count}, model {o.m.count}`)
				o.m.count = o.q.count -- resync to keep finding independent diffs
			end
		end
		for _, e in effects do
			if e.m.runs ~= e.q.runs or e.m.cleanups ~= e.q.cleanups then
				viol(`{tag}: eff#{e.id} runs {e.q.runs}/{e.m.runs} cleanups {e.q.cleanups}/{e.m.cleanups} (quad/model)`)
				e.m.runs, e.m.cleanups = e.q.runs, e.q.cleanups
			end
		end
	end

	if verbose then
		for i = 1, N do
			local nd = case.nodes[i]
			print(`node {i}: {nd.kind} {nd.gk or ""} deps={nd.deps and table.concat(nd.deps, ",") or "-"} blocker={nd.blocker or "-"} late={i >= case.lateFrom}`)
		end
	end
	-- initial nodes
	for i = 1, N do
		if i < case.lateFrom then
			createNode(i)
		end
	end
	recomputeModel()
	local nextLate = case.lateFrom
	local obsId, effId = 0, 0

	local function activeOfKind(pred)
		local l = {}
		for i = 1, N do
			if M.active[i] and pred(case.nodes[i]) then
				l[#l + 1] = i
			end
		end
		return l
	end
	local function pick(l, r)
		if #l == 0 then
			return nil
		end
		return l[(r % #l) + 1]
	end

	for step, op in case.ops do
		curStep = step
		STATS.steps += 1
		primMutations = 0
		REENT_BUDGET = 3
		for _, rt in nodeRuntime do
			rt.calls = 0
		end
		local kind, r1, r2, r3, v1, v2 = op[1], op[2], op[3], op[4], op[5], op[6]
		local srcs = activeOfKind(function(nd) return nd.kind == "src" end)
		local all = activeOfKind(function() return true end)
		local bgates = activeOfKind(function(nd) return nd.kind == "gate" and nd.gk == "manual" end)
		log(`-- step {step}: {kind} {r1} {r2} {r3} {v1} {v2}`)
		if kind == "set" then
			local s = pick(srcs, r1)
			if s then
				doSet(s, v1)
			end
		elseif kind == "setsame" then
			local s = pick(srcs, r1)
			if s then
				doSet(s, M.value[s])
			end
		elseif kind == "emit" then
			local s = pick(srcs, r1)
			if s then
				doSet(s, nil)
			end
		elseif kind == "bon" then
			local b = (r1 % case.nBlockers) + 1
			M.blocking[b] = true
			blockers[b]:On()
		elseif kind == "boff" or kind == "boffx" then
			local b = (r1 % case.nBlockers) + 1
			blockerOff(b, kind == "boff")
		elseif kind == "mopen" or kind == "mclose" or kind == "mdiscard" then
			local gi = pick(bgates, r1)
			if gi then
				local g = Qn[gi]._e40
				if kind == "mopen" then
					M.mopen[gi] = true
					g.open = true
					local b = M.withheld[gi]
					local copy = {}
					for k in b do
						copy[k] = true
					end
					flushGate(gi, true)
					EXPECT_FROM = { kind = "batch", sets = { copy } }
					g.emit()
					EXPECT_FROM = nil
				elseif kind == "mclose" then
					M.mopen[gi] = false
					g.open = false
				else
					flushGate(gi, false)
					g.emit(false)
				end
			end
		elseif kind == "obs" then
			local i = pick(all, r1)
			if i then
				obsId += 1
				local o = newObserver(i, "none", obsId, r3 % 3 == 0)
				local m = r2 % 3
				if m == 1 then
					obsSub(o, "strong")
				elseif m == 2 then
					obsSub(o, "weak")
				end
			end
		elseif kind == "obssub" then
			local o = observers[(r1 % math.max(1, #observers)) + 1]
			if o and o.mode == "none" then
				obsSub(o, if r2 % 2 == 0 then "strong" else "weak")
			end
		elseif kind == "obsunsub" then
			local o = observers[(r1 % math.max(1, #observers)) + 1]
			if o and o.mode ~= "none" then
				obsUnsub(o)
			end
		elseif kind == "eff" then
			if #all > 0 then
				effId += 1
				local deps = { pick(all, r1) }
				if r2 % 2 == 0 then
					deps[#deps + 1] = pick(all, r2 // 2)
				end
				if r3 % 3 == 0 then
					deps[#deps + 1] = pick(all, r3 // 3)
				end
				-- duplicates are merged by quad (docs 05:219) — model: depSet
				local e = newEffect(deps, r3 % 2 == 0, effId)
				local m = r2 % 3
				if m == 1 then
					effSub(e, "strong")
				elseif m == 2 then
					effSub(e, "weak")
				end
			end
		elseif kind == "effsub" then
			local e = effects[(r1 % math.max(1, #effects)) + 1]
			if e and e.mode == "none" then
				effSub(e, if r2 % 2 == 0 then "strong" else "weak")
			end
		elseif kind == "effunsub" then
			local e = effects[(r1 % math.max(1, #effects)) + 1]
			if e and e.mode ~= "none" then
				effUnsub(e)
			end
		elseif kind == "effrerun" then
			local e = effects[(r1 % math.max(1, #effects)) + 1]
			if e then
				modelEffRerun(e)
				e.h:Rerun()
			end
		elseif kind == "get" then
			local i = pick(all, r1)
			if i then
				local v = readQ(Qn[i])
				if not FLAGS.reent and not same(v, expected[i]) then
					viol(`get node {i}: {tostring(v)} expected {tostring(expected[i])}`)
				end
			end
		elseif kind == "batch2" then
			-- two Sources in one Blocker window
			local b = (r1 % case.nBlockers) + 1
			M.blocking[b] = true
			blockers[b]:On()
			local s1, s2 = pick(srcs, r2), pick(srcs, r3)
			if s1 then
				doSet(s1, v1)
			end
			if s2 then
				doSet(s2, v2)
			end
			blockerOff(b, true)
		elseif kind == "late" then
			if nextLate <= N then
				createNode(nextLate)
				nextLate += 1
				recomputeModel()
			end
		end
		if FLAGS.reent then
			-- model values from quad's ACTUAL source values (callback order is unspecified)
			for _, s in srcs do
				M.value[s] = Qn[s]:Get()
			end
			recomputeModel()
		end
		if verbose then
			for _, e in effects do
				log(`   eff#{e.id} mode={e.mode} runs q{e.q.runs}/m{e.m.runs} pendingM={e.m.pending} rrq={e.h._rerunRequired}`)
			end
			for _, o in observers do
				log(`   obs#{o.id} node={o.node} mode={o.mode} q{o.q.count}/m{o.m.count}`)
			end
			local w = {}
			for gi, set in M.withheld do
				local ks = {}
				for k in set do ks[#ks + 1] = k end
				if #ks > 0 then w[#w + 1] = `{gi}:\{{table.concat(ks, ",")}\}` end
			end
			log(`   model withheld {table.concat(w, " ")} blocking={tostring(M.blocking[1])},{tostring(M.blocking[2])}`)
		end
		if not FLAGS.reent then
			compareCounts(kind)
		end
		-- read a random subset (every 5th step: all) — lazy paths stay exercised
		local RR = newRng(case.seed * 1000 + step)
		for i = 1, N do
			if M.active[i] and (step % 5 == 0 or RR(2) == 1) then
				local v = readQ(Qn[i])
				if not same(v, expected[i]) then
					viol(`final read node {i} ({case.nodes[i].kind}): {tostring(v)} expected {tostring(expected[i])}`)
				end
			end
		end
		if FLAGS.reent then
			-- eventual consistency: a subscribed Observer/Effect whose target has no gate upstream
			-- must have last read the final value
			local function gateFree(i)
				local stack, seen = { i }, {}
				while #stack > 0 do
					local x = table.remove(stack)
					if not seen[x] then
						seen[x] = true
						local nd = case.nodes[x]
						if nd.kind == "gate" then
							return false
						end
						if nd.deps then
							for _, d in nd.deps do
								stack[#stack + 1] = d
							end
						end
					end
				end
				return true
			end
			for _, o in observers do
				if o.mode ~= "none" and o.staleOk and gateFree(o.node) and o.q.lastRead ~= nil and not same(o.q.lastRead, expected[o.node]) then
					STATS.installWindowStale += 1
				end
				if o.mode ~= "none" and not o.staleOk and gateFree(o.node) and o.q.lastRead ~= nil and not same(o.q.lastRead, expected[o.node]) then
					viol(`reent: obs#{o.id} on node {o.node} last read {tostring(o.q.lastRead)}, final {tostring(expected[o.node])}`)
				end
			end
			for _, e in effects do
				if e.mode ~= "none" then
					for k, d in e.deps do
						if gateFree(d) and e.q.lastReads[k] ~= nil and not same(e.q.lastReads[k], expected[d]) then
							viol(`reent: eff#{e.id} last read dep node {d} = {tostring(e.q.lastReads[k])}, final {tostring(expected[d])}`)
						end
					end
				end
			end
		end
		-- recompute-count histogram (single-mutation steps only, no throwing node)
		if not FLAGS.reent then
			for i, rt in nodeRuntime do
				if primMutations <= 1 then
					STATS.callHist[rt.calls] = (STATS.callHist[rt.calls] or 0) + 1
				end
				if isDiamond[i] and primMutations == 1 then
					STATS.diamondSetSteps += 1
					STATS.diamondCalls += rt.calls
				end
			end
		end
		if #violations > 0 and not verbose then
			break
		end
	end
	for i in isDiamond do
		STATS.diamondNodes += 1
	end
	return violations
end

-- ── shrinking ───────────────────────────────────────────────────────────
local function copyCase(c, ops)
	return { seed = c.seed, nodes = c.nodes, nBlockers = c.nBlockers, lateFrom = c.lateFrom, ops = ops }
end
local function fails(c)
	local ok, v = pcall(run, c, false)
	if not ok then
		return true, { "crash: " .. tostring(v) }
	end
	return #v > 0, v
end
local function shrink(c)
	local ops = table.clone(c.ops)
	-- truncate after the first failing step
	local _, v = fails(c)
	local st = tonumber(string.match(v[1] or "", "^step (%d+)")) or #ops
	while #ops > st do
		table.remove(ops)
	end
	local progress = true
	while progress do
		progress = false
		local i = #ops
		while i >= 1 do
			local trial = table.clone(ops)
			table.remove(trial, i)
			if fails(copyCase(c, trial)) then
				ops = trial
				progress = true
			end
			i -= 1
		end
	end
	return copyCase(c, ops)
end
local function ser(v, ind)
	ind = ind or ""
	if type(v) == "table" then
		local parts = {}
		local isArr = #v > 0
		for k, x in (if isArr then ipairs(v) else pairs(v)) do
			if isArr then
				parts[#parts + 1] = ser(x, ind .. "\t")
			else
				parts[#parts + 1] = `{k} = {ser(x, ind .. "\t")}`
			end
		end
		return "{ " .. table.concat(parts, ", ") .. " }"
	elseif type(v) == "string" then
		return string.format("%q", v)
	end
	return tostring(v)
end

-- ── main ────────────────────────────────────────────────────────────────
local failed = 0
local firstFail = nil
for seed = FROM, FROM + COUNT - 1 do
	local c = genCase(seed)
	local ok, v = pcall(run, c, seed == VERBOSE)
	if not ok then
		v = { "crash: " .. tostring(v) }
	end
	if #v > 0 then
		failed += 1
		if not FLAGS.quiet then
			print(`R seed={seed} FAIL {v[1]}`)
			if seed == VERBOSE then
				for _, m in v do
					print("   ", m)
				end
			end
		end
		firstFail = firstFail or c
	end
end
local hist = {}
for k, n in STATS.callHist do
	hist[#hist + 1] = `{k}:{n}`
end
table.sort(hist)
print(`SUMMARY flags={ARGS[3] or ""} seeds={COUNT} failed={failed} steps={STATS.steps} fnCalls={STATS.calls} spurious={STATS.spurious} prevBad={STATS.prevBad} obsFires={STATS.obsFires} effRuns={STATS.effRuns} fromChecks={STATS.fromChecks} throws={STATS.throwsSeen} recoveries={STATS.recoveries} reentSets={STATS.reentSets} multiPayloadArrivals={STATS.multiPayload} installWindowSkips={STATS.installWindowLoss} installWindowStaleObsSteps={STATS.installWindowStale}`)
print(`CALLS per node per single-mutation step: {table.concat(hist, " ")}; diamond-bottom nodes={STATS.diamondNodes} diamond single-Set node-steps={STATS.diamondSetSteps} calls={STATS.diamondCalls}`)
if firstFail and FLAGS.shrink then
	local s = shrink(firstFail)
	local _, v = fails(s)
	local path = `.claude/audit/round13-e40-reactive-fuzz/repros/{s.seed}{FLAGS.throw and "-throw" or ""}{FLAGS.late and "-late" or ""}.luau`
	local f = io and io.open and io.open(path, "w")
	local body = `-- E40 shrunk repro (seed {s.seed}, flags {ARGS[3] or ""})\n-- first violation: {v[1]}\nreturn {ser({ seed = s.seed, nodes = s.nodes, nBlockers = s.nBlockers, lateFrom = s.lateFrom, ops = s.ops })}\n`
	if f then
		f:write(body)
		f:close()
		print("WROTE " .. path)
	else
		print("REPRO-BEGIN")
		print(body)
		print("REPRO-END")
	end
end
