--!strict
--[[
	The kit's setup module — the same shape the quad docs recommend for a game (getting-started/01-setup):
	install the Roblox provider once on the shared quad-base singleton and re-export the types the kit uses.
	`UseProvider` is idempotent for the same provider, so a game that already ran its own setup module on the
	SAME install copy shares this instance (States mix freely between the game and the kit).

	These three requires are the ONLY place that knows where quad lives. In-repo they point at the
	workspace copies the quad-roblox specs use; a consumer project replaces them with its package paths
	(e.g. `@game/ReplicatedStorage/Packages/quad_base`).
]]

local Quad = require("../../quad-roblox/luau_packages/quad_base")
local RobloxModule = require("../../quad-roblox/src")
local QuadTypes = require("../../quad-roblox/luau_packages/quad_types")

local q = Quad:UseProvider(RobloxModule.QuadRoblox)

-- core value types (quad-types)
export type State<T> = QuadTypes.State<T>
export type Source<T> = QuadTypes.Source<T>
export type StateData<T> = QuadTypes.StateData<T>
export type Slot<T> = QuadTypes.Slot<T>
export type SlotItem<T> = QuadTypes.SlotItem<T>
export type Ref<T> = QuadTypes.Ref<T>
export type PreRef<T> = QuadTypes.PreRef<T>
export type PostRef<T> = QuadTypes.PostRef<T>
export type Observer = QuadTypes.Observer
export type Effect = QuadTypes.Effect
export type Store<T> = QuadTypes.Store<T>
export type Context = QuadTypes.Context
export type Provider<T> = QuadTypes.Provider<T>
export type KeyGone = QuadTypes.KeyGone

-- typed surface (quad-roblox module root): one generic per axis, the class is the type argument
export type Modifier<C> = RobloxModule.Modifier<C>
export type ModifierInto<C> = RobloxModule.ModifierInto<C>
export type Spread<C> = RobloxModule.Spread<C>
export type SpreadInto<C> = RobloxModule.SpreadInto<C>
export type Props<C> = RobloxModule.Props<C>
export type ElemCtor<C> = RobloxModule.ElemCtor<C>
export type OnChangeDescriptor<K> = RobloxModule.OnChangeDescriptor<K>
export type OnEventDescriptor<K> = RobloxModule.OnEventDescriptor<K>
export type ModifierField<T> = RobloxModule.ModifierField<T>
export type ModifierFieldOut<T> = RobloxModule.ModifierFieldOut<T>
export type Tween<T> = RobloxModule.Tween<T>
export type TweenOptions<T> = RobloxModule.TweenOptions<T>
export type AnimateInfo = RobloxModule.AnimateInfo

return q
