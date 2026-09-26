--!strict
local Setup = require("./_setup")
local q = Setup.q
local D = q.Declaration
local n = q.Source(1)
local label = D.TextLabel({ Text = n:Compute(function(c) return `count: {c:Get()}` end) })
print(label)
