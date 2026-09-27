--!strict
-- E70 strict (generated) — how-to_07-studio-ui-binding-and-claim-L26
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_07-studio-ui-binding-and-claim-L11) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
local M = D.Mapper
-- ==== doc block how-to/07-studio-ui-binding-and-claim.md:26 ====
local template = script.Parent:WaitForChild("ItemCard")
local clicks = q.Source(0)
local clickText: q.State<string> = clicks:Compute(function(c)
    return `클릭 횟수: {c:Get()}`
end)

q.Claim(template, M.Frame(M.Root)({
    M.TextLabel("ItemName")({ Text = "검" }),
    M.ImageLabel("ItemIcon")({ Image = "rbxassetid://1" }),
    M.TextButton("ActionButton")({
        Text = clickText,
        Activated = function()
            clicks:Set(clicks:Get() + 1)
        end,
    }),
    Visible = true,
}))
