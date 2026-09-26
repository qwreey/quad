--!nocheck
-- axis g: StoreBind registration fire throws (value at index+1 has no handler / handler throws).
-- What remains subscribed to the Source? Does a later src:Set still reach dispatch?
local E = require("./env")
local q = E.newBase()
local D = q.Dispatch
local inst = E.mock.Instance.new("Frame")
local log = {}
D.addHandler({ name = "Leaf", priority = 5, keyType = "string",
	isHandlable = function(_, k, v) return type(v) == "number" end,
	process = function(_, k, v, i)
		table.insert(log, `P {v} @{i}`)
		if v == 13 then error("UBOOM", 0) end
		return function(n, r) table.insert(log, `R next={tostring(n)} retracting={r}`) end
	end })
-- g1: registration fire has no handler (string value) -> Quad0076
local src = q.Source("nope")
print("g1 process State('nope'):", pcall(D.process, inst, "Foo", src, 1))
local ok, e = pcall(src.Set, src, 1)
print("g1 after throw, src:Set(1):", ok, ok and "" or E.id(e), "log:", table.concat(log, " | "))
collectgarbage(); collectgarbage()
table.clear(log)
ok, e = pcall(src.Set, src, 2)
print("g1 after GC, src:Set(2):", ok, "log:", table.concat(log, " | "))
table.clear(log)
-- now put a different value at Foo: what does the chain look like?
print("g1 process 5 at Foo:", pcall(D.process, inst, "Foo", 5, 1), "log:", table.concat(log, " | "))
table.clear(log)
ok, e = pcall(src.Set, src, 3)
print("g1 src:Set(3) after Foo replaced:", ok, "log:", table.concat(log, " | "))
table.clear(log)
-- g2: registration fire leaf throws
local src2 = q.Source(13)
print("g2 process State(13) at Bar:", pcall(D.process, inst, "Bar", src2, 1), "log:", table.concat(log, " | "))
table.clear(log)
ok, e = pcall(src2.Set, src2, 4)
print("g2 src2:Set(4):", ok, ok and "" or E.id(e), "log:", table.concat(log, " | "))
table.clear(log)
ok, e = pcall(src2.Set, src2, 6)
print("g2 src2:Set(6):", ok, "log:", table.concat(log, " | "))
table.clear(log)
print("g2 retractFrom Bar 1:", pcall(D.retractFrom, inst, "Bar", 1), "log:", table.concat(log, " | "))
table.clear(log)
ok, e = pcall(src2.Set, src2, 7)
print("g2 src2:Set(7) after retract:", ok, "log:", table.concat(log, " | "))
-- g3: emission throws later (value set to string) on a healthy binding
table.clear(log)
local src3 = q.Source(1)
D.process(inst, "Baz", src3, 1)
ok, e = pcall(src3.Set, src3, "x")
print("g3 healthy bind, Set('x') ->", ok, ok and "" or E.id(e), "log:", table.concat(log, " | "))
table.clear(log)
ok, e = pcall(src3.Set, src3, 9)
print("g3 then Set(9) ->", ok, ok and "" or E.id(e), "log:", table.concat(log, " | "))
table.clear(log)
print("g3 retract:", pcall(D.retractFrom, inst, "Baz", 1), table.concat(log, " | "))
table.clear(log)
ok, e = pcall(src3.Set, src3, 10)
print("g3 Set(10) after retract ->", ok, table.concat(log, " | "))
