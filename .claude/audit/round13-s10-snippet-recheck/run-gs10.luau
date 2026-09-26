--!nocheck
local H = require("./harness")
local q, D = H.q, H.D
UDim2 = H.EG.UDim2
Color3 = H.EG.Color3

local hot = q.Source(false)

local cardColor = hot:Compute(function(h)
	return if h:Get()
		then Color3.fromRGB(240, 60, 60)
		else Color3.fromRGB(35, 35, 42)
end)

local CardStyle = D.Modifier.Frame {
	BackgroundColor3 = cardColor, -- Compute를 테이블 안에 바로 쓰면 strict가 콜백 타입을 못 잡습니다 — 지역 변수로 빼세요
	BorderSizePixel = 0,
}

local card = D.Frame { CardStyle, Size = UDim2.fromOffset(240, 160), UICorner = 12 }
print("bg before:", card.BackgroundColor3.R, card.BackgroundColor3.G, card.BackgroundColor3.B)

hot:Set(true)
print("bg after hot=true:", card.BackgroundColor3.R, card.BackgroundColor3.G, card.BackgroundColor3.B)
