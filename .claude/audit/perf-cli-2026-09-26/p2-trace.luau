--!nocheck
--[[
	P2-trace — cause of the near-quadratic Slot:List full-reverse / full-replace
	and of the nested-Slot linear slowdown (perf-cli-2026-09-26 REPORT follow-up).
	Run from repo root:  ./scripts/relink.sh && luau .claude/audit/perf-cli-2026-09-26/p2-trace.luau

	NO source changes. Instrumentation is purely runtime:
	  (a) Bookkeeping surface functions are wrapped on q.Bookkeeping (Slot reaches
	      them through `S.BK.<fn>` at call time, so the wrap is seen):
	      getOffsetAt (scan = how far the prefix-cache cursor advanced),
	      _recompute  (scan = bk.N loop length at entry), setLength, setOffsetSource.
	      Time is SELF time (a stack subtracts nested wrapped calls).
	  (b) Slot/Raw.luau's reindexFrom / reindexRange / spliceArraysUp/Down /
	      rotateInPlace are file-local, so they cannot be wrapped. Instead the
	      Slot's bookkeeping tables (bk.indexOfElement / lengthList / sourceList /
	      observers / offsetCache) are swapped for counting proxies after mount,
	      and every write is attributed to the WRITING function by
	      debug.info(2, "n") — that is a per-function scan count.
	  (c) Backend native* are wrapped (mock cost, self time).
	Counting runs (proxied, slow) and timing runs (no proxies, only the cheap
	wraps of (a)/(c)) are SEPARATE fresh builds.
]]

local mock = require("../../../quad-base/test/mock")
local Instance = mock.Instance
local clock = os.clock

-- ── instrumentation ──────────────────────────────────────────────────────
local function newStats()
	return { calls = {}, scan = {}, self = {}, writes = {} }
end

local function bump(t, k, v)
	t[k] = (t[k] or 0) + v
end

-- self-time stack across all wrapped functions
local function instrument(q, stats, withTime: boolean)
	local BK = q.Bookkeeping
	local origGetBk = BK.getBookkeeping
	local stack = {} -- child time accumulators
	local function wrap(tbl, name, scanFn)
		local orig = tbl[name]
		tbl[name] = function(...)
			bump(stats.calls, name, 1)
			local pre = scanFn and scanFn("pre", ...)
			local t0 = withTime and clock() or 0
			table.insert(stack, 0)
			local r = table.pack(orig(...))
			local child = table.remove(stack)
			if withTime then
				local dt = clock() - t0
				bump(stats.self, name, dt - child)
				if #stack > 0 then stack[#stack] += dt end
			end
			if scanFn then
				local sc = scanFn("post", pre, ...)
				bump(stats.scan, name, sc)
				if name == "getOffsetAt" then -- split the cursor advance by CALLER (reconcile vs rawMove vs rawAdd …)
					bump(stats.writes, "getOffsetAt cursor-advance, caller " .. (debug.info(2, "n") or "?"), sc)
				end
			end
			return table.unpack(r, 1, r.n)
		end
	end
	wrap(BK, "getOffsetAt", function(phase, a, b, c)
		if phase == "pre" then
			local bk = origGetBk(a)
			return { bk = bk, before = bk.offsetCacheValidUpTo }
		end
		local pre = a
		local adv = pre.bk.offsetCacheValidUpTo - pre.before
		return adv > 0 and adv or 0
	end)
	wrap(BK, "_recompute", function(phase, a, b)
		if phase == "pre" then return (b.N or 0) end
		return a
	end)
	wrap(BK, "setLength")
	wrap(BK, "setOffsetSource")
	for _, n in ipairs({ "nativeInsert", "nativeExtract", "nativeRemove", "nativeMove", "nativeSwap", "nativeDispose" }) do
		wrap(q.Backend, n)
	end
	return origGetBk
end

-- counting proxies on one owner's bk tables; writes attributed to caller name
local PROXIED = { "indexOfElement", "lengthList", "sourceList", "observers", "offsetCache" }
local function proxyBk(bk, stats, countReads: boolean?)
	for _, field in ipairs(PROXIED) do
		local backing = bk[field]
		local mt = getmetatable(backing)
		local store = if mt and mt.__mode then setmetatable({}, { __mode = mt.__mode }) else {}
		for k, v in pairs(backing) do store[k] = v end
		bk[field] = setmetatable({}, {
			__index = if countReads then function(_, k)
				bump(stats.writes, "READ " .. field .. " by " .. (debug.info(2, "n") or "?"), 1)
				return store[k]
			end else store,
			__newindex = function(_, k, v)
				local who = debug.info(2, "n") or "?"
				bump(stats.writes, who .. " -> " .. field, 1)
				store[k] = v
			end,
			__iter = function() return next, store end,
		})
	end
end

-- ── P2 list build (same shape as p2-slotlist.luau) ─────────────────────
local function buildList(n, withTime, withProxy)
	local q = mock.newQuad()
	local Slot, dispatch, Source = q.Slot, q.Dispatch, q.Source
	local initial = table.create(n)
	for i = 1, n do initial[i] = { id = "k" .. i } end
	local data = Source(initial)
	local slot = Slot()
	slot:List(data, function(ctx)
		local item, prev = ctx.Item, ctx.Prev
		if item == q.KeyGone then return nil end
		if prev then return prev end
		local f = Instance.new("Frame")
		f.Name = item.id
		return f
	end, function(item) return item.id end)
	local parent = Instance.new("Folder")
	dispatch.drive(parent, { slot })
	local stats = newStats()
	local origGetBk = instrument(q, stats, withTime)
	if withProxy then proxyBk(origGetBk(slot), stats) end
	return { data = data, initial = initial, stats = stats }
end

local ops = {
	{ name = "front-insert-1", mutate = function(initial, n)
		local out = table.create(n + 1); out[1] = { id = "new-front" }
		for i, v in ipairs(initial) do out[i + 1] = v end
		return out
	end },
	{ name = "full-reverse", mutate = function(initial, n)
		local out = table.create(n)
		for i = 1, n do out[i] = initial[n - i + 1] end
		return out
	end },
	{ name = "full-replace", mutate = function(_, n)
		local out = table.create(n)
		for i = 1, n do out[i] = { id = "r" .. i } end
		return out
	end },
}

local function sortedKeys(t)
	local ks = {}
	for k in pairs(t) do table.insert(ks, k) end
	table.sort(ks, function(a, b) return t[a] > t[b] end)
	return ks
end

local NS = { 100, 1000, 5000 }
for _, op in ipairs(ops) do
	print(("=== %s — writes into bk tables by writing function (counting run, proxied) ==="):format(op.name))
	local rows, allKeys = {}, {}
	for _, n in ipairs(NS) do
		local b = buildList(n, false, true)
		b.data:Set(op.mutate(b.initial, n))
		rows[n] = b.stats
		for k in pairs(b.stats.writes) do allKeys[k] = true end
		for k in pairs(b.stats.scan) do allKeys["scan:" .. k] = true end
	end
	local merged = {}
	for k in pairs(allKeys) do
		local s = rows[NS[#NS]]
		merged[k] = if k:sub(1, 5) == "scan:" then (s.scan[k:sub(6)] or 0) else (s.writes[k] or 0)
	end
	print(("%-42s %12s %12s %14s %10s"):format("writer -> table  (scan: = wrapped fn)", "N=100", "N=1000", "N=5000", "/N² @5000"))
	for _, k in ipairs(sortedKeys(merged)) do
		local vals = {}
		for i, n in ipairs(NS) do
			local s = rows[n]
			vals[i] = if k:sub(1, 5) == "scan:" then (s.scan[k:sub(6)] or 0) else (s.writes[k] or 0)
		end
		print(("%-42s %12d %12d %14d %10.3f"):format(k, vals[1], vals[2], vals[3], vals[3] / (5000 * 5000)))
	end
	print(("%-42s %12s %12s %14s"):format("calls: getOffsetAt / _recompute", 
		rows[100].calls.getOffsetAt .. "/" .. (rows[100].calls._recompute or 0),
		rows[1000].calls.getOffsetAt .. "/" .. (rows[1000].calls._recompute or 0),
		rows[5000].calls.getOffsetAt .. "/" .. (rows[5000].calls._recompute or 0)))
	print()
end

print("=== timing runs (no proxies): SELF time of wrapped functions vs total — median-of-1, fresh build ===")
print(("%-14s %-5s %9s  %s"):format("op", "N", "total(s)", "self-time share of wrapped fns (rest = Slot internals: reindex*/splice*/rotate/table.insert|remove on _elements, List reconcile, updateFn)"))
for _, op in ipairs(ops) do
	for _, n in ipairs(NS) do
		local b = buildList(n, true, false)
		local nd = op.mutate(b.initial, n)
		local t0 = clock()
		b.data:Set(nd)
		local total = clock() - t0
		local parts, wrapped = {}, 0
		for _, k in ipairs(sortedKeys(b.stats.self)) do
			local v = b.stats.self[k]
			wrapped += v
			if v / total > 0.005 then table.insert(parts, ("%s %.1f%%"):format(k, 100 * v / total)) end
		end
		table.insert(parts, ("REST %.1f%%"):format(100 * (total - wrapped) / total))
		print(("%-14s %-5d %9.4f  %s"):format(op.name, n, total, table.concat(parts, ", ")))
	end
end
print()

-- ── micro: what one reindex write / one bk-array shift costs (to price REST) ─
do
	local M = 5000
	local els, idx = table.create(M), setmetatable({}, { __mode = "k" })
	for i = 1, M do els[i] = {} end
	local t0 = clock()
	local reps = 200
	for _ = 1, reps do for i = 1, M do idx[els[i]] = i end end
	local perWrite = (clock() - t0) / (reps * M)
	local arr = table.create(M, 0)
	t0 = clock()
	for _ = 1, reps do for i = M - 1, 1, -1 do arr[i + 1] = arr[i] end end
	local perShift = (clock() - t0) / (reps * M)
	print(("micro: one weak-key reindex write %.1f ns, one array-slot shift %.1f ns"):format(perWrite * 1e9, perShift * 1e9))
end
print()

-- ── nested: outer N, position 1 = inner Slot:List(10); inner insert 1 ─────
print("=== nested: inner insert 1 — per-owner scans (counting run) + time ===")
print(("%-7s %-26s %-26s %-22s %-10s %s"):format("outerN", "recompute calls in/out", "recompute scan in/out", "getOffsetAt adv in/out", "t(s)", "self-time shares"))
local function buildNested(outerN, withTime, withProxy)
	local q = mock.newQuad()
	local Slot, dispatch, Source = q.Slot, q.Dispatch, q.Source
	local inner = Slot()
	local it = {}
	for i = 1, 10 do it[i] = { id = "i" .. i } end
	local innerData = Source(it)
	inner:List(innerData, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		return ctx.Prev or Instance.new("Frame")
	end, function(item) return item.id end)
	local items = { { id = "nested" } }
	for i = 2, outerN do items[i] = { id = "leaf" .. i } end
	local outer = Slot()
	outer:List(Source(items), function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		if ctx.Item.id == "nested" then return ctx.Prev or inner end
		return ctx.Prev or Instance.new("Frame")
	end, function(item) return item.id end)
	dispatch.drive(Instance.new("Folder"), { outer })
	-- per-owner split: wrap again on top, tagging by owner
	local per = { [inner] = newStats(), [outer] = newStats() }
	local stats = newStats()
	local origGetBk = instrument(q, stats, withTime)
	local BK = q.Bookkeeping
	local g, r = BK.getOffsetAt, BK._recompute
	BK.getOffsetAt = function(owner, at)
		local s = per[owner]
		local bk = origGetBk(owner)
		local before = bk.offsetCacheValidUpTo
		local v = g(owner, at)
		if s then bump(s.calls, "gOA", 1); bump(s.scan, "gOA", math.max(0, bk.offsetCacheValidUpTo - before)) end
		return v
	end
	BK._recompute = function(owner, bk)
		local s = per[owner]
		if s then bump(s.calls, "rc", 1); bump(s.scan, "rc", bk.N or 0) end
		return r(owner, bk)
	end
	if withProxy then proxyBk(origGetBk(outer), per[outer], true); proxyBk(origGetBk(inner), per[inner], true) end
	return { innerData = innerData, per = per, inner = inner, outer = outer, stats = stats }
end
local function mutateInner(d)
	local t = {}
	for i = 1, 10 do t[i] = { id = "i" .. i } end
	t[11] = { id = "i-new" }
	d:Set(t)
end
for _, outerN in ipairs({ 10, 100, 1000, 5000 }) do
	local b = buildNested(outerN, false, true)
	mutateInner(b.innerData)
	local pi, po = b.per[b.inner], b.per[b.outer]
	local tb = buildNested(outerN, true, false)
	local t0 = clock()
	mutateInner(tb.innerData)
	local total = clock() - t0
	local parts, wrapped = {}, 0
	for _, k in ipairs(sortedKeys(tb.stats.self)) do
		wrapped += tb.stats.self[k]
		table.insert(parts, ("%s %.0f%%"):format(k, 100 * tb.stats.self[k] / total))
	end
	table.insert(parts, ("REST %.0f%%"):format(100 * (total - wrapped) / total))
	print(("%-7d %-26s %-26s %-22s %-10.6f %s"):format(outerN,
		(pi.calls.rc or 0) .. "/" .. (po.calls.rc or 0),
		(pi.scan.rc or 0) .. "/" .. (po.scan.rc or 0),
		(pi.scan.gOA or 0) .. "/" .. (po.scan.gOA or 0),
		total, table.concat(parts, ", ")))
	if outerN == 5000 or outerN == 1000 then
		print("  inner bk reads/writes by function (N=5000):")
		for _, k in ipairs(sortedKeys(pi.writes)) do print(("    %-40s %d"):format(k, pi.writes[k])) end
		print("  outer bk reads/writes by function (N=5000) — recompute here is Bookkeeping's LOCAL recompute reached via gatedRecompute, invisible to the BK._recompute wrap:")
		for _, k in ipairs(sortedKeys(po.writes)) do print(("    %-40s %d"):format(k, po.writes[k])) end
	end
end
print()
print("DONE")
