type Row = { Id: string }
type RowCtx = {
    Item: Row | QuadTypes.KeyGone,
    Index: number,
    Offset: QuadTypes.State<number>,
    Prev: QuadTypes.SlotItem<Instance>?,
    UserData: nil,
}

local visible = q.Source(true)
local rows = q.Source<<{ Row }>>({ { Id = "a" } })
local slot = q.Slot<<Instance>>()

slot:List(rows, function(ctx: RowCtx): (any, nil)
    if ctx.Item == q.KeyGone then return q.Detach end
    if not visible:Get() then return q.Detach end -- 숨김: 떼되 살려둔다
    if ctx.Prev then return ctx.Prev end          -- 복귀: 그대로 다시 붙는다
    return D.Frame {}
end, function(item: Row) return item.Id end)
