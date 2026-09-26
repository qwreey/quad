--!strict
local Setup = require("./_setup")
local q = Setup.q
local D = q.Declaration

local isHovered = q.Source(false)
local CommonButtonModifier = D.Modifier.Frame({
	BorderSizePixel = 0,
})

local f = D.Frame({
	Size = UDim2.new(0, 200, 0, 50),
	BackgroundColor3 = isHovered:Compute(function(h)
		return if h:Get() then Color3.fromRGB(80, 120, 240) else Color3.fromRGB(50, 50, 60)
	end),
})
print(f, CommonButtonModifier)
