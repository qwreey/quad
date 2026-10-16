--!strict
local L = require("../../src/Lib")
type ClassMap = { TextButton: TextButton, TextLabel: TextLabel, ScrollingFrame: ScrollingFrame }
local OnChangeO = (nil :: any) :: <C0>(class: C0 & keyof<ClassMap>) -> L.ChangeOverloads<index<ClassMap, C0>>
local B = OnChangeO "TextButton"
local S = OnChangeO "ScrollingFrame"
local a = B "Text" (function(v) local n: number = v end) -- should error at body
local b = S "CanvasSize" (function(v) local n: number = v end) -- should error at body
local c = B "Txet" (function(v) end) -- should error
return { a, b, c }
