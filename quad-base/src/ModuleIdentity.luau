--!strict
--[[
	ModuleIdentity.luau — the cross-instance guard (2026-09-15 user decision, public surface (12)).

	Every quad module instance carries `moduleIdentity`, an EMPTY table made in `New()` — an identity
	token that holds nothing (no back-reference to the module, so nothing it is stored on keeps the
	module alive). Each subsystem that owns a per-instance implementation stores the token where its
	shape makes that cheapest (the per-instance Impl/metatable read through `__index` for Observer,
	EffectHandle, State/Source and Slot — zero per-value slots) and compares it at the doors where a
	value can arrive from another instance. Values from shared leaf modules (Ref, Blocker, …) have no
	owning instance and are not guarded — mixing those stays documented UB.

	Why guard at all (user): mixing is the user's mistake, not the provider's, and it fails silently —
	lifetime registries are per instance, so another instance's handle bound here is never executable
	there (no error, just nothing runs), which is fatal to debug. One field + one comparison is cheap.
]]

local QuadTypes = require("../luau_packages/quad_types")
local Err = require("./ErrorNamespace")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

local ModuleIdentity = {}

local function message(what: string): string
	return `{what}: this value was made by another quad module instance (a second quad_base copy, or q.New()) — values cannot cross instances`
end

-- dispatch depth (handlers): outermost, like the other handler raises (`H-272`)
function ModuleIdentity.assertOwnAtDispatch(module: any, value: any, what: string)
	if value._moduleIdentity ~= module.moduleIdentity then
		Err.errorBefore(message(what), SURFACE)
	end
end

-- direct public call (e.g. `slot:List(data)`): nearest surface frame's caller
function ModuleIdentity.assertOwnAtCall(module: any, value: any, what: string)
	if value._moduleIdentity ~= module.moduleIdentity then
		Err.errorBeforeNearest(message(what), SURFACE)
	end
end

return ModuleIdentity
