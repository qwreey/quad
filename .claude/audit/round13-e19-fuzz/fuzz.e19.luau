--!nocheck
-- E19 — reference-model differential fuzzer for MANUAL Slot CRUD
-- (Add/Replace/Remove/Splice/Extract/ExtractAll/Clear/Move/Swap + dispose)
-- x element kinds (Instance leaf / nested manual Slot / State element (nil/None/leaf/Slot values)
-- / :Single slots with OwnsElements true|false and KeyGone -> nil|Detach) x nesting depth <= 3
-- x mount/unmount toggles.  The model is a pure-Lua array tree; the contract it encodes is
-- docs/reference/core/06-slot.md + .claude/base/slot-plan.md (contract reading: see results.txt header + the report).
--
-- Run from a scratch copy of quad-base (cp -rL) carrying the probe hooks in HOOKS.txt:
--   cp fuzz.e19.luau <copy>/quad-base/test/ && cd <copy>/quad-base && luau test/fuzz.e19.luau <from> <count> [verboseSeed] [flags]
-- flags (comma list): noerr (no defined-error ops), nost, noss, nomount, nodispose
-- Output: one "R" line per seed (ok or first mismatch), "N" lines (notification excess), "P" lines (perf).
local mock = require("./mock")
local Instance = mock.Instance

local ARGS = { ... }
local FROM, COUNT = tonumber(ARGS[1]) or 1, tonumber(ARGS[2]) or 100
local VERBOSE = tonumber(ARGS[3]) or 0
local FLAGS = {}
for f in string.gmatch(ARGS[4] or "", "[^,]+") do FLAGS[f] = true end

local function nm(e) return if e == nil then "nil" elseif type(e) == "table" and e.Name then e.Name else tostring(e) end

local function newEnv()
	local q = mock.newQuad()
	local phys = setmetatable({}, { __mode = "k" })
	local env = { q = q, phys = phys, violations = {}, known = {} }
	local function P(t) local l = phys[t]; if not l then l = {}; phys[t] = l end; return l end
	env.P = P
	local function viol(msg) table.insert(env.violations, msg) end
	local function checkBlock(t, off, els, op)
		local l = P(t)
		for k, e in ipairs(els) do
			if l[off + k] ~= e then viol(`{op}: expected {nm(e)} at phys[{off + k}] got {nm(l[off + k])}`); return false end
		end
		return true
	end
	local function removeBlock(t, off, els, op)
		local l = P(t)
		local first = els[1] and table.find(l, els[1])
		if first and first - 1 ~= off then
			local contiguous = true
			for k, e in ipairs(els) do if l[first + k - 1] ~= e then contiguous = false end end
			if contiguous then
				table.insert(env.known, `stale {op}: passed {off}, actual {first - 1} ({nm(els[1])})`)
				for _ = 1, #els do table.remove(l, first) end
				return
			end
		end
		if not checkBlock(t, off, els, op) then
			for _, e in ipairs(els) do local i = table.find(l, e); if i then table.remove(l, i) end end
			return
		end
		for _ = 1, #els do table.remove(l, off + 1) end
	end
	local function insertBlock(t, off, els, op)
		local l = P(t)
		if off < 0 or off > #l then viol(`{op}: offset {off} out of [0,{#l}]`); off = math.clamp(off, 0, #l) end
		for k, e in ipairs(els) do table.insert(l, off + k, e) end
	end
	local B = q.Backend
	B.nativeInsert = function(t, off, els) insertBlock(t, off, els, "insert"); for _, e in els do e.Parent = t end end
	B.nativeExtract = function(t, off, els, new)
		removeBlock(t, off, els, "extract"); for _, e in els do e.Parent = nil end
		if new then insertBlock(t, off, new, "extract/new"); for _, e in new do e.Parent = t end end
	end
	B.nativeRemove = function(t, off, els, new)
		removeBlock(t, off, els, "remove"); for _, e in els do e:Destroy() end
		if new then insertBlock(t, off, new, "remove/new"); for _, e in new do e.Parent = t end end
	end
	B.nativeMove = function(t, fo, els, to) removeBlock(t, fo, els, "move"); insertBlock(t, to, els, "move/to") end
	B.nativeSwap = function(t, oa, ea, ob, eb)
		local okA = checkBlock(t, oa, ea, "swapA"); local okB = checkBlock(t, ob, eb, "swapB")
		local l = P(t)
		if not (okA and okB) then return end
		local out = {}
		for i = 1, oa do table.insert(out, l[i]) end
		for _, x in eb do table.insert(out, x) end
		for i = oa + #ea + 1, ob do table.insert(out, l[i]) end
		for _, x in ea do table.insert(out, x) end
		for i = ob + #eb + 1, #l do table.insert(out, l[i]) end
		phys[t] = out
	end
	B.nativeDispose = function(e)
		for _, l in pairs(phys) do local i = table.find(l, e); if i then table.remove(l, i) end end
		e:Destroy()
	end
	q.Dispatch.addHandler({
		name = "ProbeLeaf",
		isHandlable = function(_i, k, v) return type(k) == "number" and type(v) == "string" end,
		priority = q.Dispatch.HANDLER_PRIORITY_NORMAL,
		process = function(inst, k, v, _index)
			local f = Instance.new("Frame"); f.Name = v
			q.Bookkeeping.setOffsetSource(inst, k, q.None)
			B.nativeInsert(inst, q.Bookkeeping.getOffsetAt(inst, k), { f })
			q.Bookkeeping.setLength(inst, k, 1)
			return q.Void
		end,
	})
	q._pc = { reindexCalls = 0, reindexIters = 0, spliceArr = 0, getOffsetAt = 0, getOffsetIters = 0, recompute = 0, recomputeIters = 0 }
	return env
end

local PERF = {} -- op -> list of {n, getOffsetAt, iters, reindexIters, recompute, recomputeIters}
local NOTIF = {} -- op .. kind -> {steps, over, transient}
local RESULTS = {}
CURSTEP = 0
TRANSIENT = 0
COV = {}
local function cov(k) COV[k] = (COV[k] or 0) + 1 end

local function run(seed)
	math.randomseed(seed)
	local env = newEnv()
	local q = env.q
	local ownerRel = q._probeOwner
	local host = Instance.new("Folder"); host.Name = "P"
	local log = {}
	local function L(s) table.insert(log, s) end

	-- ── model records ──
	local R = {} -- real obj -> rec
	local recs = {} -- ordered list of recs (for deterministic walks)
	local nextId = 0
	local function reg(rec) nextId += 1; rec.id = nextId; R[rec.obj] = rec; table.insert(recs, rec); return rec end
	local obsCount = {} -- slot obj -> {L=n, O=n}
	local function watch(slot)
		local c = { L = 0, O = 0 }
		obsCount[slot] = c
		local a = slot.Length:Observer(function() c.L += 1 end); a:Subscribe()
		local b = slot.Offset:Observer(function() c.O += 1 end); b:Subscribe()
		c.L, c.O = 0, 0
		c.keep = { a, b }
	end
	local leafSeq = 0
	local function freshLeafObj(prefix)
		leafSeq += 1
		local f = Instance.new("Frame"); f.Name = (prefix or "f") .. leafSeq
		return f
	end
	local function newLeafRec(obj) return reg({ k = "leaf", obj = obj, alive = true }) end
	local function freshLeaf() return newLeafRec(freshLeafObj()) end

	local TAGS = if FLAGS.ssheavy then { "a", "b" } else { "a", "b", "c", "d", "e" }
	local ssQueue = {} -- ss obj -> created frames (in order)
	local ssCalls = {} -- ss obj -> updateFn call count
	local leafTag = setmetatable({}, { __mode = "k" })
	local function makeSS(owns, data)
		local src = q.Source(data)
		local slot
		local rec
		local function uf(ctx)
			ssCalls[slot] = (ssCalls[slot] or 0) + 1
			if ctx.Item == q.KeyGone then
				return (if rec.policy == "detach" then q.Detach else nil)
			end
			if ctx.Prev ~= nil and leafTag[ctx.Prev] == ctx.Item then return ctx.Prev end
			local f = freshLeafObj("s" .. rec.id .. "_")
			leafTag[f] = ctx.Item
			table.insert(ssQueue[slot], f)
			return f
		end
		slot = q.Slot():Single(src, uf, { OwnsElements = owns })
		ssQueue[slot] = {}
		rec = reg({ k = "ss", obj = slot, src = src, owns = owns, data = data, rdata = nil, el = nil, det = nil, activated = false, pending = false, destroyed = false, policy = "nil", everMat = false })
		watch(slot)
		return rec
	end
	local function makeMS(children)
		local objs = {}
		for i, c in ipairs(children) do objs[i] = c.obj end
		local slot = q.Slot(objs)
		local rec = reg({ k = "ms", obj = slot, elems = table.clone(children), destroyed = false, everMat = false })
		watch(slot)
		return rec
	end
	local function makeST(valueRec, useNone)
		local v = if valueRec then valueRec.obj elseif useNone then q.None else nil
		local src = q.Source(v)
		return reg({ k = "st", obj = src, value = valueRec, recon = nil, placed = false, activated = false })
	end

	-- root
	local N0 = math.random(1, 50)
	local rootChildren = {}
	for _ = 1, N0 do table.insert(rootChildren, freshLeaf()) end
	if FLAGS.ssheavy then
		for _ = 1, 3 do table.insert(rootChildren, math.random(#rootChildren + 1), makeSS(math.random(2) == 1, "a")) end
	end
	local root = makeMS(rootChildren)
	local startMounted = math.random(3) ~= 1
	local mounted = false
	local holder = q.Source(if startMounted then root.obj else nil)
	q.Dispatch.drive(host, { "L", holder, "T" })

	-- ── model helpers ──
	local function holders()
		local h = {} -- obj -> {kind, rec, i}
		for _, r in ipairs(recs) do
			if r.k == "ms" and not r.destroyed then
				for i, e in ipairs(r.elems) do h[e.obj] = { kind = "ms", rec = r, i = i } end
			elseif r.k == "ss" and not r.destroyed then
				if r.el then h[r.el.obj] = { kind = "ss", rec = r } end
				if r.det then h[r.det.obj] = { kind = "ssdet", rec = r } end
			elseif r.k == "st" and r.placed and r.activated and r.recon then
				h[r.recon.obj] = { kind = "st", rec = r }
			end
		end
		if mounted then h[root.obj] = { kind = "host" } end
		return h
	end
	local function referencedByST()
		local s = {}
		for _, r in ipairs(recs) do if r.k == "st" and r.value then s[r.value] = true end end
		return s
	end
	-- children of a slot-ish rec in the model (for subtree/depth walks)
	local function kids(r)
		if r.k == "ms" then return r.elems
		elseif r.k == "st" then return if r.value then { r.value } else {}
		elseif r.k == "ss" then local t = {}; if r.el then table.insert(t, r.el) end; if r.det then table.insert(t, r.det) end; return t end
		return {}
	end
	local function contains(x, y) -- y in subtree of x (incl. x)
		if x == y then return true end
		for _, c in ipairs(kids(x)) do if contains(c, y) then return true end end
		return false
	end
	local function height(r)
		if r.k == "leaf" then return 0 end
		local m = 0
		for _, c in ipairs(kids(r)) do m = math.max(m, height(c)) end
		return 1 + m
	end
	-- parent-in-model of a rec (ms that holds it, or st whose value it is)
	local function parentOf(r)
		for _, p in ipairs(recs) do
			if p.k == "ms" and not p.destroyed then for _, e in ipairs(p.elems) do if e == r then return p end end
			elseif p.k == "st" and p.placed and p.value == r then return p end
		end
		return nil
	end
	local function depthOf(r) -- slot levels above r's own level (root = 0)
		local d, cur = 0, r
		while true do
			local p = parentOf(cur)
			if p == nil then return d end
			d += 1; cur = p
		end
	end
	local function topOf(r)
		local cur = r
		while true do local p = parentOf(cur); if p == nil then return cur end; cur = p end
	end
	local function inRootTree(r) return topOf(r) == root end

	local function flatten(r, out)
		out = out or {}
		if r.k == "leaf" then table.insert(out, r)
		elseif r.k == "ms" then for _, e in ipairs(r.elems) do flatten(e, out) end
		elseif r.k == "st" then if r.recon then flatten(r.recon, out) end
		elseif r.k == "ss" then if r.el then table.insert(out, r.el) end end
		return out
	end
	local function lenOf(r) return #flatten(r) end

	-- disposition
	local disposeRec, releaseST
	function releaseST(st) -- wrapper leaves / is destroyed: occupant released, placement gone
		st.placed = false; st.activated = false; st.recon = nil
	end
	local creations = {} -- expected creations: list of {ss, tag}
	function disposeRec(r)
		if r.k == "leaf" then r.alive = false
		elseif r.k == "ms" then
			for _, e in ipairs(r.elems) do disposeRec(e) end
			r.elems = {}; r.destroyed = true
		elseif r.k == "st" then releaseST(r)
		elseif r.k == "ss" then
			if r.owns then
				if r.el then r.el.alive = false end
				if r.det then r.det.alive = false end
				r.el, r.det = nil, nil
				r.destroyed = true
			else
				cov("ss-noown-destroy-release")
				r.el = nil -- released alive
				r.activated = false; r.pending = false; r.rdata = nil
			end
		end
	end
	local function extractRec(r)
		if r.k == "st" then releaseST(r) end
	end

	-- SS transition (reconcile once, from rdata to data) — expected updateFn calls returned
	local function ssTransition(r)
		local calls = 0
		local d0, d1 = r.rdata, r.data
		if d1 ~= nil then
			calls += 1
			local prev = r.el or r.det
			if prev and prev.tag == d1 then
				if r.det and prev == r.det then r.el, r.det = r.det, nil; cov("ss-reattach-detached") else cov("ss-keep-prev") end
			else
				cov(if r.det then "ss-replace-detached" elseif r.el then (if r.owns then "ss-replace-own" else "ss-replace-noown") else "ss-create")
				local nl = { k = "leaf", alive = true, tag = d1, pendingBind = r }
				table.insert(creations, nl)
				if r.det then r.det.alive = false; r.det = nil end -- detached held only when owns → destroyed
				if r.el then
					if r.owns then r.el.alive = false end -- else released alive
				end
				r.el = nl
			end
		else
			if d0 ~= nil then
				calls += 1 -- KeyGone
				if r.policy == "detach" and not r.owns then cov("ss-keygone-detach-noown-release") end
				if r.policy == "detach" and r.owns then
					cov("ss-keygone-detach-hold")
					r.det, r.el = r.el, nil
				else
					if r.el and r.owns then r.el.alive = false end
					r.el = nil
				end
			end
		end
		r.rdata = d1
		r.pending = false
		return calls
	end
	local expectCalls = {} -- ss rec -> expected calls this step
	local function addCalls(r, n) expectCalls[r] = (expectCalls[r] or 0) + n end

	-- bring every placed ST/SS in the mounted root tree up to date (contract: a mounted Slot shows its data)
	local function sync()
		if not mounted then return end
		local stack = { root }
		while #stack > 0 do
			local r = table.remove(stack)
			if r.k == "ms" then r.everMat = true; for _, e in ipairs(r.elems) do table.insert(stack, e) end
			elseif r.k == "st" then
				if not r.activated then
					r.activated = true; r.recon = r.value -- fresh wrapper: reconciles straight to the current value
				elseif r.recon ~= r.value then
					-- a value set while the wrapper was unmounted: quad re-materializes the STALE occupant
					-- first (its subtree mounts, nested :Single/State wrappers activate) and only then the
					-- catch-up reconcile swaps it (observed order; counted in the "T" line)
					local old = r.recon
					r.recon = r.value
					if old then TRANSIENT += 1; table.insert(stack, old) end
				end
				if r.recon then table.insert(stack, r.recon) end
			elseif r.k == "ss" then
				r.everMat = true
				if not r.activated then
					r.activated = true; r.rdata = nil; r.el = nil
					addCalls(r, ssTransition(r))
				elseif r.pending then
					cov("ss-pending-remount")
					addCalls(r, ssTransition(r))
				end
			end
		end
	end
	if startMounted then mounted = true; sync() end

	-- ── comparison ──
	local function realElOf(r) return r.obj end
	local function wrapperMatches(el, st) return type(el) == "table" and q.isSlot(el) and el._wrapped == st.obj end
	local mismatch = nil
	local function MM(cls, msg) if mismatch == nil then mismatch = cls .. " " .. msg end end
	local prevVals = {}
	local function compare(stepOp, errExpected, errGot)
		-- 1. error
		if errExpected == nil and errGot ~= nil then MM("ERR-UNEXPECTED", errGot); return end
		if errExpected ~= nil then
			if errGot == nil then MM("ERR-MISSING", errExpected); return end
			if not string.find(errGot, errExpected, 1, true) then MM("ERR-ID", `want {errExpected} got {errGot}`); return end
		end
		-- 2. raw order
		for _, r in ipairs(recs) do
			if r.k == "ms" then
				if (r.obj._destroyed == true) ~= r.destroyed then MM("DESTROYED-SLOT", `ms#{r.id} real={tostring(r.obj._destroyed)} model={tostring(r.destroyed)}`); return end
				if not r.destroyed then
					local els = r.obj._elements
					if #els ~= #r.elems then MM("RAW-LEN", `ms#{r.id} real={#els} model={#r.elems}`); return end
					for i, e in ipairs(r.elems) do
						local ok = if e.k == "st" then wrapperMatches(els[i], e) else els[i] == e.obj
						if not ok then MM("RAW-ORDER", `ms#{r.id}[{i}] model={e.k}#{e.id}`); return end
					end
				end
			elseif r.k == "ss" then
				if (r.obj._destroyed == true) ~= r.destroyed then MM("DESTROYED-SLOT", `ss#{r.id} real={tostring(r.obj._destroyed)} model={tostring(r.destroyed)}`); return end
				if not r.destroyed then
					local els = r.obj._elements
					local want = if r.el then 1 else 0
					if #els ~= want or (r.el and els[1] ~= r.el.obj) then MM("SS-ELEMENT", `ss#{r.id} real={#els}:{nm(els[1])} model={r.el and nm(r.el.obj) or "none"}`); return end
					local rd = r.obj._detached and r.obj._detached[true]
					if rd ~= (r.det and r.det.obj) then MM("SS-DETACHED", `ss#{r.id} real={nm(rd)} model={r.det and nm(r.det.obj) or "none"}`); return end
				end
			elseif r.k == "st" and r.placed then
				-- wrapper occupant
			end
		end
		-- 3. updateFn calls & creations
		for _, r in ipairs(recs) do
			if r.k == "ss" then
				local got = ssCalls[r.obj] or 0
				local want = expectCalls[r] or 0
				if got ~= want then MM("SS-CALLS", `ss#{r.id} real={got} model={want}`); return end
				local qd = ssQueue[r.obj]
				local wantC = 0
				for _, c in ipairs(creations) do if c.pendingBind == r then wantC += 1 end end
				if #qd ~= wantC then MM("SS-CREATIONS", `ss#{r.id} real={#qd} model={wantC}`); return end
			end
		end
		-- 4. liveness of leaves
		for _, r in ipairs(recs) do
			if r.k == "leaf" then
				if mock.isDestroyed(r.obj) == r.alive then MM("DESTROYED-LEAF", `leaf#{r.id} {nm(r.obj)} real_destroyed={tostring(mock.isDestroyed(r.obj))} model_alive={tostring(r.alive)}`); return end
			end
		end
		-- 5. owners
		local h = holders()
		local function realOwner(o) return ownerRel:GetWeak(o, "__owner") end
		for _, r in ipairs(recs) do
			local live = (r.k == "leaf" and r.alive) or ((r.k == "ms" or r.k == "ss") and not r.destroyed)
			if live then
				local want = h[r.obj]
				local got = realOwner(r.obj)
				local ok
				if want == nil then ok = got == nil
				elseif want.kind == "host" then ok = got == host
				elseif want.kind == "ms" then
					ok = got == want.rec.obj
				elseif want.kind == "ss" or want.kind == "ssdet" then ok = got == want.rec.obj
				elseif want.kind == "st" then ok = got ~= nil and q.isSlot(got) and got._wrapped == want.rec.obj end
				if not ok then MM("OWNER", `{r.k}#{r.id} {nm(r.obj)} real={nm(got)}{got and q.isSlot(got) and (got._wrapped and "(wrapper)" or "(slot)") or ""} model={want and want.kind or "nil"}`); return end
			end
		end
		-- wrappers' owners
		for _, r in ipairs(recs) do
			if r.k == "ms" and not r.destroyed then
				for i, e in ipairs(r.elems) do
					if e.k == "st" then
						local w = r.obj._elements[i]
						if realOwner(w) ~= r.obj then MM("OWNER-WRAPPER", `ms#{r.id}[{i}]`); return end
					end
				end
			end
		end
		-- 6. physical: parent + phys list + Length/Offset
		local flat = if mounted then flatten(root) else {}
		local inFlat = {}
		for _, l in ipairs(flat) do inFlat[l] = true end
		for _, r in ipairs(recs) do
			if r.k == "leaf" and r.alive then
				local want = if inFlat[r] then host else nil
				if r.obj.Parent ~= want then MM("PARENT", `leaf#{r.id} {nm(r.obj)} real={nm(r.obj.Parent)} model={nm(want)}`); return end
			end
		end
		local ph = env.P(host)
		local exp = { "L" }
		for _, l in ipairs(flat) do table.insert(exp, l.obj.Name) end
		table.insert(exp, "T")
		local got = {}
		for i, e in ipairs(ph) do got[i] = e.Name end
		if table.concat(got, ",") ~= table.concat(exp, ",") then MM("PHYS-ORDER", `real=[{table.concat(got, ",")}] model=[{table.concat(exp, ",")}]`); return end
		if #host:GetChildren() ~= #exp then MM("MOCK-CHILDREN", `real={#host:GetChildren()} model={#exp}`); return end
		if #env.violations > 0 then MM("NATIVE-OFFSET", env.violations[1]); return end
		if #env.known > 0 then
			-- Q75 class (stale offset handed to a native op; logical bookkeeping unaffected) — recorded, not fatal
			for _, k in ipairs(env.known) do print(`S {seed} st={CURSTEP} {stepOp} {k} :: {log[#log]}`) end
			table.clear(env.known)
		end
		-- Length/Offset of every slot in the mounted tree
		if mounted then
			local function walk(r, off)
				local obj = r.obj
				if r.k == "ms" or r.k == "ss" then
					if obj.Length:Get() ~= lenOf(r) then MM("LENGTH", `{r.k}#{r.id} real={obj.Length:Get()} model={lenOf(r)}`); return false end
					if obj.Offset:Get() ~= off then MM("OFFSET", `{r.k}#{r.id} real={obj.Offset:Get()} model={off}`); return false end
				end
				if r.k == "ms" then
					local o = off
					for i, e in ipairs(r.elems) do
						if e.k == "st" then
							local w = obj._elements[i]
							if w.Length:Get() ~= lenOf(e) then MM("LENGTH", `wrapper(st#{e.id}) real={w.Length:Get()} model={lenOf(e)}`); return false end
							if w.Offset:Get() ~= o then MM("OFFSET", `wrapper(st#{e.id}) real={w.Offset:Get()} model={o}`); return false end
							if e.recon and e.recon.k == "ms" then if not walk(e.recon, o) then return false end end
						elseif e.k ~= "leaf" then
							if not walk(e, o) then return false end
						end
						o += lenOf(e)
					end
				end
				return true
			end
			if not walk(root, 1) then return end
		end
		-- never-materialized slots read 0/0
		for _, r in ipairs(recs) do
			if (r.k == "ms" or r.k == "ss") and not r.destroyed and not r.everMat then
				if r.obj.Length:Get() ~= 0 or r.obj.Offset:Get() ~= 0 then MM("PREMOUNT-NONZERO", `{r.k}#{r.id} L={r.obj.Length:Get()} O={r.obj.Offset:Get()}`); return end
			end
		end
	end

	-- notifications: compare observer counts with real value change
	local function snapVals()
		local v = {}
		for obj, _ in obsCount do v[obj] = { obj.Length:Get(), obj.Offset:Get() } end
		return v
	end
	local function notifCheck(opname, before, seedTag)
		for obj, c in obsCount do
			local b = before[obj]
			if b then
				for _, kind in { "L", "O" } do
					local v0 = if kind == "L" then b[1] else b[2]
					local v1 = if kind == "L" then obj.Length:Get() else obj.Offset:Get()
					local exp = if v0 ~= v1 then 1 else 0
					local key = opname .. ":" .. kind
					local t = NOTIF[key]; if not t then t = { steps = 0, over = 0, transient = 0, maxn = 0, changed = 0 }; NOTIF[key] = t end
					t.steps += 1
					if v0 ~= v1 then t.changed += 1 end
					local n = c[kind]
					if n > exp then t.over += 1; if exp == 0 then t.transient += 1 end; if FLAGS.ndetail then print(`ND {seed} st={CURSTEP} {opname} {kind} {R[obj] and (R[obj].k .. "#" .. R[obj].id) or "?"} v0={v0} v1={v1} n={n} :: {log[#log]}`) end end
					if n > t.maxn then t.maxn = n end
				end
			end
			c.L, c.O = 0, 0
		end
	end

	-- ── generators ──
	local function freeSets()
		local h = holders()
		local ref = referencedByST()
		local leaves, mss, sts, sss = {}, {}, {}, {}
		for _, r in ipairs(recs) do
			if r.k == "leaf" and r.alive and not h[r.obj] and not ref[r] and not r.pendingBind then table.insert(leaves, r)
			elseif r.k == "ms" and not r.destroyed and r ~= root and not h[r.obj] and not ref[r] and parentOf(r) == nil then table.insert(mss, r)
			elseif r.k == "st" and not r.placed then table.insert(sts, r)
			elseif r.k == "ss" and not r.destroyed and parentOf(r) == nil then table.insert(sss, r) end
		end
		return leaves, mss, sts, sss
	end
	local function pick(t) return t[math.random(#t)] end
	-- a new element for target ms t (not yet chosen in `used`); nil if none fits
	local function genElement(t, used, avail)
		local leaves, mss, sts, sss = freeSets()
		local function ok(r) return not used[r] end
		for _ = 1, 10 do
			local r = math.random(100)
			if r <= 40 then return freshLeaf()
			elseif r <= 52 then
				local c = {}; for _, x in leaves do if ok(x) then table.insert(c, x) end end
				if #c > 0 then return pick(c) end
			elseif r <= 62 then
				if avail >= 1 then
					local ch = {}
					for _ = 1, math.random(0, 3) do table.insert(ch, freshLeaf()) end
					if avail >= 2 and math.random(4) == 1 then table.insert(ch, math.random(#ch + 1), makeMS({ freshLeaf() })) end
					return makeMS(ch)
				end
			elseif r <= 70 then
				local c = {}
				for _, x in mss do if ok(x) and height(x) <= avail and not contains(x, t) then table.insert(c, x) end end
				if #c > 0 then return pick(c) end
			elseif r <= 80 and not FLAGS.nost then
				if avail >= 1 then
					local rr = math.random(10)
					if rr <= 5 then return makeST(freshLeaf())
					elseif rr <= 7 then return makeST(nil)
					elseif rr == 8 then return makeST(nil, true)
					elseif avail >= 2 then return makeST(makeMS({ freshLeaf(), freshLeaf() })) end
				end
			elseif r <= 85 and not FLAGS.nost then
				local c = {}
				for _, x in sts do if ok(x) and height(x) <= avail and not contains(x, t) then table.insert(c, x) end end
				if #c > 0 then return pick(c) end
			elseif r <= 94 and not FLAGS.noss then
				if avail >= 1 then return makeSS(math.random(2) == 1, if math.random(4) == 1 then nil else pick(TAGS)) end
			elseif not FLAGS.noss then
				local c = {}
				for _, x in sss do if ok(x) and avail >= 1 then table.insert(c, x) end end
				if #c > 0 then return pick(c) end
			end
		end
		return freshLeaf()
	end

	local function allMS()
		local t = {}
		for _, r in ipairs(recs) do if r.k == "ms" and not r.destroyed then table.insert(t, r) end end
		return t
	end
	local function placeInto(t, e) -- model: e is now held by ms t
		if e.k == "st" then e.placed = true; e.activated = false; e.recon = nil end
	end

	-- bind predicted creations to the frames quad's updateFn made
	local function bindCreations()
		for _, c in ipairs(creations) do
			local ss = c.pendingBind
			local qd = ssQueue[ss.obj]
			local used = 0
			for _, c2 in ipairs(creations) do if c2.pendingBind == ss and c2.obj ~= nil then used += 1 end end
			local f = qd[used + 1]
			if f then c.obj = f; R[f] = c; nextId += 1; c.id = nextId; table.insert(recs, c) end
		end
		for _, c in ipairs(creations) do if c.obj == nil then c.alive = false end end
	end
	bindCreations()
	local steps = math.random(1, 40)
	for _, c in obsCount do c.L, c.O = 0, 0 end
	compare("init", nil, nil)
	for _, c in ipairs(creations) do c.pendingBind = nil end
	if mismatch then return { seed = seed, step = 0, mm = mismatch, log = log } end
	for step = 1, steps do
		CURSTEP = step
		table.clear(creations); table.clear(expectCalls)
		for _, r in ipairs(recs) do if r.k == "ss" then ssCalls[r.obj] = 0; table.clear(ssQueue[r.obj]); r.policy = if math.random(2) == 1 then "detach" else "nil" end end
		local before = snapVals()
		for k in pairs(q._pc) do q._pc[k] = 0 end
		local mss = allMS()
		local t = pick(mss)
		local n = #t.elems
		local avail = 3 - depthOf(t) - 0 -- levels available below t
		local op = math.random(100)
		if FLAGS.ssheavy and math.random(3) == 1 then op = (if math.random(3) == 1 then 80 else 86) end
		local opname, qfn, errExpected
		local modelFn
		local function idx(allowEnd) return math.random(1, n + (allowEnd and 1 or 0)) end
		if op <= 20 then
			opname = "Add"
			local e = genElement(t, {}, avail - 1 + 1 - 1 + (0))
			-- avail counts levels below t: an element of height h needs h <= avail
			local i = if math.random(2) == 1 then idx(true) else nil
			qfn = function() return t.obj:Add(e.obj, i) end
			modelFn = function() placeInto(t, e); table.insert(t.elems, i or (#t.elems + 1), e) end
			L(`Add ms#{t.id} {e.k}#{e.id} @{tostring(i)}`)
		elseif op <= 28 and n > 0 then
			opname = "Remove"
			local i = idx()
			qfn = function() t.obj:Remove(i) end
			modelFn = function() local e = table.remove(t.elems, i); disposeRec(e) end
			L(`Remove ms#{t.id} {i}`)
		elseif op <= 36 and n > 0 then
			opname = "Replace"
			local i = idx()
			local e = genElement(t, { [t.elems[i]] = true }, avail)
			if contains(t.elems[i], e) then e = freshLeaf() end
			qfn = function() t.obj:Replace(i, e.obj) end
			modelFn = function() local old = t.elems[i]; placeInto(t, e); t.elems[i] = e; disposeRec(old) end
			L(`Replace ms#{t.id} {i} {e.k}#{e.id}`)
		elseif op <= 44 and n > 0 then
			opname = "Extract"
			local i = idx()
			local e = if math.random(2) == 1 then genElement(t, { [t.elems[i]] = true }, avail) else nil
			if e and contains(t.elems[i], e) then e = freshLeaf() end
			qfn = function() t.obj:Extract(i, e and e.obj) end
			modelFn = function()
				local old = t.elems[i]
				if e then placeInto(t, e); t.elems[i] = e else table.remove(t.elems, i) end
				extractRec(old)
			end
			L(`Extract ms#{t.id} {i} {e and (e.k .. "#" .. e.id) or "-"}`)
		elseif op <= 52 then
			opname = "Splice"
			local i = idx(true)
			local rc = math.random(0, n - i + 1)
			local used = {}
			for j = i, i + rc - 1 do used[t.elems[j]] = true end
			local news = {}
			for _ = 1, math.random(0, 3) do
				local e = genElement(t, used, avail)
				local bad = false
				for j = i, i + rc - 1 do if contains(t.elems[j], e) then bad = true end end
				if not bad and not used[e] then used[e] = true; table.insert(news, e) end
			end
			local objs = {}
			for k, e in ipairs(news) do objs[k] = e.obj end
			qfn = function() return t.obj:Splice(i, rc, table.unpack(objs)) end
			modelFn = function()
				local removed = {}
				for _ = 1, rc do table.insert(removed, table.remove(t.elems, i)) end
				for k, e in ipairs(news) do placeInto(t, e); table.insert(t.elems, i + k - 1, e) end
				for _, e in ipairs(removed) do extractRec(e) end
			end
			L(`Splice ms#{t.id} {i} {rc} +{#news}`)
		elseif op <= 55 then
			opname = "ExtractAll"
			qfn = function() return t.obj:ExtractAll() end
			modelFn = function() local old = t.elems; t.elems = {}; for _, e in ipairs(old) do extractRec(e) end end
			L(`ExtractAll ms#{t.id}`)
		elseif op <= 58 then
			opname = "Clear"
			qfn = function() t.obj:Clear() end
			modelFn = function() local old = t.elems; t.elems = {}; for k = #old, 1, -1 do disposeRec(old[k]) end end
			L(`Clear ms#{t.id}`)
		elseif op <= 66 and n > 0 then
			opname = "Move"
			local a, b = idx(), idx()
			qfn = function() t.obj:Move(a, b) end
			modelFn = function() local e = table.remove(t.elems, a); table.insert(t.elems, b, e) end
			L(`Move ms#{t.id} {a}->{b}`)
		elseif op <= 74 and n > 0 then
			opname = "Swap"
			local a, b = idx(), idx()
			qfn = function() t.obj:Swap(a, b) end
			modelFn = function() t.elems[a], t.elems[b] = t.elems[b], t.elems[a] end
			L(`Swap ms#{t.id} {a},{b}`)
		elseif op <= 82 and not FLAGS.nost then
			opname = "StSet"
			local sts = {}
			for _, r in ipairs(recs) do if r.k == "st" then table.insert(sts, r) end end
			if #sts == 0 then opname = "Noop"; qfn = function() end; modelFn = function() end
			else
				local s = pick(sts)
				local d = if s.placed then depthOf(s) else 0
				local rr = math.random(10)
				local v, useNone
				if rr <= 4 then v = freshLeaf()
				elseif rr <= 6 then v = nil
				elseif rr == 7 then v = nil; useNone = true
				elseif rr == 8 then v = s.value -- same value again (Source re-emits)
				elseif rr == 9 and d + 2 <= 3 then v = makeMS({ freshLeaf() })
				else
					local leaves = freeSets()
					v = if #leaves > 0 then pick(leaves) else freshLeaf()
				end
				qfn = function() s.obj:Set(if v then v.obj elseif useNone then q.None else nil) end
				modelFn = function() s.value = v end
				L(`StSet st#{s.id} -> {v and (v.k .. "#" .. v.id) or (useNone and "None" or "nil")}`)
			end
		elseif op <= 90 and not FLAGS.noss then
			opname = "SsSet"
			local sss = {}
			for _, r in ipairs(recs) do if r.k == "ss" and not r.destroyed then table.insert(sss, r) end end
			if #sss == 0 then opname = "Noop"; qfn = function() end; modelFn = function() end
			else
				local s = pick(sss)
				local rr = math.random(10)
				local v, useNone = nil, false
				if rr <= (if FLAGS.ssheavy then 5 else 6) then v = pick(TAGS) elseif rr <= 8 then v = nil else useNone = true end
				qfn = function() s.src:Set(if v then v elseif useNone then q.None else nil) end
				modelFn = function()
					s.data = v
					if s.activated then
						if mounted and inRootTree(s) then addCalls(s, ssTransition(s)) else s.pending = true end
					end
				end
				L(`SsSet ss#{s.id} -> {v or (useNone and "None" or "nil")} pol={s.policy}`)
			end
		elseif op <= 93 and not FLAGS.nomount then
			opname = "Toggle"
			qfn = function() holder:Set(if mounted then nil else root.obj) end
			modelFn = function() mounted = not mounted end
			L(`Toggle -> {not mounted}`)
		elseif op <= 96 and not FLAGS.nodispose then
			opname = "Dispose"
			local leaves, mss2, _, sss = freeSets()
			local cands = {}
			for _, x in leaves do table.insert(cands, x) end
			for _, x in mss2 do table.insert(cands, x) end
			for _, x in sss do table.insert(cands, x) end
			if #cands == 0 then opname = "Noop"; qfn = function() end; modelFn = function() end
			else
				local x = pick(cands)
				qfn = function() q.dispose(x.obj) end
				modelFn = function() disposeRec(x) end
				L(`Dispose {x.k}#{x.id}`)
			end
		elseif not FLAGS.noerr then
			-- defined-error ops: the call must raise with its ID and change nothing
			local h = holders()
			local rr = math.random(6)
			modelFn = function() end
			if rr == 1 then
				opname = "ErrHeld"
				local c = {}
				for _, r in ipairs(recs) do if r.k == "leaf" and r.alive and h[r.obj] and not (h[r.obj].kind == "ms" and h[r.obj].rec == t) then table.insert(c, r) end end
				if #c == 0 then opname = "Noop"; qfn = function() end
				else
					local x = pick(c)
					local hx = h[x.obj]
					-- quad seeds "already in this Slot" from each wrapper's CURRENT State value, not the claimed occupant
					local viaOwnWrapper = hx.kind == "st" and parentOf(hx.rec) == t and hx.rec.value == x
					qfn = function() t.obj:Add(x.obj) end
					errExpected = if viaOwnWrapper then "Quad0170" else "Quad0172"
					L(`ErrHeld ms#{t.id} add leaf#{x.id}`)
				end
			elseif rr == 2 then
				opname = "ErrCycle"
				local top = topOf(t)
				if top == root or top.k ~= "ms" then
					opname = "ErrCycleSelf"
					if t == root and mounted then qfn = function() t.obj:Add(t.obj) end; errExpected = "Quad0172"
					elseif h[t.obj] then qfn = function() t.obj:Add(t.obj) end; errExpected = "Quad0172"
					else qfn = function() t.obj:Add(t.obj) end; errExpected = "Quad0173" end
				else
					-- does the t -> top path cross a State link whose wrapper has not claimed its occupant?
					local cur, viaST = t, false
					while cur ~= top do
						local p = parentOf(cur)
						if p.k == "st" and (not p.activated or p.recon ~= p.value) then viaST = true end
						cur = p
					end
					if viaST then opname = "ErrCycleViaST" end
					qfn = function() t.obj:Add(top.obj) end
					-- a top still claimed by a pending wrapper (value moved on while unmounted) trips the owner gate first
					errExpected = if h[top.obj] then "Quad0172" else "Quad0173"
				end
				L(`{opname} ms#{t.id}`)
			elseif rr == 3 then
				opname = "ErrDup"
				local x = freshLeaf()
				qfn = function() t.obj:Splice(1, 0, x.obj, x.obj) end; errExpected = "Quad0171"
				L(`ErrDup ms#{t.id}`)
			elseif rr == 4 and n > 0 then
				opname = "ErrReplaceSelf"
				local i = idx()
				local e = t.elems[i]
				if e.k == "st" and (e.value == nil or not e.activated) then opname = "Noop"; qfn = function() end
				else qfn = function() t.obj:Replace(i, t.obj:Get(i)) end; errExpected = "Quad0170"; L(`ErrReplaceSelf ms#{t.id} {i}`) end
			elseif rr == 5 then
				opname = "ErrNil"
				local useNone = math.random(2) == 1
				qfn = function() t.obj:Add(if useNone then q.None else nil) end; errExpected = "Quad0239"
				L(`ErrNil ms#{t.id}`)
			else
				opname = "ErrDisposeHeld"
				local c = {}
				for _, r in ipairs(recs) do if ((r.k == "leaf" and r.alive) or (r.k == "ms" and not r.destroyed)) and h[r.obj] then table.insert(c, r) end end
				if #c == 0 then opname = "Noop"; qfn = function() end
				else local x = pick(c); qfn = function() q.dispose(x.obj) end; errExpected = "Quad0179"; L(`ErrDisposeHeld {x.k}#{x.id}`) end
			end
		else
			opname = "Noop"; qfn = function() end; modelFn = function() end
		end
		local nBefore = #flatten(root)
		do local mx = 0; for _, r in ipairs(recs) do if (r.k == "ms" or r.k == "st" or r.k == "ss") and inRootTree(r) then mx = math.max(mx, depthOf(r)) end end; cov("maxdepth" .. mx) end
		cov("op-" .. opname .. (if mounted then "-M" else "-U") .. (if t ~= root then "-nested" else ""))
		if VERBOSE == seed then
			local function desc(r)
				if r.k == "leaf" then return nm(r.obj) end
				if r.k == "ms" then local t = {}; for _, e in ipairs(r.elems) do table.insert(t, desc(e)) end; return `ms{r.id}[` .. table.concat(t, " ") .. "]" end
				if r.k == "st" then return `st{r.id}(` .. (r.recon and desc(r.recon) or "-") .. ")" end
				if r.k == "ss" then return `ss{r.id}<{r.owns and "own" or "noown"} {r.el and nm(r.el.obj) or "-"}{r.det and ("/det " .. nm(r.det.obj)) or ""}>` end
				return "?"
			end
			print("   tree:", (if mounted then "M " else "U ") .. desc(root))
		end
		local ok, err = pcall(qfn)
		local errGot = if ok then nil else tostring(err)
		if ok or errExpected == nil then modelFn() end
		if ok or errExpected ~= nil then sync() end
		bindCreations()
		compare(opname, errExpected, errGot)
		for _, c in ipairs(creations) do c.pendingBind = nil end
		-- perf
		local pc = q._pc
		local pl = PERF[opname]; if not pl then pl = {}; PERF[opname] = pl end
		table.insert(pl, { nBefore, pc.getOffsetAt, pc.getOffsetIters, pc.reindexIters, pc.recompute, pc.recomputeIters, pc.spliceArr, mounted and 1 or 0, t == root and 1 or 0 })
		if not mismatch then notifCheck(opname, before) end
		if VERBOSE == seed then print(`  [{step}] {log[#log] or opname} err={errGot or "-"} mm={mismatch or "-"}`) end
		if mismatch then return { seed = seed, step = step, op = opname, mm = mismatch, log = log } end
	end
	return { seed = seed, step = steps, mm = nil, log = log }
end

for sd = FROM, FROM + COUNT - 1 do
	local ok, res = pcall(run, sd)
	if not ok then
		print(`R {sd} HARNESS-ERROR {string.gsub(tostring(res), "%s+", "_")}`)
	elseif res.mm then
		print(`R {sd} MM step={res.step} op={res.op} {res.mm}`)
		if VERBOSE == sd then for i, l in ipairs(res.log) do print(`   {i}: {l}`) end end
	else
		print(`R {sd} ok steps={res.step}`)
	end
end
print(`T transient-stale-occupant-materializations {TRANSIENT}`)
for k, v in COV do print(`C {k} {v}`) end
for key, t in NOTIF do print(`N {key} steps={t.steps} changed={t.changed} over={t.over} transient={t.transient} maxn={t.maxn}`) end
for opname, pl in PERF do
	for _, row in ipairs(pl) do print(`P {opname} {table.concat(row, " ")}`) end
end
