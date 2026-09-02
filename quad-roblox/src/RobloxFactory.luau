--[[
	RobloxFactory(module) — mutates a quad-base module instance into the
	Roblox backend: installs the lifetime primitives + `nativeClaim`
	(LifetimeHandle.luau) and the M5 engine ops (EngineOps.luau).

	Guard is the `_initializedBy` string marker — a PUBLIC one-slot contract
	distinct from quad-base's internal `RunInit` idempotence
	(`base/module-lifecycle-plan.md`): calling the same factory again is a
	no-op, a different factory having filled the slot is an error (a module
	cannot serve two backends).
]]

local QuadTypes = require("../luau_packages/quad_types")
local installLifetime = require("./LifetimeHandle")
local installEngineOps = require("./EngineOps")

local function RobloxFactory(module: any): any
	-- tag before any raise below — without the surface tag the error walker
	-- falls back to the raise site and blames this file (`H-238`)
	module.errorNamespace.setFuncLevel(RobloxFactory, QuadTypes.ERROR_LEVEL_SURFACE)
	if module._initializedBy == "roblox" then
		return module -- same factory called again = no-op
	end
	if module._initializedBy ~= nil then
		-- errorBefore (outermost surface) so both direct calls and the
		-- QuadRoblox entry blame the user's line (`H-272` precedent)
		module.errorNamespace.errorBefore(
			`Quad module already initialized by '{module._initializedBy}'`,
			QuadTypes.ERROR_LEVEL_SURFACE
		)
	end
	module._initializedBy = "roblox"

	installLifetime(module)
	installEngineOps(module)
	return module
end

return RobloxFactory
