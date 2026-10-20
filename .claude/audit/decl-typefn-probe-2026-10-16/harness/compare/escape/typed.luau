--!strict
-- [2026-10-20 escape probe] Typed escape: the caller gives the class TYPE explicitly; no name bound.
local F = require("../../../src/FullMapsKeep")
local ElemOf = (nil :: any) :: <C>(name: string) -> (F.FProps<C>) -> C
local ModifierOf = (nil :: any) :: <C>(name: string) -> (...any) -> F.FModifierAs0<C>
local SpreadOf = (nil :: any) :: <C>(name: string) -> (F.FProps<C>) -> F.FSpread<C>

local Part = ElemOf<<Part>>("Part")
local p1 = Part { Anchored = true, Size = Vector3.new(1, 2, 3) } -- OK
local p2 = Part { Anchored = 5 } -- NEG
local p3 = Part { AssemblyMass = 1 } -- NEG ReadOnly
local Beam = ElemOf<<Beam>>("Beam")
local b1 = Beam { Width0 = 1, Color = ColorSequence.new(Color3.new()) } -- OK
local b2 = Beam { Width0 = "w" } -- NEG
local MeshPart = ElemOf<<MeshPart>>("MeshPart")
local m1 = MeshPart { Anchored = true, CanCollide = false } -- OK
local m2 = MeshPart { CanCollide = 1 } -- NEG
local HRD = ElemOf<<HumanoidRigDescription>>("HumanoidRigDescription")
local h1 = HRD {} -- OK
local VS = ElemOf<<VehicleSeat>>("VehicleSeat")
local v1 = VS { MaxSpeed = 10 } -- OK
local v2 = VS { MaxSpeed = false } -- NEG
local Trail = ElemOf<<Trail>>("Trail")
local t1 = Trail { Lifetime = 1 } -- OK
local Tool = ElemOf<<Tool>>("Tool")
local to1 = Tool { CanBeDropped = true, Part { Anchored = true } } -- OK
local PartModifier = ModifierOf<<BasePart>>("BasePart")
local pm = PartModifier()
local p4 = Part { pm } -- OK
local BPSpread = SpreadOf<<BasePart>>("BasePart")
local sp = BPSpread { Anchored = true }
local p5 = MeshPart { sp } -- OK
local sp2 = BPSpread { Anchored = 3 } -- NEG
local Mismatch = ElemOf<<Part>>("Frame") -- MISS expected (name not cross-checked)
