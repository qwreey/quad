--!nocheck
-- E72 minimal repros of the physical-order (native offset) findings with the ordered oracle, plus the seat-swap
-- transient Offset notification. Logical Length/Offset are printed next to the physical order.
local E = require("./env")
local I = E.mock.Instance
local function leaf(n) local f = I.new("Frame"); f.Name = n; return f end
local function names(env, t) local o = {}; for _, e in ipairs(env.P(t)) do table.insert(o, e.Name) end; return table.concat(o, ",") end

print("== A: drive batch — a :List whose data is a Compute of the NEXT seat Slot's Offset (converging, n = min(Offset+1, 3))")
do
	local q, env = E.newBase()
	local host = I.new("Frame")
	local S2 = q.Slot({ leaf("s2") })
	local data = S2.Offset:Compute(function(self)
		local t = {}
		for i = 1, math.min(self:Get() + 1, 3) do t[i] = "k" .. i end
		return t
	end)
	local L = q.Slot():List(data, function(ctx) if ctx.Item == q.KeyGone then return nil end return ctx.Prev or leaf(ctx.Item) end, function(x) return x end)
	q.Dispatch.drive(host, { L, S2 })
	print("phys", names(env, host), "| expected k1,k2,k3,s2 | L.L", L.Length:Get(), "S2.O", S2.Offset:Get(), "| stale", #env.stale, "viol", #env.viol, "| mock children", #host:GetChildren())
end

print("== B: Splice inside a mounted Slot; the added Slot's first Offset:Set fires a user Observer that grows an EARLIER seat")
do
	local q, env = E.newBase()
	local host = I.new("Frame")
	local sink = q.Slot()
	local T = q.Slot({ leaf("t1"), leaf("t2") })
	local N = q.Slot({ leaf("n1") }) -- free, never mounted: Offset 0
	local fired = false
	local o = N.Offset:Observer(function() if not fired and N.Offset:Get() ~= 0 then fired = true; sink:Add(leaf("sink")) end end); o:Subscribe()
	q.Dispatch.drive(host, { sink, T })
	T:Splice(2, 1, N) -- replace t2 by N
	print("phys", names(env, host), "| expected sink,t1,n1 | T.L", T.Length:Get(), "N.O", N.Offset:Get(), "T.O", T.Offset:Get(), "| stale", table.concat(env.stale, ";"), "viol", #env.viol)
	local q2, env2 = E.newBase()
	local host2 = I.new("Frame")
	local sink2 = q2.Slot(); local T2 = q2.Slot({ leaf("t1"), leaf("t2") }); local N2 = q2.Slot({ leaf("n1") })
	local f2 = false
	local o2 = N2.Offset:Observer(function() if not f2 and N2.Offset:Get() ~= 0 then f2 = true; sink2:Add(leaf("sink")) end end); o2:Subscribe()
	q2.Dispatch.drive(host2, { sink2, T2 })
	T2:Add(N2, 2) -- same through a plain Add (no pre-captured base)
	print("  control Add(N,2):", names(env2, host2), "| expected sink,t1,n1,t2 | stale", #env2.stale, "viol", #env2.viol)
end

print("== C: top-level State<Slot> seat swap with EQUAL length — later seat's Offset notifications")
do
	local q, env = E.newBase()
	local host = I.new("Frame")
	local a = q.Slot({ leaf("a1"), leaf("a2") })
	local b = q.Slot({ leaf("b1"), leaf("b2") })
	local tail = q.Slot({ leaf("z") })
	local seat = q.Source(a)
	q.Dispatch.drive(host, { seat, tail })
	local seen = {}
	local o = tail.Offset:Observer(function() table.insert(seen, tail.Offset:Get()) end); o:Subscribe(); seen = {}
	seat:Set(b)
	print("tail.Offset notifications", table.concat(seen, ","), "| final", tail.Offset:Get(), "| phys", names(env, host))
	-- same shape inside a manual Slot: Replace keeps one recompute?
	local P = q.Slot({ q.Slot({ leaf("c1"), leaf("c2") }) , q.Slot({ leaf("y") }) })
	local q2, env2 = E.newBase()
	local host2 = I.new("Frame")
	local P2 = q2.Slot({ q2.Slot({ leaf("c1"), leaf("c2") }), q2.Slot({ leaf("y") }) })
	q2.Dispatch.drive(host2, { P2 })
	local y = P2:Get(2)
	local seen2 = {}
	local o2 = y.Offset:Observer(function() table.insert(seen2, y.Offset:Get()) end); o2:Subscribe(); seen2 = {}
	P2:Replace(1, q2.Slot({ leaf("d1"), leaf("d2") }))
	print("  control manual Replace: y.Offset notifications", table.concat(seen2, ","), "| final", y.Offset:Get())
end
