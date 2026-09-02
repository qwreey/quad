--[[
	quad-roblox package entry. `QuadRoblox(quad)` version-checks the injected
	quad-base instance at compile time (`CheckedQuad<T, Pattern>`,
	`quad-types` — the monorepo pins the exact version "0.0.0"; independently
	published backends would pick a looser pattern) and hands it to
	RobloxFactory for backend installation.

	Runtime dependency is quad-types only — the module instance arrives as an
	argument, so quad-base is never required here (round14 Q3 (a); tests use
	it as a dev dependency instead).

	Later M5 units extend this export table (`D`, `Claim`).
]]

local QuadTypes = require("./luau_packages/quad_types")
local RobloxFactory = require("@self/RobloxFactory")

local function QuadRoblox<T>(quad: T): T
	-- virtual-field version check — referencing the field is what evaluates it
	local checked: QuadTypes.CheckedQuad<T, "0.0.0"> = quad :: any
	local _forceCheck = checked.__versionCheck
	-- surface tag so raises below blame the caller's line (`H-238`)
	;(quad :: any).errorNamespace.setFuncLevel(QuadRoblox, QuadTypes.ERROR_LEVEL_SURFACE)
	return RobloxFactory(quad :: any) :: any
end

return {
	QuadRoblox = QuadRoblox,
}
