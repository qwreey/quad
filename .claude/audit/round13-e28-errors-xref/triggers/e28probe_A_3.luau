local q = require("../src")
local function try(label, f) local ok, e = pcall(f); print(label, ok, ok and "" or tostring(e)) end
local v, lo, hi = q.Source(5), q.Source(0), q.Source(-1)
local c = v:Apply(q.Operator.Clamp(lo, hi))
try("first", function() return c:Get() end)
try("second", function() return c:Get() end)
hi:Set(10)
try("after fix", function() return c:Get() end)
