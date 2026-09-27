--!nocheck
local H = require("../harness")
local q, D = H.q, H.D
local s = q.Source(0); local n = 0
local o = s:Observer(function() n += 1 end)
print("created n", n); D.Frame({ o }); print("bound n", n); s:Set(1); print("after Set n", n)
local o2 = s:Observer(function() n += 1 end); n = 0; o2:Subscribe(); print("subscribe n", n); s:Set(2); print("set n", n)
local r = q.Ref(); local th = coroutine.create(function() local a, b = r:Wait(); print("Wait returned", a, b, a == r) end); coroutine.resume(th); r:Set(42)
-- dead effect without Unsubscribe
local e = q.Effect(function() error("boom") end)
print(pcall(function() e:Subscribe() end))
print(pcall(function() D.Frame({ e }) end))
local e3 = q.Effect(function() error("boom") end)
print(pcall(function() D.Frame({ e3 }) end))
print(pcall(function() D.Frame({ e3 }) end))
print(pcall(function() e3:Subscribe() end))
