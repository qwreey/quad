--!strict
local q = require("./s10-config")
local D = q.Declaration

local bad1 = D.Modifier.TextButton{ Sise = 1 }
local bad2 = D.Modifier.TextButton{ Size = "x" }
local bad3 = D.Modifier.TextButton{ Activated = function() end }
print(bad1, bad2, bad3)
