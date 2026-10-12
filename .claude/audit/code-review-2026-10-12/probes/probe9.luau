--!nocheck
local H = require("./probe_h")
local F, on = H.F, H.on
for _, mode in { "drive", "Add" } do
	local q, lay = H.new()
	local host = H.mock.Instance.new("Frame")
	local U = q.Slot({ F("u") })
	local st = q.Source(U)
	local inner = q.Slot():Single(st, nil, { OwnsElements = false })
	local x = F("x")
	local A = q.Slot({ x, inner })
	on(x, "in", function() st:Set(nil) end)
	if mode == "drive" then q.Dispatch.drive(host, { A })
	else
		local P = q.Slot({}); q.Dispatch.drive(host, { P }); P:Add(A)
	end
	print(mode, "U flag:", U._materializing, "U mounted:", U._mounted, "inner flag", inner._materializing, "A flag", A._materializing)
	local ok, e = pcall(function() U:Add(F("v")) end)
	print("  U:Add ->", ok, ok and "" or string.match(tostring(e), "Quad%d+"))
	local ran = false
	U:WhenIdle(function() ran = true end)
	print("  U:WhenIdle ran now:", ran)
	-- reuse: mount U elsewhere
	local h2 = H.mock.Instance.new("Frame")
	local ok2, e2 = pcall(function() q.Dispatch.drive(h2, { U }) end)
	print("  remount U elsewhere:", ok2, ok2 and H.names(h2) or tostring(e2):sub(1, 80), "flag after", U._materializing)
end
