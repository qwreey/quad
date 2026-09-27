--!nocheck
-- E72 probe 0: harness smoke — top-level State<Slot> seat, nested slots, :List, Length/Offset readout
local E = require("./env")
local q, env = E.newBase()
local I = E.mock.Instance
local host = I.new("Frame"); host.Name = "H"
local function leaf(n) local f = I.new("Frame"); f.Name = n; return f end
local a = q.Slot({ leaf("a1"), q.Slot({ leaf("b1"), leaf("b2") }), leaf("a2") })
local seat = q.Source(a)
local c = q.Slot()
c:List(q.Source({ "x", "y" }), function(ctx) if ctx.Item == q.KeyGone then return nil end; return ctx.Prev or leaf(ctx.Item) end)
q.Dispatch.drive(host, { seat, c })
local function dump(tag)
	local names = {}
	for _, e in ipairs(env.P(host)) do table.insert(names, e.Name) end
	print(tag, table.concat(names, ","), "a.L", a.Length:Get(), "a.O", a.Offset:Get(), "c.L", c.Length:Get(), "c.O", c.Offset:Get(), "viol", #env.viol, "stale", #env.stale)
end
dump("init")
seat:Set(nil)
dump("seat nil")
seat:Set(a)
dump("seat a")
a:Get(2):Add(leaf("b3"), 1)
dump("b3 front")
print(pcall(function() a:Add(a) end))
