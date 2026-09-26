--[[
	P3 — Compute propagation. Run: luau .claude/audit/perf-cli-2026-09-26/p3-compute.luau
	(run from repo root; relative require climbs 3 levels back to repo root then into quad-base/test).

	Measures, for a single Source at the root of a Compute chain of depth d,
	fanned out to f Observers (each bound to a live mock Instance so they
	actually fire instead of being held, and each Gets the leaf inside its
	callback — otherwise Compute stays lazy and nothing recomputes, which a
	first pass of this probe actually caught): on one root `:Set`, how many
	Compute recompute calls happen and how many Observer fires happen.
	Also a diamond case (one source -> two computes -> one join compute) to
	check the join recomputes once, not twice.

	Counting and timing are kept SEPARATE — timing repeats the `:Set` call
	3x for a median, and if that reused the same counters the counts would
	be inflated 3x (caught in a first draft of this probe: fires came out as
	exactly 3x the observer count for every depth). Each timing sample gets
	its own fresh Source/Compute/Observer graph.

	Counts only — this is CLI mock arithmetic, not a frame-time claim.
]]

local mock = require("../../../quad-base/test/mock")
local q = mock.newQuad()
local Source = q.Source
local Instance = mock.Instance

local collectgarbage = (_G :: any).collectgarbage :: (...any) -> any

local function median(xs: { number }): number
	table.sort(xs)
	return xs[math.ceil(#xs / 2)]
end

-- Build a linear chain of Computes of the given depth on top of `src`.
-- Each node's fn is instrumented to bump `recomputes.value`.
local function buildChain(src: any, depth: number, recomputes: { value: number })
	local node = src
	for _ = 1, depth do
		local this = node
		node = this:Compute(function(x: any)
			recomputes.value += 1
			return (x:Get() :: number) + 1
		end)
	end
	return node
end

-- Attach `count` Observers to `node`, each bound to a fresh live mock
-- Instance so canExecute is true and the observer actually fires (not held),
-- and each forces the recompute by Getting the target inside the callback
-- (an Observer install alone does not force a lazy Compute to run — see
-- header note).
local function attachObservers(node: any, count: number, fires: { value: number })
	local insts = {}
	for i = 1, count do
		local o = node:Observer(function(target: any)
			fires.value += 1
			target:Get()
		end)
		local inst = Instance.new("Frame")
		q.Backend.bindLifetime(inst, o)
		insts[i] = inst
	end
	return insts
end

local function buildGraph(d: number, f: number)
	local src = Source(0)
	local recomputes = { value = 0 }
	local leaf = buildChain(src, d, recomputes)
	local fires = { value = 0 }
	local insts = attachObservers(leaf, f, fires)
	-- reset AFTER install (install fires once per Observer, forcing the
	-- chain to run once — that is not what we are measuring)
	recomputes.value = 0
	fires.value = 0
	return src, leaf, recomputes, fires, insts
end

print("=== P3a: depth d, fanout f — recomputes/notifications for ONE root :Set (counting run) ===")
print(string.format("%-6s %-6s %-14s %-14s", "d", "f", "recomputes", "fires"))
for _, d in ipairs({ 1, 10, 50 }) do
	for _, f in ipairs({ 1, 10, 100 }) do
		local src, _leaf, recomputes, fires, insts = buildGraph(d, f)
		src:Set(1)
		print(string.format("%-6d %-6d %-14d %-14d", d, f, recomputes.value, fires.value))
		for _, inst in ipairs(insts) do
			inst:Destroy()
		end
	end
end

print()
print("=== P3a-time: same shapes, wall time for ONE root :Set, median of 3 FRESH graphs, + GC delta of one fresh build ===")
print(string.format("%-6s %-6s %-14s %-12s", "d", "f", "t(median,3x)", "gcΔ(build,KB)"))
for _, d in ipairs({ 1, 10, 50 }) do
	for _, f in ipairs({ 1, 10, 100 }) do
		local samples = {}
		for _ = 1, 3 do
			local src, _leaf, _recomputes, _fires, insts = buildGraph(d, f)
			local t0 = os.clock()
			src:Set(1)
			table.insert(samples, os.clock() - t0)
			for _, inst in ipairs(insts) do
				inst:Destroy()
			end
		end
		collectgarbage("collect")
		local gc0 = collectgarbage("count")
		local _src2, _leaf2, _r2, _f2, insts2 = buildGraph(d, f)
		local gc1 = collectgarbage("count")
		for _, inst in ipairs(insts2) do
			inst:Destroy()
		end
		print(string.format("%-6d %-6d %-14.6f %-12.1f", d, f, median(samples), gc1 - gc0))
	end
end

print()
print("=== P3b: diamond — one source -> two computes -> one join compute, join recomputes once? ===")
do
	local src = Source(0)
	local aRuns, bRuns, joinRuns = 0, 0, 0
	local a = src:Compute(function(x: any)
		aRuns += 1
		return (x:Get() :: number) + 1
	end)
	local b = src:Compute(function(x: any)
		bRuns += 1
		return (x:Get() :: number) + 2
	end)
	local join = a:Compute(function(_self: any, _prev: any, bb: any)
		joinRuns += 1
		return (a:Get() :: number) + (bb:Get() :: number)
	end, b)
	local fires = { value = 0 }
	local o = join:Observer(function(target: any)
		fires.value += 1
		target:Get()
	end)
	local inst = Instance.new("Frame")
	q.Backend.bindLifetime(inst, o)
	aRuns, bRuns, joinRuns, fires.value = 0, 0, 0, 0
	src:Set(5)
	print(string.format("aRuns=%d bRuns=%d joinRuns=%d fires=%d (join:Get()=%d, expected %d)", aRuns, bRuns, joinRuns, fires.value, join:Get(), 5 + 1 + 5 + 2))
end

print()
print("=== P3c: fanout-only sanity (d=1), wall time trend for ONE :Set, fresh graph per f ===")
print(string.format("%-8s %-10s", "f", "t(one :Set)"))
for _, f in ipairs({ 1, 100, 1000 }) do
	local src, _leaf, _recomputes, _fires, insts = buildGraph(1, f)
	local t0 = os.clock()
	src:Set(1)
	local t = os.clock() - t0
	print(string.format("%-8d %-10.6f", f, t))
	for _, inst in ipairs(insts) do
		inst:Destroy()
	end
end

print()
print("DONE")
