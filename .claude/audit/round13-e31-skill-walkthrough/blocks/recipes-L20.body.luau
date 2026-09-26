-- source: references/code-recipes.md:20-64
local function Counter()
    local count = q.Source(0)

    local countText = count:Compute(function(self)
        return `Count: {self:Get()}`
    end)

    local frameBg = count:Compute(function(self)
        return if self:Get() > 5 then Color3.fromRGB(220, 50, 50) else Color3.fromRGB(50, 120, 220)
    end):Apply(q.Animate {
        Time = 0.2,
        Style = Enum.EasingStyle.Quad,
    })

    return D.ScreenGui {
        ResetOnSpawn = false,

        D.Frame {
            Size = UDim2.fromOffset(200, 100),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = frameBg,

            D.TextLabel {
                Size = UDim2.new(1, 0, 0.5, 0),
                Text = countText,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
            },

            D.TextButton {
                Size = UDim2.new(1, 0, 0.5, 0),
                Position = UDim2.new(0, 0, 0.5, 0),
                Text = "Increment (+1)",
                Activated = function()
                    count:Set(count:Get() + 1)
                end,
            },
        },
    }
end

return Counter
