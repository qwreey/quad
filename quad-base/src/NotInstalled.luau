--[[
	`notInstalled(name, what, hint?)` — the loud stub a quad-base module puts on
	its public surface for an op a backend has to install (`Tag.luau` tag ops,
	`Attribute/Key.luau` attribute op, `LifetimeHandle.luau` lifetime primitives
	/ engine ops). One factory for the three byte-identical copies
	(post-implementation review Q3 ②, user-approved 2026-09-07 — "raw*에서도
	했던 행위"). Message shape is the one the specs match on
	(`"<name> is not available"`).

	errorBefore (outermost), not Nearest: these stubs are reached from dispatch
	depth (handler process) AND from quad internals (`Observer.luau` `Subscribe`
	→ `canBound`, `Slot/Elements.luau` → `isInst`); the stub tags ITSELF (`H-231`), so
	"nearest" would always be the stub's direct caller and blame quad internals
	(`H-272` reasoning, restored by 3순회 `H-378` after `H-370`/`H-373`).
	Outermost reaches the user's line from both; what it does not serve is a
	USER CALLBACK running inside a tagged public method — §4 Q7 (untagged stubs).
	`H-231`: the stubs sit on the public surface until a backend overwrites them
	(the backend tags its own replacements via `Quad.errorNamespace`).
]]

local QuadTypes = require("../luau_packages/quad_types")
local Err = require("./ErrorNamespace")

local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

local function notInstalled(name: string, what: string, hint: string?): (...any) -> ...any
	local stub = function(...: any)
		Err.errorBefore(
			`quad: {name} is not available — no backend has installed {what} `
				.. `(install a provider with quad:UseProvider — a bare Quad.New() has none{hint or ""})`,
			SURFACE
		)
	end
	Err.setFuncLevel(stub, SURFACE)
	return stub
end

return notInstalled
