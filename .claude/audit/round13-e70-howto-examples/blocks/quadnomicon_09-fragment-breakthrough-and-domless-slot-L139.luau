local data = q.Source({ "a", "b", "c" })
local list = q.Slot<<Instance>>()
list:List(data, function(ctx)
	if ctx.Item == q.KeyGone then
		return nil, ctx.UserData -- 키가 빠진 사이클: 파괴(nil/None) 또는 홀드(Detach)만 허용
	end
	if ctx.Prev and ctx.UserData then
		ctx.UserData.order:Set(ctx.Index) -- 재활용: 자리 값만 갱신하고 요소는 그대로
		return ctx.Prev, ctx.UserData
	end
	local order = q.Source(ctx.Index)
	local layoutOrder = order:Depend(ctx.Offset):Compute(function(i: q.StateData<number>): number
		return i:Get() + ctx.Offset:Get()
	end)
	return D.TextButton { Text = ctx.Item :: string, LayoutOrder = layoutOrder }, { order = order }
end, function(item) return item end) -- keyFn: 문자열 자신이 키(생략하면 배열 index가 키)
