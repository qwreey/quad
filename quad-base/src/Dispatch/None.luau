--[[
	The `None` sentinel + its two handlers (`.claude/base/dispatch-core-plan.md`
	"`None` 센티널" / "`NilHandler`" sections, as-is; M3 unit 3).

	`None` is a real value meaning "explicitly nothing" (`modifier-plan.md`
	2-1): ordered arrays (`flattened`, `bk.sourceList`) stay hole-free with it —
	`nil` would be indistinguishable from "not filled yet". `isNone` is
	`v == None` (identity — no Brand, `Brand.luau` header). Frozen so nothing
	can mutate the shared sentinel; the metatable names it for diagnostics.
	The top-level `init.luau` re-exports the value (`H-233` — the value itself
	arrived one unit early for `setOffsetSource`).

	Handlers (registered per module instance by `InitDispatch` — quad-base
	fills its own registry, "base가 소유하는 핸들러" 절의 자기 등록 원칙):
	  - `NoneHandler` — recursion ONLY: matches `v == None` anywhere (array or
	    hash — `drive` has no None skip branch) and hands `nil` down with
	    `index + 1`. The real cleanup lives in one place (`NilHandler` /
	    whatever handler owns the hash key), and the descending diff already
	    retracts a previous occupant when the handler changes, so its retractor
	    is the shared no-op `Void`.
	  - `NilHandler` — the terminal pair: matches real `nil` at NUMBER keys only
	    (`State<Slot|nil>` must work without forcing `None`; hash-key `nil`
	    belongs to that key's own handler). Mounts nothing — it registers the
	    position out of the order math: `setOffsetSource(inst, k, None)` →
	    `setLength(inst, k, 0)` (release-order contract: offsetSource first so a
	    dying subtree's Source is out of recompute's reach before the recompute
	    that setLength's tail triggers). `H-39`: terminal handlers register
	    without exception — this one IS that registration. Constant length →
	    no `element` argument (Q3: no persistent closure to look anything up).
]]

local Void = require("../Void")
local QuadTypes = require("../../luau_packages/quad_types")

-- `H-300` (a, 사용자 확정 2026-09-02): the sentinel carries one MARKER field so
-- its TYPE becomes structurally expressible (`QuadTypes.None` — the generated
-- `D` prop/children unions need it; an empty table type would match every
-- table; "marker" on purpose — NOT a `Brand.luau` Brand, which this value
-- deliberately has none of). Runtime judgement is STILL identity (`v == None`) — the field is
-- advisory typing only, and freezing keeps it untouchable.
-- One constructor for every frozen marker sentinel (`None`, `ProcessedModifier`,
-- `ProcessedPreRef`/`PostRef`): the H-300 marker field `__quad<Name> = true`
-- plus a `__tostring` — kept in one place so the sentinel convention cannot
-- drift between copies (review, M8 ③).
local function sentinel(name: string): any
	return table.freeze(setmetatable({ ["__quad" .. name] = true :: true }, {
		__tostring = function()
			return name
		end,
	}))
end

local None = sentinel("None")

local module = { None = None, sentinel = sentinel }

-- The terminal "empty slot" registration (offsetSource FIRST, then length 0)
-- used to live here as `registerEmptySlot`; since the post-implementation
-- review Q3 ③ (2026-09-07) it is `dispatch.setEmpty` (Bookkeeping) — on the
-- Dispatch surface so quad-roblox handlers share the one body too.

-- The `Processed*` nop terminal (ProcessedModifier / ProcessedPreRef /
-- ProcessedPostRef — `modifier-plan.md` `H-35` block, `ref-plan.md` canon):
-- matches the sentinel by identity anywhere (it only ever sits at array
-- positions), registers the position out of the order math and retracts
-- with `Void` — flatten / the pre-pass fire already happened, nothing to
-- undo. One factory for the three (Q3 ⑤ — `Dispatch/Modifier.luau` was a
-- third hand copy of `Dispatch/Ref.luau`'s local `addProcessed`).
function module.addProcessedHandler(dispatch: QuadTypes.Dispatch, name: string, sent: any)
	dispatch.addHandler({
		name = name,
		isHandlable = function(_inst: any, _k: any, v: any): boolean
			return v == sent
		end,
		priority = dispatch.HANDLER_PRIORITY_HIGH, -- "매우 높음, NoneHandler와 동급"
		process = function(inst: any, k: any, _v: any, _index: number): (any?, boolean) -> ()
			dispatch.setEmpty(inst, k, inst) -- canon block: offsetSource → length 0 (`H-35`)
			return Void
		end,
	})
end

-- Called by InitDispatch once per module instance, after the Dispatch table
-- is assembled — the handlers close over that instance's dispatch (the
-- factory pattern, `H-174`). addHandler tags the received functions into the
-- shared error namespace itself.
-- `H-259`: typed against the shared contract — the only two production
-- handlers must not be the only untyped ones (the drift hole `H-227` closed).
function module.register(dispatch: QuadTypes.Dispatch)
	dispatch.addHandler({
		name = "NoneHandler",
		-- the sentinel itself — real nil can't come out of a table traversal;
		-- reactive nil is NilHandler's (array) or the key's own handler's (hash)
		isHandlable = function(_inst: any, _k: any, v: any): boolean
			return v == None
		end,
		priority = dispatch.HANDLER_PRIORITY_HIGH,
		process = function(inst: any, k: any, _v: any, index: number): (any?, boolean) -> ()
			-- recursion only — once we pass nil the sentinel no longer exists,
			-- and the next priority scan narrows naturally (same shape as
			-- StoreBind's realv recursion; same no-infinite-loop argument).
			dispatch.process(inst, k, nil, index + 1)
			return Void
		end,
	})
	dispatch.addHandler({
		name = "NilHandler",
		isHandlable = function(_inst: any, k: any, v: any): boolean
			return type(k) == "number" and v == nil
		end,
		priority = dispatch.HANDLER_PRIORITY_HIGH,
		process = function(inst: any, k: any, _v: any, _index: number): (any?, boolean) -> ()
			-- no recursion — already nil, nothing further to hand down
			dispatch.setEmpty(inst, k)
			return Void
		end,
	})
end

return module
