--!strict
local Setup = require("./_setup")
local q = Setup.q
local D = q.Declaration

local count = q.Source(0)
local bgColor = count:Compute(function(c)
	return if c:Get() >= 10
		then Color3.fromRGB(255, 190, 0)
		else Color3.fromRGB(0, 162, 255)
end)

local btn = D.TextButton({
	BackgroundColor3 = bgColor,
})
print(btn)
