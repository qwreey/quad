--!strict
local Setup = require("./_setup")
local q = Setup.q
local D = q.Declaration

local slotB = q.Slot<<Instance>>()
local order = slotB.Offset:Compute(function(o) return o:Get() + 2 end)

slotB:Add(D.TextLabel({
	Text = "B2",
	LayoutOrder = order,
}))
