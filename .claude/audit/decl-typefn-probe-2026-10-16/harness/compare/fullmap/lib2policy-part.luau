--!strict
-- [2026-10-19 M4] control: Lib2's GUI-scope Policy (global-name Deny) applied to a non-GUI class
local L = require("../../../src/Lib2")
local PartC = (nil :: any) :: (L.Props<Part>) -> Part
local a = PartC { Shape = Enum.PartType.Ball } -- OK? (Part.Shape is writable; Lib's global Deny lists `Shape` from a GUI class)
local b = PartC { Position = Vector3.zero } -- OK? (BasePart.Position is Hidden in the dump but Lib2's Deny does not list it)
local c = PartC { Anchored = 5 } -- NEG
return { a, b, c }
