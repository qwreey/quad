--!strict
local q = require("./s10-config")
local D = q.Declaration

local cur = q.Source<<string?>>(nil)

local single = q.Slot<<Instance>>():Single(cur, function(ctx): (Instance | nil, unknown?)
	if ctx.Item == q.KeyGone then
		return nil
	end
	return D.TextLabel {
		Text = ctx.Item,
	}
end)
print(single)
