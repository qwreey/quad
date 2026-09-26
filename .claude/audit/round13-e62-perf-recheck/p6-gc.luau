--[[
	P6 — GC residue after disposing a bulk-mounted tree. Run:
	luau .claude/audit/perf-cli-2026-09-26/p6-gc.luau (from repo root — same
	require depth/reasoning as p1-mount.luau: quad-roblox's OWN `Quad.New()` +
	`:UseProvider(QuadRoblox)`, mock only for Instance/gameShim plumbing).

	Builds the SAME two shapes as P1 (static `D.Frame { D.TextLabel {...} x N }`
	and `Slot:List` of N TextLabels), takes a baseline `collectgarbage("count")`,
	builds, `q.dispose(root)` (an Instance -> `Backend.nativeDispose` ->
	`root:Destroy()`, which the mock cascades to every descendant — header of
	`quad-base/test/mock.luau`'s Destroy: "Destroying 발화 -> Parent = nil ->
	자손 Destroy"), then `collectgarbage("collect")` TWICE and reads the count
	delta against the baseline (not against the post-build peak — the question
	is "did we get back to where we started", per
	`research/perf-measurement-plan.md` P6).

	Reused from `audit/tween-completed-2026-09-21/gc-probe.luau`'s idiom:
	weak-value tables holding the things we want to ask "still alive?" about
	AFTER the destroy+collect, since a plain local variable would itself keep
	them alive (own-upvalue caveat noted in that file's `mkCallbacks`).

	Three residue checks per scenario, all live-code observation (no source
	edited):
	  1. root + a SAMPLE of children (first 3, middle 1, last 1 — not all N,
	     to keep this file's own weak table from being the thing measured)
	     via `setmetatable({}, {__mode="v"})`.
	  2. (list shape only) `data._subs` — the `Source` behind `Slot:List`'s
	     data — is a plain field (`Source.luau`: "weak-key: subscribers"), so
	     reading `#`-by-`pairs` after collect answers "did the Slot's internal
	     Observer actually unsubscribe, or is it still parked in `_subs`
	     waiting for ITS OWN key to also die" directly, per
	     `perf-measurement-plan.md` P6's `_subs` question.
	  3. Bookkeeping owner residue: `q.Bookkeeping.getBookkeeping` is wrapped to
	     remember every OWNER it was ever called for, in a WEAK-KEY-ONLY set
	     (`{__mode = "k"}`, no value beyond `true`) — after collect, counting
	     that set's surviving entries answers "is this owner still pinned by
	     something, independent of `Bookkeeping.luau`'s own (also ownerKey-weak)
	     registry". A first draft used a weak-VALUE `owner -> bk` map instead
	     (to also inspect the bk table's shape) and that map's plain STRONG
	     keys were themselves keeping `root`/`slot` alive — this file's own
	     instrumentation manufacturing the exact "still alive" result it was
	     trying to observe. Left in as a documented mistake because it is the
	     kind of thing this whole probe is checking FOR in the actual source.

	Counts only, `os.clock()` not used here (this file measures memory, not
	time — P1 already has the time table for these same two shapes).
]]

local Quad = require("../../../quad-roblox/luau_packages/quad_base")
local QuadRobloxModule = require("../../../quad-roblox/src")
local QuadRoblox = QuadRobloxModule.QuadRoblox
local installProperty = require("../../../quad-roblox/src/Handlers/Property")
local installEvent = require("../../../quad-roblox/src/Handlers/Event")
local mock = require("../../../quad-base/test/mock")

local collectgarbage = (_G :: any).collectgarbage :: (...any) -> any

local W = { Write = "" }
local REFLECTED: { [string]: { any } } = {
	Frame = { { Name = "Name", Permits = W }, { Name = "Size", Permits = W } },
	TextLabel = { { Name = "Text", Permits = W }, { Name = "Name", Permits = W } },
}

local function newSetup()
	local gameShim = mock.gameShim(REFLECTED)
	local q: any = Quad.New()
	q:UseProvider(QuadRoblox)
	;(getfenv(installProperty) :: any).game = gameShim
	;(getfenv(installEvent) :: any).game = gameShim
	;(getfenv(q.Declaration.New) :: any).Instance = { new = mock.Instance.new }
	q.Backend.isInst = mock.isMockInstance

	-- weak-key set of owners `getBookkeeping` has ever allocated a bk for.
	-- `getBookkeeping` is the one chokepoint every `setLength`/`setOffsetSource`/
	-- `recompute` call goes through, so wrapping it here sees every owner this
	-- build ever registers, without touching `Bookkeeping.luau`. MUST be
	-- weak-key-only (`__mode = "k"`, no value stored beyond `true`) — a first
	-- draft also kept a weak-VALUE `owner -> bk` map to inspect the bk table
	-- itself, and that map's STRONG keys (the owners) turned out to be exactly
	-- what made `root`/`slot` look leaked below: the instrumentation itself
	-- was the retention. This file's own `newSetup()` result (`s`) is dropped
	-- (goes out of scope) once each scenario's iteration ends, same as `weak`.
	local bkOwners = setmetatable({}, { __mode = "k" }) :: { [any]: true }
	local origGetBookkeeping = q.Bookkeeping.getBookkeeping
	q.Bookkeeping.getBookkeeping = function(ownerKey: any, ...)
		bkOwners[ownerKey] = true
		return origGetBookkeeping(ownerKey, ...)
	end

	return { q = q, bkOwners = bkOwners }
end

local PROP_NAMES = { "Text" }

local function buildStatic(s: any, n: number)
	local q = s.q
	local D = q.Declaration
	local children = table.create(n)
	local weak = setmetatable({}, { __mode = "v" }) :: { [string]: any }
	for i = 1, n do
		local child = D.TextLabel({ Text = "item" .. i })
		children[i] = child
		if i <= 3 or i == math.floor(n / 2) or i == n then
			weak["child" .. i] = child
		end
	end
	local root = D.Frame(children)
	weak.root = root
	return root, weak, nil
end

local function buildList(s: any, n: number)
	local q = s.q
	local D = q.Declaration
	local Slot = q.Slot
	local items = table.create(n)
	for i = 1, n do
		items[i] = { id = "k" .. i }
	end
	local data = q.Source(items)
	local slot = Slot()
	slot:List(data, function(ctx: any)
		local item, prev = ctx.Item, ctx.Prev
		if item == q.KeyGone then
			return nil
		end
		if prev then
			return prev
		end
		return D.TextLabel({ Text = item.id })
	end, function(item: any)
		return item.id
	end)
	local root = D.Frame({ slot })
	local weak = setmetatable({}, { __mode = "v" }) :: { [string]: any }
	weak.root = root
	weak.slot = slot
	weak.data = data
	return root, weak, data
end

local function gcFull()
	for _ = 1, 5 do
		collectgarbage("collect")
	end
end

local function countAlive(weak: { [string]: any }): { string }
	local left = {}
	for k in pairs(weak) do
		table.insert(left, k)
	end
	table.sort(left)
	return left
end

local function countBkOwnersAlive(s: any): number
	local n = 0
	for _ in pairs(s.bkOwners) do
		n += 1
	end
	return n
end

local Ns = { 100, 1000, 5000 }

print("=== P6: dispose a bulk-mounted tree, collectgarbage x2, compare against a pre-build baseline ===")
print(string.format("%-8s %-6s %-12s %-12s %-12s %-10s %-8s %-30s", "shape", "N", "baseKB", "peakKB", "afterKB", "residKB", "bkLeft", "weak refs still alive"))
for _, shape in ipairs({ "static", "list" }) do
	for _, n in ipairs(Ns) do
		local s = newSetup()
		collectgarbage("collect")
		local baseKB = collectgarbage("count")

		local root, weak, data
		if shape == "static" then
			root, weak = buildStatic(s, n)
		else
			root, weak, data = buildList(s, n)
		end
		collectgarbage("collect")
		local peakKB = collectgarbage("count")

		local subsBeforeDestroy = 0
		if data ~= nil then
			for _ in pairs((data :: any)._subs) do
				subsBeforeDestroy += 1
			end
		end

		s.q.dispose(root)
		-- drop EVERY strong local this file itself holds — `weak`'s own values
		-- are the only thing we still ask about below. First-draft bug caught
		-- here: leaving `data` in this local slot (to reread `_subs` after gc)
		-- IS itself a strong GC root that would keep the Source alive forever,
		-- indistinguishable from a real leak — the exact "own upvalue" caveat
		-- `gc-probe.luau`'s header already warns about, just missed once.
		root, weak, data = nil :: any, weak, nil :: any
		gcFull()
		local afterKB = collectgarbage("count")

		local aliveKeys = countAlive(weak)
		local bkLeft = countBkOwnersAlive(s)

		local subsAfter: number? = nil
		local aliveData = weak.data
		if aliveData ~= nil then
			subsAfter = 0
			for _ in pairs((aliveData :: any)._subs) do
				subsAfter = (subsAfter :: number) + 1
			end
		end

		print(string.format(
			"%-8s %-6d %-12.1f %-12.1f %-12.1f %-10.1f %-8d %-30s",
			shape,
			n,
			baseKB,
			peakKB,
			afterKB,
			afterKB - baseKB,
			bkLeft,
			if #aliveKeys == 0 then "(none)" else table.concat(aliveKeys, ",")
		))
		if shape == "list" then
			print(string.format(
				"%-8s %-6s Source._subs: before-destroy=%d after-destroy+gc=%s",
				shape,
				"N=" .. n,
				subsBeforeDestroy,
				if subsAfter == nil then "n/a (Source itself was collected)" else tostring(subsAfter)
			))
		end
	end
end
