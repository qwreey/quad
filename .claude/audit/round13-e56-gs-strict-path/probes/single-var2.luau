--!strict
const q = require("../annotated/Quad")
const QuadTypes = require("../../../../quad-roblox/luau_packages/quad_types")
const D = q.Declaration
const cur = q.Source<<string?>>(nil)
type SCtx = { Item: string | QuadTypes.KeyGone, Index: number, Offset: q.State<number>, Prev: QuadTypes.SlotItem<Instance>?, UserData: nil }
-- V5: ctx 완전 주석 + <<string,nil>> + 캐스트
const s5 = q.Slot<<Instance>>():Single<<string, nil>>(cur, function(ctx: SCtx): (any, nil)
	if ctx.Item == q.KeyGone then return nil end
	return D.TextLabel { Text = ctx.Item :: string, LayoutOrder = ctx.Offset:Compute(function(o: q.StateData<number>) return o:Get() + 1 end) }
end)
-- V6: ctx 완전 주석, 타입 인자 없음
const s6 = q.Slot<<Instance>>():Single(cur, function(ctx: SCtx): (any, nil)
	if ctx.Item == q.KeyGone then return nil end
	return D.TextLabel { Text = ctx.Item :: string, LayoutOrder = ctx.Offset:Compute(function(o: q.StateData<number>) return o:Get() + 1 end) }
end)
-- V7: 무주석 ctx, 타입 인자, Offset만 지역으로 뺌(ctx.Offset 읽기를 람다 밖 구조에서 제거 못 하므로 참고용)
const s7 = q.Slot<<Instance>>():Single<<string, nil>>(cur, function(ctx): (any, nil)
	if ctx.Item == q.KeyGone then return nil end
	const off: q.State<number> = ctx.Offset
	return D.TextLabel { Text = ctx.Item :: string, LayoutOrder = off:Compute(function(o: q.StateData<number>) return o:Get() + 1 end) }
end)
print(s5, s6, s7)
