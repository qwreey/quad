--!strict
local Setup = require("./_setup")
local q = Setup.q
local D = q.Declaration

local flag = q.Source(false)
local cardTag = flag:Compute(function(c)
	return q.Tag("Card"):Added(if c:Get() then "Even" else nil)
end)

local card = D.Frame({
	q.Tag("Card"),
	cardTag,
})
print(card)
