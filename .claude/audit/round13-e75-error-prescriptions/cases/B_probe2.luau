--!nocheck
-- follow-ups: Quad0023 half-built retry; Quad0071 message names retractFrom when entered via process (retractRange from process (B) branch)
local H = require("../harness")
local q, D = H.q, H.D
local a, b = D.TextLabel({ Text = "a" }), D.TextLabel({ Text = "b" })
print("trig", pcall(function() D.Frame({ a, nil, b }) end))
print("a.Parent", a.Parent, "b.Parent", b.Parent)
print("retry same children", pcall(function() local f = D.Frame({ a, q.None, b }); print(" children", #f:GetChildren()) end))
local a2, b2 = D.TextLabel({ Text = "a" }), D.TextLabel({ Text = "b" })
print("trig2", pcall(function() D.Frame({ a2, nil, b2 }) end))
local half = a2.Parent
q.dispose(half)
print("after dispose a2.Parent", a2.Parent)
print("retry after dispose same children", pcall(function() local f = D.Frame({ a2, q.None, b2 }); print(" children", #f:GetChildren()) end))
