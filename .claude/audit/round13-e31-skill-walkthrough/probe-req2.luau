--!strict
local Quad = require("../../../quad-base/src")
local QuadRoblox = require("../../../quad-roblox/src").QuadRoblox
local QuadTypes = require("../../../quad-roblox/luau_packages/quad_types")
local q = Quad:UseProvider(QuadRoblox)
local D = q.Declaration

type Row = { Id: string }
type RowCtx = { Item: Row | QuadTypes.KeyGone, Index: number, Offset: QuadTypes.State<number>, Prev: QuadTypes.SlotItem<Instance>?, UserData: number? }
local rows = q.Source({ { Id = "a" } } :: { Row })
local listed = q.Slot<<Instance>>():List(rows, function(ctx: RowCtx): (any, number?)
    local item, ud = ctx.Item, ctx.UserData
    if item == q.KeyGone then return nil, nil end
    return D.TextLabel({ Text = (item :: Row).Id }), (ud or 0) + 1
end, function(item: Row) return item.Id end)
print(listed)
