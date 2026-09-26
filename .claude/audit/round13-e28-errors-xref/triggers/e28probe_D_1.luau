--!nocheck
local Quad = require("../src")
local mock = require("./mock")
local quad = Quad.New()
mock.installLifetime(quad)
local Source, Effect = quad.Source, quad.Effect
local function try(label, f) local ok, e = pcall(f); print(label, ok, ok and "" or tostring(e)) end
local s = Source(1)
-- 1 double WeakSubscribe (Effect)
local e = Effect(function() end, s)
e:WeakSubscribe()
try("E weak,weak", function() e:WeakSubscribe() end)
-- 2 Observer double WeakSubscribe / weak->Subscribe
local o = s:Observer(function() end)
o:WeakSubscribe()
try("O weak,weak", function() o:WeakSubscribe() end)
try("O weak,strong", function() o:Subscribe() end)
-- 3 dead Effect: throw at emit, then unsubscribe, then resubscribe
local d = Effect(function() if s:Get() == 2 then error("boom") end end, s):Subscribe()
pcall(function() s:Set(2) end)
d:Unsubscribe()
try("E dead resub", function() d:Subscribe() end)
try("E dead bind", function() quad.Dispatch.drive(mock.Instance.new("Frame"), { d }) end)
-- 4 dead Observer
local s2 = Source(1)
local o2 = s2:Observer(function(st) if st:Get() == 2 then error("boom2") end end):Subscribe()
pcall(function() s2:Set(2) end)
o2:Unsubscribe()
try("O dead resub", function() o2:Subscribe() end)
try("O dead bind", function() quad.Dispatch.drive(mock.Instance.new("Frame"), { o2 }) end)
-- 5 Effect bound, Subscribe -> 0231; after retract -> ok?
local inst = mock.Instance.new("Frame")
local e3 = Effect(function() end, s)
quad.Dispatch.drive(inst, { e3 })
try("E bound sub", function() e3:Subscribe() end)
-- 6 install-time bind of self (0087)
try("E self-bind at install", function() Effect(function(self) quad.Dispatch.drive(mock.Instance.new("Frame"), { self }) end) end)
-- 7 Effect returning false
try("E return false", function() Effect(function() return false end) end)
