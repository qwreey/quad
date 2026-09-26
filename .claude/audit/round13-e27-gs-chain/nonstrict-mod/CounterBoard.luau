--!nonstrict
-- GS 14#2 + 14#4(§3 버튼) + 15#4(Ctx 한 줄) — 15장 이후 모양
const q = require("./Quad")
const D = q.Declaration
const Counter = require("./Counter16")
return function(props)
    const list = q.Slot()
    list:List(props.Rows, function(ctx)
        if ctx.Item == q.KeyGone then
            return nil, ctx.UserData
        end
        if ctx.Prev then
            return ctx.Prev, ctx.UserData
        end
        return Counter {
            Label = ctx.Item.Label,
            Start = ctx.Item.Start,
            Ctx = props.Ctx,
        }, ctx.UserData
    end, function(item)
        return item.Id
    end)
    return D.Frame {
        Size = UDim2.fromOffset(640, 140), BackgroundTransparency = 1,
        D.UIListLayout { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12) },
        list,
        D.TextButton {
            Size = UDim2.fromOffset(120, 40),
            Text = "+ 카운터",
            Activated = function()
                const nextRows = table.clone(props.Rows:Get())
                table.insert(nextRows, { Id = `c{#nextRows}`, Label = "새 카운터", Start = 0 })
                props.Rows:Set(nextRows)
            end,
        },
    }
end
