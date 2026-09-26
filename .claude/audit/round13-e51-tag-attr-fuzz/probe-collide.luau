--!nocheck
local H = require("./harness")
local mock, Instance = H.mock, H.Instance
local log = {}
local q = H.newQ(log)
local function dump(inst) local a = mock.getAttributes(inst) local t = {} for k,v in a do table.insert(t, k.."="..tostring(v)) end table.sort(t) print("  tags=", table.concat(mock.getTags(inst), ","), "attrs=", table.concat(t, ","), "log=", table.concat(log, " | ")) table.clear(log) end
local inst = Instance.new("Frame")
local A = q.Source(q.Attr({ X = 1 }))
local B = q.Source(q.Attr({ Y = 1 }))
q.Dispatch.drive(inst, { A, B }) dump(inst)
local ok, e = pcall(function() B:Set(q.Attr({ X = 2, Z = 5 })) end)
print("B collide:", ok, H.idOf(e)) dump(inst)
print("B:Get", B:Get() and tostring(B:Get()))
-- original owner still works?
A:Set(q.Attr({ X = 7 })) dump(inst)
-- B next set
local ok2, e2 = pcall(function() B:Set(q.Attr({ Z = 9 })) end)
print("B after:", ok2, ok2 or H.idOf(e2)) dump(inst)
-- A releases X, B takes it
A:Set(nil) dump(inst)
local ok3, e3 = pcall(function() B:Set(q.Attr({ X = 3 })) end)
print("B take X:", ok3, ok3 or H.idOf(e3)) dump(inst)
