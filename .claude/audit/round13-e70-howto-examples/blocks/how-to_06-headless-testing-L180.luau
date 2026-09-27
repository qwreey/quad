local data = q.Source({ { id = "a" }, { id = "b" } })
-- makeElement()는 이 백엔드가 만드는 요소, parent는 이 백엔드가 소유한 부모 인스턴스
local slot = q.Slot<<Instance>>():List(data, function(ctx: any): (any, any)
    if ctx.Item == q.KeyGone then
        return nil, ctx.UserData
    end
    return ctx.Prev or makeElement(), ctx.UserData
end, function(item)
    return item.id
end)

q.Dispatch.drive(parent, { slot })
assert(#parent:GetChildren() == 2, "두 요소가 붙었다")

data:Set({ { id = "b" } })
assert(#parent:GetChildren() == 1, "사라진 키의 요소는 파괴된다")
