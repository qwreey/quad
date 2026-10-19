--!strict
-- [2026-10-19 M4] full checked As tree (FModifier, Classes = 417-class ModClassMapFull) for one class: Part
local F = require("../../../src/FullMapsKeep")
local Modifier = (nil :: any) :: <K>(name: K & F.ModClassNamesFull) -> (...any) -> F.FModifier<index<F.ModClassMapFull, K>>
local m = Modifier "Part" ()
local bad = m:Name(5) -- NEG
return { m, bad }
