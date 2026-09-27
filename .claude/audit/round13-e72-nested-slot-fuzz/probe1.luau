--!nocheck
-- E72 probe 1: model assumptions before the fuzzer — (1) seat Set to a held Slot, (2) :List remount catch-up
-- after data:Set while unmounted, (3) detached nested Slot CRUD then reattach, (4) Length/Offset frozen when unmounted
local E = require("./env")
local q, env = E.newBase()
local I = E.mock.Instance
local host = I.new("Frame"); host.Name = "H"
local function leaf(n) local f = I.new("Frame"); f.Name = n; return f end
local function names(t) local o = {}; for _, e in ipairs(env.P(t)) do table.insert(o, e.Name) end; return table.concat(o, ",") end
local hidden = {}
local made = {}
local L = q.Slot()
local data = q.Source({ "a", "b", "c" })
L:List(data, function(ctx)
	if ctx.Item == q.KeyGone then return q.Detach end
	if hidden[ctx.Item] then return q.Detach end
	if ctx.Prev then return ctx.Prev end
	local s = q.Slot({ leaf(ctx.Item .. "1") }); made[ctx.Item] = s; return s
end, function(x) return x end)
local P = q.Slot({ leaf("p0"), L })
local other = q.Slot({ leaf("o0") })
local seatA = q.Source(P)
local seatB = q.Source(other)
q.Dispatch.drive(host, { "h0", seatA, seatB })
print("1 init", names(host), "P.L", P.Length:Get(), "L.L", L.Length:Get(), "L.O", L.Offset:Get(), "other.O", other.Offset:Get())
-- (1) seat Set to a held slot
print("1a", pcall(function() seatB:Set(P) end))
print("1b", names(host), "other.L", other.Length:Get(), "other held?", pcall(function() q.Slot():Add(other) end))
seatB:Set(nil)
-- (2) unmount P, data change, remount
seatA:Set(nil)
print("2 unmounted", names(host), "P.L", P.Length:Get(), "L.L", L.Length:Get(), "L.O", L.Offset:Get())
data:Set({ "c", "d" })
print("2 after set (unmounted)", "L.L", L.Length:Get(), "#els", #L._elements)
seatA:Set(P)
print("2 remount", names(host), "P.L", P.Length:Get(), "L.L", L.Length:Get(), "L.O", L.Offset:Get())
-- (3) hide c -> detached nested slot; CRUD it; unhide
hidden.c = true; data:Set({ "c", "d" })
print("3 hidden", names(host), "L.L", L.Length:Get())
local cs = made.c
local obs = 0
local o = cs.Length:Observer(function() obs += 1 end); o:Subscribe(); obs = 0
cs:Add(leaf("c2")); cs:Add(leaf("c3"), 1)
print("3 detached crud", "cs.L", cs.Length:Get(), "obs", obs, "L.L", L.Length:Get(), "held?", pcall(function() q.Slot():Add(cs) end), pcall(function() q.dispose(cs) end))
hidden.c = nil; data:Set({ "c", "d" })
print("3 unhidden", names(host), "cs.L", cs.Length:Get(), "cs.O", cs.Offset:Get(), "L.L", L.Length:Get(), "obs", obs, "viol", #env.viol, "stale", #env.stale)
