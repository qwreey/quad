--!strict
-- E45: GS14-shaped :Single body with <<string, nil>> + return-pack annotation (does the doc remedy + 409 rule suffice?)
local q = require("./e45-config")
local D = q.Declaration
local cur = q.Source<<string?>>(nil)
local b1 = q.Slot<<Instance>>():Single<<string, nil>>(cur, function(ctx): (any, nil)
	if ctx.Item == q.KeyGone then return nil, nil end
	return D.TextLabel { Text = ctx.Item :: string }, nil
end)
local b2 = q.Slot<<Instance>>():Single<<string, nil>>(cur, function(ctx): (any, nil)
	if ctx.Item == q.KeyGone then return nil, nil end
	return D.TextLabel { Text = ctx.Item }, nil -- no cast: is Item narrowed by the == KeyGone arm?
end)
return { b1, b2 }
