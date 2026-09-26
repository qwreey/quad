--!strict
local Setup = require("./_setup")
local q = Setup.q
local D = q.Declaration

local flag = q.Source(false)
local maybeChild = flag:Compute(function(c): TextLabel?
	if c:Get() then
		return D.TextLabel({ Text = "on" })
	end
	return nil
end)

local card = D.Frame({
	maybeChild,
})
print(card)
