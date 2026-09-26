--!strict
-- E45 representative strict shapes (luau-lsp new solver + roblox defs, test.sh flags)
local q = require("./e45-config")
local QuadTypes = require("../../../quad-roblox/luau_packages/quad_types")
local D = q.Declaration

type Row = { Id: string, Title: string }
type RowUD = { made: number }
type RowCtx = {
	Item: Row | QuadTypes.KeyGone,
	Index: number,
	Offset: QuadTypes.State<number>,
	Prev: QuadTypes.SlotItem<Instance>?,
	UserData: RowUD?,
}
local rows = q.Source<<{ Row }>>({ { Id = "a", Title = "A" } })

-- S1: doc shape + UD + Detach + State return
local s1 = q.Slot<<Instance>>()
s1:List(rows, function(ctx: RowCtx): (any, RowUD?)
	if ctx.Item == q.KeyGone then return q.Detach, ctx.UserData end
	if ctx.Prev then return ctx.Prev, ctx.UserData end
	local label = q.Source<<Instance?>>(D.TextLabel { Text = (ctx.Item :: Row).Title })
	return label, { made = 1 }
end, function(item: Row) return item.Id end)

-- S2: table key, OwnsElements=false
local s2 = q.Slot<<Instance>>()
s2:List(rows, function(ctx: RowCtx): (any, nil)
	if ctx.Item == q.KeyGone then return nil end
	return ctx.Prev or D.Frame {}
end, function(item: Row) return item end, { OwnsElements = false })

-- S3: unannotated lambda (doc says :List passes)
local s3 = q.Slot<<Instance>>()
s3:List(rows, function(ctx)
	if ctx.Item == q.KeyGone then return nil end
	return D.Frame {}
end)

-- S4 (expected errors?): unknown opts key, non-boolean OwnsElements
local s4 = q.Slot<<Instance>>()
s4:List(rows, function(ctx: RowCtx): (any, nil) return nil end, nil, { Owned = false } :: any)
local s5 = q.Slot<<Instance>>()
s5:List(rows, function(ctx: RowCtx): (any, nil) return nil end, nil, { OwnsElements = "no" }) -- EXPECT type error
local s6 = q.Slot<<Instance>>()
s6:List(rows, function(ctx: RowCtx): (any, nil) return nil end, nil, { Owned = false }) -- literal extra key

-- S7: keyFn returning nil type / wrong arity
local s7 = q.Slot<<Instance>>()
s7:List(rows, function(ctx: RowCtx): (any, nil) return nil end, function(item: Row) return nil end)

-- S8: Index / Offset types
local s8 = q.Slot<<Instance>>()
s8:List(rows, function(ctx: RowCtx): (any, nil)
	local i: number = ctx.Index
	local o: number = ctx.Offset:Get()
	local bad: string = ctx.Index -- EXPECT type error
	return nil
end)

-- S9: Single typed
local cur = q.Source<<string?>>(nil)
local s9 = q.Slot<<Instance>>():Single<<string, nil>>(cur, function(ctx)
	if ctx.Item == q.KeyGone then return nil end
	return ctx.Prev or D.TextLabel { Text = ctx.Item :: string }
end)

return { s1, s2, s3, s4, s5, s6, s7, s8, s9 }
