--!strict
local Setup = require("./_setup")
local q = Setup.q
local D = q.Declaration

local count = q.Source(0)

local label = D.TextLabel({
	Text = "hi",
	LayoutOrder = 1,
})
print(count, label)
