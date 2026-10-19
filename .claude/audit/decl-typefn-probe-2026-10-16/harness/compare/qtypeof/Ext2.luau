--!strict
-- [2026-10-19 M1] q = Quad & Ext2 — the confirmed backend-contract members typed by Lib2 (class-first curry for
-- OnChange/OnEvent/Out, Q127 (a) read surface incl. ReadOnly). Same merge as round 1 `qmerge/Ext.luau`, minus Modifier/Spread/Mapper.
local QT = require("../../../../../../quad-types/src")
local L = require("../../../src/Lib2")
type CM<K> = index<L.ModClassMap, K>
type EM<K> = index<L.CreatableMap, K>
export type Ext = {
	Elem: <K>(name: K & keyof<L.CreatableMap>) -> (L.Props<EM<K>>) -> EM<K>,
	OnChange: <C0>(class: C0 & keyof<L.ModClassMap>) -> <K>(name: K & keyof<L.ReadMap<CM<C0>>>) -> (fn: (index<L.ReadMap<CM<C0>>, K>) -> ()) -> L.OnChangeDescriptor<K>,
	OnEvent: <C0>(class: C0 & keyof<L.ModClassMap>) -> <K>(name: K & keyof<L.Events<CM<C0>>>) -> (fn: index<L.Events<CM<C0>>, K>) -> L.OnEventDescriptor<K>,
	Out: <C0>(class: C0 & keyof<L.ModClassMap>) -> <K>(name: K & keyof<L.ReadMap<CM<C0>>>) -> (src: QT.Source<index<L.ReadMap<CM<C0>>, K>>) -> L.OnChangeDescriptor<K>,
}
export type Q = QT.Quad & Ext
return {}
