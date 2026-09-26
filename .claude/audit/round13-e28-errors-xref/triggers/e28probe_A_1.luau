local Quad = require("../src")
local q = Quad
local function try(label, f) local ok, e = pcall(f); print(label, ok, ok and "" or tostring(e)) end
try("debounce trailing=false only", function() return q.Debounce({ Time = 1, Trailing = false }) end)
try("tag:Apply(Operator.Not)", function() return q.Tag("a"):Apply(q.Operator.Not) end)
try("tag:Apply(Operator.Sum(1))", function() return q.Tag("a"):Apply(q.Operator.Sum(1)) end)
try("tag:Apply(blocker)", function() return q.Tag("a"):Apply(q.Blocker()) end)
try("Operator.Not(5)", function() return q.Operator.Not(5) end)
local opts = { Time = 1 }
local f = q.Debounce(opts)
opts.Time = "x"
local s = q.Source(0)
local g = s:Apply(f)
try("mutated opts Time", function() s:Set(1) end)
try("store Of reserved __x", function() return q.Store():Of("__x") end)
