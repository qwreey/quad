--!strict
--[[
	Handler — the handler contract (types) + the shared frozen marker-sentinel
	constructor. `.claude/base/dispatch-core-plan.md` "핸들러 계약" section, as-is:

	  isHandlable(inst, key, value) -> boolean  -- pure, fast predicate (no side
	                                            -- effects; validation happens
	                                            -- *after* selection, inside process)
	  priority: number                          -- open numeric space; use the
	                                            -- HANDLER_PRIORITY_* band constants
	                                            -- (`Dispatch/init.luau`) ± offsets
	  keyType: ("number" | "string")?           -- optional (`H-484`, round7 Q37 (a)):
	                                            -- the only key type this handler can
	                                            -- match — getHandler scans per-type
	                                            -- buckets; absent = every bucket.
	                                            -- isHandlable stays the decider.
	  debugOnly: boolean?                       -- optional (round13 Q135, 2026-10-01): true =
	                                            -- a candidate only on scans where
	                                            -- `module.debug` is on (read per scan);
	                                            -- its isHandlable may print a diagnostic
	                                            -- — the one exception to "no side effects".
	  process(inst, key, value, index) -> retractor
	     -- does the work and returns the closure `(nextValue, retracting)` that
	     -- undoes exactly what this call did. Returning nil is a contract
	     -- violation (Dispatch errors immediately); return `Void` when there is
	     -- nothing to undo (`H-162`).
	     -- `nextValue` is either nil (plain retract) or a new value this same
	     -- handler is about to process — nothing else can arrive (descending
	     -- diff, "Dispatch 체인" section). `retracting` (`H-258`, 2026-09-01 —
	     -- the closure was 1-arg before that) is true on a plain retract and
	     -- false when the same handler reprocesses `nextValue` right after.

	This file is a leaf on purpose: concrete handlers and `Dispatch/init.luau`
	both depend on it, never the other way around ("Dispatch는 프리미티브가
	아니다" — the dependency is one-way). The type itself is owned by
	`quad-types` (so `Quad.Dispatch.addHandler` and backends share it) and only
	re-exported here.

	`sentinel(name)` (2026-10-01 — moved here from 옛 `Dispatch/None.luau` when `None`
	became a top-level value module that requires Dispatch): the one constructor for
	every frozen marker sentinel — `None` (top-level `None.luau`), the drive's own
	`ProcessedModifier` (`Dispatch/Modifier/init.luau`) / `ProcessedPreRef`·`PostRef`
	(`Dispatch/RefPrePass.luau`), Slot's `Detach`/`KeyGone` and Claim's `MapperRoot`. It must sit in a leaf both sides can require: `None.luau` →
	`Dispatch/init.luau` → `Dispatch/RefPrePass.luau` would otherwise loop back to `None.luau`.
]]

local QuadTypes = require("../../luau_packages/quad_types")

export type Handler = QuadTypes.Handler

-- `H-300` (a): the sentinel carries one MARKER field `__quad<Name> = true` so its
-- TYPE is structurally expressible, plus a `__tostring` — kept in one place so the
-- sentinel convention cannot drift between copies (review, M8 ③). Runtime judgement
-- is identity (`v == sentinel`); freezing keeps the shared value untouchable.
local function sentinel(name: string): any
	return table.freeze(setmetatable({ ["__quad" .. name] = true :: true }, {
		__tostring = function()
			return name
		end,
	}))
end

return { sentinel = sentinel }
