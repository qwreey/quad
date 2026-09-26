--!strict
local Setup = require("./_setup")
local q = Setup.q
local D = q.Declaration

local count = q.Source(0)

local btn = D.TextButton({
	BackgroundColor3 = count:Compute(function(c)
		return if c:Get() >= 10
			then Color3.fromRGB(255, 190, 0)
			else Color3.fromRGB(0, 162, 255)
	end),
})
print(btn)
