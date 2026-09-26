--!strict
-- GS 16 끝 모양(+17#1/#2) — E56 주석판
const q = require("./Quad")
const D = q.Declaration
const Theme = require("./Theme")
const Settings = require("./Settings")
return function(props: {
    read Label: string,
    read Start: number?,
    read Ctx: q.Context,
    read Children: q.Slot<Instance>?,
    read Watch: ((q.State<number>) -> q.Effect)?,
}): Frame -- [§4]
    const theme = props.Ctx:Get(Theme.Provider)
    const settings = props.Ctx:Get(Settings.Provider)
    const count = q.Source(props.Start or 0)
    const countText: q.State<string> = count:Compute(function(c: q.StateData<number>): string -- [§6]
        return `{props.Label}: {c:Get()}`
    end)
    const flash = q.Source(false)
    return D.Frame {
        Size = UDim2.fromOffset(200, 120), BackgroundColor3 = Color3.fromRGB(35, 35, 42), UICorner = 12,
        D.TextLabel { TextScaled = true, Text = countText,
            TextColor3 = count:Compute(function(c: q.StateData<number>)
                const n = c:Get()
                const isMilestone = n > 0 and n % 10 == 0
                return q.Tween {
                    Value = if isMilestone then Color3.fromRGB(255, 215, 0) else Color3.fromRGB(255, 255, 255),
                    Time = if isMilestone then 0.6 else 0.2,
                    Started = if isMilestone then function() flash:Set(true) end else nil,
                    Completed = if isMilestone then function() flash:Set(false) end else nil,
                    Cancelled = if isMilestone then function() flash:Set(false) end else nil,
                }
            end),
        },
        D.TextButton {
            BackgroundColor3 = theme.Accent,
            Text = flash:Compute(function(f: q.StateData<boolean>) return if f:Get() then "✨" else "+ 1" end),
            Activated = function()
                count:Set(count:Get() + settings.Step:Get())
            end,
        },
        props.Children or q.None,
        if props.Watch then props.Watch(count) else q.None,
    }
end
