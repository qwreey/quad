--!strict
-- [2026-10-19 M4 isolation] full map + literal-union bound, FullPolicy minus Classes
local L = require("../../../src/Lib2")
local F = require("../../../src/FullMapsKeep")
type EM<K> = index<F.CreatableMapFull, K>
type P = { Deny: {}, DenyWrite: {}, DenyIn: F.DenyInFullX, DenyWriteIn: F.DenyWriteInFullX, Inject: {}, Shorthand: L.Shorthand, Child: L.NewChild, Classes: {} }
local Elem = (nil :: any) :: <K>(name: K & F.CreatableNamesFull) -> (L.Build<"props", EM<K>, P>) -> EM<K>
local Part = Elem "Part"
local Frame = Elem "Frame"
local TextLabel = Elem "TextLabel"
local p1 = Part { Anchored = true } -- OK
local bad1 = Part { Anchored = 5 } -- NEG
local bad2 = Frame { Visible = 5 } -- NEG
return { p1, bad1, bad2, TextLabel }
