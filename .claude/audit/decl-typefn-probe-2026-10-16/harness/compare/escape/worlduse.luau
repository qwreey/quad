--!strict
-- [2026-10-20 escape probe] consumer of worldmod.luau (cross-module)
local W = require("./worldmod")

local Part = W.Elem "Part"
local p1 = Part { Anchored = true, Size = Vector3.new(1, 2, 3) } -- OK
local p2 = Part { Anchored = 5 } -- NEG
local p3 = Part { AssemblyMass = 1 } -- NEG ReadOnly
local Beam = W.Elem "Beam"
local b2 = Beam { Width0 = "w" } -- NEG
local MeshPart = W.Elem "MeshPart"
local m2 = MeshPart { CanCollide = 1 } -- NEG
local VS = W.Elem "VehicleSeat"
local v2 = VS { MaxSpeed = false } -- NEG
local Tool = W.Elem "Tool"
local to1 = Tool { CanBeDropped = true, Part { Anchored = true } } -- OK
local typo = W.Elem "Prt" -- NEG name not in user map
local sp = W.Spread "BasePart" { Anchored = true }
local p5 = MeshPart { sp } -- OK
local sp2 = W.Spread "BasePart" { Anchored = 3 } -- NEG
local pm = W.Modifier "BasePart" ()
local p4 = Part { pm } -- OK
