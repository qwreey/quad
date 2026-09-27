--!strict
-- E70 strict (generated) — how-to_07-studio-ui-binding-and-claim-L121
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_07-studio-ui-binding-and-claim-L11) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
local M = D.Mapper
-- ==== doc block how-to/07-studio-ui-binding-and-claim.md:121 ====
-- Templates.luau — 정적인 것만. 자식의 `Name`이 나중에 Claim이 찾을 열쇠다
local ItemTemplate = D.Frame {
    Name = "ItemCard",
    Size = UDim2.fromOffset(240, 64),
    BackgroundColor3 = Color3.fromRGB(35, 35, 42),
    BorderSizePixel = 0,
    UICorner = UDim.new(0, 8),

    D.TextLabel { Name = "ItemName", Text = "-", TextSize = 14 },
    D.TextButton { Name = "ActionButton", Text = "사용" },
}
