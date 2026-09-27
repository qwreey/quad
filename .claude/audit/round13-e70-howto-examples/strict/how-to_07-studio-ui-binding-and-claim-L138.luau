--!strict
-- E70 strict (generated) — how-to_07-studio-ui-binding-and-claim-L138
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_07-studio-ui-binding-and-claim-L11) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
local M = D.Mapper
-- ==== with how-to/07-studio-ui-binding-and-claim.md:121 ====
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
-- ==== doc block how-to/07-studio-ui-binding-and-claim.md:138 ====
local function ItemCard(item: { id: string, label: string }, label: q.Source<string>)
    local card = ItemTemplate:Clone()          -- 정적 프로퍼티는 이미 들어가 있다
    return q.Claim(card, M.Frame(M.Root)({     -- 디스크립터는 사본마다 새로 만든다
        M.TextLabel("ItemName")({ Text = label }),
        M.TextButton("ActionButton")({
            Activated = function()
                print("Selected:", item.id)
            end,
        }),
    }))
end
