-- source: SKILL.md:271-310
type ItemData = { Id: string, Title: string }
type RowUD = { titleSrc: QuadTypes.Source<string>, orderSrc: QuadTypes.Source<number> }
type RowCtx = {
    Item: ItemData | QuadTypes.KeyGone,
    Index: number,
    Offset: QuadTypes.State<number>,
    Prev: QuadTypes.SlotItem<Instance>?,
    UserData: RowUD?,
}

local function ItemList(itemsState: QuadTypes.State<{ ItemData }>)
    local slot = q.Slot<<Instance>>()

    slot:List(itemsState, function(ctx: RowCtx): (any, RowUD?)
        if ctx.Item == q.KeyGone then
            return nil -- key gone: destroy
        end
        local data = ctx.Item :: ItemData
        local prev, ud = ctx.Prev, ctx.UserData
        if prev and ud then
            ud.titleSrc:Set(data.Title)     -- mutate cached Sources, reuse the Instance
            ud.orderSrc:Set(ctx.Index)
            return prev, ud
        end

        local titleSrc = q.Source(data.Title)
        local orderSrc = q.Source(ctx.Index)
        local row = D.Frame {
            LayoutOrder = orderSrc,
            D.TextLabel { Text = titleSrc },
        }
        return row, { titleSrc = titleSrc, orderSrc = orderSrc }
    end, function(item: ItemData)
        return item.Id -- stable unique key; duplicates error
    end)

    return slot
end
