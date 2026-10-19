--!strict
-- [2026-10-19 M4] map-only cost: the Lib2 31/47 maps (control) required and the Elem/Modifier/OnChange factories typed, no calls
local L = require("../../../src/Lib2")

type EM<K> = index<L.CreatableMap, K>
type MM<K> = index<L.ModClassMap, K>
local Elem = (nil :: any) :: <K>(name: K & keyof<L.CreatableMap>) -> (L.Props<EM<K>>) -> EM<K>
local Modifier = (nil :: any) :: <K>(name: K & keyof<L.ModClassMap>) -> (...any) -> L.ModifierAs0<MM<K>>
local OnChange = (nil :: any) :: <C0>(class: C0 & keyof<L.ModClassMap>) -> <K>(name: K & keyof<L.ReadMap<MM<C0>>>) -> (fn: (index<L.ReadMap<MM<C0>>, K>) -> ()) -> L.OnChangeDescriptor<K>
return { Elem, Modifier, OnChange }
