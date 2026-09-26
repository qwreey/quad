--!nocheck
-- E63 — dependency-set contract fuzzer for q.Effect(fn, ...deps) / state:Observer(fn) / :Depend / :Compute trailing deps.
-- Run from this folder after ./scripts/relink.sh:   luau fuzz.luau -a <from> <count> [flags] [verboseSeed]
-- flags: late (consumers created mid-sequence), inj1 (model forgets diamond dedup — self-check),
--        inj2 (model treats Ref same-value Set as no emit — self-check), inj3 (model: WeakUnsubscribe consumes cleanup)
--
-- MODEL (written from the docs, not from Effect.luau/State.luau):
--  * roots = Source / Ref, each Set (same value too) = new revision (core/02-source.md:78, core/07-ref.md:190,240).
--  * a node forwards a root revision at most once (diamond absorbed; quadnomicon 01 rules 1~3), Depend node = receiver's
--    value, emits on ANY dep (core/03-state.md:112-120); Compute trailing deps emit even when fn doesn't read them (core/03:68).
--  * gate (state:Apply(blocker)): while Blocking, withholds the root set; Off flushes one batch per gate in the blocker's
--    handle order (unspecified by contract — read from blocker._handles, as E40 did); OffWithoutEmit discards (sugar/06).
--  * Effect: fn once at construction; afterwards (cleanup → fn) once per delivery carrying a root revision it has not seen
--    (seen-set seeded LIVE at construction — base/state-epoch-plan.md §6); duplicate deps merge (core/05:196);
--    unexecutable → held, replayed once on (re)subscribe / bind (core/05:222); Unsubscribe consumes the cleanup and a later
--    Subscribe re-installs (base/gate-plan.md:523); WeakUnsubscribe leaves cleanup (core/05:300); host Destroy consumes
--    cleanup with dying=true (core/05:219) and stops; Ref dep emits per Ref:Set; instance destroy of a Ref's host does not.
--  * Observer: one target, install fire, fires per forward of its target, held → one replay (core/05:101-103).
local ARGS = { ... }
local FROM, COUNT = tonumber(ARGS[1]) or 1, tonumber(ARGS[2]) or 200
local FLAGS = {}
for f in string.gmatch(ARGS[3] or "", "[^,]+") do FLAGS[f] = true end
local VERBOSE = tonumber(ARGS[4]) or 0

local H = require("./harness")
local q, D = H.q, H.D
local function firstLine(e) return (tostring(e):gsub("\n.*", "")) end
local function errId(e) return string.match(tostring(e), "Quad%d%d%d%d") or ("RAW:" .. firstLine(e)) end

local function newRng(seed)
	local s = (seed * 7919 + 12345) % 2147483647
	if s <= 0 then s += 2147483646 end
	return function(n) s = (s * 48271) % 2147483647; return s % n + 1 end
end

local stats = { seeds = 0, steps = 0, diffs = 0, effRuns = 0, obsFires = 0, cleanups = 0, dying = 0, errOps = 0,
	refSets = 0, refSame = 0, srcSame = 0, destroyRefHost = 0, destroyHost = 0, flushes = 0, lateMade = 0,
	dupDepEffects = 0, zeroDepEffects = 0, invalidCtor = 0, heldReplays = 0 }
local failSeeds = {}

local function runSeed(seed)
	local R = newRng(seed)
	local log = {}
	local function V(s) if VERBOSE == seed then print(s) end end
	local diff = nil
	local function fail(msg) if not diff then diff = msg end end

	-- ── build graph ──
	local nBl = R(2)
	local bls = {}
	for i = 1, nBl do bls[i] = { obj = q.Blocker(), gates = {} } end
	local handleOwner = {} -- blocker handle closure -> gate node (model)
	local nodes = {}
	local roots = {} -- list of root nodes
	local n = 2 + R(9) -- 3..10
	local function nonRefBefore(i, noGateUp)
		local c = {}
		for j = 1, i - 1 do
			local nd = nodes[j]
			if nd.kind ~= "ref" and (not noGateUp or not nd.gated) then c[#c + 1] = nd end
		end
		return c
	end
	for i = 1, n do
		local nd = { id = i }
		local r = R(10)
		local pool = nonRefBefore(i, false)
		if i == 1 or #pool == 0 or r <= 2 then
			nd.kind = "src"; nd.val = R(20); nd.obj = q.Source(nd.val)
		elseif r == 3 then
			nd.kind = "ref"; if R(2) == 1 then nd.val = nil; nd.obj = q.Ref() else nd.val = R(20); nd.obj = q.Ref(nd.val) end
		elseif r <= 6 then
			nd.kind = "cmp"
			nd.recv = pool[R(#pool)]
			nd.trail = {}
			for k = 1, R(3) - 1 do nd.trail[k] = pool[R(#pool)] end
			nd.coef = {}
			for k = 1, #nd.trail + 1 do nd.coef[k] = R(5) end
			nd.unread = (#nd.trail > 0 and R(3) == 1) and R(#nd.trail) or nil -- index of a trailing dep fn never reads
			local spec = nd
			local args = {}
			for k, t in nd.trail do args[k] = t.obj end
			nd.obj = nd.recv.obj:Compute(function(s, _prev, ...)
				local acc = spec.coef[1] * s:Get()
				local hs = { ... }
				for k = 1, #spec.trail do
					if spec.unread ~= k then acc += spec.coef[k + 1] * hs[k]:Get() end
				end
				return acc % 997
			end, table.unpack(args))
		elseif r <= 8 then
			nd.kind = "dep"
			nd.recv = pool[R(#pool)]
			nd.trail = {}
			for k = 1, R(3) do nd.trail[k] = pool[R(#pool)] end
			local args = {}
			for k, t in nd.trail do args[k] = t.obj end
			nd.obj = nd.recv.obj:Depend(table.unpack(args))
		else
			local gpool = nonRefBefore(i, true)
			if #gpool == 0 then
				nd.kind = "src"; nd.val = R(20); nd.obj = q.Source(nd.val)
			else
				nd.kind = "gate"; nd.recv = gpool[R(#gpool)]; nd.trail = {}
				nd.bl = bls[R(nBl)]
				local before = {}
				for h in nd.bl.obj._handles do before[h] = true end
				nd.obj = nd.recv.obj:Apply(nd.bl.obj)
				for h in nd.bl.obj._handles do if not before[h] then handleOwner[h] = nd end end
				nd.withheld = {}
				nd.gated = true
			end
		end
		if nd.kind ~= "src" and nd.kind ~= "ref" and nd.kind ~= "gate" then
			nd.gated = nd.recv.gated
			for _, t in nd.trail do nd.gated = nd.gated or t.gated end
		end
		if nd.kind == "src" or nd.kind == "ref" then nd.rev = 0; roots[#roots + 1] = nd end
		nd.subs = {} -- downstream nodes (model)
		nd.cons = {} -- consumers subscribed (Observer / Effect internal)
		nd.emit = {} -- emit map (starts EMPTY)
		nodes[i] = nd
		if VERBOSE == seed then local s = {} for _, t in nd.trail or {} do s[#s + 1] = t.id end print(`  node {i} {nd.kind} recv {nd.recv and nd.recv.id or "-"} trail {table.concat(s, ",")}`) end
		if nd.recv then
			nd.recv.subs[#nd.recv.subs + 1] = nd
			for _, t in nd.trail do t.subs[#t.subs + 1] = nd end
		end
	end
	-- roots reachable
	local function rootsOf(nd, acc)
		acc = acc or {}
		if nd.kind == "src" or nd.kind == "ref" then acc[nd] = true return acc end
		rootsOf(nd.recv, acc)
		for _, t in nd.trail do rootsOf(t, acc) end
		return acc
	end
	local function valueOf(nd)
		if nd.kind == "src" or nd.kind == "ref" then return nd.val end
		if nd.kind == "dep" or nd.kind == "gate" then return valueOf(nd.recv) end
		local acc = nd.coef[1] * valueOf(nd.recv)
		for k, t in nd.trail do if nd.unread ~= k then acc += nd.coef[k + 1] * valueOf(t) end end
		return acc % 997
	end

	-- ── consumers ──
	local cons = {}
	local frames = {} -- live host frames of consumers
	local function newConsumer(late)
		local c = { id = #cons + 1, runs = 0, cleanups = 0, dying = 0, strong = false, weak = false, host = nil,
			pending = false, stored = false, lastRead = nil }
		if R(3) ~= 1 then
			c.kind = "E"
			local nd = R(5) - 1 -- 0..4 deps
			c.deps = {}
			local cand = nodes
			for k = 1, nd do c.deps[k] = cand[R(#cand)] end
			if nd == 0 then stats.zeroDepEffects += 1 end
			local uniq = {}
			local dupSeen = false
			for _, d in c.deps do if uniq[d] then dupSeen = true end uniq[d] = true end
			if dupSeen then stats.dupDepEffects += 1 end
			c.clMode = R(3) -- 1 always cleanup, 2 never, 3 alternate
			c.seen = {}
			for d in uniq do for rt in rootsOf(d) do c.seen[rt] = rt.rev end end
			c.depSet = uniq
			local depObjs = {}
			for k, d in c.deps do depObjs[k] = d.obj end
			local cc = c
			local function fn(self)
				cc.runs += 1; stats.effRuns += 1
				local reads = {}
				for k, d in cc.deps do
					if d.kind == "ref" then reads[k] = d.obj.Value else reads[k] = d.obj:Get() end
				end
				cc.lastRead = reads
				cc.readLog = cc.readLog or {}
				if cc.clMode == 1 or (cc.clMode == 3 and cc.runs % 2 == 1) then
					return function(dying)
						cc.cleanups += 1; stats.cleanups += 1
						if dying == true then cc.dying += 1; stats.dying += 1 end
					end
				end
				return nil
			end
			c.obj = q.Effect(fn, table.unpack(depObjs, 1, nd))
			if VERBOSE == seed then local s = {} for _, d in c.deps do s[#s + 1] = d.kind .. d.id end print(`  E{c.id} deps {table.concat(s, ",")}`) end
			-- model: install
			c.mRuns, c.mCleanups, c.mDying = 1, 0, 0
			c.mStored = (c.clMode == 1 or c.clMode == 3)
			c.mNeeds = false
			for d in uniq do
				if d.kind == "ref" then d.cons[#d.cons + 1] = c else d.cons[#d.cons + 1] = c end
			end
		else
			c.kind = "O"
			local pool = {}
			for _, nd in nodes do if nd.kind ~= "ref" then pool[#pool + 1] = nd end end
			c.target = pool[R(#pool)]
			local cc = c
			c.obj = c.target.obj:Observer(function(t, self, from)
				cc.runs += 1; stats.obsFires += 1
				cc.lastRead = { t:Get() }
			end)
			c.mRuns = 1
			c.mNeeds = false
			c.target.cons[#c.target.cons + 1] = c
		end
		cons[#cons + 1] = c
		if late then stats.lateMade += 1 end
		return c
	end
	local nCons = R(4)
	for _ = 1, nCons do newConsumer(false) end

	-- ── model helpers ──
	local function exec(c) return c.strong or c.weak or (c.host ~= nil and c.host.alive) end
	local function mRun(c) -- cleanup → fn on an executable Effect
		if c.mStored then c.mCleanups += 1 end
		c.mStored = false
		c.mRuns += 1
		c.mNeeds = false
		c.mStored = (c.clMode == 1 or (c.clMode == 3 and c.mRuns % 2 == 1))
	end
	local function effDeliver(c, batch) -- batch: set of roots
		if VERBOSE == seed then local s = {} for rt in batch do s[#s + 1] = rt.id .. "@" .. rt.rev .. "/seen" .. tostring(c.seen[rt]) end print(`    deliver E{c.id} {table.concat(s, ",")} exec {tostring(exec(c))}`) end
		local new = false
		for rt in batch do
			if FLAGS.inj1 then new = true end
			if c.seen[rt] ~= rt.rev then new = true end
		end
		for rt in batch do c.seen[rt] = rt.rev end
		if not new then return end
		if exec(c) then mRun(c) else c.mNeeds = true end
	end
	local function obsDeliver(c)
		if exec(c) then c.mRuns += 1 else c.mNeeds = true end
	end
	local function consDeliver(nd, batch)
		for _, c in nd.cons do
			if c.kind == "E" then effDeliver(c, batch) else obsDeliver(c) end
		end
	end
	local receive
	local function forward(nd, batch)
		consDeliver(nd, batch)
		for _, s in nd.subs do receive(s, batch) end
	end
	receive = function(nd, batch)
		local new = false
		for rt in batch do if nd.emit[rt] ~= rt.rev or FLAGS.inj1 then new = true end end
		if not new then return end
		if nd.kind == "gate" then
			for rt in batch do nd.withheld[rt] = true end
			if not nd.bl.obj.Blocking then
				local b = nd.withheld; nd.withheld = {}
				for rt in b do nd.emit[rt] = rt.rev end
				forward(nd, b)
			end
			return
		end
		for rt in batch do nd.emit[rt] = rt.rev end
		forward(nd, batch)
	end
	local function rootChanged(rt)
		rt.rev += 1
		local b = { [rt] = true }
		if rt.kind == "ref" then consDeliver(rt, b) else forward(rt, b) end
	end
	local function flushBlocker(bl, doEmit)
		local order = {}
		for h in bl.obj._handles do order[#order + 1] = handleOwner[h] end
		return function()
			for _, g in order do
				if g and next(g.withheld) then
					local b = g.withheld; g.withheld = {}
					if doEmit then
						stats.flushes += 1
						for rt in b do g.emit[rt] = rt.rev end
						forward(g, b)
					end
				end
			end
		end
	end

	-- ── compare ──
	local function compare(tag)
		for _, c in cons do
			if c.runs ~= c.mRuns then fail(`{tag}: {c.kind}{c.id} runs real {c.runs} model {c.mRuns}`) end
			if c.kind == "E" then
				if c.cleanups ~= c.mCleanups then fail(`{tag}: E{c.id} cleanups real {c.cleanups} model {c.mCleanups}`) end
				if c.dying ~= c.mDying then fail(`{tag}: E{c.id} dying real {c.dying} model {c.mDying}`) end
				if c.lastRead then
					for k, d in c.deps do
						local mv = valueOf(d)
						if FLAGS.inj4 and type(mv) == "number" then mv += 1 end
						if c.lastRead[k] ~= mv and c.lastRun == c.runs then
							fail(`{tag}: E{c.id} read dep#{k} real {tostring(c.lastRead[k])} model {tostring(valueOf(d))}`)
						end
					end
				end
			end
		end
		for _, nd in nodes do
			if nd.kind ~= "ref" then
				local ok, v = pcall(function() return nd.obj:Get() end)
				if not ok then fail(`{tag}: node {nd.id} Get threw {firstLine(v)}`)
				elseif v ~= valueOf(nd) then fail(`{tag}: node {nd.id}({nd.kind}) value real {v} model {valueOf(nd)}`) end
			elseif nd.obj.Value ~= nd.val then fail(`{tag}: ref {nd.id} value`) end
		end
	end
	-- lastRead is only checked for runs that happened in this op: mark before each op
	local function markRuns() for _, c in cons do c.lastRun = nil; c.runsBefore = c.runs end end
	local function settleReads() for _, c in cons do if c.runs ~= c.runsBefore then c.lastRun = c.runs end end end

	-- ── ops ──
	local refHosts = {} -- ref node -> frame record
	local nOps = 30 + R(51)
	for step = 1, nOps do
		if diff then break end
		stats.steps += 1
		markRuns()
		local op = R(20)
		local desc
		if op <= 5 then
			local srcs = {}
			for _, rt in roots do if rt.kind == "src" then srcs[#srcs + 1] = rt end end
			local rt = srcs[R(#srcs)]
			local same = R(4) == 1
			local v = if same then rt.val else R(20)
			if v == rt.val then stats.srcSame += 1 end
			desc = `src{rt.id}:Set({v})`
			rt.val = v
			rt.obj:Set(v)
			rootChanged(rt)
		elseif op <= 7 then
			local refs = {}
			for _, rt in roots do if rt.kind == "ref" then refs[#refs + 1] = rt end end
			if #refs > 0 then
				local rt = refs[R(#refs)]
				local k = R(6)
				if k == 1 and not (refHosts[rt] and refHosts[rt].alive) then
					local f = D.Frame { rt.obj }
					local rec = { inst = f, alive = true }
					refHosts[rt] = rec
					desc = `place ref{rt.id} in frame`
					rt.val = f
					rootChanged(rt)
					stats.refSets += 1
				elseif k == 2 and refHosts[rt] and refHosts[rt].alive then
					desc = `destroy ref{rt.id} host`
					refHosts[rt].alive = false
					refHosts[rt].inst:Destroy()
					stats.destroyRefHost += 1 -- core/07:92: no Set, no emit
				else
					local same = R(3) == 1
					local v = if same then rt.val else R(20)
					if same then stats.refSame += 1 end
					desc = `ref{rt.id}:Set({tostring(v)})`
					rt.val = v
					rt.obj:Set(v)
					stats.refSets += 1
					if not (FLAGS.inj2 and same) then rootChanged(rt) end
				end
			end
		elseif op <= 9 then
			local bl = bls[R(nBl)]
			local k = R(3)
			if k == 1 then desc = "blocker:On"; bl.obj:On()
			else
				local was = bl.obj.Blocking
				local fl = flushBlocker(bl, k == 2)
				desc = if k == 2 then "blocker:Off" else "blocker:OffWithoutEmit"
				if k == 2 then bl.obj:Off() else bl.obj:OffWithoutEmit() end
				fl()
			end
		elseif op <= 16 then
			local c = cons[R(#cons)]
			local k = R(7)
			local names = { "Subscribe", "WeakSubscribe", "Unsubscribe", "WeakUnsubscribe", "bind", "destroyHost", "Rerun" }
			desc = `{c.kind}{c.id}:{names[k]}`
			local E = c.kind == "E"
			local subscribed = c.strong or c.weak
			local bound = c.host ~= nil and c.host.alive
			local expect -- error id or nil
			if k == 1 then expect = if subscribed then (E and "Quad0091" or "Quad0114") elseif bound then (E and "Quad0231" or "Quad0235") else nil
			elseif k == 2 then expect = if subscribed then (E and "Quad0089" or "Quad0111") elseif bound then (E and "Quad0230" or "Quad0234") else nil
			elseif k == 3 then expect = if not c.strong then (E and "Quad0093" or "Quad0115") else nil
			elseif k == 4 then expect = if c.strong then (E and "Quad0092" or "Quad0112") else nil
			elseif k == 5 then expect = if subscribed then "Quad0104" elseif bound then "Quad0233" else nil
			end
			if k == 6 then
				if bound then
					desc ..= " (alive)"
					stats.destroyHost += 1
					c.host.alive = false
					local inst = c.host.inst
					if E then
						if c.mStored then c.mCleanups += 1; c.mDying += 1 end
						c.mStored = false; c.mNeeds = true
					end
					inst:Destroy()
				end
			elseif k == 7 then
				if E then
					if exec(c) then mRun(c) else c.mNeeds = true end
					c.obj:Rerun()
				end
			else
				local ok, e = pcall(function()
					if k == 1 then c.obj:Subscribe()
					elseif k == 2 then c.obj:WeakSubscribe()
					elseif k == 3 then c.obj:Unsubscribe()
					elseif k == 4 then c.obj:WeakUnsubscribe()
					else local f = D.Frame { c.obj }; c.pendingHost = f end
				end)
				local got = if ok then nil else errId(e)
				if got ~= expect then fail(`{desc}: error real {tostring(got)} expected {tostring(expect)}`) end
				if ok then
					if expect == nil then
						if k == 1 or k == 2 then
							if k == 1 then c.strong = true end
							c.weak = true
							if c.mNeeds then
								if E then mRun(c) else c.mRuns += 1; c.mNeeds = false; stats.heldReplays += 1 end
							end
						elseif k == 3 then
							c.strong = false; c.weak = false
							if E then if c.mStored then c.mCleanups += 1 end c.mStored = false; c.mNeeds = true end
						elseif k == 4 then
							c.weak = false
							if FLAGS.inj3 and E then if c.mStored then c.mCleanups += 1 end c.mStored = false end
						elseif k == 5 then
							c.host = { inst = c.pendingHost, alive = true }
							if c.mNeeds then
								if E then mRun(c) else c.mRuns += 1; c.mNeeds = false; stats.heldReplays += 1 end
							end
						end
					end
				else
					stats.errOps += 1
				end
			end
		elseif op <= 18 then
			-- invalid constructor attempts (ID + index)
			stats.invalidCtor += 1
			local choice = R(3)
			local bad = { "nil", 5, "str", {}, q.Slot(), q.Tag("t"), q.Blocker(), true }
			local len = R(4)
			local args, expect = {}, nil
			for k = 1, len do
				if R(3) == 1 then
					local b = R(#bad)
					args[k] = if b == 1 then nil else bad[b]
				else
					local cand = nodes[R(#nodes)]
					if choice ~= 1 and cand.kind == "ref" then args[k] = cand.obj -- invalid for Compute/Depend
					else args[k] = cand.obj end
				end
			end
			if choice == 1 then
				for k = 1, len do
					local a = args[k]
					if a == nil then expect = `Quad0095 #{k}` break end
					if not (q.isState(a) or q.isRef(a)) then expect = `Quad0096 #{k}` break end
				end
			else
				for k = 1, len do if args[k] == nil then expect = `Quad0186 #{k + 1}` break end end
				if not expect then
					for k = 1, len do if not q.isState(args[k]) then expect = `Quad0183 #{k + 1}` break end end
				end
			end
			local recv = nil
			for _, nd in nodes do if nd.kind ~= "ref" then recv = nd.obj break end end
			local ok, e = pcall(function()
				if choice == 1 then return q.Effect(function() end, table.unpack(args, 1, len))
				elseif choice == 2 then return recv:Depend(table.unpack(args, 1, len))
				else return recv:Compute(function(s) return s:Get() end, table.unpack(args, 1, len)) end
			end)
			local got = nil
			if not ok then got = errId(e) .. " #" .. (string.match(tostring(e), "dep #(%d+)") or "?") end
			desc = `invalid ctor {choice} len {len}`
			if got ~= expect then fail(`{desc}: real {tostring(got)} expected {tostring(expect)}`) end
		else
			if FLAGS.late and #cons < 8 then desc = "late consumer"; newConsumer(true)
			else desc = "noop" end
		end
		settleReads()
		V(`  step {step}: {desc}`)
		compare(`seed {seed} step {step} ({desc})`)
	end
	-- teardown: release strong subscriptions & frames (module-lifetime registries otherwise grow)
	for _, c in cons do
		if c.strong then pcall(function() c.obj:Unsubscribe() end) end
		if c.weak then pcall(function() c.obj:WeakUnsubscribe() end) end
		if c.host and c.host.alive then c.host.inst:Destroy() end
	end
	for _, rec in refHosts do if rec.alive then rec.inst:Destroy() end end
	stats.seeds += 1
	if diff then
		stats.diffs += 1
		failSeeds[#failSeeds + 1] = seed
		if #failSeeds <= 8 then print("DIFF", diff) end
	end
end

for seed = FROM, FROM + COUNT - 1 do
	local ok, e = pcall(runSeed, seed)
	if not ok then
		stats.diffs += 1
		failSeeds[#failSeeds + 1] = seed
		if #failSeeds <= 8 then print("CRASH seed", seed, firstLine(e)) end
	end
end
local keys = {}
for k in stats do keys[#keys + 1] = k end
table.sort(keys)
local out = {}
for _, k in keys do out[#out + 1] = k .. "=" .. stats[k] end
print(`flags={ARGS[3] or ""} from={FROM} count={COUNT}`)
print(table.concat(out, " "))
print("failSeeds(first 20):", table.concat(failSeeds, ",", 1, math.min(20, #failSeeds)))
