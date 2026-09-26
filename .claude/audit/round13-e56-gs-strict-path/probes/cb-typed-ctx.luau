--!strict
-- 대조: SKILL §4.2처럼 ctx를 명시 타입으로 주석하면 오타가 잡히는가
const q = require("../annotated/mod/Quad")
const QuadTypes = require("../../../../quad-roblox/luau_packages/quad_types")
const D = q.Declaration
type Row = { Id: string, Label: string, Start: number }
type RowCtx = { Item: Row | QuadTypes.KeyGone, Index: number, Offset: q.State<number>, Prev: QuadTypes.SlotItem<Instance>?, UserData: nil }
const rows = q.Source({} :: { Row })
const list = q.Slot<<Instance>>()
list:List(rows, function(ctx: RowCtx): (any, nil)
    if ctx.Item == q.KeyGone then return nil, nil end
    if ctx.Prev then return ctx.Prev, nil end
    return D.TextLabel { Text = ctx.Item.Lable }, nil
end, function(item: Row) return item.Id end)
