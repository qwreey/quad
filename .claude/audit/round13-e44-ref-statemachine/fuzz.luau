--!nocheck
-- E44 differential fuzzer: Ref / PreRef / PostRef state machine vs a reference model built
-- from the documented contract (see STATE-TABLE.md; every model rule cites doc file:line).
-- usage: luau fuzz.luau -a <firstSeed> <count> [verbose]
local H = require("./harness")
local q, D = H.q, H.D
local None = q.None
local args = { ... }
local FIRST = tonumber(args[1]) or 1
local COUNT = tonumber(args[2]) or 200
local VERBOSE = args[3] == "v"

local function errId(e)
	local s = tostring(e)
	return s:match("Quad%d%d%d%d") or ("RAW:" .. (s:gsub("\n.*", "")))
end
local REENTRY = setmetatable({}, { __tostring = function() return "REENTRY" end })
local TBL = setmetatable({}, { __tostring = function() return "TBL" end })
local STATEVAL = q.Source(123)
local NILKEY = setmetatable({}, { __tostring = function() return "nil" end })
local function K(v) if v == nil then return NILKEY end return v end
local ORPHAN = setmetatable({}, { __tostring = function() return "ORPHAN*" end })

local stats = { seeds = 0, ops = 0, diffs = 0, opKinds = {}, errIds = {}, undecided = {} }
local diffs = {}

local function runSeed(seed)
	math.randomseed(seed)
	local rnd = math.random
	local trace = {}
	local failed = nil
	local function fail(msg)
		if not failed then failed = msg end
	end

	---------------------------------------------------------------- actors
	-- two plain refs, each with a callback pool
	local refs = {}
	local function newRefActor(i)
		local a = { i = i, ref = q.Ref(nil), log = {}, model = {} }
		a.model.value = nil
		a.model.S = {} -- strong set  (core/07:202, :277)
		a.model.W = {} -- weak set    (core/07:216)
		a.model.T = {} -- waiter set  (core/07:204, :327)
		a.model.bound = nil -- frame record (core/07:64)
		a.model.synced = true -- every registered fn last saw model.value
		a.fns = {}
		local function rec(name, v) table.insert(a.log, { name, v }) end
		a.fns.cA = function(v) rec("cA", v) end
		a.fns.cB = function(v) rec("cB", v) end
		a.fns.cW = function(v) rec("cW", v) end
		a.fns.cX = function(v) rec("cX", v); a.ref:Callback(a.fns.cB) end -- re-registers cB inside
		a.fns.cU = function(v) rec("cU", v); a.ref:Uncallback(a.fns.cA) end -- unregisters cA inside
		a.armed = false
		a.fns.cR = function(v)
			rec("cR", v)
			if a.armed then
				a.armed = false
				a.ref:Set(REENTRY) -- re-entrant Set (core/07:242)
			end
		end
		a.waiterLog = {}
		return a
	end
	refs[1] = newRefActor(1)
	refs[2] = newRefActor(2)

	local frames = {} -- { inst=, alive=, orphan= }
	local seat = nil -- { st=, frame=, holds=actor|nil }

	-- one-shot actors
	local pre = { ref = q.PreRef(nil), fired = false, n = 0 }
	local post = { ref = q.PostRef(nil), fired = false, n = 0 }
	local orderLog = {}
	local function hookOneShot(o, tag)
		o.ref:Callback(function(v) if v ~= nil then o.n += 1; table.insert(orderLog, tag) end end)
	end
	hookOneShot(pre, "pre"); hookOneShot(post, "post")

	---------------------------------------------------------------- model helpers
	local function registered(a)
		local set = {}
		for k in a.model.S do set[k] = true end
		for k in a.model.W do set[k] = true end
		return set
	end
	-- expected deliveries for one op: exp[name] = { min=, max=, values = {v=true} }
	local CUR -- ctx of the running op (reentry bookkeeping)
	local function plainExpectSet(a, v, exp)
		for name in registered(a) do
			local e = exp[name] or { min = 0, max = 0, values = {} }
			e.min += 1; e.max += 1; e.values[K(v)] = true
			exp[name] = e
		end
		-- cX re-registers cB (core/07:276 — registration calls immediately)
		if a.model.S.cX or a.model.W.cX then
			local e = exp.cB or { min = 0, max = 0, values = {} }
			e.min += 1; e.max += 1; e.values[K(v)] = true
			exp.cB = e
			a.model.S.cB = true
		end
		-- cU unregisters cA mid-walk: cA delivery is order-dependent (0 or 1) (core/07:240, :248)
		if (a.model.S.cU or a.model.W.cU) and (a.model.S.cA or a.model.W.cA) then
			exp.cA.min = 0
			a.model.S.cA = nil; a.model.W.cA = nil
		end
		-- waiters consumed (core/07:244, :327)
		local woke = {}
		for th, info in a.model.T do woke[th] = info end
		a.model.T = {}
		for th, info in woke do
			table.insert(info.expect, K(v))
			if info.kind == "rewait" and info.left > 1 then
				info.left -= 1
				a.model.T[th] = info
			end
		end
		a.model.value = v
	end
	local function expectSet(a, v, exp)
		if not a.model.armed then
			return plainExpectSet(a, v, exp)
		end
		-- re-entrant walk (core/07:242): outer order undefined -> each fn gets v 0..1 times,
		-- cR gets v once, then the inner Set(REENTRY) reaches everyone exactly once
		a.model.armed = false
		for name in registered(a) do exp[name] = { min = 0, max = 1, values = { [K(v)] = true } } end
		exp.cR = { min = 1, max = 1, values = { [K(v)] = true } }
		local T0 = {}
		for th, info in a.model.T do T0[th] = info end
		local inner = {}
		plainExpectSet(a, REENTRY, inner)
		for name, e in inner do
			local o = exp[name] or { min = 0, max = 0, values = {} }
			o.min += e.min; o.max += e.max
			for vv in e.values do o.values[vv] = true end
			exp[name] = o
		end
		-- waiters: woken by outer or inner walk (a rewaiter possibly by both) — adopt after the op
		if CUR then
			CUR.reentryWaiters = CUR.reentryWaiters or {}
			for th, info in T0 do table.insert(CUR.reentryWaiters, { a = a, info = info, before = #info.seen, v = K(v) }) end
			CUR.reentryActors = CUR.reentryActors or {}
			CUR.reentryActors[a] = true
		end
	end
	local function checkDeliveries(a, before, exp, opname, relaxed)
		local got = {}
		for idx = before + 1, #a.log do
			local name, v = a.log[idx][1], a.log[idx][2]
			got[name] = got[name] or {}
			table.insert(got[name], K(v))
		end
		for name, e in exp do
			local g = got[name] or {}
			if not relaxed and (#g < e.min or #g > e.max) then
				fail(`{opname}: ref{a.i} {name} delivered {#g}x, model {e.min}..{e.max}`)
			end
			for _, v in g do
				if not relaxed and not e.values[v] then
					fail(`{opname}: ref{a.i} {name} got {tostring(v)} not in model values`)
				end
			end
		end
		for name, g in got do
			if not exp[name] and not relaxed then
				fail(`{opname}: ref{a.i} {name} delivered {#g}x, model 0`)
			end
		end
	end
	local function modelValueEq(a)
		local mv, rv = a.model.value, a.ref.Value
		if mv == ORPHAN then
			return typeof(rv) == "table" and H.q.Backend.isInst(rv)
		end
		return rawequal(mv, rv)
	end
	local function boundAlive(a)
		return a.model.bound ~= nil and a.model.bound.alive
	end

	---------------------------------------------------------------- ops
	local ops = {}
	local function op(name, weight, pre_, run)
		table.insert(ops, { name = name, w = weight, pre = pre_, run = run })
	end
	local function pickActor() return refs[rnd(1, 2)] end
	local A -- actor chosen for this op

	-- plain user Set (core/07:236-248)
	op("Set(v)", 6, nil, function(ctx)
		local choices = { nil, None, "same", 1, 2, TBL, STATEVAL, "s" }
		local k = rnd(1, #choices)
		local v = choices[k]
		if v == "same" then v = A.ref.Value end
		ctx.label = "Set(" .. tostring(v) .. ")"
		ctx.exp = {}
		expectSet(A, v, ctx.exp)
		A.ref:Set(v)
	end)
	op("Set with Wait(main) registered", 1, function() return not A.model.armed end, function(ctx)
		-- Quad0130 (core/07:244-246): current coroutine registered
		ctx.expectErr = { Quad0130 = true }
		ctx.partial = true
		A.ref:Wait(coroutine.running())
		A.model.value = 5
		A.model.T = {} -- UNDECIDED: consumed? (code: consumed before the status check)
		A.model.synced = false
		A.ref:Set(5)
	end)
	op("Set with dead thread registered", 1, function() return not A.model.armed end, function(ctx)
		-- core/07 silent; ref-plan.md:419-424 says resume fails and :Set raises (UB)
		ctx.expectErr = { ["RAW:cannot resume dead coroutine"] = true }
		ctx.partial = true
		local co = coroutine.create(function() end)
		coroutine.resume(co)
		A.ref:Wait(co)
		A.model.value = 6
		A.model.T = {}
		A.model.synced = false
		A.ref:Set(6)
	end)
	local function reg(fname, weak)
		return function(ctx)
			ctx.label = (weak and "WeakCallback(" or "Callback(") .. fname .. ")"
			local fn = A.fns[fname]
			ctx.exp = { [fname] = { min = 1, max = 1, values = { [K(A.model.value)] = true } } } -- core/07:276, :288
			if fname == "cX" then
				ctx.exp.cB = { min = 1, max = 1, values = { [K(A.model.value)] = true } }
				A.model.S.cB = true
			elseif fname == "cU" then
				A.model.S.cA = nil; A.model.W.cA = nil
			end
			if weak then A.model.W[fname] = true else A.model.S[fname] = true end
			if weak then A.ref:WeakCallback(fn) else A.ref:Callback(fn) end
		end
	end
	for _, n in { "cA", "cB", "cW" } do
		op("Callback " .. n, 2, nil, reg(n, false))
		op("WeakCallback " .. n, 1, nil, reg(n, true))
	end
	op("Callback cX", 1, function() return not A.model.armed end, reg("cX", false))
	op("Callback cU", 1, function() return not A.model.armed end, reg("cU", false))
	op("Uncallback", 2, nil, function(ctx)
		local names = { "cA", "cB", "cW", "cX", "cU", "cR" }
		local n = names[rnd(1, #names)]
		ctx.label = "Uncallback(" .. n .. ")"
		A.model.S[n] = nil; A.model.W[n] = nil -- core/07:300
		A.ref:Uncallback(A.fns[n])
		if n == "cR" then A.armed = false; A.model.armed = false end
	end)
	op("armReentry", 1, function()
		return not (A.model.S.cX or A.model.W.cX or A.model.S.cU or A.model.W.cU) and not A.model.armed
	end, function(ctx)
		ctx.exp = { cR = { min = 1, max = 1, values = { [K(A.model.value)] = true } } }
		A.model.S.cR = true
		A.ref:Callback(A.fns.cR)
		A.armed = true
		A.model.armed = true
	end)
	op("Wait() in coroutine", 2, nil, function(ctx)
		local kind = rnd(1, 3) == 1 and "rewait" or "once"
		ctx.label = "Wait() " .. kind
		local info = { kind = kind, left = 2, seen = {}, expect = {} }
		local a = A
		local co = coroutine.create(function()
			for _ = 1, (kind == "rewait" and 2 or 1) do
				local r = a.ref:Wait()
				if not rawequal(r, a.ref) then table.insert(info.seen, "WRONG-RETURN") end
				table.insert(info.seen, K(r.Value))
			end
		end)
		info.co = co
		A.model.T[co] = info
		table.insert(A.waiterLog, info)
		coroutine.resume(co)
	end)
	op("Wait(parked thread)", 1, nil, function(ctx)
		local info = { kind = "parked", left = 1, seen = {}, expect = {} }
		local a = A
		local co = coroutine.create(function()
			while true do
				local r = coroutine.yield()
				table.insert(info.seen, if rawequal(r, a.ref) then K(a.ref.Value) else "WRONG-ARG")
			end
		end)
		coroutine.resume(co)
		info.co = co
		A.model.T[co] = info
		table.insert(A.waiterLog, info)
		A.ref:Wait(co)
	end)
	op("Unwrap", 2, nil, function(ctx)
		if A.model.value == nil then ctx.expectErr = { Quad0135 = true } end -- core/07:358-360
		local v = A.ref:Unwrap()
		if not rawequal(v, A.ref.Value) then fail("Unwrap returned something else") end
	end)
	op("place D.Frame{ref}", 4, nil, function(ctx)
		ctx.exp = {}
		if boundAlive(A) then
			ctx.expectErr = { Quad0233 = true } -- core/07:64
			local f = D.Frame { A.ref }
			return
		end
		ctx.placeInto = true
		expectSet(A, ORPHAN, ctx.exp)
		local f = D.Frame { A.ref }
		table.insert(frames, { inst = f, alive = true })
		ctx.newFrame = frames[#frames]
	end)
	op("place D.Frame{ref, ref}", 1, function() return not boundAlive(A) and not A.model.armed end, function(ctx)
		ctx.exp = {}
		ctx.expectErr = { Quad0232 = true } -- core/07:64
		ctx.twice = true
		expectSet(A, ORPHAN, ctx.exp)
		local f = D.Frame { A.ref, A.ref }
	end)
	op("place D.Frame{post, ref, pre}", 1, function() return not boundAlive(A) and not A.model.armed end, function(ctx)
		ctx.exp = {}
		table.clear(orderLog)
		local a = A
		local mark = function(v) if v ~= nil then table.insert(orderLog, "ref") end end
		a.ref:WeakCallback(mark)
		table.clear(orderLog)
		ctx.cleanup = function() a.ref:Uncallback(mark) end
		ctx.mixed = true
		if pre.fired or post.fired then
			ctx.expectErr = { Quad0069 = true } -- errors/02:234-238
			ctx.oneShotErr = true
		end
		local f = D.Frame { post.ref, A.ref, pre.ref }
		table.insert(frames, { inst = f, alive = true })
		ctx.newFrame = frames[#frames]
	end)
	op("dispose frame", 2, function()
		for _, f in frames do if f.alive then return true end end
		return false
	end, function(ctx)
		local live = {}
		for _, f in frames do if f.alive then table.insert(live, f) end end
		local f = live[rnd(1, #live)]
		f.alive = false
		ctx.label = "dispose(frame)"
		q.dispose(f.inst) -- core/10:94-110 ; Value untouched (core/07:92 — UNDECIDED for dispose)
	end)
	op("Destroy frame", 1, function()
		for _, f in frames do if f.alive then return true end end
		return false
	end, function(ctx)
		local live = {}
		for _, f in frames do if f.alive then table.insert(live, f) end end
		local f = live[rnd(1, #live)]
		f.alive = false
		f.inst:Destroy() -- core/07:92
	end)
	op("new PreRef/PostRef", 1, nil, function(ctx)
		pre = { ref = q.PreRef(nil), fired = false, n = 0 }
		post = { ref = q.PostRef(nil), fired = false, n = 0 }
		hookOneShot(pre, "pre"); hookOneShot(post, "post")
	end)
	op("place fired PreRef alone", 1, nil, function(ctx)
		if pre.fired then ctx.expectErr = { Quad0069 = true } end
		ctx.preAlone = true
		local f = D.Frame { pre.ref }
		pre.fired = true
		table.insert(frames, { inst = f, alive = true })
	end)
	op("seat set", 3, nil, function(ctx)
		local choice = rnd(1, 3)
		local target = choice <= 2 and refs[choice] or nil
		if target and seat and seat.holds ~= target and boundAlive(target) then
			return "skip" -- bound elsewhere: covered by the deterministic axis, not the fuzz
		end
		if target and not seat and boundAlive(target) then return "skip" end
		ctx.label = "seat:Set(" .. (target and ("ref" .. target.i) or "None") .. ")"
		ctx.seatExp = {}
		if not seat then
			if VERBOSE then print("SEAT target", target, target and tostring(target.ref), target and q.isRef(target.ref)) end
			local st = q.Source(target and target.ref or None)
			local rec = { inst = nil, alive = true, seat = true }
			if target then
				ctx.seatExp[target] = {}
			end
			-- predict
			local before = {}
			for _, a in refs do before[a] = #a.log end
			ctx.before = before
			if target then expectSet(target, ORPHAN, ctx.seatExp[target]) end
			local f = D.Frame { st }
			rec.inst = f
			seat = { st = st, frame = rec, holds = target }
			if target then
				target.model.bound = rec
				if target.model.value == ORPHAN then target.model.value = f end
				if ctx.reentryWaiters then for _, w in ctx.reentryWaiters do if w.v == ORPHAN then w.v = f end end end
			end
			return
		end
		if seat.holds == target then
			ctx.seatSame = true
			seat.st:Set(target and target.ref or None)
			return
		end
		local before = {}
		for _, a in refs do before[a] = #a.log end
		ctx.before = before
		if not seat.frame.alive then
			-- seat frame destroyed: UNDECIDED what the State seat does now; record only
			ctx.seatDead = true
			seat.st:Set(target and target.ref or None)
			seat.holds = target
			return
		end
		local old = seat.holds
		if old then
			ctx.seatExp[old] = ctx.seatExp[old] or {}
			old.model.bound = nil
			expectSet(old, nil, ctx.seatExp[old]) -- core/07:91 retract -> :Set(nil)
		end
		if target then
			ctx.seatExp[target] = ctx.seatExp[target] or {}
			expectSet(target, seat.frame.inst, ctx.seatExp[target])
			target.model.bound = seat.frame
		end
		seat.holds = target
		seat.st:Set(target and target.ref or None)
	end)
	op("seat frame Destroy", 1, function() return seat ~= nil and seat.frame.alive end, function(ctx)
		seat.frame.alive = false
		seat.frame.inst:Destroy()
		seat = nil -- a fresh seat next time
	end)

	---------------------------------------------------------------- run
	local nOps = rnd(5, 25)
	for step = 1, nOps do
		if failed then break end
		local total = 0
		local cands = {}
		A = pickActor()
		for _, o in ops do
			if not o.pre or o.pre() then
				total += o.w
				table.insert(cands, o)
			end
		end
		local pickN = rnd(1, total)
		local chosen
		for _, o in cands do
			pickN -= o.w
			if pickN <= 0 then chosen = o break end
		end
		local ctx = { exp = nil }
		local beforeLog = {}
		local beforeRev = {}
		local beforeWaiters = {}
		for _, a in refs do
			beforeLog[a] = #a.log; beforeRev[a] = a.ref.Revision
		end
		local preFiredBefore, postFiredBefore = pre.fired, post.fired
		local preN, postN = pre.n, post.n
		local bindExpect = A.model.bound
		CUR = ctx
		local ok, err = pcall(chosen.run, ctx)
		if ctx.cleanup then ctx.cleanup() end
		local label = ctx.label or chosen.name
		table.insert(trace, `ref{A.i} {label}` .. (ok and "" or (" !" .. errId(err))))
		if not ok and VERBOSE then print("ERR", label, tostring(err)) end
		stats.ops += 1
		stats.opKinds[chosen.name] = (stats.opKinds[chosen.name] or 0) + 1
		if err == "skip" or ok and false then end
		-- error check
		local gotId = nil
		if not ok then gotId = errId(err) end
		if gotId then stats.errIds[gotId] = (stats.errIds[gotId] or 0) + 1 end
		if ctx.expectErr then
			if not gotId or not ctx.expectErr[gotId] then
				fail(`{label}: expected error {next(ctx.expectErr)}, got {tostring(gotId)}`)
			end
		elseif gotId then
			fail(`{label}: unexpected error {gotId}`)
		end
		-- placement bookkeeping (the actual instance comes from the real run)
		if ctx.placeInto and ok then
			local f = ctx.newFrame
			A.model.bound = f
			if A.model.value == ORPHAN then A.model.value = f.inst end
			for _, e in ctx.exp do if e.values[ORPHAN] then e.values[ORPHAN] = nil; e.values[f.inst] = true end end
			for _, a in refs do for _, info in a.waiterLog do
				for i, v in info.expect do if v == ORPHAN then info.expect[i] = f.inst end end
			end end
			if ctx.reentryWaiters then for _, w in ctx.reentryWaiters do if w.v == ORPHAN then w.v = f.inst end end end
		end
		if ctx.twice and gotId == "Quad0232" then
			-- orphan: the first seat bound; record the real orphan
			local rv = A.ref.Value
			local rec = { inst = rv, alive = true, orphan = true }
			table.insert(frames, rec)
			A.model.bound = rec
			A.model.value = rv
			-- deliveries recorded as ORPHAN in ctx.exp: rewrite to actual
			for _, e in ctx.exp do if e.values[ORPHAN] then e.values[ORPHAN] = nil; e.values[rv] = true end end
			for _, info in A.waiterLog do
				for i, v in info.expect do if v == ORPHAN then info.expect[i] = rv end end
			end
		end
		if ctx.mixed then
			if ctx.oneShotErr then
				-- UNDECIDED-ish: which one-shot threw first; pre-pass visits index order: post(1) then pre(3)
				-- ref binding: body loop never ran -> ref untouched (the orphan holds nothing)
				post.fired = true; pre.fired = true
				ctx.exp = {}
				if ctx.newFrame then table.remove(frames) end
			else
				local f = ctx.newFrame
				expectSet(A, f.inst, ctx.exp)
				A.model.bound = f
				pre.fired = true; post.fired = true
				-- order: pre before ref before post (core/07:10, :117, :146)
				local s = table.concat(orderLog, ",")
				if s ~= "pre,ref,post" then fail(`mixed placement order {s}, model pre,ref,post`) end
			end
		end
		if ctx.preAlone then
			if preFiredBefore then
				if pre.n ~= preN then fail("fired PreRef re-fired") end
			else
				if pre.n ~= preN + 1 then fail("PreRef did not fire once") end
			end
		end
		if ctx.seatExp and ctx.before then
			if seat and seat.st and not ctx.seatDead and seat.holds and seat.frame.inst then
				-- first seat creation used ORPHAN for the not-yet-known frame
				for a, exp in ctx.seatExp do
					for _, e in exp do if e.values[ORPHAN] then e.values[ORPHAN] = nil; e.values[seat.frame.inst] = true end end
					for _, info in a.waiterLog do
						for i, v in info.expect do if v == ORPHAN then info.expect[i] = seat.frame.inst end end
					end
				end
			end
			for a, exp in ctx.seatExp do
				checkDeliveries(a, ctx.before[a], exp, label)
			end
		end
		-- deliveries (non-seat ops)
		if ctx.exp and not ctx.seatExp then
			checkDeliveries(A, beforeLog[A], ctx.exp, label, ctx.partial)
		elseif not ctx.exp and not ctx.seatExp and not ctx.seatDead and not ctx.partial then
			for _, a in refs do
				if #a.log ~= beforeLog[a] and not ctx.seatSame then
					fail(`{label}: ref{a.i} got {#a.log - beforeLog[a]} deliveries, model 0`)
				end
			end
		end
		if ctx.seatDead then
			stats.undecided["seat:Set after seat frame Destroy"] = (stats.undecided["seat:Set after seat frame Destroy"] or 0) + 1
			local rv = {}
			for _, a in refs do
				if #a.log ~= beforeLog[a] then table.insert(rv, `ref{a.i}+{#a.log - beforeLog[a]}`) end
				a.model.value = a.ref.Value -- adopt
			end
			seat = nil
		end
		-- value / bound checks
		for _, a in refs do
			if not modelValueEq(a) then
				fail(`{label}: ref{a.i}.Value {tostring(a.ref.Value)} ≠ model {tostring(a.model.value)}`)
			end
			if a.model.value == ORPHAN then a.model.value = a.ref.Value end
			local cb = q.Backend.canBound(a.ref)
			if cb ~= not boundAlive(a) then
				fail(`{label}: ref{a.i} canBound={cb}, model bound={boundAlive(a)}`)
			end
		end
		-- waiter checks
		local skipInfo = {}
		if ctx.reentryWaiters then
			for _, w in ctx.reentryWaiters do
				skipInfo[w.info] = true
				if #w.info.seen <= w.before then fail(`{label}: reentry waiter ({w.info.kind}) not woken`) end
				for i = w.before + 1, #w.info.seen do
					local sv = w.info.seen[i]
					if not (rawequal(sv, w.v) or rawequal(sv, REENTRY)) then fail(`{label}: reentry waiter saw {tostring(sv)}`) end
				end
				w.info.expect = table.clone(w.info.seen)
			end
		end
		for _, a in refs do
			for _, info in a.waiterLog do
				if skipInfo[info] then continue end
				if ctx.partial then info.expect = table.clone(info.seen); continue end
				if #info.seen > #info.expect then fail(`{label}: waiter ({info.kind}) woke {#info.seen}x, model {#info.expect}`) end
				for i, v in info.seen do
					local e = info.expect[i]
					if not rawequal(v, e) then
						fail(`{label}: waiter ({info.kind}) #{i} saw {tostring(v)}, model {tostring(e)}`)
					end
				end
				if ctx.partial then info.expect = table.clone(info.seen) end
			end
		end
		-- adopt the real waiter set after partial / reentrant ops (UNDECIDED which woke)
		for _, a in refs do
			if ctx.partial or (ctx.reentryActors and ctx.reentryActors[a]) then
				local T = {}
				for k in a.ref.Callbacks do
					if type(k) == "thread" then
						for _, info in a.waiterLog do
							if info.co == k then T[k] = info; info.left = (info.kind == "rewait") and (2 - #info.seen) or 1 end
						end
					end
				end
				a.model.T = T
				if ctx.partial then -- cX/cU may or may not have run: adopt the real registration sets
					local S, W = {}, {}
					for name, fn in a.fns do
						if a.ref.Callbacks[fn] then S[name] = true end
						if a.ref.WeakCallbacks[fn] then W[name] = true end
					end
					a.model.S, a.model.W = S, W
				end
			end
		end
	end
	stats.seeds += 1
	if failed then
		stats.diffs += 1
		table.insert(diffs, { seed = seed, msg = failed, trace = trace })
	elseif VERBOSE then
		print(seed, table.concat(trace, " ; "))
	end
end

for seed = FIRST, FIRST + COUNT - 1 do
	local ok, e = pcall(runSeed, seed)
	if not ok then
		stats.diffs += 1
		table.insert(diffs, { seed = seed, msg = "HARNESS: " .. tostring(e), trace = {} })
	end
end
print(`seeds {stats.seeds}  ops {stats.ops}  diffs {stats.diffs}`)
local ks = {}
for k, v in stats.opKinds do table.insert(ks, k .. "=" .. v) end
table.sort(ks)
print("op kinds: " .. table.concat(ks, ", "))
local es = {}
for k, v in stats.errIds do table.insert(es, k .. "=" .. v) end
table.sort(es)
print("errors seen: " .. table.concat(es, ", "))
for k, v in stats.undecided do print("undecided cell hit: " .. k .. " x" .. v) end
local shown = 0
local byMsg = {}
for _, d in diffs do
	local key = d.msg:gsub("0x%x+", ""):gsub("%d+x", "Nx")
	if not byMsg[key] then
		byMsg[key] = true
		shown += 1
		if shown <= 12 then
			print(`DIFF seed {d.seed}: {d.msg}`)
			print("   trace: " .. table.concat(d.trace, " ; "))
		end
	end
end
