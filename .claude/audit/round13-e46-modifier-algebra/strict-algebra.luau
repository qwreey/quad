--!strict
-- E46 (g): does the result of each composition keep the class tag in the TYPE? `-- E:` expects an error, `-- OK:` none.
local q = require("./s10-config")
local R = require("../../../quad-roblox/src")
local D = q.Declaration
local s = q.Source(1)

local _g0: R.FrameModifier = D.Modifier.TextButton() -- E:G0 control sibling
local _g1: R.FrameModifier = D.Modifier.Frame():ZIndex(1):ZIndex(function(_o) return 2 end) -- OK:G1 transform keeps tag
local _g2: R.FrameModifier = D.Modifier.Frame():ZIndex(s) -- OK:G2 State setter keeps tag
local _g3: R.FrameModifier = D.Modifier.Frame(D.Modifier.Frame { ZIndex = 1 }, { LayoutOrder = 2 }) -- OK:G3 typed ctor of mods+tables
local _g4: R.FrameModifier = D.Modifier.Frame(D.Modifier.TextButton { TextSize = 3 }) -- ?:G4 typed ctor accepts a SIBLING-class modifier (runtime retags silently)
local _g5: R.TextButtonModifier = D.Modifier.Frame(D.Modifier.TextButton { TextSize = 3 }) -- E:G5 result is Frame
local _g6: R.FrameModifier = D.Modifier.GuiObject():Visible(true):AsFrame():ZIndex(1) -- OK:G6 downcast then Frame setter
local _g7: R.FrameModifier = D.Modifier.Frame():As() -- OK:G7 As() — T inferred from annotation
local _g8: R.TextButtonModifier = D.Modifier.Frame():As("TextButton") -- ?:G8 unchecked As(name): T free → any?
local _g9 = D.Modifier.Frame { ZIndex = 1 }:Overridden(D.Modifier.Frame { ZIndex = 2 })
local _g9b: number = _g9 -- ?:G9 Overridden result is any (documented untyped → any, E14 I5)
local _g10: R.FrameModifier = D.Modifier.Frame():Apply(function(m: R.FrameModifier): R.FrameModifier return m:ZIndex(3) end) -- OK:G10
local _g11 = D.Frame { D.Modifier.Frame():ZIndex(1):AsFrame() } -- OK:G11
local _g12 = D.Frame { D.Modifier.TextButton():TextSize(1) } -- E:G12 sibling in children
local _g13 = D.Frame { D.Modifier.GuiObject():ZIndex(1) } -- OK:G13 ancestor-tagged marker accepted
local _g14 = D.Frame { q.Modifier { ZIndex = 1 } } -- OK:G14 untyped
local _g15 = D.Frame { q.Modifier(D.Modifier.TextButton { TextSize = 1 }) } -- ?:G15 untyped wrapper launders a sibling
local _g16: R.FrameModifier = D.Modifier.Frame():ZIndex(q.None) -- OK:G16
local _g17: R.FrameModifier = D.Modifier.Frame():ZIndex(q.Tween { Value = 2, Time = 1 }) -- OK:G17
local _g18: R.FrameModifier = D.Modifier.Frame { ZIndex = s } -- OK:G18 table form with State
local _g19 = D.Modifier.Frame():ZIndex(function(old) return (old :: number) + 1 end) -- OK:G19 plain-old cast
local _g20: R.IntoFrame = D.Modifier.GuiObject():ZIndex(1) -- OK:G20
local _g21: R.IntoFrame = D.Modifier.Frame():AsGuiObject() -- ?:G21 checked upcast: type has it? (runtime Quad0056)
local _g22 = D.Frame { D.Modifier.TextLabel():As("Frame") } -- ?:G22 roblox/03:218 retag then use (result type unknown?)
local _g23 = D.Modifier.Frame():As():ZIndex(1) -- ?:G23 As() then chain
local _g24: R.FrameModifier = D.Modifier.Frame():As<<R.FrameModifier>>() -- OK:G24 explicit T
