--!strict
-- E45: isolate the two variables behind strict-lambda.out — (x) real `q` (UseProvider) vs QT.Quad, (y) single-return vs KeyGone→nil-first body
local q = require("./e45-config")
local QT = require("../../../quad-roblox/luau_packages/quad_types")
local D = q.Declaration
local inst: Instance = nil :: any
local cur = q.Source<<string?>>(nil)
local names = q.Source<<{ string }>>({ "a" })
-- A1 real q, Single<<string,nil>>, single return
local a1 = q.Slot<<Instance>>():Single<<string, nil>>(cur, function(ctx) return inst, nil end)
-- A2 real q, Single<<string,nil>>, KeyGone→nil first
local a2 = q.Slot<<Instance>>():Single<<string, nil>>(cur, function(ctx)
	if ctx.Item == q.KeyGone then return nil, nil end
	return inst, nil
end)
-- A3 real q, :List unannotated, single return
local a3 = q.Slot<<Instance>>():List(names, function(ctx) return inst end)
-- A4 real q, :List unannotated, KeyGone→nil first
local a4 = q.Slot<<Instance>>():List(names, function(ctx)
	if ctx.Item == q.KeyGone then return nil end
	return inst
end)
-- A5 real q, :List, only return-pack annotated
local a5 = q.Slot<<Instance>>():List(names, function(ctx): (any, nil)
	if ctx.Item == q.KeyGone then return nil, nil end
	return inst, nil
end)
return { a1, a2, a3, a4, a5 }
