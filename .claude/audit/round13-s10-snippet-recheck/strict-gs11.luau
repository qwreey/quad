--!strict
local q = require("./s10-config")
local D = q.Declaration

local slotA = q.Slot { D.TextLabel { Text = "A1" }, D.TextLabel { Text = "A2" } }
local slotB = q.Slot { D.TextLabel { Text = "B1" } }

local panel = D.Frame {
	D.TextLabel { Text = "머리" },
	slotA,
	slotB,
}

slotA:Add(D.TextLabel { Text = "A3" })

slotB:Add(D.TextLabel {
	Text = "B2",
	LayoutOrder = slotB.Offset:Compute(function(o: q.StateData<number>) return o:Get() + 2 end), -- 지금은 6
})
print(panel)
