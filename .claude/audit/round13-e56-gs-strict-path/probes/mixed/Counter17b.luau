--!strict
-- GS 17#1 원래 형태 + 17#3/#4 — E56 주석판
const q = require("./Quad")
const D = q.Declaration
return function(props: { read Label: string, read Start: number? }): Frame -- [§4]
    const count = q.Source(props.Start or 0)
    const countText: q.State<string> = count:Compute(function(c: q.StateData<number>): string return `{props.Label}: {c:Get()}` end) -- [§6]
    const numberColor: q.State<Color3> = count:Compute(function(c: q.StateData<number>): Color3 -- [§6]
        return if c:Get() % 2 == 0
            then Color3.fromRGB(0, 200, 255)
            else Color3.fromRGB(255, 255, 255)
    end)
    return D.Frame {
        D.TextLabel { Text = countText, TextColor3 = numberColor:Apply(q.Animate { Time = 0.3, Style = Enum.EasingStyle.Quad }) },
        D.TextLabel {
            TextColor3 = count:Compute(function(c: q.StateData<number>)
                const n = c:Get()
                const isMilestone = n > 0 and n % 10 == 0
                return q.Tween {
                    Value = if isMilestone then Color3.fromRGB(255, 215, 0) else Color3.fromRGB(255, 255, 255),
                    Time = if isMilestone then 0.6 else 0.2,
                    Style = Enum.EasingStyle.Quad,
                    Override = "Cancel",
                }
            end),
        },
    }
end
