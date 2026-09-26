--!strict
local Setup = require("./_setup")
local q = Setup.q
local D = q.Declaration
local n = q.Source(false)
local btn = D.TextButton({ BackgroundColor3 = n:Compute(function(c) return Color3.fromRGB(0,0,0) end) })
print(btn)
