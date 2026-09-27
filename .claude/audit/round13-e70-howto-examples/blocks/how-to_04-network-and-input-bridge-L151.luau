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
