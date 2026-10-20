--!strict
--[[
	DebugPrint — the one channel the `q.debug` diagnostics of quad-base go out through. Every line carries the
	`[quad debug] ` prefix so it stands apart from the user's own prints in the Studio output, and switching the
	channel (to `warn`, say) is one edit here. quad-roblox is a separate package and keeps the same prefix in its
	own `Tween.luau` (its Tween/Animate lines). Specs and the kit harnesses capture `print`, so a channel change
	goes together with them. Diagnostics carry no error id (`base/error-id-plan.md`). Ref: H-915 Q190
]]

local PREFIX = "[quad debug] "

local function debugPrint(line: string)
	print(PREFIX .. line)
end

return debugPrint
