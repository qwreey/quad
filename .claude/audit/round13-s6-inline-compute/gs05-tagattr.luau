--!strict
local Setup = require("./_setup")
local q = Setup.q
local D = q.Declaration

local count = q.Source(0)

local card = D.Frame({
	q.Tag("Card"),
	count:Compute(function(c)
		return q.Tag("Card"):Added(if c:Get() % 2 == 0 then "Even" else nil)
	end),
})
print(card)
