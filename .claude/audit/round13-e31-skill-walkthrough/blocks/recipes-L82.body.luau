-- source: references/code-recipes.md:82-148
export type Item = {
    Id: string,
    Title: string,
    Score: number,
}
type RowUD = {
    titleSrc: QuadTypes.Source<string>,
    scoreSrc: QuadTypes.Source<string>,
    orderSrc: QuadTypes.Source<number>,
}
type RowCtx = {
    Item: Item | QuadTypes.KeyGone,
    Index: number,
    Offset: QuadTypes.State<number>,
    Prev: QuadTypes.SlotItem<Instance>?,
    UserData: RowUD?,
}

local function Leaderboard(itemsState: QuadTypes.State<{ Item }>)
    local slot = q.Slot<<Instance>>()

    slot:List(itemsState, function(ctx: RowCtx): (any, RowUD?)
        if ctx.Item == q.KeyGone then
            return nil -- the key left the data: destroy the row
        end
        local data = ctx.Item :: Item
        local prev, ud = ctx.Prev, ctx.UserData
        if prev and ud then
            -- recycle path: mutate the cached Sources, reuse the Instance
            ud.titleSrc:Set(data.Title)
            ud.scoreSrc:Set(`Score: {data.Score}`)
            ud.orderSrc:Set(ctx.Index)
            return prev, ud
        end

        local titleSrc = q.Source(data.Title)
        local scoreSrc = q.Source(`Score: {data.Score}`)
        local orderSrc = q.Source(ctx.Index)

        local row = D.Frame {
            LayoutOrder = orderSrc,
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = Color3.fromRGB(30, 30, 30),

            D.TextLabel {
                Size = UDim2.new(0.7, 0, 1, 0),
                Text = titleSrc,
                TextColor3 = Color3.fromRGB(255, 255, 255),
            },

            D.TextLabel {
                Size = UDim2.new(0.3, 0, 1, 0),
                Position = UDim2.new(0.7, 0, 0, 0),
                Text = scoreSrc,
                TextColor3 = Color3.fromRGB(200, 200, 100),
            },
        }

        return row, { titleSrc = titleSrc, scoreSrc = scoreSrc, orderSrc = orderSrc }
    end, function(item: Item)
        return item.Id -- stable unique key; a duplicate errors with `Quad0145 Slot:List: duplicate key ...`
    end)

    return slot
end
