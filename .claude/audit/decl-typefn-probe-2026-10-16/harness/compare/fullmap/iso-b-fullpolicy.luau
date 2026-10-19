--!strict
-- [2026-10-19 M4 isolation] full map + literal-union bound, FullPolicy (Classes = 417-class map, owner-keyed deny)
local L = require("../../../src/Lib2")
local F = require("../../../src/FullMapsKeep")
type EM<K> = index<F.CreatableMapFull, K>

local Elem = (nil :: any) :: <K>(name: K & F.CreatableNamesFull) -> (F.FProps<EM<K>>) -> EM<K>
local Part = Elem "Part"
local Frame = Elem "Frame"
local TextLabel = Elem "TextLabel"
local p1 = Part { Anchored = true } -- OK
local bad1 = Part { Anchored = 5 } -- NEG
local bad2 = Frame { Visible = 5 } -- NEG
return { p1, bad1, bad2, TextLabel }
