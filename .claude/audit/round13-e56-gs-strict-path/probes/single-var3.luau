--!strict
const q = require("../annotated/Quad")
const QuadTypes = require("../../../../quad-roblox/luau_packages/quad_types")
const D = q.Declaration
const cur = q.Source<<string?>>(nil)
type SCtx = { Item: string | QuadTypes.KeyGone, Index: number, Offset: q.State<number>, Prev: QuadTypes.SlotItem<Instance>?, UserData: nil }
-- V8: ctx 완전 주석 + <<string,nil>>, Offset 안 씀(E45 b1 + ctx 주석)
const s8 = q.Slot<<Instance>>():Single<<string, nil>>(cur, function(ctx: SCtx): (any, nil)
	if ctx.Item == q.KeyGone then return nil, nil end
	return D.TextLabel { Text = ctx.Item :: string }, nil
end)
-- V9: E45 b1 그대로(무주석 ctx)
const s9 = q.Slot<<Instance>>():Single<<string, nil>>(cur, function(ctx): (any, nil)
	if ctx.Item == q.KeyGone then return nil, nil end
	return D.TextLabel { Text = ctx.Item :: string }, nil
end)
print(s8, s9)
