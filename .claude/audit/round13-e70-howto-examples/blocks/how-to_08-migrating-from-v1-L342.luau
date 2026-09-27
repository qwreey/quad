-- v1: local s = Style { BorderSizePixel = 0 }; Frame { s }
local CardStyle = D.Modifier.Frame {
	BorderSizePixel = 0,
	BackgroundColor3 = Color3.fromRGB(35, 35, 45),
}
local Accent = D.Modifier.Frame():BackgroundColor3(Color3.fromRGB(0, 120, 255))

local card = D.Frame {
	Size = UDim2.fromOffset(200, 80),
	UICorner = 12, -- v1의 Corner = 12
	CardStyle,
	Accent, -- 뒤에 온 Modifier가 필드 단위로 이긴다
}
