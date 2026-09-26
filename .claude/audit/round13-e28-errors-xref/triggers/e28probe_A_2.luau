local Quad = require("../src")
local q = Quad
local function try(label, f) local ok, e = pcall(f); print(label, ok, ok and "" or tostring(e)) end
local m = q.Modifier()
local s = q.Source(nil)
local a = s:Apply(q.Operator.Alternative(m))
try("Alternative(modifier) get", function() return a:Get() end)
local t = q.Source({ k = m })
local ix = t:Apply(q.Operator.Indexed("k"))
try("Indexed -> modifier", function() return ix:Get() end)
try("modifier:Apply(Operator.Bnot)", function() return m:Apply(q.Operator.Bnot) end)
try("Observer(5)", function() return s:Observer(5 :: any) end)
try("Debounce()", function() return q.Debounce() end)
