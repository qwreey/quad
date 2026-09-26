--!nocheck
local H = require("./harness")
local q, D = H.q, H.D

local cur = q.Source(nil :: string?)

local single = q.Slot():Single(cur, function(ctx)
	if ctx.Item == q.KeyGone then
		return nil
	end
	return D.TextLabel {
		Text = ctx.Item,
		LayoutOrder = ctx.Offset:Compute(function(o: q.StateData<number>) return o:Get() + 1 end), -- TARGET
	}
end)

local top = q.Slot { D.TextLabel { Text = "T1" }, D.TextLabel { Text = "T2" } }

local panel = D.Frame {
	D.TextLabel { Text = "머리" },
	top,
	single,
}

cur:Set("지금 화면")
print(single:Get(1).LayoutOrder) --> 4

top:Add(D.TextLabel { Text = "T3" })
print(single:Get(1).LayoutOrder) --> 5

top:Remove(1)
print(single:Get(1).LayoutOrder) --> 4
