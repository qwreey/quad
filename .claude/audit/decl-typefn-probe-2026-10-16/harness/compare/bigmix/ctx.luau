--!strict
local E = require("./Ext5")
local q: E.Q = (nil :: any)
local GuiOnEvent = q.OnEvent "GuiObject"
local FrameOnEvent = q.OnEvent "Frame"
local a = GuiOnEvent "MouseEnter" (function(x, y) local _s: string = x end) -- expect NEG (number)
local b = FrameOnEvent "MouseEnter" (function(x, y) local _s: string = x end) -- expect NEG
local c = q.OnEvent "Frame" "MouseEnter" (function(x, y) local _s: string = x end) -- expect NEG inline
local d = q.OnEvent "GuiObject" "MouseEnter" (function(x, y) local _s: string = x end) -- expect NEG inline abstract
local FrameOnChange = q.OnChange "Frame"
local e = FrameOnChange "Visible" (function(v) local _s: string = v end) -- expect NEG
