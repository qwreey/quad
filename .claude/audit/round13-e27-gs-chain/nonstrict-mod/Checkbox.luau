--!nonstrict
-- GS 12#5 그대로
const q = require("./Quad")
const D = q.Declaration
return function(props)
    const checked = props.Value
    const labelText = checked:Compute(function(c)
        return `{if c:Get() then "☑" else "☐"} {props.Label}`
    end)
    return D.TextButton {
        Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Color3.fromRGB(255, 255, 255), Text = labelText,
        Activated = function() checked:Set(not checked:Get()) end,
    }
end
