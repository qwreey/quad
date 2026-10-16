--!strict
-- CLI-only: can the type-function Modifier<Frame> and the generated FrameModifier stand in for each other
-- (coexistence during a migration), and does a generated-D element accept the type-function Modifier/Spread markers?
local DM = require("../../../../../quad-roblox/src/Declaration")
local L = require("../../src/Lib")
local D: DM.Declaration = nil :: any
local tfm = L.Modifier<<Frame>>()
local genm = D.Modifier.Frame()
local a: DM.FrameModifier = tfm -- type-function value into generated alias
local b: L.Modifier<Frame> = genm -- generated value into type-function alias
local c = D.Frame({ tfm }) -- tf Modifier marker into generated element
local d = L.New<<Frame>>("Frame")({ genm }) -- generated Modifier into tf element
return { a, b, c, d }
