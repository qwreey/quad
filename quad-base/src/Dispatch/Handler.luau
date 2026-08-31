--[[
	Handler — the handler contract, types only. `.claude/base/dispatch-core-plan.md`
	"핸들러 계약" section, as-is:

	  isHandlable(inst, key, value) -> boolean  -- pure, fast predicate (no side
	                                            -- effects; validation happens
	                                            -- *after* selection, inside process)
	  priority: number                          -- open numeric space; use the
	                                            -- HANDLER_PRIORITY_* band constants
	                                            -- (`Dispatch/init.luau`) ± offsets
	  process(inst, key, value, index) -> retractor
	     -- does the work and returns the 1-arg closure that undoes exactly what
	     -- this call did. Returning nil is a contract violation (Dispatch errors
	     -- immediately); return `Void` when there is nothing to undo (`H-162`).
	     -- The retractor's argument is either nil (plain retract) or a new value
	     -- this same handler is about to process — nothing else can arrive
	     -- (descending diff, "Dispatch 체인" section).

	This file is a leaf on purpose: concrete handlers and `Dispatch/init.luau`
	both depend on it, never the other way around ("Dispatch는 프리미티브가
	아니다" — the dependency is one-way). The type itself is owned by
	`quad-types` (so `Quad.Dispatch.addHandler` and backends share it) and only
	re-exported here.
]]

local QuadTypes = require("../../roblox_packages/quad_types")

export type Handler = QuadTypes.Handler

return {}
