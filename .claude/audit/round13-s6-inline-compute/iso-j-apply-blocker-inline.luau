--!strict
local Setup = require("./_setup")
local q = Setup.q
local D = q.Declaration

local raw = q.Source(0)
local blocker = q.Blocker()

local label = D.TextLabel({
	LayoutOrder = raw:Apply(blocker),
})
print(label)
