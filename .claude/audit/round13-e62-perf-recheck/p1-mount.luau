--[[
	P1 — Bulk mount. Run: luau .claude/audit/perf-cli-2026-09-26/p1-mount.luau
	(run from repo root; relative require climbs 3 levels back to repo root, then into
	quad-roblox/luau_packages + quad-roblox/src — this needs the REAL quad-roblox
	provider (Dispatch/Bookkeeping wiring, `D.<Class>` generated factories), not
	quad-base's own `mock.newQuad()`, so the setup mirrors
	`quad-roblox/test/spec.component.luau`: quad-roblox's OWN `Quad.New()` +
	`:UseProvider(QuadRoblox)`, getfenv(`game`/`Instance`/`Enum`) shims, and
	`q.Backend.isInst = mock.isMockInstance` — mock is only borrowed for its
	Instance/gameShim plumbing, never for the quad module instance itself
	(mixing quad-base/test/mock's own `Quad.New()` with quad-roblox's copy would be
	two different module instances — `UseProvider`'s one-slot/identity guard exists
	for exactly this).

	CLI mock arithmetic only — `os.clock()` is a 3-run median REFERENCE, not a
	frame-time claim (Studio is the only source of truth for frame time, `conventions.md`).

	Counters (all via monkey-patched fields on live `q.*` tables, reset between builds):
	  - Dispatch.process total calls (wrap `q.Dispatch.process` directly)
	  - per-handler-name process calls (wrap `q.Dispatch.addHandler` BEFORE
	    `:UseProvider(QuadRoblox)` runs — every Handlers/*.luau install call goes
	    through this one chokepoint, so wrapping it once here catches Property/
	    InstanceChild/Event/InstanceShorthand without editing source)
	  - Bookkeeping._recompute calls + sum of `bk.N` read at each call (the
	    "scan length" proxy — recompute is a documented full O(bk.N) pass every
	    time it runs, `Bookkeeping.luau`'s `recompute` function; `_recompute` is
	    a NAMED field on `q.Bookkeeping`, no proxy-table trick needed unlike
	    P2-trace's `Slot/Raw.luau` locals)
	  - Bookkeeping.getOffsetAt calls (separate from recompute's own internal
	    calls to it — this is the SAME counting concern P2-trace found expensive
	    under reordering; here there is none, so this is the baseline)
	  - Backend.nativeClaim calls (each `D.<Class>({...})` claims its own new
	    Instance exactly once — `quad-roblox/src/Declaration/init.luau:4962`)
	  - Backend.holdLifetime + quad-base's own `bindLifetime` calls. NOT Ref/Effect-
	    specific as first assumed — traced with a throwaway debug.info probe (not
	    kept): `Dispatch/init.luau`'s `process` lazily creates one retractor "list"
	    the FIRST time a given (inst, k) key is dispatched and anchors it with
	    exactly one `bindLifetime(inst, list)` call (the `H-229` GC-anchor comment
	    there) — so this counts ONE per distinct dispatched key, on every handler,
	    not just Ref/Effect. `Bookkeeping.luau` adds one more per owner that ever
	    gets a `bk` allocated (once for the root Frame here, never for a childless
	    leaf). `bindLifetime` itself calls `Backend.holdLifetime` once per call
	    (`LifetimeHandle.luau:165`), so hold count == bind count here — the sum
	    below double-counts that on purpose (one "GC-anchor events" figure).

	Known artifact: the "process" column below is always 0. `q.Dispatch.process`
	is a FIELD on the returned table, but `Dispatch/init.luau`'s internal call
	sites (the `drive` body loop, recursive continuations) call the closure's
	captured LOCAL `process`, not the table field — the same local-vs-field split
	`conventions.md`'s "하나의 무언가가 두 일을 하고 있지 않은지" note is about,
	just on a function reference instead of a value. Wrapping the field is a
	no-op for anything internal; it is kept in the table below only to show that
	0 explicitly rather than silently drop the column. The per-HANDLER counts
	(Property/InstanceChild) are real — those wrap `handler.process` on the
	handler object itself, which `Dispatch/init.luau` DOES call through (`h.process(...)`).

	First finding worth knowing BEFORE reading the table: `Dispatch.drive`
	(`quad-base/src/Dispatch/init.luau`, the "⓪ batch Blocker" block) already
	batches an ENTIRE array-part call (a `D.Frame { child1, ..., childN }`
	literal, or one `Slot:List` reconcile pass) under one Blocker window and
	calls `_recompute` EXACTLY ONCE at the end, regardless of N — so a naive
	"N children appended one at a time -> N full recompute passes -> O(N^2)"
	guess (the shape P2 found in `Slot/Raw.luau`'s reindex functions) does NOT
	apply here. Confirmed by counting below, not assumed.
]]

local Quad = require("../../../quad-roblox/luau_packages/quad_base")
local QuadRobloxModule = require("../../../quad-roblox/src")
local QuadRoblox = QuadRobloxModule.QuadRoblox
local installProperty = require("../../../quad-roblox/src/Handlers/Property")
local installEvent = require("../../../quad-roblox/src/Handlers/Event")
local mock = require("../../../quad-base/test/mock")
local Instance = mock.Instance

local collectgarbage = (_G :: any).collectgarbage :: (...any) -> any

local function median(xs: { number }): number
	table.sort(xs)
	return xs[math.ceil(#xs / 2)]
end

-- 10 plain (untyped-by-mock) TextLabel properties, sliced to `count` — the
-- mock does not validate property VALUES against real Roblox types, only
-- whether the (ClassName, Name) pair is in REFLECTED with a Write permit, so
-- arbitrary values are fine and keep the shim small (no Enum/UDim/Color3 needed).
local PROP_NAMES = { "Text", "Size", "Position", "BackgroundTransparency", "Visible", "ZIndex", "LayoutOrder", "ClipsDescendants", "AutomaticSize", "RichText" }
local W = { Write = "" }
local TEXTLABEL_REFLECTED = {}
for _, name in PROP_NAMES do
	table.insert(TEXTLABEL_REFLECTED, { Name = name, Permits = W })
end
table.insert(TEXTLABEL_REFLECTED, { Name = "Name", Permits = W })
local REFLECTED: { [string]: { any } } = {
	Frame = { { Name = "Name", Permits = W }, { Name = "Size", Permits = W } },
	TextLabel = TEXTLABEL_REFLECTED,
}

-- One fresh quad-roblox module instance, wired exactly like spec.component.luau,
-- plus the counters. `addHandler` is wrapped BEFORE `:UseProvider` runs (that
-- call is what triggers every Handlers/*.luau `dispatch.addHandler(...)`).
local function newSetup()
	local gameShim = mock.gameShim(REFLECTED)
	local q: any = Quad.New()

	-- Per-handler-name process counts, covering BOTH core handlers `Quad.New()`
	-- already registered before this function ever sees `q` (SlotHandler,
	-- NoneHandler, NilHandler, StoreBind's family — mutated in place through
	-- `listHandlers()`, which the doc on that function allows reading but warns
	-- against writing; this is instrumentation-only, delegates to the original
	-- body unchanged, and is never used outside this throwaway CLI probe) AND
	-- handlers the provider (`:UseProvider(QuadRoblox)`, called right after this)
	-- still has to register (Property/InstanceChild/Event/InstanceShorthand),
	-- via wrapping `addHandler` for anything added from here on.
	local handlerCalls: { [string]: number } = {}
	local function instrument(handler: any)
		local name = handler.name
		handlerCalls[name] = 0
		local origProcess = handler.process
		handler.process = function(...)
			handlerCalls[name] += 1
			return origProcess(...)
		end
	end
	for _, handler in q.Dispatch.listHandlers() do
		instrument(handler)
	end
	local origAddHandler = q.Dispatch.addHandler
	q.Dispatch.addHandler = function(handler: any)
		instrument(handler)
		return origAddHandler(handler)
	end

	q:UseProvider(QuadRoblox)
	;(getfenv(installProperty) :: any).game = gameShim
	;(getfenv(installProperty) :: any).TweenInfo = mock.tweenInfoShim
	;(getfenv(installProperty) :: any).Enum = { EasingStyle = { Quad = "Quad" }, EasingDirection = { Out = "Out" }, PlaybackState = { Completed = "Completed", Cancelled = "Cancelled" } }
	;(getfenv(installEvent) :: any).game = gameShim
	;(getfenv(q.Declaration.New) :: any).Instance = { new = mock.Instance.new }
	q.Backend.isInst = mock.isMockInstance

	local processTotal = { value = 0 }
	local origProcess = q.Dispatch.process
	q.Dispatch.process = function(...)
		processTotal.value += 1
		return origProcess(...)
	end

	local recomputeCalls = { value = 0 }
	local recomputeScanSum = { value = 0 }
	local origRecompute = q.Bookkeeping._recompute
	q.Bookkeeping._recompute = function(ownerKey: any, bk: any)
		recomputeCalls.value += 1
		recomputeScanSum.value += (bk.N or 0)
		return origRecompute(ownerKey, bk)
	end

	local getOffsetCalls = { value = 0 }
	local origGetOffsetAt = q.Bookkeeping.getOffsetAt
	q.Bookkeeping.getOffsetAt = function(...)
		getOffsetCalls.value += 1
		return origGetOffsetAt(...)
	end

	local claimCalls = { value = 0 }
	local origNativeClaim = q.Backend.nativeClaim
	q.Backend.nativeClaim = function(...)
		claimCalls.value += 1
		return origNativeClaim(...)
	end

	local holdCalls = { value = 0 }
	local origHoldLifetime = q.Backend.holdLifetime
	q.Backend.holdLifetime = function(...)
		holdCalls.value += 1
		return origHoldLifetime(...)
	end
	local bindCalls = { value = 0 }
	local origBindLifetime = q.Backend.bindLifetime
	q.Backend.bindLifetime = function(...)
		bindCalls.value += 1
		return origBindLifetime(...)
	end

	return {
		q = q,
		handlerCalls = handlerCalls,
		processTotal = processTotal,
		recomputeCalls = recomputeCalls,
		recomputeScanSum = recomputeScanSum,
		getOffsetCalls = getOffsetCalls,
		claimCalls = claimCalls,
		holdCalls = holdCalls,
		bindCalls = bindCalls,
	}
end

local function resetCounters(s: any)
	for k in pairs(s.handlerCalls) do
		s.handlerCalls[k] = 0
	end
	s.processTotal.value = 0
	s.recomputeCalls.value = 0
	s.recomputeScanSum.value = 0
	s.getOffsetCalls.value = 0
	s.claimCalls.value = 0
	s.holdCalls.value = 0
	s.bindCalls.value = 0
end

-- Static: `D.Frame { D.TextLabel {...} x n }` built and returned in ONE call
-- (the array part is the n children — "한 번에 만들어 뿌리에 붙일 때").
local function buildStatic(s: any, n: number, propsPerItem: number)
	local q = s.q
	local D = q.Declaration
	local children = table.create(n)
	for i = 1, n do
		local props: { [string]: any } = {}
		for p = 1, propsPerItem do
			props[PROP_NAMES[p]] = if PROP_NAMES[p] == "Text" then "item" .. i else i
		end
		children[i] = D.TextLabel(props)
	end
	return D.Frame(children)
end

-- Slot:List: same n TextLabels (1 property, Text), built through a keyed
-- reconcile instead of a positional array literal, then mounted as the
-- Frame's single child (position 1 IS the Slot).
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
	return D.Frame({ slot })
end

local Ns = { 100, 1000, 5000 }

print("=== P1-count: static `D.Frame { D.TextLabel {...} x N }`, 1 property/item — one counting build per N ===")
print(string.format("%-6s %-10s %-10s %-14s %-14s %-10s %-10s %-8s %-8s", "N", "process", "Property", "InstChild", "recompute", "scanSum", "getOffset", "claim", "hold+bind"))
for _, n in ipairs(Ns) do
	local s = newSetup()
	buildStatic(s, n, 1)
	print(string.format(
		"%-6d %-10d %-10d %-14d %-14d %-10d %-10d %-8d %-8d",
		n,
		s.processTotal.value,
		s.handlerCalls.Property or 0,
		s.handlerCalls.InstanceChild or 0,
		s.recomputeCalls.value,
		s.recomputeScanSum.value,
		s.getOffsetCalls.value,
		s.claimCalls.value,
		s.holdCalls.value + s.bindCalls.value
	))
end

print()
print("=== P1-count-list: `Slot:List` building the SAME N TextLabels (1 property/item), mounted as the Frame's one child ===")
print(string.format("%-6s %-10s %-10s %-14s %-14s %-10s %-10s %-8s %-8s", "N", "process", "Property", "SlotHandler", "recompute", "scanSum", "getOffset", "claim", "hold+bind"))
for _, n in ipairs(Ns) do
	local s = newSetup()
	buildList(s, n)
	print(string.format(
		"%-6d %-10d %-10d %-14d %-14d %-10d %-10d %-8d %-8d",
		n,
		s.processTotal.value,
		s.handlerCalls.Property or 0,
		s.handlerCalls.SlotHandler or 0,
		s.recomputeCalls.value,
		s.recomputeScanSum.value,
		s.getOffsetCalls.value,
		s.claimCalls.value,
		s.holdCalls.value + s.bindCalls.value
	))
end

print()
print("=== P1-props: static, N=1000 fixed, properties/item varied — Property.process call count and per-item marginal cost ===")
print(string.format("%-16s %-10s %-10s %-12s %-12s", "propsPerItem", "process", "Property", "t(median,3x)", "gcΔ(KB)"))
for _, propsPerItem in ipairs({ 1, 5, 10 }) do
	local sCount = newSetup()
	buildStatic(sCount, 1000, propsPerItem)
	local samples = {}
	for _ = 1, 3 do
		local s = newSetup()
		local t0 = os.clock()
		buildStatic(s, 1000, propsPerItem)
		table.insert(samples, os.clock() - t0)
	end
	local sGc = newSetup()
	collectgarbage("collect")
	local gc0 = collectgarbage("count")
	buildStatic(sGc, 1000, propsPerItem)
	local gc1 = collectgarbage("count")
	print(string.format("%-16d %-10d %-10d %-12.6f %-12.1f", propsPerItem, sCount.processTotal.value, sCount.handlerCalls.Property or 0, median(samples), gc1 - gc0))
end

print()
print("=== P1-time: static vs Slot:List, same N, 1 property/item — wall time (median of 3 FRESH builds) + gcΔ (1 fresh build) ===")
print(string.format("%-8s %-8s %-12s %-12s", "shape", "N", "t(median,3x)", "gcΔ(KB)"))
for _, n in ipairs(Ns) do
	for _, shape in ipairs({ "static", "list" }) do
		local samples = {}
		for _ = 1, 3 do
			local s = newSetup()
			local t0 = os.clock()
			if shape == "static" then
				buildStatic(s, n, 1)
			else
				buildList(s, n)
			end
			table.insert(samples, os.clock() - t0)
		end
		local sGc = newSetup()
		collectgarbage("collect")
		local gc0 = collectgarbage("count")
		if shape == "static" then
			buildStatic(sGc, n, 1)
		else
			buildList(sGc, n)
		end
		local gc1 = collectgarbage("count")
		print(string.format("%-8s %-8d %-12.6f %-12.1f", shape, n, median(samples), gc1 - gc0))
	end
end
