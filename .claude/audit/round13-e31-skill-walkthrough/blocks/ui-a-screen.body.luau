-- E31 walkthrough (a): counter + keyed list (Slot:List) + modal toggle + one Tween.
-- Written from SKILL.md only; every deviation / guess is tagged GAP-n (see README).
type ItemData = { Id: string, Title: string }
type RowUD = { titleSrc: QuadTypes.Source<string>, orderSrc: QuadTypes.Source<number> }
type RowCtx = { -- copied from SKILL.md §4.2
    Item: ItemData | QuadTypes.KeyGone,
    Index: number,
    Offset: QuadTypes.State<number>,
    Prev: QuadTypes.SlotItem<Instance>?,
    UserData: RowUD?,
}
-- §4.3 says Single has "the same updateFn(ctx) shape" — but a concrete Item type fails strict
-- (probe-single-*.luau); `Item: any` is what passes (GAP-6 / finding B1)
type ModalCtx = {
    Item: any,
    Index: number,
    Offset: QuadTypes.State<number>,
    Prev: QuadTypes.SlotItem<Instance>?,
    UserData: nil,
}

local function ItemList(itemsState: QuadTypes.State<{ ItemData }>)
    local slot = q.Slot<<Instance>>()
    slot:List(itemsState, function(ctx: RowCtx): (any, RowUD?)
        if ctx.Item == q.KeyGone then
            return nil
        end
        local data = ctx.Item :: ItemData
        local prev, ud = ctx.Prev, ctx.UserData
        if prev and ud then
            ud.titleSrc:Set(data.Title)
            ud.orderSrc:Set(ctx.Index)
            return prev, ud
        end
        local titleSrc = q.Source(data.Title)
        local orderSrc = q.Source(ctx.Index)
        local row = D.Frame {
            Name = data.Id,
            LayoutOrder = orderSrc,
            Size = UDim2.new(1, 0, 0, 24),
            D.TextLabel { Text = titleSrc },
        }
        return row, { titleSrc = titleSrc, orderSrc = orderSrc }
    end, function(item: ItemData)
        return item.Id
    end)
    return slot
end

local function Screen()
    local count = q.Source(0)
    local countText = count:Compute(function(self)
        return `Count: {self:Get()}`
    end)

    -- GAP-2: SKILL never says whether :Set(sameTable) re-emits; always hand a new table
    local items = q.Source<<{ ItemData }>>({})
    local modalOpen = q.Source(false)

    -- one Tween (§6.1 "a first-class value emitted from a Compute")
    local panelPos = modalOpen:Compute(function(self)
        return q.Tween {
            Value = if self:Get() then UDim2.fromScale(0.5, 0.5) else UDim2.fromScale(0.5, 1.5),
            Time = 0.25,
            Style = Enum.EasingStyle.Quad,
        }
    end)

    -- modal as a Slot:Single (GAP-5: SKILL has no overlay/modal recipe; §4.3 is the only toggle-ish tool)
    local modalSlot = q.Slot<<Instance>>()
    modalSlot:Single(modalOpen, function(ctx: ModalCtx): (any, nil)
        if ctx.Item ~= true then
            return nil -- closed: destroy
        end
        return ctx.Prev or D.TextButton {
            Name = "ModalClose",
            Text = "Close",
            Activated = function()
                modalOpen:Set(false)
            end,
        }
    end)

    local gui = D.ScreenGui {
        ResetOnSpawn = false,
        D.TextLabel { Name = "Count", Text = countText },
        D.TextButton {
            Name = "Inc",
            Text = "+1",
            Activated = function()
                count:Set(count:Get() + 1)
            end,
        },
        D.TextButton {
            Name = "AddItem",
            Text = "add",
            Activated = function()
                local nextItems = table.clone(items:Get())
                local n = #nextItems + 1
                table.insert(nextItems, { Id = `id{n}`, Title = `Item {n}` })
                items:Set(nextItems)
            end,
        },
        D.TextButton {
            Name = "Open",
            Text = "open",
            Activated = function()
                modalOpen:Set(true)
            end,
        },
        D.Frame {
            Name = "List",
            D.UIListLayout { SortOrder = Enum.SortOrder.LayoutOrder },
            ItemList(items),
        },
        D.Frame {
            Name = "Panel",
            Position = panelPos,
            modalSlot,
        },
    }
    return gui, items
end

local gui, items = Screen()
print(gui, items)
