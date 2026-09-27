--!strict
-- E70 strict (generated) — how-to_07-studio-ui-binding-and-claim-L75
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_07-studio-ui-binding-and-claim-L11) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
local M = D.Mapper
--[[E70 보강 pre]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- ==== doc block how-to/07-studio-ui-binding-and-claim.md:75 ====
local ItemTemplate = ReplicatedStorage:WaitForChild("Templates"):WaitForChild("ItemCard")

local function ItemCard(item: { id: string, label: string }, label: q.Source<string>)
    local card = ItemTemplate:Clone()
    return q.Claim(card, M.Frame(M.Root)({
        M.TextLabel("ItemName")({ Text = label }),
        M.ImageLabel("ItemIcon")({ Image = "rbxassetid://2" }),
        M.TextButton("ActionButton")({
            Text = "사용",
            Activated = function()
                print("Selected:", item.id)
            end,
        }),
    }))
end

local itemsState = q.Source({ { id = "sword", label = "검" }, { id = "shield", label = "방패" } }) -- 인벤토리 데이터
local rows = q.Slot<<Instance>>():List(itemsState, function(ctx: any): (any, any)
    local item, prev, ud = ctx.Item, ctx.Prev, ctx.UserData
    if item == q.KeyGone then
        return nil, ud
    end
    if prev then
        ud.label:Set(item.label) -- 재활용: userdata 안의 Source만 갱신
        return prev, ud
    end
    local label = q.Source(item.label)
    return ItemCard(item, label), { label = label }
end, function(item)
    return item.id
end) -- 생성자의 제네릭은 추론되지 않는다 — `q.Slot<<Instance>>()`처럼 명시 타입 인자로 준다
