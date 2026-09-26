--!strict
local Setup = require("./_setup")
local q = Setup.q
local D = q.Declaration
local n = q.Source(false)
local btn = D.TextButton({ BackgroundColor3 = n:Compute(function(c) return if c:Get() then Color3.fromRGB(0,0,0) else Color3.fromRGB(1,1,1) end) })
print(btn)
