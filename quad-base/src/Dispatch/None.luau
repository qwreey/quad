--[[
	The `None` sentinel — a real value that means "explicitly nothing"
	(`.claude/base/dispatch-core-plan.md` "`None` 센티널" section,
	`.claude/base/modifier-plan.md` 2-1). It exists so ordered arrays
	(`flattened`, `bk.sourceList`) can stay hole-free — `nil` would be
	indistinguishable from "not filled yet" and would break the array part.
	`isNone` is `v == None` (identity — no Brand, `Brand.luau` header).

	Definition lives here next to its handlers (`slot-plan.md`): the
	`NoneHandler`/`NilHandler` pair joins this file in M3 unit 3; unit 2
	already needs the sentinel value itself (`setOffsetSource`'s "no publish
	channel" marker). The top-level `init.luau` re-exports the value.

	Frozen so no code can accidentally mutate the shared sentinel; the
	metatable gives diagnostics a readable name.
]]

local None = table.freeze(setmetatable({}, {
	__tostring = function()
		return "None"
	end,
}))

return None
