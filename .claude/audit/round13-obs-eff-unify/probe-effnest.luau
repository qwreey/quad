--!nocheck
-- Does a SUBSCRIBED Effect see a Set its own fn makes on its dep? (P2 check: internal Observer deferral)
local mock = require("./mock")
local q = mock.newQuad()
for _, depKind in { "Source", "Compute" } do
	local s = q.Source(0)
	local dep = if depKind == "Source" then s else s:Compute(function(x) return x:Get() end)
	local seen = {}
	local e = q.Effect(function()
		local v = dep:Get()
		table.insert(seen, v)
		if v == 10 then s:Set(11) end
	end, dep):Subscribe()
	s:Set(10)
	print(depKind, "seen", table.concat(seen, ","), "final dep", dep:Get(), if seen[#seen] == dep:Get() then "OK" else "STALE")
	e:Unsubscribe()
end
