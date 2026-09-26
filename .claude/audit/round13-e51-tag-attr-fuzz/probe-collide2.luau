--!nocheck
local H = require("./harness")
local mock, Instance = H.mock, H.Instance
local log = {}
local q = H.newQ(log)
local function dump(inst) local a = mock.getAttributes(inst) local t = {} for k,v in a do table.insert(t, k.."="..tostring(v)) end table.sort(t) print("  attrs=", table.concat(t, ","), "log=", table.concat(log, " | ")) table.clear(log) end
local inst = Instance.new("Frame")
local A = q.Source(q.Attr({ X = 1 }))
local B = q.Source(nil)
local C = q.Source(nil)
q.Dispatch.drive(inst, { A, B, C }) dump(inst)
local g = {} for _, n in {"a","b","c","d","e","f","g","h","X"} do g[n] = 2 end
local order = {} for k in pairs(g) do table.insert(order, k) end print("pairs order", table.concat(order, ","))
local ok, e = pcall(function() B:Set(q.Attr(g)) end)
print("B collide:", ok, H.idOf(e)) dump(inst)
-- now C claims 'a' (which B's failed group may have claimed)
local ok2, e2 = pcall(function() C:Set(q.Attr({ a = 9 })) end)
print("C take a:", ok2, ok2 or H.idOf(e2)) dump(inst)
-- B clears: does it release a?
local ok3, e3 = pcall(function() B:Set(nil) end)
print("B nil:", ok3, ok3 or H.idOf(e3)) dump(inst)
local ok4, e4 = pcall(function() C:Set(q.Attr({ a = 10 })) end)
print("C take a again:", ok4, ok4 or H.idOf(e4)) dump(inst)
-- Tag analog: tag process can't throw after partial? no Quad in tag process.
