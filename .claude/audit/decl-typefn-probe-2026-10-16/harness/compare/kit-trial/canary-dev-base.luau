--!strict
-- [kit trial canary — current surface]
local Quad = require("./Quad")
local q = Quad
local Progress = require("./Progress")
local D = q.Declaration
local FrameModifier = D.Modifier.Frame
local TextLabelModifier = D.Modifier.TextLabel
local c1 = Progress.ProgressBar({ Value = 0.5, Modifier = FrameModifier():Size(UDim2.new()) }) -- OK
local n1 = Progress.ProgressBar({ Value = 0.5, Modifier = TextLabelModifier() }) -- NEG
local n2 = D.Frame { Visible = 5 } -- NEG
local n3: number = Progress.ProgressBar({ Value = 1 }) -- NEG
local n4 = Progress.ProgressBar({ Value = "x" }) -- NEG
return { c1, n1, n2, n3, n4 }
