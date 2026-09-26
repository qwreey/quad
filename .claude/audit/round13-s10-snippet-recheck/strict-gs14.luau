--!strict
local q = require("./s10-config")
local D = q.Declaration

local cur = q.Source<<string?>>(nil)

local single = q.Slot<<Instance>>():Single(cur, function(ctx)
	if ctx.Item == q.KeyGone then
		return nil
	end
	return D.TextLabel {
		Text = ctx.Item,
		LayoutOrder = ctx.Offset:Compute(function(o: q.StateData<number>) return o:Get() + 1 end),
	}
end)

local top = q.Slot { D.TextLabel { Text = "T1" }, D.TextLabel { Text = "T2" } }

local panel = D.Frame {
	D.TextLabel { Text = "머리" },
	top,
	single,
}
print(panel)
