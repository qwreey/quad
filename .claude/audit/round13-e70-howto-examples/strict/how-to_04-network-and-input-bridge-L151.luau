--!strict
-- E70 strict (generated) — how-to_04-network-and-input-bridge-L151
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_04-network-and-input-bridge-L22) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- ==== with how-to/04-network-and-input-bridge.md:111 ====
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
-- ==== doc block how-to/04-network-and-input-bridge.md:151 ====
local function CrosshairOverlay()
    local mousePos = q.Source(Vector2.zero)
    local dotPosition: q.State<UDim2> = mousePos:Compute(function(pos)
        local p = pos:Get()
        return UDim2.fromOffset(p.X, p.Y)
    end)

    return D.Frame {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,

        -- 숫자 키 자리에 둔다 — 마운트 시 연결, 파괴 시 해제
        q.Effect(function()
            local conn = UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    mousePos:Set(Vector2.new(input.Position.X, input.Position.Y))
                end
            end)
            return function()
                conn:Disconnect()
            end
        end),

        D.Frame {
            Size = UDim2.fromOffset(8, 8),
            Position = dotPosition,
            BackgroundColor3 = Color3.fromRGB(255, 0, 0),
        },
    }
end
