local function updateFn(ctx: {
    Item: any,
    Index: number,
    Offset: q.State<number>, -- 이 Slot 앞에 놓인 물리 자식 수를 담은 읽기 전용 State
    Prev: any,
    UserData: any,
}): (any, any)
    if ctx.Item == q.KeyGone then
        return nil, ctx.UserData -- 사라진 키 — 파괴
    end

    if not ctx.Prev then
        -- 새 요소: 이전 Source를 재사용하지 말고 처음부터 올바른 값으로 만든다
        local layoutOrder = q.Source(ctx.Index)
        local order: q.State<number> = layoutOrder:Depend(ctx.Offset):Compute(function(i)
            return i:Get() + ctx.Offset:Get()
        end)
        return D.Frame {
            LayoutOrder = order,
            -- ...
        }, { layoutOrder = layoutOrder }
    end

    -- 재활용: 실제로 바뀔 때만 Set
    local layoutOrder = ctx.UserData.layoutOrder
    if layoutOrder:Get() ~= ctx.Index then
        layoutOrder:Set(ctx.Index)
    end
    return ctx.Prev, ctx.UserData
end
