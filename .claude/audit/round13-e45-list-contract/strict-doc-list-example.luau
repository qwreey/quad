--!strict
local q = require("./e45-config")
local QuadTypes = require("../../../quad-roblox/luau_packages/quad_types")
local D = q.Declaration
type Row = { Id: string, Title: string }
type RowCtx = {
    Item: Row | QuadTypes.KeyGone,
    Index: number,
    Offset: QuadTypes.State<number>,
    Prev: QuadTypes.SlotItem<Instance>?,
    UserData: nil,
}

local rows = q.Source<<{ Row }>>({ { Id = "a", Title = "첫째" } })
local slot = q.Slot<<Instance>>()

slot:List(rows, function(ctx: RowCtx): (any, nil)
    if ctx.Item == q.KeyGone then
        return nil            -- 사라진 키: 파괴
    end
    if ctx.Prev then
        return ctx.Prev       -- 이미 있는 키: 그대로 둔다
    end
    return D.TextLabel { Text = (ctx.Item :: Row).Title }
end, function(item: Row)
    return item.Id            -- 신원은 Id
end)

local view = D.Frame { slot }
rows:Set({ { Id = "b", Title = "둘째" }, { Id = "a", Title = "첫째" } }) -- a는 재사용, b는 새로 생성
return view
