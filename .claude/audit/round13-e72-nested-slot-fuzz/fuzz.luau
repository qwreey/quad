--!nocheck
-- E72 — nested-Slot tree differential fuzzer: Slot as bookkeeping ownerKey (ensureBase / Slot Offset base /
-- `Length:Set(sum)`), 2~4 deep trees under a physical host, vs a pure-Lua tree model.
-- usage (repo root, after ./scripts/relink.sh):
--   mise exec -- luau .claude/audit/round13-e72-nested-slot-fuzz/fuzz.luau -a <seeds> <start> [mutant] [flags]
-- flags (comma list): reent (an Offset observer on a watched Slot appends a leaf to a seat-1 sink Slot, once per step)
-- Model rules (doc line = where the rule comes from):
--  T1 physical order under host = seats in key order, each Slot flattened depth-first (core/06 132 "앞에 놓인 숫자 키
--     자리들의 길이 합"; slot-plan "Slot-in-Slot 중첩")
--  T2 mounted Slot: Length = its physical leaf count (core/06 102), Offset = leaves before it under host (core/06 132)
--  T3 unmounted Slot: Length/Offset frozen at the last mounted value, 0 if never mounted (core/06 104)
--  T4 Remove/Replace/Clear destroy; Extract/ExtractAll/Splice-removed come back alive and unowned (core/06 CRUD 표)
--  T5 :List (owned): hidden key -> Detach (held, unmounted), KeyGone -> Detach|nil per list, Prev re-attaches
--     (core/06 376, 497~509); data Set while unmounted is caught up at remount (core/06 481 (1))
--  T6 ownership: held (Slot element, seat, detached) -> Add 0172 / dispose 0179; same Slot 0170; cycle 0173;
--     destroyed Slot CRUD 0165; :List CRUD 0166; index 0168/0236; destroyed leaf 0241 / Slot 0242; seat swap to a
--     held Slot 0160 (seat left empty, old released — E1/E2 recovery shape)
--  T7 leaves: mounted -> Parent == host; alive unmounted -> Parent nil; destroyed -> isDestroyed, isClaimed false
--  T8 Get(i) returns the model element order for every live Slot (list: mounted order)
local E = require("./env")
local RNG = require("./rng")
local args = { ... }
local SEEDS, START, MUT = tonumber(args[1]) or 100, tonumber(args[2]) or 1, args[3]
if MUT == "none" or MUT == "" then MUT = nil end
local FLAGS = {}
for f in string.gmatch(args[4] or "", "[^,]+") do FLAGS[f] = true end
local STEPS = tonumber(args[5]) or 30
-- mutants (model only): unmountZero (T3 -> 0), detachCounts (detached counted in Length), leafSeatFree (top
-- string seats not counted in offsets), noCatchUp (unmounted data Set ignored at remount), cycleAs0172 (cycle
-- reported 0172), extractDestroys (Extract destroys like Remove)
local I = E.mock.Instance
local catchUpLeft = {}
local prevMountedStep = {}
local stats = { seeds = 0, steps = 0, diffs = 0, diffSeeds = 0, errs = {}, maxDepth = 0, detach = 0, reattach = 0,
	creates = 0, seatSwaps = 0, gc = 0, reentFired = 0, stale = 0, viol = 0, checks = 0, catchUp = 0, disposeOk = 0,
	opCount = {} }
local samples = {}
local q75samples = {}
stats.q75phys = 0
stats.transientFire = {}
stats.catchUpTransient = 0
local function bump(t, k) t[k] = (t[k] or 0) + 1 end

local function runSeed(seed)
	local rng = RNG.new(seed)
	local q, env = E.newBase()
	local host = I.new("Frame"); host.Name = "H"
	local recs, nextId = {}, 0
	local diffsBefore = stats.diffs
	local curOp = "init"
	local function diff(msg)
		stats.diffs += 1
		if #samples < 25 then table.insert(samples, `seed {seed} step {stats.curStep} [{curOp}]: {msg}`) end
	end
	local function newLeafRec(obj)
		nextId += 1
		local r = { k = "leaf", id = nextId, obj = obj, owner = nil, destroyed = false }
		table.insert(recs, r); return r
	end
	local function mkLeaf()
		local f = I.new("Frame"); f.Name = "f" .. (nextId + 1)
		return newLeafRec(f)
	end
	local function newSlotRec(obj, mode)
		nextId += 1
		local r = { k = "slot", id = nextId, obj = obj, mode = mode, ch = {}, owner = nil, destroyed = false, L = 0, O = 0,
			mounted = false }
		table.insert(recs, r); return r
	end
	-- creation queue filled by :List updateFns (real side), drained by the model's reconcile
	local createdQ = {}
	catchUpLeft = {}
	local function mkList(depthLeft)
		local s = q.Slot()
		local r = newSlotRec(s, "list")
		r.keys, r.hidden, r.el, r.det, r.prevKeys = {}, {}, {}, {}, {}
		r.policy = if rng:NextInteger(1, 2) == 1 then "detach" else "nil"
		r.childKind = if depthLeft > 1 and rng:NextInteger(1, 3) == 1 then "slot" else "leaf"
		r.activated, r.dirty = false, false
		createdQ[r] = {}
		local nk = rng:NextInteger(0, 4)
		for i = 1, nk do table.insert(r.keys, "k" .. i) end
		r.data = q.Source(table.clone(r.keys))
		local hidden = r.hidden
		s:List(r.data, function(ctx)
			if ctx.Item == q.KeyGone then return if r.policy == "detach" then q.Detach else nil end
			if hidden[ctx.Item] then return q.Detach end
			if ctx.Prev ~= nil then return ctx.Prev end
			local obj
			if r.childKind == "slot" then
				local lf = I.new("Frame"); lf.Name = "lf"
				obj = q.Slot({ lf })
				table.insert(createdQ[r], { key = ctx.Item, obj = obj, leaf = lf })
			else
				obj = I.new("Frame"); obj.Name = "lk"
				table.insert(createdQ[r], { key = ctx.Item, obj = obj })
			end
			return obj
		end, function(x) return x end)
		return r
	end
	local function mkTree(depthLeft)
		if depthLeft >= 2 and rng:NextInteger(1, 4) == 1 then return mkList(depthLeft) end
		local n = rng:NextInteger(0, 3)
		local kids = {}
		for _ = 1, n do
			if depthLeft > 1 and rng:NextInteger(1, 3) == 1 then table.insert(kids, mkTree(depthLeft - 1))
			else table.insert(kids, mkLeaf()) end
		end
		local objs = {}
		for i, c in ipairs(kids) do objs[i] = c.obj end
		local s = q.Slot(objs)
		local r = newSlotRec(s, "manual")
		for _, c in ipairs(kids) do c.owner = r; table.insert(r.ch, c) end
		return r
	end

	-- ── seats ──
	local MAXD = rng:NextInteger(2, 4)
	local seats = {}
	local props = {}
	local sink
	if FLAGS.reent then
		sink = newSlotRec(q.Slot(), "manual"); sink.isSink = true
		table.insert(seats, { kind = "static", cur = sink }); sink.owner = "seat"
	end
	for _ = 1, rng:NextInteger(1, 3) do
		local roll = rng:NextInteger(1, 5)
		if roll == 1 then
			local name = "s" .. (#seats + 1)
			table.insert(seats, { kind = "leaf", name = name })
		elseif roll == 2 then
			local t = mkTree(MAXD)
			t.owner = "seat"
			table.insert(seats, { kind = "static", cur = t })
		else
			local t = if rng:NextInteger(1, 5) == 1 then nil else mkTree(MAXD)
			if t then t.owner = "seat" end
			table.insert(seats, { kind = "state", cur = t, src = q.Source(if t then t.obj else nil) })
		end
	end
	for i, st in ipairs(seats) do
		props[i] = if st.kind == "leaf" then st.name elseif st.kind == "static" then st.cur.obj else st.src
	end

	-- ── model helpers ──
	local function flatten(r, out)
		for _, c in ipairs(r.ch) do
			if c.k == "leaf" then table.insert(out, c.obj) else flatten(c, out) end
		end
		if MUT == "detachCounts" and r.mode == "list" then
			for _, c in pairs(r.det) do if c.k == "leaf" then table.insert(out, c.obj) end end
		end
		return out
	end
	local function expectedHost()
		local out = {}
		for _, st in ipairs(seats) do
			if st.kind == "leaf" then
				if MUT ~= "leafSeatFree" then table.insert(out, env.seatLeaf[st.name]) end
			elseif st.cur then flatten(st.cur, out) end
		end
		return out
	end
	local function isAncOrSelf(cand, target) -- cand is target or an owner-chain ancestor of target
		local c = target
		while type(c) == "table" do
			if c == cand then return true end
			c = c.owner
		end
		return false
	end
	local function destroyRec(r)
		if r.destroyed then return end
		r.destroyed = true
		if r.k == "slot" then
			for _, c in ipairs(r.ch) do destroyRec(c) end
			if r.mode == "list" then for _, c in pairs(r.det) do destroyRec(c) end end
		end
	end
	local function popCreate(L, key)
		local qd = createdQ[L]
		local e = table.remove(qd, 1)
		if e == nil then diff(`list {L.id}: model expected a creation for {key}, none happened`); return nil end
		if e.key ~= key then diff(`list {L.id}: creation order {e.key} vs expected {key}`) end
		stats.creates += 1
		if FLAGS.trace then print(`  create for list{L.id}[{key}] at step {stats.curStep} (next id {nextId + 1})`) end
		if e.leaf then
			local s = newSlotRec(e.obj, "manual")
			local lr = newLeafRec(e.leaf); lr.owner = s; table.insert(s.ch, lr)
			return s
		end
		return newLeafRec(e.obj)
	end
	local function reconcile(L)
		local newCh, seen = {}, {}
		for _, key in ipairs(L.keys) do
			seen[key] = true
			L.prevKeys[key] = true
			local prev = L.el[key] or L.det[key]
			if L.hidden[key] then
				if L.el[key] then L.det[key] = L.el[key]; L.el[key] = nil; stats.detach += 1 end
			elseif prev then
				if L.det[key] then L.det[key] = nil; L.el[key] = prev; stats.reattach += 1 end
				table.insert(newCh, prev)
			else
				local e = popCreate(L, key)
				if e then e.owner = L; L.el[key] = e; table.insert(newCh, e) end
			end
		end
		for key in pairs(L.prevKeys) do
			if not seen[key] then
				if L.policy == "detach" then
					if L.el[key] then L.det[key] = L.el[key]; L.el[key] = nil; stats.detach += 1 end
				else
					if L.el[key] then destroyRec(L.el[key]); L.el[key] = nil end
					if L.det[key] then destroyRec(L.det[key]); L.det[key] = nil end
				end
				L.prevKeys[key] = nil
			end
		end
		L.ch = newCh
	end
	-- mounted set + list activation/catch-up fixpoint (T3, T5)
	local function markMounted()
		local m = {}
		local function walk(r) m[r] = true; for _, c in ipairs(r.ch) do if c.k == "slot" then walk(c) end end end
		for _, st in ipairs(seats) do if st.kind ~= "leaf" and st.cur then walk(st.cur) end end
		return m
	end
	-- Real order (Slot/Tree.luau materializeSlotTree + List.luau _activateList): a remount first re-materializes the
	-- OLD elements depth-first — a never-activated nested :List reconciles inside that walk, an activated dirty one
	-- catches up when its observer is re-bound at the end of its own materialize — and only then does the outer
	-- :List's re-bound observer catch up. So: always process the DEEPEST pending list first, recomputing the mounted
	-- set after each. Every Slot seen mounted in any snapshot is "transient" if it ends unmounted (E19 shape).
	local function settleMount(prevMounted)
		for _ = 1, 200 do
			local m = markMounted()
			for r in pairs(m) do catchUpLeft[r] = true end
			local best, bestD = nil, -1
			for _, r in ipairs(recs) do
				if r.k == "slot" and m[r] and not r.destroyed and r.mode == "list" then
					local need = (not r.activated) or (not prevMounted[r] and r.dirty and MUT ~= "noCatchUp")
					if need then
						local d = 0; local c = r; while type(c) == "table" do d += 1; c = c.owner end
						if d > bestD then best, bestD = r, d end
					end
				end
			end
			if not best then return m end
			if not best.activated then best.activated = true; best.dirty = false
			else best.dirty = false; stats.catchUp += 1 end
			reconcile(best)
		end
		return markMounted()
	end

	-- ── mount ──
	local mounted = {}
	local okDrive, errDrive = pcall(q.Dispatch.drive, host, props)
	if not okDrive then diff("drive threw " .. E.id(errDrive)); return end
	mounted = settleMount({})

	-- ── reentrant watcher (flag reent) ──
	local watch, armed = nil, false
	local staleAtStep = 0
	local reentFired = false
	local function pickWatch()
		local cands = {}
		for _, r in ipairs(recs) do if r.k == "slot" and not r.isSink and mounted[r] and not r.destroyed then table.insert(cands, r) end end
		if #cands == 0 then return end
		watch = cands[rng:NextInteger(1, #cands)]
		local o = watch.obj.Offset:Observer(function()
			if armed and not reentFired then
				reentFired = true
				sink.obj:Add(I.new("Frame"))
			end
		end)
		o:Subscribe()
		watch.keep = o
	end
	if FLAGS.reent then pickWatch() end

	-- ── check ──
	local function check()
		stats.checks += 1
		local exp = expectedHost()
		local got = env.P(host)
		local ok = #exp == #got
		if ok then for i = 1, #exp do if exp[i] ~= got[i] then ok = false break end end end
		if not ok then
			local a, b = {}, {}
			for _, e in ipairs(exp) do table.insert(a, E.nm(e)) end
			for _, e in ipairs(got) do table.insert(b, E.nm(e)) end
			if #env.stale > staleAtStep or reentFired then
				-- Q75 family (native op got a stale offset inside a batch/wave): logical bookkeeping is still
				-- compared below; the oracle is resynced so later steps are judged on their own
				stats.q75phys += 1
				if #q75samples < 8 then table.insert(q75samples, `seed {seed} step {stats.curStep} [{curOp}] reent={tostring(reentFired)}: expected {table.concat(a, ",")} got {table.concat(b, ",")}`) end
				env.phys[host] = table.clone(exp)
			else
				diff(`phys: expected {table.concat(a, ",")} got {table.concat(b, ",")}`)
			end
		end
		-- mock Parent membership agrees with the oracle
		local kids = host:GetChildren()
		if #kids ~= #exp then diff(`mock children {#kids} vs expected {#exp}`) end
		-- Length / Offset
		local pos = {}
		for i, e in ipairs(exp) do pos[e] = i end
		local function firstLeafOffset(r, acc)
			return acc
		end
		local cursor = 0
		local function walkLO(r)
			local startOff = cursor
			local function inner(x)
				for _, c in ipairs(x.ch) do
					if c.k == "leaf" then cursor += 1 else walkLO(c) end
				end
			end
			inner(r)
			local len = cursor - startOff
			if MUT == "detachCounts" and r.mode == "list" then for _ in pairs(r.det) do len += 0 end end
			r.L, r.O = len, startOff
		end
		for _, st in ipairs(seats) do
			if st.kind == "leaf" then if MUT ~= "leafSeatFree" then cursor += 1 end
			elseif st.cur then walkLO(st.cur) end
		end
		for _, r in ipairs(recs) do
			if r.k == "slot" and not r.destroyed then
				if not mounted[r] and MUT == "unmountZero" and r.everMounted then r.L, r.O = 0, 0 end
				if mounted[r] then r.everMounted = true end
				local gl, go = r.obj.Length:Get(), r.obj.Offset:Get()
				if catchUpLeft[r] and not mounted[r] and not prevMountedStep[r] and (gl ~= r.L or go ~= r.O) then
					-- E19-known shape: remount re-materializes the old :List elements BEFORE the catch-up reconcile
					stats.catchUpTransient += 1; r.L, r.O = gl, go
				end
				if gl ~= r.L then
					local ch = {}
					local c = r.owner
					while c ~= nil do table.insert(ch, if type(c) == "table" then c.mode .. c.id else tostring(c)); c = if type(c) == "table" then c.owner else nil end
					local det = ""
					for _, x in ipairs(recs) do if x.mode == "list" then for k, d in pairs(x.det) do if d == r then det = ` detachedIn list{x.id}[{k}]` end end end end
					diff(`slot {r.id} ({r.mode}, mounted={tostring(mounted[r] == true)}) Length {gl} vs {r.L} chain={table.concat(ch, "<")}{det} everMounted={tostring(r.everMounted)}`); r.L = gl
				end
				if go ~= r.O then diff(`slot {r.id} ({r.mode}, mounted={tostring(mounted[r] == true)}) Offset {go} vs {r.O}`); r.O = go end
				-- T8
				for i, c in ipairs(r.ch) do
					if r.obj:Get(i) ~= c.obj then diff(`slot {r.id} Get({i}) mismatch`) break end
				end
				if r.obj:Get(#r.ch + 1) ~= nil then diff(`slot {r.id} Get({#r.ch + 1}) not nil (model len {#r.ch})`) end
				if r.obj._destroyed then diff(`slot {r.id} destroyed but model alive`) end
			elseif r.k == "slot" then
				if not r.obj._destroyed then diff(`slot {r.id} alive but model destroyed`) end
			else
				local d = E.mock.isDestroyed(r.obj)
				if d ~= r.destroyed then diff(`leaf {r.id} destroyed={tostring(d)} vs {tostring(r.destroyed)}`) end
				if q.Backend.isClaimed(r.obj) == r.destroyed then diff(`leaf {r.id} isClaimed wrong`) end
				if not r.destroyed then
					local want = if pos[r.obj] then host else nil
					if r.obj.Parent ~= want then diff(`leaf {r.id} Parent {E.nm(r.obj.Parent)} vs {E.nm(want)}`) end
				end
			end
		end
		for _, qd in pairs(createdQ) do if #qd > 0 then diff(`unexpected creation(s): {#qd}`); table.clear(qd) end end
	end
	check()

	-- ── op generators ──
	local function liveSlots(pred)
		local out = {}
		for _, r in ipairs(recs) do if r.k == "slot" and not r.isSink and not r.destroyed and (pred == nil or pred(r)) then table.insert(out, r) end end
		return out
	end
	local function pick(t) if #t == 0 then return nil end return t[rng:NextInteger(1, #t)] end
	local function depthOf(r) local d = 0; local c = r; while type(c) == "table" do d += 1; c = c.owner end; return d end
	local function subDepth(r) if r.k ~= "slot" then return 0 end local m = 0; for _, c in ipairs(r.ch) do m = math.max(m, subDepth(c)) end; return 1 + m end
	local function freeItems()
		local out = {}
		for _, r in ipairs(recs) do if r.owner == nil and not r.destroyed and not r.isSink then table.insert(out, r) end end
		return out
	end
	-- the element a CRUD adds: fresh leaf, fresh small tree (depth bounded), or a pooled free item
	local function newElementFor(target)
		local roll = rng:NextInteger(1, 6)
		local room = MAXD - depthOf(target)
		if roll <= 2 then
			local free = freeItems()
			local cands = {}
			for _, r in ipairs(free) do
				if not isAncOrSelf(r, target) and subDepth(r) <= room then table.insert(cands, r) end
			end
			local c = pick(cands)
			if c then return c end
		end
		if roll == 3 and room >= 1 then return mkTree(room) end
		return mkLeaf()
	end
	local function expectErr(fn, id)
		local ok, err = pcall(fn)
		local got = if ok then "OK" else E.id(err)
		if MUT == "cycleAs0172" and id == "Quad0173" then id = "Quad0172" end
		bump(stats.errs, id)
		if got ~= id then diff(`expected {id}, got {got}`) end
	end
	-- attach helper: model side of adding element e to manual slot s at idx
	local function modelInsert(s, idx, e) e.owner = s; table.insert(s.ch, idx, e) end
	local function modelTake(s, idx, destroy)
		local e = table.remove(s.ch, idx)
		if destroy then e.owner = s; destroyRec(e) else e.owner = nil end
		if MUT == "extractDestroys" and not destroy then destroyRec(e) end
		return e
	end
	local function listSet(L)
		-- permutation / add / remove / hide toggle, always a fresh array (T5)
		local keys = table.clone(L.keys)
		local roll = rng:NextInteger(1, 5)
		if roll == 1 and #keys < 6 then table.insert(keys, rng:NextInteger(1, #keys + 1), "k" .. rng:NextInteger(1, 8))
		elseif roll == 2 and #keys > 0 then table.remove(keys, rng:NextInteger(1, #keys))
		elseif roll == 3 then for i = #keys, 2, -1 do local j = rng:NextInteger(1, i); keys[i], keys[j] = keys[j], keys[i] end
		elseif roll == 4 then local k = "k" .. rng:NextInteger(1, 8); L.hidden[k] = not L.hidden[k] or nil
		else keys = {} ; for i = 1, rng:NextInteger(0, 5) do table.insert(keys, "k" .. rng:NextInteger(1, 8)) end end
		-- dedupe (duplicate keys are a defined error, out of scope here)
		local seen, out = {}, {}
		for _, k in ipairs(keys) do if not seen[k] then seen[k] = true; table.insert(out, k) end end
		L.keys = out
		L.data:Set(table.clone(out))
		if mounted[L] then reconcile(L)
		elseif L.activated then L.dirty = true end
	end

	for step = 1, STEPS do
		stats.steps += 1
		stats.curStep = step
		reentFired = false
		staleAtStep = #env.stale
		catchUpLeft = {}
		armed = FLAGS.reent and watch ~= nil and not watch.destroyed
		local watchOffBefore = if watch then watch.O else nil
		local roll = rng:NextInteger(1, 100)
		local manual = liveSlots(function(r) return r.mode == "manual" end)
		if roll <= 14 then
			curOp = "Add"
			local s = pick(manual)
			if s then
				local e = newElementFor(s)
				local useIdx = rng:NextInteger(1, 2) == 1
				local idx = if useIdx then rng:NextInteger(1, #s.ch + 1) else #s.ch + 1
				if useIdx then s.obj:Add(e.obj, idx) else s.obj:Add(e.obj) end
				modelInsert(s, idx, e)
			end
		elseif roll <= 22 then
			curOp = "Remove"
			local s = pick(liveSlots(function(r) return r.mode == "manual" and #r.ch > 0 end))
			if s then local i = rng:NextInteger(1, #s.ch); s.obj:Remove(i); modelTake(s, i, true) end
		elseif roll <= 32 then
			curOp = "Extract"
			local s = pick(liveSlots(function(r) return r.mode == "manual" and #r.ch > 0 end))
			if s then local i = rng:NextInteger(1, #s.ch); local got = s.obj:Extract(i); local e = modelTake(s, i, false)
				if got ~= e.obj then diff("Extract returned the wrong element") end end
		elseif roll <= 38 then
			curOp = "Replace"
			local s = pick(liveSlots(function(r) return r.mode == "manual" and #r.ch > 0 end))
			if s then
				local i = rng:NextInteger(1, #s.ch)
				local e = newElementFor(s)
				if e.owner == nil and not isAncOrSelf(e, s) then
					s.obj:Replace(i, e.obj); modelTake(s, i, true); modelInsert(s, i, e)
				end
			end
		elseif roll <= 44 then
			curOp = "Splice"
			local s = pick(manual)
			if s then
				local i = rng:NextInteger(1, #s.ch + 1)
				local rc = rng:NextInteger(0, #s.ch - i + 1)
				local news, objs, used = {}, {}, {}
				for _ = 1, rng:NextInteger(0, 2) do
					local e = newElementFor(s)
					if not used[e] then used[e] = true; table.insert(news, e); table.insert(objs, e.obj) end
				end
				local removed = s.obj:Splice(i, rc, table.unpack(objs))
				local exp = {}
				for _ = 1, rc do table.insert(exp, modelTake(s, i, false)) end
				for k, e in ipairs(news) do modelInsert(s, i + k - 1, e) end
				for k, e in ipairs(exp) do if removed[k] ~= e.obj then diff("Splice returned wrong removed") break end end
			end
		elseif roll <= 47 then
			curOp = "ExtractAll"
			local s = pick(manual)
			if s then s.obj:ExtractAll(); while #s.ch > 0 do modelTake(s, 1, false) end end
		elseif roll <= 49 then
			curOp = "Clear"
			local s = pick(manual)
			if s then s.obj:Clear(); while #s.ch > 0 do modelTake(s, #s.ch, true) end end
		elseif roll <= 55 then
			curOp = "MoveSwap"
			local s = pick(liveSlots(function(r) return r.mode == "manual" and #r.ch > 1 end))
			if s then
				local a, b = rng:NextInteger(1, #s.ch), rng:NextInteger(1, #s.ch)
				if rng:NextInteger(1, 2) == 1 then
					s.obj:Move(a, b); local e = table.remove(s.ch, a); table.insert(s.ch, b, e)
				else
					s.obj:Swap(a, b); s.ch[a], s.ch[b] = s.ch[b], s.ch[a]
				end
			end
		elseif roll <= 70 then
			curOp = "ListSet"
			local L = pick(liveSlots(function(r) return r.mode == "list" end))
			if L then listSet(L) end
		elseif roll <= 77 then
			curOp = "SeatSet"
			local st = {}
			for _, x in ipairs(seats) do if x.kind == "state" then table.insert(st, x) end end
			local seat = pick(st)
			if seat then
				stats.seatSwaps += 1
				local r2 = rng:NextInteger(1, 4)
				if r2 == 1 then
					seat.src:Set(nil)
					if seat.cur then seat.cur.owner = nil end
					seat.cur = nil
				else
					local cands = {}
					for _, r in ipairs(freeItems()) do if r.k == "slot" and r ~= seat.cur and subDepth(r) <= MAXD then table.insert(cands, r) end end
					local held = liveSlots(function(r) return r.owner ~= nil and r ~= seat.cur end)
					if r2 == 2 and #held > 0 then
						-- T6: held Slot into a seat -> 0160 from the Set, seat left empty, old released
						local h = pick(held)
						curOp = "SeatSetHeld"
						expectErr(function() seat.src:Set(h.obj) end, "Quad0160")
						if seat.cur then seat.cur.owner = nil end
						seat.cur = nil
					else
						local c = pick(cands) or mkTree(MAXD)
						seat.src:Set(c.obj)
						if seat.cur then seat.cur.owner = nil end
						c.owner = "seat"; seat.cur = c
					end
				end
			end
		elseif roll <= 80 then
			curOp = "dispose"
			local free = {}
			for _, r in ipairs(freeItems()) do table.insert(free, r) end
			local r = pick(free)
			if r then q.dispose(r.obj); destroyRec(r); stats.disposeOk += 1 end
		elseif roll <= 82 then
			curOp = "GC"
			collectgarbage("collect"); stats.gc += 1
		else
			-- ── defined errors (T6): nothing may change ──
			local k = rng:NextInteger(1, 10)
			if k == 1 then
				curOp = "err:heldAdd"
				local s = pick(manual)
				local held = {}
				for _, r in ipairs(recs) do if r.owner ~= nil and not r.destroyed and r.owner ~= s and r ~= s and not r.isSink then table.insert(held, r) end end
				local h = pick(held)
				if s and h then expectErr(function() s.obj:Add(h.obj) end, "Quad0172") end
			elseif k == 2 then
				curOp = "err:sameAdd"
				local s = pick(liveSlots(function(r) return r.mode == "manual" and #r.ch > 0 end))
				if s then expectErr(function() s.obj:Add(s.ch[rng:NextInteger(1, #s.ch)].obj) end, "Quad0170") end
			elseif k == 3 then
				curOp = "err:cycle"
				-- a FREE root Slot added into its own subtree (or itself)
				local roots = {}
				for _, r in ipairs(freeItems()) do if r.k == "slot" and r.mode == "manual" then table.insert(roots, r) end end
				local root = pick(roots)
				if root then
					local inside = {}
					for _, r in ipairs(recs) do if r.k == "slot" and r.mode == "manual" and not r.destroyed and isAncOrSelf(root, r) then table.insert(inside, r) end end
					local t = pick(inside)
					expectErr(function() t.obj:Add(root.obj) end, "Quad0173")
				end
			elseif k == 4 then
				curOp = "err:index"
				local s = pick(manual)
				if s then
					local n = #s.ch
					local w = rng:NextInteger(1, 4)
					if w == 1 then expectErr(function() s.obj:Remove(n + 1) end, "Quad0236")
					elseif w == 2 then expectErr(function() s.obj:Remove(0) end, "Quad0168")
					elseif w == 3 then expectErr(function() s.obj:Add(I.new("Frame"), n + 2) end, "Quad0236")
					else expectErr(function() s.obj:Move(1, n + 1) end, if n == 0 then "Quad0236" else "Quad0236") end
				end
			elseif k == 5 then
				curOp = "err:listCrud"
				local L = pick(liveSlots(function(r) return r.mode == "list" end))
				if L then expectErr(function() L.obj:Add(I.new("Frame")) end, "Quad0166") end
			elseif k == 6 then
				curOp = "err:destroyedSlotCrud"
				local d = {}
				for _, r in ipairs(recs) do if r.k == "slot" and r.destroyed then table.insert(d, r) end end
				local r = pick(d)
				if r then expectErr(function() r.obj:Add(I.new("Frame")) end, "Quad0165") end
			elseif k == 7 then
				curOp = "err:addDestroyed"
				local s = pick(manual)
				local d = {}
				for _, r in ipairs(recs) do if r.destroyed then table.insert(d, r) end end
				local r = pick(d)
				if s and r then expectErr(function() s.obj:Add(r.obj) end, if r.k == "leaf" then "Quad0241" else "Quad0242") end
			elseif k == 8 then
				curOp = "err:disposeHeld"
				local held = {}
				for _, r in ipairs(recs) do if r.owner ~= nil and not r.destroyed and not r.isSink then table.insert(held, r) end end
				local h = pick(held)
				if h then expectErr(function() q.dispose(h.obj) end, "Quad0179") end
			elseif k == 9 then
				curOp = "err:heldLeafProbe"
				-- T6 via a throwaway unmounted Slot: free leaf accepted (then extracted back), held refused
				local lv = {}
				for _, r in ipairs(recs) do if r.k == "leaf" and not r.destroyed then table.insert(lv, r) end end
				local r = pick(lv)
				if r then
					local tmp = q.Slot()
					local ok, err = pcall(function() tmp:Add(r.obj) end)
					if (r.owner == nil) ~= ok then diff(`held probe: leaf {r.id} model owner={tostring(r.owner ~= nil)} Add ok={tostring(ok)} {if ok then "" else E.id(err)}`) end
					if ok then tmp:Extract(1) end
				end
			else
				curOp = "err:seatDestroyed"
				local st = {}
				for _, x in ipairs(seats) do if x.kind == "state" then table.insert(st, x) end end
				local seat = pick(st)
				local d = {}
				for _, r in ipairs(recs) do if r.k == "slot" and r.destroyed then table.insert(d, r) end end
				local r = pick(d)
				if seat and r then
					expectErr(function() seat.src:Set(r.obj) end, "Quad0140")
					if seat.cur then seat.cur.owner = nil end
					seat.cur = nil
				end
			end
		end
		bump(stats.opCount, curOp)
		if #env.stale > staleAtStep then
			stats.staleByOp = stats.staleByOp or {}
			local kinds = {}
			for i = staleAtStep + 1, #env.stale do kinds[(env.stale[i]:match("^(%S+):"))] = true end
			for kd in pairs(kinds) do bump(stats.staleByOp, curOp .. "/" .. kd) end
		end
		if FLAGS.trace then
			local function show(r)
				if r.k == "leaf" then return E.nm(r.obj) .. "#" .. r.id end
				local parts = {}
				for _, c in ipairs(r.ch) do table.insert(parts, show(c)) end
				local d = ""
				if r.mode == "list" then local dk = {}; for k, c in pairs(r.det) do table.insert(dk, k .. "=" .. show(c)) end; d = " det{" .. table.concat(dk, ",") .. "}" end
				return `{r.mode}{r.id}[` .. table.concat(parts, " ") .. "]" .. d
			end
			local seatS = {}
			for _, st in ipairs(seats) do table.insert(seatS, if st.kind == "leaf" then st.name elseif st.cur then show(st.cur) else "nil") end
			print(`T step {step} {curOp} reent={tostring(reentFired)} :: ` .. table.concat(seatS, " | "))
		end
		prevMountedStep = mounted
		local prevMounted = mounted
		local pm = {}
		for r in pairs(prevMounted) do pm[r] = true end
		mounted = settleMount(pm)
		-- mounted = settleMount marks EVERYTHING mounted before as "seen"; recompute plain mounted set
		mounted = markMounted()
		-- reentrant model: the watched Slot's Offset moved (primary op) -> sink got one leaf appended
		if armed then
			local will = false
			if mounted[watch] then
				-- compute the watched offset on the model after the primary op
				local tmpC = 0
				local found
				local function w(r)
					if r == watch then found = tmpC end
					for _, c in ipairs(r.ch) do if c.k == "leaf" then tmpC += 1 else w(c) end end
				end
				for _, st in ipairs(seats) do
					if st.kind == "leaf" then tmpC += 1 elseif st.cur then w(st.cur) end
				end
				will = found ~= nil and found ~= watchOffBefore
			end
			if will ~= reentFired then
				if reentFired and not will then
					bump(stats.transientFire, curOp) -- a->b->a notification (the model predicts no NET change)
				else
					diff(`reent: model fire={tostring(will)} real={tostring(reentFired)} (watch {watch.id} {watchOffBefore})`)
				end
			end
			if reentFired then
				stats.reentFired += 1
				-- identify the appended frame (last child of the sink)
				local obj = sink.obj:Get(#sink.ch + 1)
				if obj then local lr = newLeafRec(obj); lr.owner = sink; table.insert(sink.ch, lr) end
			end
			armed = false
		end
		for _, r in ipairs(recs) do if r.k == "slot" and not r.destroyed then stats.maxDepth = math.max(stats.maxDepth, depthOf(r)) end end
		check()
		if FLAGS.reent and (watch == nil or watch.destroyed or not mounted[watch]) and rng:NextInteger(1, 4) == 1 then
			if watch and watch.keep then watch.keep:Unsubscribe() end
			watch = nil
			pickWatch()
		end
	end
	stats.stale += #env.stale
	stats.viol += (env.violCount or 0)
	for _, v in ipairs(env.viol) do if #samples < 25 then table.insert(samples, `seed {seed} viol: {v}`) end end
	for _, v in ipairs(env.stale) do if #samples < 25 and FLAGS.showstale then table.insert(samples, `seed {seed} stale: {v}`) end end
	if stats.diffs > diffsBefore then stats.diffSeeds += 1 end
	-- harness hygiene (out-probe-leak.txt): an undestroyed mock host that held a mounted Slot keeps the whole
	-- quad instance alive (Roblox-faithful nil-parent + connection shape) — destroy it and every pooled value
	host:Destroy()
	for _, r in ipairs(recs) do if r.k == "leaf" and not r.destroyed then r.obj:Destroy() end end
end

local t0 = os.clock()
for seed = START, START + SEEDS - 1 do
	stats.seeds += 1
	local ok, err = pcall(runSeed, seed)
	if not ok then
		stats.diffs += 1; stats.diffSeeds += 1
		if #samples < 25 then table.insert(samples, `seed {seed} CRASH: {tostring(err):sub(1, 300)}`) end
	end
end
print(`E72 fuzz mutant={MUT or "none"} flags={args[4] or ""} seeds={stats.seeds} steps={stats.steps} checks={stats.checks} diffs={stats.diffs} diffSeeds={stats.diffSeeds} time={string.format("%.1f", os.clock() - t0)}s`)
print(`  maxDepth={stats.maxDepth} creates={stats.creates} detach={stats.detach} reattach={stats.reattach} catchUp={stats.catchUp} seatSwaps={stats.seatSwaps} disposeOk={stats.disposeOk} gc={stats.gc} reentFired={stats.reentFired} staleOffsets(Q75)={stats.stale} oracleViol={stats.viol}`)
local e = {}
for k, v in pairs(stats.errs) do table.insert(e, `{k}={v}`) end
table.sort(e)
print("  expectedErrors " .. table.concat(e, " "))
local o = {}
for k, v in pairs(stats.opCount) do table.insert(o, `{k}={v}`) end
table.sort(o)
print("  ops " .. table.concat(o, " "))
local tf = {}
for k, v in pairs(stats.transientFire) do table.insert(tf, `{k}={v}`) end
table.sort(tf)
local sb = {}
for k, v in pairs(stats.staleByOp or {}) do table.insert(sb, `{k}={v}`) end
table.sort(sb)
print("  staleOffsetSteps(by op/native) " .. table.concat(sb, " "))
print(`  q75phys={stats.q75phys} catchUpTransient={stats.catchUpTransient} transientFire(a->b->a) ` .. table.concat(tf, " "))
for _, s in ipairs(q75samples) do print("  Q75 " .. s) end
for _, s in ipairs(samples) do print("  " .. s) end
