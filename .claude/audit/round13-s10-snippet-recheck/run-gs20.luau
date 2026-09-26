--!nocheck
local H = require("./harness")
local q, D = H.q, H.D

local a = q.Source("A")
local b = q.Source("B")
local which = q.Source(a)

local label = D.TextLabel { Text = which :: any }
print(label.Text) --> "A"

a:Set("A2")
print(label.Text) --> "A2"

which:Set(b)
print(label.Text) --> "B"

a:Set("A3")
print(label.Text) --> "B"
