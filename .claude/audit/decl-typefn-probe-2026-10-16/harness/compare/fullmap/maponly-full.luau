--!strict
-- [2026-10-19 M4] map-only cost: the full maps/policy module required and the Elem/Modifier/OnChange factories typed, no calls
local L = require("../../../src/Lib2")
local F = require("../../../src/FullMapsKeep")
type EM<K> = index<F.CreatableMapFull, K>
type MM<K> = index<F.ModClassMapFull, K>
local Elem = (nil :: any) :: <K>(name: K & F.CreatableNamesFull) -> (F.FProps<EM<K>>) -> EM<K>
local Modifier = (nil :: any) :: <K>(name: K & F.ModClassNamesFull) -> (...any) -> F.FModifierAs0<MM<K>>
local OnChange = (nil :: any) :: <C0>(class: C0 & F.ModClassNamesFull) -> <K>(name: K & keyof<F.FReadMap<MM<C0>>>) -> (fn: (index<F.FReadMap<MM<C0>>, K>) -> ()) -> L.OnChangeDescriptor<K>
return { Elem, Modifier, OnChange }
