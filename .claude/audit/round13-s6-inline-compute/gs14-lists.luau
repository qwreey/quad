--!strict
local Setup = require("./_setup")
local q = Setup.q
local D = q.Declaration

local cur = q.Source(nil :: string?)

local single = q.Slot<<Instance>>():Single(cur, function(ctx)
	if ctx.Item == q.KeyGone then
		return nil
	end
	return D.TextLabel({
		Text = ctx.Item,
		LayoutOrder = ctx.Offset:Compute(function(o) return o:Get() + 1 end),
	})
end)
print(single)
