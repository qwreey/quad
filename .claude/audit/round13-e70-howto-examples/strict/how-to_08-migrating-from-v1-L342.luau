--!strict
-- E70 strict (generated) — how-to_08-migrating-from-v1-L342
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_08-migrating-from-v1-L40) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- ==== doc block how-to/08-migrating-from-v1.md:342 ====
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
