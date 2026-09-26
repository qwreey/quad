--!strict
-- GS 12#1 (== 12#3) + 12#8 — E56 주석판. 주석마다 [근거] 태그: §4=how-to 01 §4, §6=how-to 01 §6, 08§7=how-to 08 §7 표, OUT=문서 밖 우회
const q = require("../annotated/mod/Quad")
const D = q.Declaration
return function(props: { read Label: string, read Start: number?, read Children: q.Slot<Instance>? }): Frame -- [§4] props 타입·반환
    const count = q.Source(props.Start or 0)
    const countText= count:Compute(function(c) -- [§6] 결과 타입 + 콜백 파라미터
        return c:Get()
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
