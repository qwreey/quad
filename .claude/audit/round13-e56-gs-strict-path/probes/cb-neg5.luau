--!strict
-- GS 14#2 + 14#4 + 15#4 — E56 주석판(1단계: 문서 안 주석만)
const q = require("../annotated/mod/Quad")
const D = q.Declaration
const Counter = require("../annotated/mod/Counter16")
type Row = { Id: string, Label: string, Start: number }
return function(props: { read Rows: q.Source<{ Row }>, read Ctx: q.Context }): Frame -- [§4]
    const list = q.Slot<<Instance>>() -- [08§7 / GS11 strict 접이]
    list:List(props.Rows, function(ctx): (any, nil) -- [08§7] 반환 팩(UD는 쓰지 않으므로 nil)
        const _l: number = ctx.Item.Label -- NEG4
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
    end, function(item: Row)
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
