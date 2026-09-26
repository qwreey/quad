--!strict
local Setup = require("./_setup")
local q = Setup.q
local D = q.Declaration

local flag = q.Source(false)

-- "children 배열 자리" — an Instance-returning inline compute placed positionally (not as a named field)
local card = D.Frame({
	flag:Compute(function(c)
		if c:Get() then
			return D.TextLabel({ Text = "on" })
		end
		return nil
	end),
})
print(card)
