--!strict
--[[
	The stories' own setup module — what a game that consumes the kit has (quad docs getting-started/01-setup).
	The stories are a consumer of the kit, not part of it: they reach the kit only through the kit's root export table
	(`require("../src")`) and reach quad through this module, like the gallery does with `gallery/Quad.luau`.
	(A separate module rather than reusing the gallery's: each consumer folder stands on its own, as two games would.)
	`UseProvider` is idempotent for the same provider and returns the same singleton, so this `q` IS the kit's `q`
	(States and Modifiers mix freely between the two).

	These requires point at the in-repo workspace copies, like the kit's `src/Quad.luau`; a game uses its package
	paths (e.g. `@game/ReplicatedStorage/Packages/quad_base`). Only the types the stories name are re-exported.
]]

local Quad = require("../../quad-roblox/luau_packages/quad_base")
local RobloxModule = require("../../quad-roblox/src")
local QuadTypes = require("../../quad-roblox/luau_packages/quad_types")

local q = Quad:UseProvider(RobloxModule.QuadRoblox)

export type State<T> = QuadTypes.State<T>
export type Source<T> = QuadTypes.Source<T>
export type StateData<T> = QuadTypes.StateData<T>
export type Slot<T> = QuadTypes.Slot<T>
export type Effect = QuadTypes.Effect

-- typed surface (quad-roblox module root)
export type Modifier<C> = RobloxModule.Modifier<C>
export type ModifierInto<C> = RobloxModule.ModifierInto<C>
export type Spread<C> = RobloxModule.Spread<C>
export type SpreadInto<C> = RobloxModule.SpreadInto<C>
export type Props<C> = RobloxModule.Props<C>
export type ElemCtor<C> = RobloxModule.ElemCtor<C>
export type OnChangeDescriptor<K> = RobloxModule.OnChangeDescriptor<K>
export type OnEventDescriptor<K> = RobloxModule.OnEventDescriptor<K>

return q
