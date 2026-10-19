--!strict
-- [2026-10-19 M4] variant of lit-361: Map/Names IMPORTED from src/FullMaps (all 361 creatable, same set)
local L = require("../../../src/Lib2")
local F = require("../../../src/FullMaps")
type Map = F.CreatableMapFull
type Names = F.CreatableNamesFull
local E = (nil :: any) :: <K>(name: K & Names) -> (L.Props<index<Map, K>>) -> index<Map, K>
local Part = E "Part"
local Frame = E "Frame"
local TextLabel = E "TextLabel"
local ok1 = Frame { Visible = true }
local bad1 = Frame { Visible = 5 } -- NEG
local bad2 = E "Prt" -- NEG
return { Part, TextLabel, ok1, bad1, bad2 }
