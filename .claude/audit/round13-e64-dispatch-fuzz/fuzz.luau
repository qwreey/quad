--!nocheck
-- E64 differential fuzzer: q.Dispatch handler contract (docs/reference/extend/02 + Dispatch/init.luau)
-- vs an independent reference model. usage (repo root):
--   luau .claude/audit/round13-e64-dispatch-fuzz/fuzz.luau -a <mode base|prov> <seeds> <start> [v] [mutant]
-- Model rules (each cites the doc/code line it encodes):
--  R1 scan order = listHandlers() (priority desc, extend/02:106, :136 "우선순위 순으로 첫 핸들러")
--  R2 bucket = declared keyType filter; nil keyType in every bucket; non-string/number keys only nil-declared (extend/02:41,45; quadnomicon/08 §2.1)
--  R3 first isHandlable==true wins; an isHandlable that raises propagates as-is (no pcall anywhere)
--  R4 no match -> Quad0076 (+ nil hint when v==nil, extend/02:161-165)
--  R5 same handler at slot -> old retractor(v,false), then process(index); deeper layers untouched (extend/02:66)
--  R6 different/empty slot -> retract index..tail tail-first with (nil,true), then process (extend/02:66,183)
--  R7 retractFrom(inst,k,i): i..tail tail-first (nil,true); i>len no-op (extend/02:183)
--  R8 process throw -> slot keeps no-op marker: next retract/replace of that slot calls nothing (extend/02:381)
--  R9 index > #chain+1 -> Quad0075; index not positive int -> Quad0073 (init.luau:328-333, extend/02:173)
--  R10 wrapper delegation = process(inst,k,inner,index+1) (extend/02:43)
--  R11 State at slot: StoreBind(HIGH) subscribes; every Set re-emits process(index+1, value) even if same (H-68); retract stops it
--  R12 None -> NoneHandler(HIGH) recurses nil at index+1 (None.luau); nil at number key -> NilHandler(HIGH)
--  R13 retractor nil return -> Quad0077 (extend/02:167)
--  R14 drive = process(k,v,1) for each k in the table's own iteration order (extend/02:201)
--  R15 prov: Property(NORMAL, reflected string keys, any value incl. nil), Event(NORMAL-1, event keys; nil ok, non-function Quad0218)
local E = require("./env")
local RNG = require("./rng")
local args = { ... }
local MODE = args[1] or "base"
local SEEDS = tonumber(args[2]) or 200
local START = tonumber(args[3]) or 1
local VERBOSE = args[4] == "v"
local MUT = args[5] -- model mutants: "stable" (tie=registration order), "noA" (always B), "retractHead" (head-first), "noNoop" (throw leaves nothing)

local HIGH, NORMAL, LOW, FALLBACK = 1000, 0, -1000, -1000000
local PRIOS = { HIGH + 1, HIGH, HIGH, NORMAL + 1, NORMAL, NORMAL, NORMAL - 1, LOW, FALLBACK, FALLBACK - 1, 500, 7, 7 }

local stats = { seeds = 0, ops = 0, diffs = 0, userP = 0, userR = 0, errs = {}, ties = 0, tieDecided = 0, poisoned = 0,
	opsBy = {}, sortBad = 0, aKeep = 0, stale = 0 }
local samples = {}
local function bump(t, k) t[k] = (t[k] or 0) + 1 end

-- ── values ─────────────────────────────────────────────────────
local None -- set per q (all q share one None? checked per seed)
local curSrcRec = {} -- per seed: Source -> record (vdesc names States "St<n>")
local function vdesc(v)
	if v == nil then return "nil" end
	if type(v) == "table" and curSrcRec[v] then return "St" .. curSrcRec[v].n end
	if v == None then return "None" end
	local t = type(v)
	if t == "number" then return "n" .. v end
	if t == "string" then return "s" .. v end
	if t == "boolean" then return tostring(v) end
	if t == "table" then
		if v.__st then return "St" .. v.__st end
		if v.kind == "W" then return "W(" .. vdesc(v.inner) .. ")" end
		return v.kind .. (v.tag or "")
	end
	if t == "function" then return "fn" end
	return "?"
end

local function runSeed(seed)
	local rng = RNG.new(seed)
	local q = if MODE == "prov" then E.newProv() else E.newBase()
	None = q.None
	local D = q.Dispatch
	local log = {} -- implementation log
	local exp = {} -- model log
	local ridN = 0
	local ridM = 0

	-- value pool
	local T1, T2 = { kind = "T", tag = 1 }, { kind = "T", tag = 2 }
	local BOOM, EVIL = { kind = "B" }, { kind = "E" }
	local FN = function() end
	local plain = { 1, 2, 3, "a", "b", true, T1, T2, BOOM, EVIL }
	local function W(inner) return { kind = "W", inner = inner } end
	local wraps = { W(1), W("a"), W(T1), W(W(2)), W(W(T2)), W(BOOM), W(None), W(W(BOOM)) }
	for _, w in wraps do table.insert(plain, w) end
	if MODE == "prov" then table.insert(plain, FN) end
	local stateSafe = { 1, 2, 3, "a", true, T1, T2, W(1), W("a"), W(T1), W(W(2)), None } -- values never meant to throw
	local stN = 0
	local srcRec = {} -- src -> { value, st = modelStateRecord }
	curSrcRec = srcRec

	-- ── handlers ─────────────────────────────────────────────
	local specs = {}
	local nH = rng:NextInteger(2, 8)
	local function pick(t) return t[rng:NextInteger(1, #t)] end
	local PRED_KINDS = { "type:number", "type:string", "type:boolean", "type:table", "kind:W", "kind:T", "kind:B", "tag:1", "all", "nil", "None", "keyname", "fn", "notnil" }
	for i = 1, nH do
		local s = { id = i, prio = pick(PRIOS), keyType = pick({ false, false, "string", "number" }) or nil,
			pred = pick(PRED_KINDS), pred2 = if rng:NextInteger(1, 3) == 1 then pick(PRED_KINDS) else nil,
			keyGuard = pick({ false, false, "string", "number" }) or nil,
			wrapper = rng:NextInteger(1, 2) == 1, throwBefore = rng:NextInteger(1, 2) == 1,
			evil = rng:NextInteger(1, 3) == 1, keynames = { Foo = rng:NextInteger(1, 2) == 1, Size = rng:NextInteger(1, 2) == 1, [2] = true } }
		specs[i] = s
	end
	local function vmatch(p, k, v, s)
		if p == "type:number" then return type(v) == "number"
		elseif p == "type:string" then return type(v) == "string"
		elseif p == "type:boolean" then return type(v) == "boolean"
		elseif p == "type:table" then return type(v) == "table" and v ~= None
		elseif p == "kind:W" then return type(v) == "table" and v.kind == "W"
		elseif p == "kind:T" then return type(v) == "table" and v.kind == "T"
		elseif p == "kind:B" then return type(v) == "table" and v.kind == "B"
		elseif p == "tag:1" then return type(v) == "table" and v.tag == 1
		elseif p == "all" then return true
		elseif p == "nil" then return v == nil
		elseif p == "None" then return v == None
		elseif p == "keyname" then return s.keynames[k] == true
		elseif p == "fn" then return type(v) == "function"
		elseif p == "notnil" then return v ~= nil
		end
		return false
	end
	local function upred(s, k, v) -- the user predicate (pure)
		if s.keyGuard and type(k) ~= s.keyGuard then return false end
		if v ~= nil and v ~= None and type(v) == "table" and v.__st then
			-- States: only "type:table"/"all"/"notnil" user predicates see them as tables
			return s.pred == "type:table" or s.pred == "all" or s.pred == "notnil"
		end
		local ok = vmatch(s.pred, k, v, s)
		if s.pred2 then ok = ok or vmatch(s.pred2, k, v, s) end
		return ok
	end
	local function uthrowsIsH(s, v) return s.evil and v == EVIL end
	local function uthrowsProc(v) return v == BOOM end
	local function unwrap(s, v) return s.wrapper and type(v) == "table" and v.kind == "W" end

	-- register (real)
	local preUser = D.listHandlers()
	local handlers = {}
	for i, s in specs do
		local h = { name = "h" .. i, priority = s.prio, keyType = s.keyType }
		h.isHandlable = function(inst, k, v)
			if uthrowsIsH(s, v) then error("UEVIL:h" .. i, 0) end
			return upred(s, k, v)
		end
		h.process = function(inst, k, v, index)
			table.insert(log, `P h{i} {tostring(k)} {vdesc(v)} {index}`)
			if type(k) == "number" and not unwrap(s, v) then q.Bookkeeping.setEmpty(inst, k) end
			if s.throwBefore and uthrowsProc(v) then error("UBOOM:h" .. i, 0) end
			if unwrap(s, v) then D.process(inst, k, v.inner, index + 1) end
			if uthrowsProc(v) then error("UBOOM:h" .. i, 0) end
			ridN += 1
			local rid = ridN
			return function(nextValue, retracting)
				table.insert(log, `R h{i}#{rid} {tostring(k)} {vdesc(nextValue)} {tostring(retracting)}`)
			end
		end
		handlers[i] = h
		D.addHandler(h)
		if rng:NextInteger(1, 6) == 1 then D.addHandler(h) end -- identity dedup (init.luau:405-409)
	end

	-- model scan order: listHandlers (R1) — verify sortedness separately
	local order = D.listHandlers()
	for j = 2, #order do if order[j - 1].priority < order[j].priority then stats.sortBad += 1 end end
	local specOf = {}
	for i, h in handlers do specOf[h] = specs[i] end
	if MUT == "stable" then
		-- mutant: "ties resolve in registration order" (a rule the docs explicitly do NOT promise)
		local reg = {}
		for i, h in preUser do reg[h] = i end
		for i, h in handlers do reg[h] = 1000 + i end
		order = table.clone(order)
		table.sort(order, function(a, b)
			if a.priority ~= b.priority then return a.priority > b.priority end
			return reg[a] < reg[b]
		end)
	end
	-- tie accounting
	for a = 1, #order do for b = a + 1, #order do
		local sa, sb = specOf[order[a]], specOf[order[b]]
		if (sa or sb) and order[a].priority == order[b].priority then stats.ties += 1 end
	end end

	-- built-in model predicates
	local classProps = { Size = true, Visible = true, ZIndex = true, Name = true, Position = true }
	local classEvents = { MouseEnter = true, MouseLeave = true }
	local function builtinMatch(name, k, v)
		if name == "NoneHandler" then return v == None
		elseif name == "NilHandler" then return type(k) == "number" and v == nil
		elseif name == "StoreBind" then return type(v) == "table" and v.__st ~= nil
		elseif name == "Property" then return MODE == "prov" and type(k) == "string" and k ~= "Parent" and classProps[k] == true
		elseif name == "Event" then return MODE == "prov" and type(k) == "string" and classEvents[k] == true
		end
		return false
	end

	-- ── model ───────────────────────────────────────────────
	local chains = {} -- inst -> k -> { {h=handlerTable, rid=number|"NOOP"|"VOID", st=?} }
	local poisoned = {} -- inst -> k -> true
	local propVal = {} -- inst -> k -> last Property write
	local function chainOf(inst, k)
		local c = chains[inst]
		if not c then c = {}; chains[inst] = c end
		local l = c[k]
		if not l then l = {}; c[k] = l end
		return l
	end
	local function mscan(k, v)
		local kt = type(k)
		for _, h in order do
			local okBucket = h.keyType == nil or h.keyType == kt
			if okBucket then
				local s = specOf[h]
				if s then
					if uthrowsIsH(s, v) then return nil, "UEVIL:h" .. s.id end
					if upred(s, k, v) then return h end
				elseif builtinMatch(h.name, k, v) then
					return h
				end
			end
		end
		return nil, "Quad0076"
	end
	local mprocess
	local function callRetractor(slot, k, nextValue, retracting)
		local s = specOf[slot.h]
		if slot.rid == "NOOP" then return end
		if s then
			table.insert(exp, `R h{s.id}#{slot.rid} {tostring(k)} {vdesc(nextValue)} {tostring(retracting)}`)
		elseif slot.h.name == "StoreBind" then
			slot.st.alive = false
		end
	end
	local function mretractRange(inst, k, index)
		local l = chainOf(inst, k)
		if MUT == "retractHead" then
			for i = index, #l do callRetractor(l[i], k, nil, true) end
			for i = #l, index, -1 do l[i] = nil end
			return
		end
		for i = #l, index, -1 do
			callRetractor(l[i], k, nil, true)
			l[i] = nil
		end
	end
	-- returns error id or nil
	local function runProc(inst, k, v, index, h)
		local s = specOf[h]
		if s then
			table.insert(exp, `P h{s.id} {tostring(k)} {vdesc(v)} {index}`)
			stats.userP += 1
			if s.throwBefore and uthrowsProc(v) then return "UBOOM:h" .. s.id end
			if unwrap(s, v) then
				local e = mprocess(inst, k, v.inner, index + 1)
				if e then return e end
			end
			if uthrowsProc(v) then return "UBOOM:h" .. s.id end
			ridM += 1 -- model's own counter: impl and model create retractors in the same order iff equivalent
			return nil, { rid = ridM }
		end
		local n = h.name
		if n == "NoneHandler" then
			local e = mprocess(inst, k, nil, index + 1)
			if e then return e end
			return nil, { rid = "VOID" }
		elseif n == "NilHandler" then
			return nil, { rid = "VOID" }
		elseif n == "StoreBind" then
			local rec = srcRec[v]
			local st = { alive = false, inst = inst, k = k, index = index, src = v }
			local e = mprocess(inst, k, rec.value, index + 1)
			if e then return e end
			st.alive = true
			rec.st = st
			return nil, { rid = "SB", st = st }
		elseif n == "Property" then
			propVal[inst] = propVal[inst] or {}
			propVal[inst][k] = { v = v }
			return nil, { rid = "VOID" }
		elseif n == "Event" then
			if v == nil then return nil, { rid = "VOID" } end
			if type(v) ~= "function" then return "Quad0218" end
			return nil, { rid = "VOID" }
		end
		return "MODEL:unknown builtin " .. tostring(n)
	end
	function mprocess(inst, k, v, index)
		local l = chainOf(inst, k)
		if index > #l + 1 then return "Quad0075" end
		local h, err = mscan(k, v)
		if not h then return err end
		local slot = l[index]
		if slot and slot.h == h and MUT ~= "noA" then
			stats.aKeep += 1
			callRetractor(slot, k, v, false)
			slot.rid = "NOOP"; slot.st = nil
			local e, r = runProc(inst, k, v, index, h)
			if e then return e end
			slot.rid = r.rid; slot.st = r.st
		else
			mretractRange(inst, k, index)
			local newSlot = { h = h, rid = "NOOP" }
			l[index] = newSlot
			local e, r = runProc(inst, k, v, index, h)
			if e then
				if MUT == "noNoop" then l[index] = nil end
				return e
			end
			newSlot.rid = r.rid; newSlot.st = r.st
		end
		return nil
	end
	-- rid mapping: the model tracks rids by replaying the implementation's counter order — simpler: rewrite
	-- rid in both logs to per-handler ordinal of creation. (normalize below)

	-- ── instances/keys ─────────────────────────────────────
	local insts = {}
	for i = 1, 2 do
		insts[i] = if MODE == "prov" then q.Declaration.Frame {} else E.mock.Instance.new("Frame")
		-- positions 1..4 pre-registered empty (leaf contract, extend/02:220) so a direct process at k=3
		-- does not trip recompute's hole check (Quad0023) — that is bookkeeping, not dispatch, under test
		for p = 1, 4 do q.Bookkeeping.setEmpty(insts[i], p) end
	end
	local KEYS = if MODE == "prov" then { "Foo", "Bar", "Size", "Visible", "MouseEnter", 1, 2, 3, 4 } else { "Foo", "Bar", "Baz", "Size", 1, 2, 3, 4, true }
	local function isPoisoned(inst, k) return poisoned[inst] and poisoned[inst][k] end
	local function poison(inst, k)
		poisoned[inst] = poisoned[inst] or {}
		if not poisoned[inst][k] then stats.poisoned += 1 end
		poisoned[inst][k] = true
	end

	local function newState(v)
		stN += 1
		local src = q.Source(v)
		src.__st = nil
		-- tag for vdesc: keep a side table (Source is a plain table with metatable)
		local wrapper = src
		srcRec[src] = { value = v, n = stN }
		return src
	end
	-- States must satisfy the model's "__st" test: use srcRec membership instead
	local oldUpred = upred
	upred = function(s, k, v)
		if type(v) == "table" and srcRec[v] then
			if s.keyGuard and type(k) ~= s.keyGuard then return false end
			return s.pred == "type:table" or s.pred == "all" or s.pred == "notnil"
		end
		return oldUpred(s, k, v)
	end
	local oldBM = builtinMatch
	builtinMatch = function(name, k, v)
		if name == "StoreBind" then return type(v) == "table" and srcRec[v] ~= nil end
		return oldBM(name, k, v)
	end

	local nOps = rng:NextInteger(20, 60)
	local function norm(lst)
		-- rewrite "#<rid>" into per-seed creation ordinal per handler so model/impl rids compare
		return lst
	end
	for step = 1, nOps do
		stats.ops += 1
		local inst = insts[rng:NextInteger(1, #insts)]
		local r = rng:NextInteger(1, 100)
		local opName, eImpl, eModel
		local mark = #log
		local markE = #exp
		if r <= 45 then
			opName = "process"
			local k = pick(KEYS)
			if isPoisoned(inst, k) then continue end
			local v
			local vr = rng:NextInteger(1, 20)
			if vr <= 13 then v = pick(plain)
			elseif vr <= 15 then v = None
			elseif vr <= 16 then v = nil
			else v = newState(pick(stateSafe)) end
			local l = chainOf(inst, k)
			local index = 1
			local ir = rng:NextInteger(1, 20)
			if ir == 1 then index = #l + 1 elseif ir == 2 then index = #l + 2 elseif ir == 3 and #l > 0 then index = rng:NextInteger(1, #l) end
			local ok, e = pcall(D.process, inst, k, v, index)
			eImpl = if ok then nil else E.id(e)
			eModel = mprocess(inst, k, v, index)
			-- R11b: a throw inside the StoreBind registration fire leaves the observer unbound (never fires again,
			-- axis-g g1/g2); a throw inside a later emission leaves it alive (g3) — both modelled, no poisoning
		elseif r <= 65 then
			opName = "retractFrom"
			local k = pick(KEYS)
			if isPoisoned(inst, k) then continue end
			local l = chainOf(inst, k)
			local index = if rng:NextInteger(1, 3) == 1 then rng:NextInteger(1, #l + 2) else 1
			local ok, e = pcall(D.retractFrom, inst, k, index)
			eImpl = if ok then nil else E.id(e)
			mretractRange(inst, k, index)
		elseif r <= 85 then
			opName = "stateSet"
			local live = {}
			for src, rec in srcRec do
				if rec.st and rec.st.alive and not isPoisoned(rec.st.inst, rec.st.k) then table.insert(live, src) end
			end
			table.sort(live, function(a, b) return srcRec[a].n < srcRec[b].n end)
			if #live == 0 then continue end
			local src = pick(live)
			local rec = srcRec[src]
			local nv = pick(stateSafe)
			local ok, e = pcall(src.Set, src, nv)
			eImpl = if ok then nil else E.id(e)
			rec.value = nv
			local st = rec.st
			eModel = mprocess(st.inst, st.k, nv, st.index + 1)
			-- also dead (retracted) records must not fire: covered by log equality
		else
			opName = "drive"
			local props = {}
			local n = rng:NextInteger(1, 4)
			for _ = 1, n do
				local k = pick(KEYS)
				if type(k) == "number" then k = rng:NextInteger(1, 3) end
				local v = if rng:NextInteger(1, 4) == 1 then newState(pick(stateSafe)) else pick(plain)
				props[k] = v
			end
			-- array part must be hole-free for drive's contract (sparse holes UB — init.luau:487)
			if props[3] and not props[2] then props[3] = nil end
			if props[2] and not props[1] then props[2] = nil end
			local bad = false
			for k in props do if isPoisoned(inst, k) then bad = true end end
			if bad then continue end
			local ok, e = pcall(D.drive, inst, props)
			eImpl = if ok then nil else E.id(e)
			for k, v in props do
				local em = mprocess(inst, k, v, 1)
				if em then
					eModel = em
					break
				end
			end
		end
		bump(stats.opsBy, opName)
		if eModel then bump(stats.errs, eModel) end
		-- compare step
		local implStep = table.concat(log, "\n", mark + 1)
		local expStep = table.concat(exp, "\n", markE + 1)
		-- rid normalization: model doesn't know impl rid numbers -> compare with rids stripped, then check rid consistency below
		local function strip(sx) return sx end -- rids compared exactly (separate counters, R5/R6 retractor identity)
		if eImpl ~= eModel or strip(implStep) ~= strip(expStep) then
			stats.diffs += 1
			if #samples < 25 then
				table.insert(samples, `[{MODE}] seed {seed} step {step} op {opName}: impl err {tostring(eImpl)} model err {tostring(eModel)}\n  impl:\n    {implStep:gsub("\n", "\n    ")}\n  model:\n    {expStep:gsub("\n", "\n    ")}`)
			end
			return -- one diff per seed
		end
		-- sync logs (keep impl's rid strings for the model retractor calls: rid consistency check)
	end
	-- final flush: retract everything, compare
	local mark = #log
	for inst, c in chains do
		local ks = {}
		for k in c do table.insert(ks, k) end
		table.sort(ks, function(a, b) return tostring(a) < tostring(b) end)
		for _, k in ks do
			if not isPoisoned(inst, k) then
				local markE = #exp
				local m2 = #log
				D.retractFrom(inst, k, 1)
				mretractRange(inst, k, 1)
				local a = table.concat(log, "\n", m2 + 1)
				local b = table.concat(exp, "\n", markE + 1)
				if a ~= b then
					stats.diffs += 1
					if #samples < 25 then table.insert(samples, `[{MODE}] seed {seed} flush {tostring(k)}:\n impl {a}\n model {b}`) end
					return
				end
			end
		end
	end
	-- Property values (prov): last model write equals the instance's property
	if MODE == "prov" then
		for inst, m in propVal do
			for k, rec in m do
				if not isPoisoned(inst, k) and inst[k] ~= rec.v then
					stats.diffs += 1
					if #samples < 25 then table.insert(samples, `[{MODE}] seed {seed} Property {k}: inst {vdesc(inst[k])} model {vdesc(rec.v)}`) end
					return
				end
			end
		end
	end
end

local t0 = os.clock()
for seed = START, START + SEEDS - 1 do
	stats.seeds += 1
	local ok, e = pcall(runSeed, seed)
	if not ok then
		stats.diffs += 1
		if #samples < 25 then table.insert(samples, `[{MODE}] seed {seed} HARNESS ERROR {e}`) end
	end
end
print(`mode={MODE} mutant={tostring(MUT)} seeds={stats.seeds} ops={stats.ops} diffs={stats.diffs} userProcess={stats.userP} ties(user-involved pairs)={stats.ties} sameHandlerA={stats.aKeep} poisonedKeys={stats.poisoned} listHandlersUnsorted={stats.sortBad} time={string.format("%.1f", os.clock() - t0)}s`)
local ks = {}
for k, n in stats.opsBy do table.insert(ks, `{k}={n}`) end
table.sort(ks)
print("ops: " .. table.concat(ks, " "))
ks = {}
for k, n in stats.errs do table.insert(ks, `{k}={n}`) end
table.sort(ks)
print("expected errors: " .. table.concat(ks, " "))
for _, s in samples do print(s) end
