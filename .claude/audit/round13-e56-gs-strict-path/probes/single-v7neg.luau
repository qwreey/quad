--!strict
const q = require("../annotated/Quad")
const QuadTypes = require("../../../../quad-roblox/luau_packages/quad_types")
const D = q.Declaration
const cur = q.Source<<string?>>(nil)
const s7 = q.Slot<<Instance>>():Single<<string, nil>>(cur, function(ctx): (any, nil)
	if ctx.Item == q.KeyGone then return nil end
	const off: q.State<number> = ctx.Offset
	return D.TextLabel { Text = 5, LayoutOrder = off:Compute(function(o: q.StateData<number>) return o:Get() + 1 end) }
end)
print(s5, s6, s7)
