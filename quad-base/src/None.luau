--!strict
--[[
	The `None` sentinel + its handler (`.claude/base/dispatch-core-plan.md`
	"`None` 센티널" section, as-is; M3 unit 3).

	`None` is a real value meaning "explicitly nothing" (`modifier-plan.md`
	2-1): ordered arrays (`flattened`, `bk.sourceList`) stay hole-free with it —
	`nil` would be indistinguishable from "not filled yet". `isNone` is
	`v == None` (identity — no Brand, `Brand.luau` header). Frozen so nothing
	can mutate the shared sentinel; the metatable names it for diagnostics.
	The top-level `init.luau` re-exports the value (`H-233` — the value itself
	arrived one unit early for `setOffsetSource`).

	[2026-10-01 user decision] a top-level module beside `Void.luau` (옛 `Dispatch/None.luau`):
	None is a value, so its handler is registered by THIS module's `Init` — the `H-278`
	rule ("각 객체를 아는 곳은 각 객체가 선언된 곳"; Effect.luau/Observer.luau shape:
	pull `InitDispatch` via `RunInit`, then `addHandler`). The user: *"Dispatch 가 코어
	객체들을 아는 방향이 되지 않아야하니까"*. What stays in Dispatch: `NilHandler` (a
	number-key real `nil` is an empty seat, not an object — the drive's own terminal) and
	the `Processed*` nop terminals.

	  - `NoneHandler` — recursion ONLY: matches `v == None` anywhere (array or
	    hash — `drive` has no None skip branch) and hands `nil` down with
	    `index + 1`. The real cleanup lives in one place (`NilHandler` at a
	    number key / whatever handler owns the hash key), and the descending diff
	    already retracts a previous occupant when the handler changes, so its
	    retractor is the shared no-op `Void`.

	The frozen marker-sentinel constructor (`sentinel`) is NOT here: the `Processed*`
	sentinels in `Dispatch/` need it and this module requires `Dispatch` for its
	registration, so it sits in the Dispatch leaf `Dispatch/Handler.luau` (no cycle).
]]

local Void = require("./Void")
local InitDispatch = require("./Dispatch")
local sentinel = require("./Dispatch/Handler").sentinel
local QuadTypes = require("../luau_packages/quad_types")

-- `H-300` (a, 사용자 확정 2026-09-02): the sentinel carries one MARKER field so
-- its TYPE becomes structurally expressible (`QuadTypes.None` —
-- the backend prop/children unions need it; an empty table type would match every
-- table; "marker" on purpose — NOT a `Brand.luau` Brand, which this value
-- deliberately has none of). Runtime judgement is STILL identity (`v == None`) — the field is
-- advisory typing only, and freezing keeps it untouchable.
local None = sentinel("None")

-- Called once per module instance (top-level `init.luau` — `module:RunInit(None.Init)`).
-- The handler closes over that instance's dispatch (the factory pattern, `H-174`);
-- addHandler tags the received functions into the shared error namespace itself.
local function Init(module: any)
	module:RunInit(InitDispatch) -- idempotent pull (the `H-174` idiom)
	local dispatch: QuadTypes.Dispatch = module.Dispatch
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
			-- StateHandler's realv recursion; same no-infinite-loop argument).
			dispatch.process(inst, k, nil, index + 1)
			return Void
		end,
	})
end

return { None = None, Init = Init }
