local mock = require("./mock")
local q = mock.newQuad()
local Instance = mock.Instance
local Slot, dispatch = q.Slot, q.Dispatch
local function kids(p) local t = {} for _, c in p:GetChildren() do table.insert(t, c.Name) end table.sort(t) return table.concat(t, ",") end
local function F(n) local f = Instance.new("Frame"); f.Name = n; return f end
local function try(label, f) local ok, e = pcall(f) print(label, ok and "ok" or ("ERR " .. tostring(e))) return ok, e end
print("--- S1 Replace on a materialized-but-unmounted Slot (swapped out of a State<Slot> seat), then swap back")
do
	local sA = Slot(); sA:Add(F("a1")); sA:Add(F("a2"))
	local sB = Slot(); sB:Add(F("b1"))
	local seat = q.Source(sA)
	local p = Instance.new("Folder"); dispatch.drive(p, { seat })
	print("A mounted", kids(p), sA.Length:Get(), "_mounted", sA._mounted, "target", sA._physicalTarget ~= nil)
	seat:Set(sB)
	print("B mounted", kids(p), "sA._mounted", sA._mounted, "sA target kept", sA._physicalTarget ~= nil)
	local inner = Slot(); inner:Add(F("i1")); inner:Add(F("i2")); inner:Add(F("i3"))
	local a1 = sA:Get(1)
	try("Replace(1, Slot) on unmounted A", function() sA:Replace(1, inner) end)
	print("a1 destroyed", mock.isDestroyed(a1), "sA.Length", sA.Length:Get(), "inner.Offset", inner.Offset:Get())
	local z = F("z")
	try("Replace(2, plain) on unmounted A", function() sA:Replace(2, z) end)
	print("sA.Length", sA.Length:Get())
	seat:Set(sA)
	print("A remounted", kids(p), "Length", sA.Length:Get(), "inner mounted", inner._mounted, "inner.Offset", inner.Offset:Get(), "z.Parent==p", z.Parent == p)
	sA:Add(F("tail")); print("tail", kids(p), sA.Length:Get())
end
print("--- S2 Extract(i, Slot) on unmounted-materialized (destroyOld=false, old is Slot)")
do
	local old = Slot(); old:Add(F("o1"))
	local sA = Slot(); sA:Add(old); sA:Add(F("x"))
	local seat = q.Source(sA)
	local p = Instance.new("Folder"); dispatch.drive(p, { seat })
	seat:Set(Slot())
	local new = Slot(); new:Add(F("n1")); new:Add(F("n2"))
	local got = sA:Extract(1, new)
	print("got old", got == old, "old el alive", not mock.isDestroyed(old:Get(1)), "old._mounted", old._mounted)
	seat:Set(sA); print("remounted", kids(p), sA.Length:Get())
	local p2 = Instance.new("Folder"); try("reuse extracted old Slot elsewhere", function() dispatch.drive(p2, { old }) end); print("p2", kids(p2), old.Length:Get())
end
