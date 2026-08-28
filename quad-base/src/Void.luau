--[[
	Void — the single no-op function quad exports.
	`.claude/base/architecture.md` source tree `Void.luau` line / `H-162`.

	Every place that would otherwise hand out a fresh `function() end`
	(handler retractors, cleanup slots, ...) returns this one value instead.
	Dependency-free leaf on purpose: `Dispatch/init.luau` (M3) binds it at
	file scope, so defining it on the top-level `init.luau` would be a
	circular require.
]]

local function Void(...: any) end

return Void
