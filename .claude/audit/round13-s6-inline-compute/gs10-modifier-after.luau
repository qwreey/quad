--!strict
local Setup = require("./_setup")
local q = Setup.q
local D = q.Declaration

local hot = q.Source(false)

local cardColor = hot:Compute(function(h)
	return if h:Get()
		then Color3.fromRGB(240, 60, 60)
		else Color3.fromRGB(35, 35, 42)
end)

local CardStyle = D.Modifier.Frame({
	BackgroundColor3 = cardColor,
	BorderSizePixel = 0,
})

local card = D.Frame({ CardStyle, Size = UDim2.fromOffset(240, 160), UICorner = 12 })
print(card)
