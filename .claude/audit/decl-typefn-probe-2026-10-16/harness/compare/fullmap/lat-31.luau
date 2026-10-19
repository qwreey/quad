--!strict
-- [2026-10-19 M4] completion latency, minimal file: Lib2 31 map (keyof bound, Lib2 Policy) — control for lat-full
local L = require("../../../src/Lib2")
type EM<K> = index<L.CreatableMap, K>
local Elem = (nil :: any) :: <K>(name: K & keyof<L.CreatableMap>) -> (L.Props<EM<K>>) -> EM<K>
local Frame = Elem "Frame"
local x0 = Elem "Frame" -- @c(lat-name) at='Elem "' ins='Te'
local f0 = Frame { Visible = true } -- @c(lat-props) at='Frame { ' ins='Back'
return { x0, f0 }
