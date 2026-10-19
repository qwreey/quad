--!strict
-- [2026-10-19 M3 follow-up] (라) cost split in sync, policy full: which half of the thin Into makes the call site too complex? One-line markers.
local L = require("../../../src/Lib3")
type P = L.PolicyFull
type CM<K> = index<L.ModClassMap, K>
type Mod<C> = L.ModP<C, P>
local Modifier = (nil :: any) :: <K>(name: K & keyof<L.ModClassMap>) -> (...any) -> Mod<CM<K>>
local GuiObjectModifier = Modifier "GuiObject"
local InstanceModifier = Modifier "Instance"
local FrameModifier = Modifier "Frame"
type TagOnly = { read __quadModifier: "GuiObject" | "GuiBase2d" | "GuiBase" | "Instance" }
type TagAny = { read __quadModifier: "GuiObject" | "GuiBase2d" | "GuiBase" | "Instance", AsGuiObject: (self: any) -> any }
type TagTiny = { read __quadModifier: "GuiObject" | "GuiBase2d" | "GuiBase" | "Instance", AsGuiObject: (self: any) -> { read __quadModifier: "GuiObject" } }
local function A(p: { read Modifier: TagOnly? }) end
local function B(p: { read Modifier: TagAny? }) end
local function C(p: { read Modifier: TagTiny? }) end
A({ Modifier = GuiObjectModifier() }) -- OK tag only
A({ Modifier = InstanceModifier() }) -- OK tag only, ancestor
A({ Modifier = FrameModifier() }) -- NEG tag only rejects Frame
B({ Modifier = GuiObjectModifier() }) -- OK tag + method returning any
B({ Modifier = InstanceModifier() }) -- OK
B({ Modifier = FrameModifier() }) -- NEG
C({ Modifier = GuiObjectModifier() }) -- OK tag + method returning a one-field tag table
C({ Modifier = InstanceModifier() }) -- OK
C({ Modifier = FrameModifier() }) -- NEG
