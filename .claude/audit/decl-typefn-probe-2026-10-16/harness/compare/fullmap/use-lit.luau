--!strict
-- [2026-10-19 M4] full class maps (dump: every creatable class 361 / + abstract ancestors 417) with the owner-keyed policy (src/FullMaps.luau).
-- [variant] generated from use.luau by sed: class-name bounds are the literal unions (F.CreatableNamesFull/F.ModClassNamesFull), policy FullMapsKeep (+Hidden Position/Orientation kept)
local L = require("../../../src/Lib2")
local F = require("../../../src/FullMapsKeep")
type EM<K> = index<F.CreatableMapFull, K>
type MM<K> = index<F.ModClassMapFull, K>
local Elem = (nil :: any) :: <K>(name: K & F.CreatableNamesFull) -> (F.FProps<EM<K>>) -> EM<K>
local Modifier = (nil :: any) :: <K>(name: K & F.ModClassNamesFull) -> (...any) -> F.FModifierAs0<MM<K>>
local Spread = (nil :: any) :: <K>(name: K & F.ModClassNamesFull) -> (F.FProps<MM<K>>) -> F.FSpread<MM<K>>
local OnChange = (nil :: any) :: <C0>(class: C0 & F.ModClassNamesFull) -> <K>(name: K & keyof<F.FReadMap<MM<C0>>>) -> (fn: (index<F.FReadMap<MM<C0>>, K>) -> ()) -> L.OnChangeDescriptor<K>
local OnEvent = (nil :: any) :: <C0>(class: C0 & F.ModClassNamesFull) -> <K>(name: K & keyof<F.FEvents<MM<C0>>>) -> (fn: index<F.FEvents<MM<C0>>, K>) -> L.OnEventDescriptor<K>
type _B = F.FBrief<Part | Frame | TextLabel | Model | Sound | ParticleEmitter | SpawnLocation | Attachment>

local Part = Elem "Part" -- @h(m4-part) at='Part ='
local x0 = Elem "Part" -- @c(m4-name) at='Elem "' ins='P'
local p1 = Part { Anchored = true, Size = Vector3.new(1, 2, 3) } -- OK
local p0 = Part { Anchored = true } -- @c(m4-props) at='Part { ' ins='Anc'
local p2 = Part { Anchored = 5 } -- NEG wrong value
local p3 = Part { Size = UDim2.new() } -- NEG GUI type on a Part
local p4 = Part { Shape = Enum.PartType.Ball } -- OK Part.Shape (Lib's global-name Deny dropped it)
local p5 = Part { UICorner = 8 } -- NEG shorthand is GuiObject-only
local p6 = Part { Position = Vector3.zero, Color = Color3.new(), Material = Enum.Material.Neon, Touched = function(hit) end } -- OK
local p7 = Part { AssemblyMass = 1 } -- NEG ReadOnly
local p8 = Part { Parent = workspace } -- NEG Parent
local p9 = Part { Transparency = 0.5, CFrame = CFrame.new() } -- OK BasePart.Transparency is a real prop
local Frame = Elem "Frame"
local f1 = Frame { Visible = 5 } -- NEG
local f2 = Frame { Visible = true, Part { Anchored = true } } -- OK any Instance child
local f3 = Frame { Anchored = true } -- NEG not a Frame prop
local a1 = Elem "BasePart" -- NEG abstract
local a2 = Elem "Workspace" -- NEG service
local a3 = Elem "Prt" -- NEG typo
local Sound = Elem "Sound"
local s1 = Sound { SoundId = "rbxassetid://1", Volume = 0.5, Looped = true } -- OK
local s2 = Sound { Volume = "loud" } -- NEG
local s3 = Sound { TimeLength = 1 } -- NEG ReadOnly
local PE = Elem "ParticleEmitter"
local pe1 = PE { Rate = 10, Color = ColorSequence.new(Color3.new()) } -- OK
local pe2 = PE { Color = Color3.new() } -- NEG ColorSequence expected
-- Modifier (AsDepth 0 — see M3) / Spread with abstract classes
local PartModifier = Modifier "Part"
local pm = PartModifier():Anchored(true):Size(Vector3.one) -- OK
local pm2 = PartModifier():Anchored(5) -- NEG
local pp = Part { pm } -- OK
local bpm = Modifier "BasePart" ():Anchored(true):CanCollide(false) -- OK abstract Modifier
local pp2 = Part { bpm } -- OK ancestor tag
local fp = Frame { pm } -- NEG Part modifier in a Frame
local gm = Modifier "GuiObject" ():Size(UDim2.new()) -- OK
local fp2 = Frame { gm } -- OK
local pp4 = Part { gm } -- NEG GuiObject modifier in a Part
local sp = Spread "BasePart" { Anchored = true } -- OK
local pp3 = Part { sp } -- OK
local fp3 = Frame { sp } -- NEG
local sp2 = Spread "PVInstance" { } -- OK
-- read surface / events
local oc1 = OnChange "Part" "Position" (function(v) local n: number = v.X end) -- OK
local oc2 = OnChange "Part" "AssemblyMass" (function(v) local n: number = v end) -- OK ReadOnly readable
local oc3 = OnChange "Part" "Position" (function(v) local s: string = v end) -- NEG
local oc4 = OnChange "Part" "Positoin" (function(v) end) -- NEG
local ev1 = OnEvent "Part" "Touched" (function(hit) local b: BasePart = hit end) -- OK
local ev2 = OnEvent "Part" "Touched" (function(hit) local s: string = hit end) -- NEG
local pe3 = Part { ev1, oc1 } -- OK descriptors of Part names
local fe = Frame { ev1 } -- NEG Touched is not a Frame event
return { x0, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, f1, f2, f3, a1, a2, a3, s1, s2, s3, pe1, pe2, pm, pm2, pp, bpm, pp2, fp, gm, fp2, pp4, sp, pp3, fp3, sp2,
	oc1, oc2, oc3, oc4, ev1, ev2, pe3, fe }
