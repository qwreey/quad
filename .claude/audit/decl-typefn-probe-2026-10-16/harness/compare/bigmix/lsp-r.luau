--!strict
-- [2026-10-20 unit 0] completion/hover: generic Elem vs reduced ElemR / SpreadR / ModifierR
local E = require("./Ext5")
local q: E.Q = (nil :: any)
local Frame = q.Elem "Frame" -- @h(gen-ctor) at='Frame ='
local FrameR = q.ElemR "Frame" -- @h(r-ctor) at='FrameR ='
local a = Frame { Visible = true } -- @c(gen-props) at='Frame { ' ins='Vis'
local b = FrameR { Visible = true } -- @c(r-props) at='FrameR { ' ins='Vis'
local SpR = q.SpreadR "Frame"
local s = SpR { Visible = true } -- @c(r-spread) at='SpR { ' ins='Vis'
local ModR = q.ModifierR "Frame"
local m = ModR():BackgroundTransparency(0.5) -- @c(r-mod) at='ModR():' ins='Back'
local b2 = FrameR { BackgroundColor3 = Color3.new(), s, m } -- @h(r-val) at='b2'
