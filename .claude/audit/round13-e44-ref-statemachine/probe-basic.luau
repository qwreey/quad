--!nocheck
local H = require("./harness")
local q, D = H.q, H.D
local log = {}
local r = q.Ref(nil)
r:Callback(function(v) table.insert(log, "cb:" .. tostring(v and v.ClassName or v)) end)
local f = D.Frame { r }
print("after mount", r.Value and r.Value.ClassName, table.concat(log, ","))
f:Destroy()
print("after destroy", r.Value, table.concat(log, ","))
local ok, e = pcall(function() return D.Frame { r } end)
print("re-place after Destroy", ok, ok or H.first(e))
local r2 = q.Ref(nil)
local f2 = D.Frame { r2 }
q.dispose(f2)
print("after dispose", r2.Value)
local ok2, e2 = pcall(function() return D.Frame { r2 } end)
print("re-place after dispose", ok2, ok2 or H.first(e2), r2.Value and r2.Value.ClassName)
