--!strict
-- E45: unannotated-lambda claims in core/06-slot.md:451 (":List passes with the same unannotated lambda"; Single needs <<string, nil>>)
local q = require("./e45-config")
local D = q.Declaration

-- L1: the GS14 lambda shape on :List (data = Source<{string}>)
local names = q.Source<<{ string }>>({ "a" })
local l1 = q.Slot<<Instance>>():List(names, function(ctx)
	if ctx.Item == q.KeyGone then
		return nil
	end
	return D.TextLabel { Text = ctx.Item }
end)

-- L2: the same lambda on :Single with explicit <<string, nil>> (doc's recommended form)
local cur = q.Source<<string?>>(nil)
local l2 = q.Slot<<Instance>>():Single<<string, nil>>(cur, function(ctx)
	if ctx.Item == q.KeyGone then
		return nil
	end
	return D.TextLabel { Text = ctx.Item }
end)

-- L3: :List with ctx.Prev reuse, unannotated
local l3 = q.Slot<<Instance>>():List(names, function(ctx)
	if ctx.Item == q.KeyGone then return nil end
	if ctx.Prev then return ctx.Prev end
	return D.TextLabel { Text = ctx.Item }
end)

return { l1, l2, l3 }
