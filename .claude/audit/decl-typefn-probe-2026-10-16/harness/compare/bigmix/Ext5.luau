--!strict
-- [2026-10-20 3.4.0 unit 0] Ext4 with the decided Spread: `:Append(SpreadInto<C>) -> ()` (no props type inside the method).
local QT = require("../../../../../../quad-roblox/luau_packages/quad_types")
local L = require("../../../src/Lib5")

type CM<K> = index<L.ModClassMap, K>
type EM<K> = index<L.CreatableMap, K>

export type Spread<C> = { read __quadSpread: L.Build<"classname", C, L.Policy>, Append: (self: Spread<C>, other: L.SpreadInto<C>) -> () }

export type Ext = {
	Elem: <K>(name: K & keyof<L.CreatableMap>) -> (L.Props<EM<K>>) -> EM<K>,
	SpreadR: <K>(name: K & keyof<L.ModClassMap>) -> L.SpreadCtorR<CM<K>>,
	ModifierR: <K>(name: K & keyof<L.ModClassMap>) -> L.ModCtorR<CM<K>>,
	ElemR: <K>(name: K & keyof<L.CreatableMap>) -> L.ElemCtorR<EM<K>>,
	Spread: <K>(name: K & keyof<L.ModClassMap>) -> (L.Props<CM<K>>) -> Spread<CM<K>>,
	Modifier: <K>(name: K & keyof<L.ModClassMap>) -> (...any) -> L.Modifier<CM<K>>,
	OnChange: <C0>(class: C0 & keyof<L.ModClassMap>) -> <K>(name: K & keyof<L.ReadMap<CM<C0>>>) -> (fn: (index<L.ReadMap<CM<C0>>, K>) -> ()) -> L.OnChangeDescriptor<K>,
	OnEvent: <C0>(class: C0 & keyof<L.ModClassMap>) -> <K>(name: K & keyof<L.Events<CM<C0>>>) -> (fn: index<L.Events<CM<C0>>, K>) -> L.OnEventDescriptor<K>,
	Out: <C0>(class: C0 & keyof<L.ModClassMap>) -> <K>(name: K & keyof<L.ReadMap<CM<C0>>>) -> (src: QT.Source<index<L.ReadMap<CM<C0>>, K>>) -> L.OnChangeDescriptor<K>,
}
export type Q = QT.Quad & Ext
export type ModifierInto<C> = L.ModifierInto<C>
export type SpreadInto<C> = L.SpreadInto<C>
return {}
