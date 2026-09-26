--!strict
-- GS 13 끝 모양 — E56 주석판
const q = require("./Quad")
const D = q.Declaration
local function highlightColor(state: q.State<number>, threshold: number): q.State<Color3> -- [GS13 strict 판]
    return state:Compute(function(c: q.StateData<number>): Color3 -- [§6]
        return if c:Get() >= threshold
            then Color3.fromRGB(255, 190, 0)
            else Color3.fromRGB(0, 162, 255)
    end)
end
return function(props: {
    read Label: string,
    read Start: number?,
    read Children: q.Slot<Instance>?,
    read Watch: ((q.State<number>) -> q.Effect)?,
}): Frame -- [§4]
    const count = q.Source(props.Start or 0)
    const countText: q.State<string> = count:Compute(function(c: q.StateData<number>): string -- [§6]
        return `{props.Label}: {c:Get()}`
    end)
    return D.Frame {
        Size = UDim2.fromOffset(200, 120), BackgroundColor3 = Color3.fromRGB(35, 35, 42), UICorner = 12,
        D.TextLabel { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 0, 48), BackgroundTransparency = 1,
            TextColor3 = Color3.fromRGB(255, 255, 255), TextScaled = true, Text = countText },
        D.TextButton {
            Size = UDim2.new(1, -24, 0, 40), Position = UDim2.new(0, 12, 1, -52), TextColor3 = Color3.fromRGB(255, 255, 255), UICorner = 8,
            BackgroundColor3 = highlightColor(count, 10),
            Text = "+ 1",
            Activated = function() count:Set(count:Get() + 1) end,
        },
        props.Children or q.None,
        if props.Watch then props.Watch(count) else q.None,
    }
end
