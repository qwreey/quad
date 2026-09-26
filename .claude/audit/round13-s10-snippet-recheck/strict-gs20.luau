--!strict
local q = require("./s10-config")
local D = q.Declaration

local a = q.Source("A")
local b = q.Source("B")
local which = q.Source(a)

local label = D.TextLabel { Text = which :: any }
print(label)
