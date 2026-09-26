--!strict
local Setup = require("./_setup")
local q = Setup.q
local D = q.Declaration

local slotB = q.Slot<<Instance>>()

slotB:Add(D.TextLabel({
	Text = "B2",
	LayoutOrder = slotB.Offset:Compute(function(o) return o:Get() + 2 end),
}))
