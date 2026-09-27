--!strict
-- E70 strict (generated) — how-to_04-network-and-input-bridge-L111
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_04-network-and-input-bridge-L22) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- ==== doc block how-to/04-network-and-input-bridge.md:111 ====
local UserInputService = game:GetService("UserInputService")

local isInventoryOpen = q.Source(false)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end
    if input.KeyCode == Enum.KeyCode.Tab then
        isInventoryOpen:Set(not isInventoryOpen:Get())
    end
end)

local function InventoryModal()
    return D.Frame {
        Size = UDim2.fromOffset(500, 400),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),

        Visible = isInventoryOpen,

        D.TextButton {
            Text = "X",
            MouseButton1Click = function()
                isInventoryOpen:Set(false)
            end,
        },
    }
end
