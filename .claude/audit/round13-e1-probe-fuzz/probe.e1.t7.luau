--!nocheck
local H = require("./probe.e1.harness")
local q, Instance, Slot, dispatch = H.q, H.Instance, H.Slot, H.dispatch
local function F(n) local f = Instance.new("Frame"); f.Name = n; return f end
print("== T9 Observer on S1.Length removes from sibling S2 mid-wave ==")
local parent = Instance.new("Folder")
local S1, S2 = Slot({ F("a") }), Slot({ F("b"), F("c") })
dispatch.drive(parent, { S1, S2 })
local fired = false
S1.Length:Observer(function()
	if not fired and S1.Length:Get() == 2 then fired = true; print("  S2.Offset seen in observer", S2.Offset:Get()); S2:Remove(1) end
end):Subscribe()
S1:Add(F("a2"))
print("fired", fired, "phys", H.names(H.P(parent)), "viol", table.concat(H.violations, "; "), "S2.Offset", S2.Offset:Get())
