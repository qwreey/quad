--!strict
-- GS 12#1 (== 12#3) 그대로 + 12#8(§3 마지막 원소)
const q = require("./Quad")
const D = q.Declaration
return function(props)
    const count = q.Source(props.Start or 0)
    const countText = count:Compute(function(c)
        return `{props.Label}: {c:Get()}`
    end)
    return D.Frame {
        Size = UDim2.fromOffset(200, 120),
        BackgroundColor3 = Color3.fromRGB(35, 35, 42),
        UICorner = 12,
        D.TextLabel {
            Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 0, 48), BackgroundTransparency = 1,
            TextColor3 = Color3.fromRGB(255, 255, 255), TextScaled = true, Text = countText,
        },
        D.TextButton {
            Size = UDim2.new(1, -24, 0, 40), Position = UDim2.new(0, 12, 1, -52), BackgroundColor3 = Color3.fromRGB(0, 162, 255),
            TextColor3 = Color3.fromRGB(255, 255, 255), Text = "+ 1", UICorner = 8,
            Activated = function()
                count:Set(count:Get() + 1)
            end,
        },
        props.Children or q.None,
    }
end
