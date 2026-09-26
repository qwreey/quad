--!strict
-- E58 strict (generated) — core_06-slot-L514
-- ==== page prologue core/06-slot.md (core_06-slot-L16.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local QuadTypes = require("../../../../quad-roblox/luau_packages/quad_types") -- 설정 모듈이 다시 내보내지 않는 타입(`QuadTypes.SlotItem<T>`·`QuadTypes.KeyGone`)
local D = q.Declaration
-- ==== doc block core/06-slot.md:514 (line offset marker) ====
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
