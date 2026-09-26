--!strict
-- GS 12#5 — E56 주석판
const q = require("./Quad")
const D = q.Declaration
return function(props: { read Label: string, read Value: q.Source<boolean> }): TextButton -- [§4]
    const checked = props.Value
    const labelText: q.State<string> = checked:Compute(function(c: q.StateData<boolean>): string -- [§6]
        return `{if c:Get() then "☑" else "☐"} {props.Label}`
    end)
    return D.TextButton {
        Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Color3.fromRGB(255, 255, 255), Text = labelText,
        Activated = function() checked:Set(not checked:Get()) end,
    }
end
