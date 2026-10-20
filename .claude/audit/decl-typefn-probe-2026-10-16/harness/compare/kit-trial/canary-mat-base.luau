--!strict
-- [kit trial canary — current surface] same lines as mat-new.luau
local q = require("./Quad")
local Card = require("./Card")
local Progress = require("./Progress")
local D = q.Declaration
local FrameModifier = D.Modifier.Frame
local GuiObjectModifier = D.Modifier.GuiObject
local c1 = Card({ Modifier = GuiObjectModifier():Size(UDim2.new()) }) -- OK
local n1 = Card({ Modifier = FrameModifier() }) -- NEG
local n2 = D.Frame { Visible = 5 } -- NEG
local n3: number = Card({}) -- NEG
local n4 = Card({ Variant = "Nope" }) -- NEG
local n5 = Card({ Modifier = 5 }) -- NEG
return { c1, n1, n2, n3, n4, n5, Progress }
