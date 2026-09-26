--!strict
const q = require("../annotated/Quad")
const D = q.Declaration
const cur = q.Source<<string?>>(nil)
-- V1: GS14 §5 모양 + <<string,nil>> + 팩 + 캐스트 (return nil 한 값)
const s1 = q.Slot<<Instance>>():Single<<string, nil>>(cur, function(ctx): (any, nil)
	if ctx.Item == q.KeyGone then return nil end
	return D.TextLabel { Text = ctx.Item :: string, LayoutOrder = ctx.Offset:Compute(function(o: q.StateData<number>) return o:Get() + 1 end) }
end)
-- V2: 두 값 반환
const s2 = q.Slot<<Instance>>():Single<<string, nil>>(cur, function(ctx): (any, nil)
	if ctx.Item == q.KeyGone then return nil, nil end
	return D.TextLabel { Text = ctx.Item :: string, LayoutOrder = ctx.Offset:Compute(function(o: q.StateData<number>) return o:Get() + 1 end) }, nil
end)
-- V3: Offset Compute 결과를 지역으로
const s3 = q.Slot<<Instance>>():Single<<string, nil>>(cur, function(ctx): (any, nil)
	if ctx.Item == q.KeyGone then return nil end
	const order: q.State<number> = ctx.Offset:Compute(function(o: q.StateData<number>): number return o:Get() + 1 end)
	return D.TextLabel { Text = ctx.Item :: string, LayoutOrder = order }
end)
-- V4: 인라인 Compute 콜백 반환 주석
const s4 = q.Slot<<Instance>>():Single<<string, nil>>(cur, function(ctx): (any, nil)
	if ctx.Item == q.KeyGone then return nil end
	return D.TextLabel { Text = ctx.Item :: string, LayoutOrder = ctx.Offset:Compute(function(o: q.StateData<number>): number return o:Get() + 1 end) }
end)
print(s1, s2, s3, s4)
