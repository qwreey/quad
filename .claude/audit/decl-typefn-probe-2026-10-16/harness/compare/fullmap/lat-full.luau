--!strict
-- [2026-10-19 M4] completion latency, minimal file: full 361 map (literal-union bound, FullMapsKeep policy)
local F = require("../../../src/FullMapsKeep")
type EM<K> = index<F.CreatableMapFull, K>
local Elem = (nil :: any) :: <K>(name: K & F.CreatableNamesFull) -> (F.FProps<EM<K>>) -> EM<K>
local Frame = Elem "Frame"
local x0 = Elem "Frame" -- @c(lat-name) at='Elem "' ins='Te'
local f0 = Frame { Visible = true } -- @c(lat-props) at='Frame { ' ins='Back'
return { x0, f0 }
