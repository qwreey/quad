--!strict
local Ext = require("./Ext")
local q = (nil :: any) :: Ext.Q
local src = q.Source(1) -- @h(q-source) at='src ='
local all = q.So -- @c(q-dot) at='q.' ins='So'
local sp2 = q.Sp -- @c(q-sp) at='q.' ins='Sp'
local oe2 = q.OnE -- @c(q-oe) at='q.' ins='OnE'
local Frame = q.Elem "Frame" -- @h(q-elem) at='Frame ='
local TextButton = q.Elem "TextButton"
local ok1 = Frame { BackgroundTransparency = 0.5 } -- @c(q-frame-Back) at='Frame { ' ins='Back'
local GuiSpread = q.Spread "GuiObject"
local sp = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.2 }
local FrameModifier = q.Modifier "Frame" -- @h(q-modifier-typed) at='FrameModifier ='
local m = FrameModifier():Visible(true) -- @c(q-mod-dot) at='FrameModifier():' ins='Back'
local baseM = q.Modifier() -- @h(q-modifier-base) at='baseM =' (base untyped Modifier still callable?)
local tf = q.Modifier.TypedFactory -- base namespace member still visible?
local ev = q.OnEvent "MouseEnter" (function(x, y) end)
local ok2 = Frame { sp, m, ev, Visible = true }
local ok3 = TextButton { sp }
local BAD1 = Frame { Visible = 5 }
local BAD2 = q.Elem "GuiObject" -- abstract: should error
local BAD3 = TextButton { m } -- Frame modifier into TextButton: should error
local BAD4 = q.Source(1):Set("x") -- base surface still checked: should error
return { src, all, ok1, sp, baseM, tf, ok2, ok3, BAD1, BAD2, BAD3, BAD4 }
