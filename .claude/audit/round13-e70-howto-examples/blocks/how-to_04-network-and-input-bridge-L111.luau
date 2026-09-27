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
