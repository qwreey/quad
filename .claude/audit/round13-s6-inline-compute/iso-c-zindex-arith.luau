--!strict
local Setup = require("./_setup")
local q = Setup.q
local D = q.Declaration
local n = q.Source(1)
local f = D.Frame({ ZIndex = n:Compute(function(h) return h:Get() + 1 end) })
print(f)
