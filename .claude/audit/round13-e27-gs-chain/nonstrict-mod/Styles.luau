--!nonstrict
-- GS 10#6 그대로
const q = require("./Quad")
const D = q.Declaration
local function accent(color)
    return D.Modifier.TextButton {
        BackgroundColor3 = color,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    }
end
return {
    Card = D.Modifier.Frame {
        BackgroundColor3 = Color3.fromRGB(35, 35, 42),
        BorderSizePixel = 0,
    },
    Accent = accent,
}
