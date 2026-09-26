--!nocheck
local H = require("./harness")
local q, D = H.q, H.D

local slotA = q.Slot { D.TextLabel { Text = "A1" }, D.TextLabel { Text = "A2" } }
local slotB = q.Slot { D.TextLabel { Text = "B1" } }

local panel = D.Frame {
	D.TextLabel { Text = "머리" },
	slotA,
	slotB,
}

print(slotA.Offset:Get(), slotA.Length:Get()) --> 1 2
print(slotB.Offset:Get(), slotB.Length:Get()) --> 3 1

slotA:Add(D.TextLabel { Text = "A3" })
print(slotA.Offset:Get(), slotA.Length:Get()) --> 1 3
print(slotB.Offset:Get(), slotB.Length:Get()) --> 4 1

-- ── TARGET block: typed inline Compute over slotB.Offset ──
local b2 = D.TextLabel {
	Text = "B2",
	LayoutOrder = slotB.Offset:Compute(function(o: q.StateData<number>) return o:Get() + 2 end), -- 지금은 6
}
slotB:Add(b2)
print("B2 LayoutOrder:", b2.LayoutOrder) --> 6

slotA:Add(D.TextLabel { Text = "A4" })
print("B2 LayoutOrder after slotA grows:", b2.LayoutOrder) --> 7
