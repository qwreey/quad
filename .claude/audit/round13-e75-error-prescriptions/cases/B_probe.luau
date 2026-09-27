--!nocheck
local H = require("../harness")
local q, D = H.q, H.D
for name, v in { Ref = function() return q.Ref(nil) end, Slot = function() return q.Slot() end, Tag = function() return q.Tag("x") end, Observer = function() return q.Source(1):Observer(function() end) end, Context = function() return q.Context() end, Store = function() return q.Store({ Name = q.Source("x") }) end } do
	print(name, pcall(function() D.Frame({ Foo = v() }) end))
end
print("storeArr", pcall(function() D.Frame({ q.Store({ Name = q.Source("x") }) }) end))
print("srcArr", pcall(function() D.Frame({ q.Source(1) }) end))
print("srcStrArr", pcall(function() D.Frame({ q.Source("x") }) end))
