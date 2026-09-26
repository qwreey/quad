--!strict
local Setup = require("./_setup")
local q = Setup.q
local D = q.Declaration

local raw = q.Source(0)

local label = D.TextLabel({
	LayoutOrder = raw:Gate(function(emit)
		return function() end
	end),
})
print(label)
