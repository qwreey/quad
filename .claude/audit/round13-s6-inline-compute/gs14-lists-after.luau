--!strict
local Setup = require("./_setup")
local QuadTypes = require("../../../quad-roblox/luau_packages/quad_types")
local q = Setup.q
local D = q.Declaration

local offset: QuadTypes.State<number> = q.Source(0)
local order = offset:Compute(function(o) return o:Get() + 1 end)

local label = D.TextLabel({
	Text = "x",
	LayoutOrder = order,
})
print(label)
