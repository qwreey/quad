--!strict
-- E58 strict (generated) — core_06-slot-L413
-- ==== page prologue core/06-slot.md (core_06-slot-L16.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local QuadTypes = require("../../../../quad-roblox/luau_packages/quad_types") -- 설정 모듈이 다시 내보내지 않는 타입(`QuadTypes.SlotItem<T>`·`QuadTypes.KeyGone`)
local D = q.Declaration
-- ==== doc block core/06-slot.md:413 (line offset marker) ====
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
