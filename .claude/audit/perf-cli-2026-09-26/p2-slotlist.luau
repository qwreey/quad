--[[
	P2 — Slot:List updates. Run: luau .claude/audit/perf-cli-2026-09-26/p2-slotlist.luau
	(run from repo root; relative require climbs 3 levels back to repo root then into quad-base/test).

	For N in {100, 1000, 5000}, builds a mounted Slot:List of N keyed items,
	then applies one mutation (end insert / front insert / middle delete /
	full reverse / full replace) and counts:
	  - updateFn calls (this reconcile invokes updateFn once per item in the
	    NEW array unconditionally, every reconcile — that is instrumented
	    directly, no wrapping needed)
	  - mock backend native* calls (nativeInsert/nativeExtract/nativeRemove/
	    nativeMove/nativeSwap/nativeDispose), wrapped on q.Backend
	  - wall time, median of 3 FRESH builds (counts and time are measured on
	    SEPARATE builds, same reasoning as p3-compute.luau: reusing counters
	    across repeated timing runs would inflate them)

	Counts only — this is CLI mock arithmetic, not a frame-time claim.
]]

local mock = require("../../../quad-base/test/mock")
local Instance = mock.Instance

local collectgarbage = (_G :: any).collectgarbage :: (...any) -> any

local function median(xs: { number }): number
	table.sort(xs)
	return xs[math.ceil(#xs / 2)]
end

-- one fresh quad + mounted Slot:List of N items (keys 1..N, stringified).
-- Returns everything needed to apply one mutation and read counters.
local function buildList(n: number)
	local q = mock.newQuad()
	local Slot, dispatch, Source = q.Slot, q.Dispatch, q.Source

	local nativeCalls = { insert = 0, extract = 0, remove = 0, move = 0, swap = 0, dispose = 0 }
	local backend = q.Backend
	local origInsert, origExtract, origRemove, origMove, origSwap, origDispose =
		backend.nativeInsert, backend.nativeExtract, backend.nativeRemove, backend.nativeMove, backend.nativeSwap, backend.nativeDispose
	backend.nativeInsert = function(...)
		nativeCalls.insert += 1
		return origInsert(...)
	end
	backend.nativeExtract = function(...)
		nativeCalls.extract += 1
		return origExtract(...)
	end
	backend.nativeRemove = function(...)
		nativeCalls.remove += 1
		return origRemove(...)
	end
	backend.nativeMove = function(...)
		nativeCalls.move += 1
		return origMove(...)
	end
	backend.nativeSwap = function(...)
		nativeCalls.swap += 1
		return origSwap(...)
	end
	backend.nativeDispose = function(...)
		nativeCalls.dispose += 1
		return origDispose(...)
	end

	local initial = table.create(n)
	for i = 1, n do
		initial[i] = { id = "k" .. i }
	end
	local data = Source(initial)
	local updateCalls = { value = 0 }
	local slot = Slot()
	slot:List(data, function(ctx: any)
		local item, prev = ctx.Item, ctx.Prev
		updateCalls.value += 1
		if item == q.KeyGone then
			return nil
		end
		if prev then
			return prev
		end
		local f = Instance.new("Frame")
		f.Name = item.id
		return f
	end, function(item: any)
		return item.id
	end)
	local parent = Instance.new("Folder")
	dispatch.drive(parent, { slot })

	-- reset AFTER initial mount (that reconcile pass is the build cost, not
	-- the mutation we are about to measure)
	for k in pairs(nativeCalls) do
		nativeCalls[k] = 0
	end
	updateCalls.value = 0

	return { q = q, data = data, slot = slot, parent = parent, initial = initial, nativeCalls = nativeCalls, updateCalls = updateCalls }
end

local function cloneArr(arr: { any })
	local out = table.create(#arr)
	for i, v in ipairs(arr) do
		out[i] = v
	end
	return out
end

local ops: { { name: string, mutate: (initial: { any }, n: number) -> { any } } } = {
	{
		name = "end-insert-1",
		mutate = function(initial, n)
			local out = cloneArr(initial)
			table.insert(out, { id = "new-end" })
			return out
		end,
	},
	{
		name = "front-insert-1",
		mutate = function(initial, n)
			local out = table.create(n + 1)
			out[1] = { id = "new-front" }
			for i, v in ipairs(initial) do
				out[i + 1] = v
			end
			return out
		end,
	},
	{
		name = "middle-delete-1",
		mutate = function(initial, n)
			local out = table.create(n - 1)
			local mid = math.floor(n / 2)
			local w = 1
			for i, v in ipairs(initial) do
				if i ~= mid then
					out[w] = v
					w += 1
				end
			end
			return out
		end,
	},
	{
		name = "full-reverse",
		mutate = function(initial, n)
			local out = table.create(n)
			for i = 1, n do
				out[i] = initial[n - i + 1]
			end
			return out
		end,
	},
	{
		name = "full-replace",
		mutate = function(_initial, n)
			local out = table.create(n)
			for i = 1, n do
				out[i] = { id = "r" .. i }
			end
			return out
		end,
	},
}

print("=== P2: Slot:List one mutation on N items — updateFn calls / native* calls (counting run) ===")
print(string.format("%-16s %-6s %-10s %-8s %-8s %-8s %-8s %-8s %-8s", "op", "N", "updateFn", "insert", "extract", "remove", "move", "swap", "dispose"))
for _, n in ipairs({ 100, 1000, 5000 }) do
	for _, op in ipairs(ops) do
		local built = buildList(n)
		local newData = op.mutate(built.initial, n)
		built.data:Set(newData)
		local nc = built.nativeCalls
		print(string.format("%-16s %-6d %-10d %-8d %-8d %-8d %-8d %-8d %-8d", op.name, n, built.updateCalls.value, nc.insert, nc.extract, nc.remove, nc.move, nc.swap, nc.dispose))
	end
end

print()
print("=== P2-time: same shapes, wall time for ONE mutation, median of 3 FRESH builds, + GC delta of one fresh mutation ===")
print(string.format("%-16s %-6s %-10s %-12s", "op", "N", "t(median,3x)", "gcΔ(KB)"))
for _, n in ipairs({ 100, 1000, 5000 }) do
	for _, op in ipairs(ops) do
		local samples = {}
		for _ = 1, 3 do
			local built = buildList(n)
			local newData = op.mutate(built.initial, n)
			local t0 = os.clock()
			built.data:Set(newData)
			table.insert(samples, os.clock() - t0)
		end
		local builtGc = buildList(n)
		local newDataGc = op.mutate(builtGc.initial, n)
		collectgarbage("collect")
		local gc0 = collectgarbage("count")
		builtGc.data:Set(newDataGc)
		local gc1 = collectgarbage("count")
		print(string.format("%-16s %-6d %-10.6f %-12.1f", op.name, n, median(samples), gc1 - gc0))
	end
end

print()
print("=== P2-nested: list-in-list (outer N items, position 1 is itself a Slot:List with 10 items, positions 2..N are plain leaves that FOLLOW it) — inner insert 1 ===")
print(string.format("%-8s %-20s %-14s", "outerN", "getOffsetAt calls", "t(one inner insert)"))

local function buildNested(outerN: number)
	local q = mock.newQuad()
	local Slot, dispatch, Source = q.Slot, q.Dispatch, q.Source

	local offsetCalls = { value = 0 }
	local origGetOffsetAt = q.Bookkeeping.getOffsetAt
	q.Bookkeeping.getOffsetAt = function(...)
		offsetCalls.value += 1
		return origGetOffsetAt(...)
	end

	local inner = Slot()
	local innerData = Source((function()
		local t = {}
		for i = 1, 10 do
			t[i] = { id = "i" .. i }
		end
		return t
	end)())
	inner:List(innerData, function(ctx: any)
		local item, prev = ctx.Item, ctx.Prev
		if item == q.KeyGone then
			return nil
		end
		if prev then
			return prev
		end
		return Instance.new("Frame")
	end, function(item: any)
		return item.id
	end)

	-- outer list: position 1 is the nested Slot itself, positions 2..outerN
	-- are plain leaf items that FOLLOW it (so their physical offset depends
	-- on the nested Slot's Length).
	local outerItems = {}
	outerItems[1] = { id = "nested" }
	for i = 2, outerN do
		outerItems[i] = { id = "leaf" .. i }
	end
	local outerData = Source(outerItems)
	local outer = Slot()
	outer:List(outerData, function(ctx: any)
		local item, prev = ctx.Item, ctx.Prev
		if item == q.KeyGone then
			return nil
		end
		if item.id == "nested" then
			return prev or inner
		end
		if prev then
			return prev
		end
		return Instance.new("Frame")
	end, function(item: any)
		return item.id
	end)

	local parent = Instance.new("Folder")
	dispatch.drive(parent, { outer })

	offsetCalls.value = 0
	return { innerData = innerData, offsetCalls = offsetCalls }
end

local function mutateInner(innerData: any)
	local newInner = {}
	for i = 1, 10 do
		newInner[i] = { id = "i" .. i }
	end
	newInner[11] = { id = "i-new" }
	innerData:Set(newInner)
end

for _, outerN in ipairs({ 10, 100, 1000, 5000 }) do
	-- counting run (own fresh build)
	local built = buildNested(outerN)
	mutateInner(built.innerData)
	local offsetCallCount = built.offsetCalls.value

	-- timing runs — separate fresh builds, same reasoning as P2/P3 above
	local samples = {}
	for _ = 1, 3 do
		local b = buildNested(outerN)
		local t0 = os.clock()
		mutateInner(b.innerData)
		table.insert(samples, os.clock() - t0)
	end

	print(string.format("%-8d %-20d %-14.6f", outerN, offsetCallCount, median(samples)))
end

print()
print("DONE")
