--!strict
local E = require("./Ext5")
local q: E.Q = (nil :: any)
local Frame = q.Elem "Frame"
local GuiSpread = q.Spread "GuiObject"
local FrameOnEvent = q.OnEvent "Frame"
local GuiOnEvent = q.OnEvent "GuiObject"
local a = Frame { FrameOnEvent "MouseEnter" (function(x, y) local _s: string = x end) } -- expect NEG, in element
local b = GuiSpread { GuiOnEvent "MouseEnter" (function(x, y) local _s: string = x end) } -- expect NEG, in spread
local c = Frame { MouseEnter = function(x, y) local _s: string = x end } -- expect NEG, hash event
local d = { FrameOnEvent "MouseEnter" (function(x, y) local _s: string = x end) } -- expect NEG, plain table
