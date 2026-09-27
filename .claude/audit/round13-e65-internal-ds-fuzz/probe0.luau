--!nocheck
local E = require("./env")
local q = E.newBase()
local BK = q.Bookkeeping
local inst = E.mock.Instance.new("Frame")
print("keys", (function() local t = {} for k in BK do table.insert(t,k) end table.sort(t) return table.concat(t,",") end)())
local L = q.Source(2)
local runs = 0
BK.setOffsetSource(inst, 1, q.None)
BK.setLength(inst, 1, L)
local s2 = q.Source(0)
BK.setOffsetSource(inst, 2, s2)
BK.setLength(inst, 2, 1)
print("s2", s2:Get(), "off3", BK.getOffsetAt(inst, 3))
-- replace pos1 length with constant; old state L no longer registered
BK.setLength(inst, 1, 5)
print("after replace s2", s2:Get())
local ok, err = pcall(function() L:Set(-1) end)
print("stale observer Set(-1) before GC:", ok, ok and "" or E.id(err))
collectgarbage("collect")
ok, err = pcall(function() L:Set(-2) end)
print("stale observer Set(-2) after GC:", ok, ok and "" or E.id(err))
