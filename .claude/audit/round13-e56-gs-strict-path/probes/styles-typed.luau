--!strict
const q = require("../annotated/mod/Quad")
const RobloxModule = require("../../../../quad-roblox/src")
const D = q.Declaration
-- (1) q 재수출 이름만으로: 값/State 둘 다 받는 파라미터
local function accentA(color: Color3 | q.State<Color3>)
    return D.Modifier.TextButton { BackgroundColor3 = color, TextColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0 }
end
-- (2) 반환 타입까지(how-to 01 §3 모양) — RobloxModule 필요
local function accentB(color: Color3 | q.State<Color3>): RobloxModule.TextButtonModifier
    return D.Modifier.TextButton { BackgroundColor3 = color, TextColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0 }
end
const c = q.Source(Color3.fromRGB(0, 162, 255))
print(D.TextButton { accentA(c), Text = "a" }, D.TextButton { accentB(Color3.new()), Text = "b" })
-- (3) 대조: Frame 자리에 TextButton Modifier
print(D.Frame { accentB(c) })
