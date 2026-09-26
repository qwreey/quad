local mock = require("./mock")
local Instance = mock.Instance
local q = mock.newQuad()
mock.installTagAttrOps(q)
-- 0003 via direct assignment
local s = q.Store({ A = q.Source(1) })
s[""] = q.Source(2)
print("0003", pcall(function() return q.Attr(s) end))
-- 0002 via two groups; and group vs key
local inst = Instance.new("Frame")
print("0002 gg", pcall(function() q.Dispatch.drive(inst, { q.Attr({ Hp = 5 }), q.Attr({ Hp = 9 }) }) end))
-- 0201 depth count
local function nest(n) local t = "x" for i=1,n do t = {t} end return t end
print("0201 64", pcall(function() return q.Tag(nest(64)) end))
print("0201 65", pcall(function() return q.Tag(nest(65)) end))
-- 0008 got
print("0008", pcall(function() return q.Attr({ X = q.Tag("a") }) end))
-- Source in plain attr value ok?
print("src", pcall(function() return q.Attr({ X = q.Source(1) }) end))
-- 0016 via same group in Slot? just check two positions
local inst2 = Instance.new("Frame")
local g = q.Attr({ Z = 1 })
print("0016", pcall(function() q.Dispatch.drive(inst2, { g, g }) end))
