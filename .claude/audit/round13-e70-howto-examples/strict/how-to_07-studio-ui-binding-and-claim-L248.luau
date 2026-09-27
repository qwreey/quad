--!strict
-- E70 strict (generated) — how-to_07-studio-ui-binding-and-claim-L248
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_07-studio-ui-binding-and-claim-L11) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
local M = D.Mapper
--[[E70 보강 pre]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- ==== doc block how-to/07-studio-ui-binding-and-claim.md:248 ====
local function ShopWindow(isOpen: q.Source<boolean>, rows: q.Slot<Instance>)
    local window = ReplicatedStorage:WaitForChild("Templates"):WaitForChild("ShopWindow"):Clone()

    q.Claim(window, M.Frame(M.Root)({
        M.TextButton("CloseButton")({
            Activated = function()
                isOpen:Set(false)
            end,
        }),
        -- 그려지는 직계 자식은 전부 적는다. 손댈 것이 없으면 빈 props로
        M.TextLabel("TitleText")({}),
        M.Frame("ContentArea")({ rows }),
        Visible = isOpen,
    }))

    return window
end
