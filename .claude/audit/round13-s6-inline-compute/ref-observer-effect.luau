--!strict
local Setup = require("./_setup")
local QuadTypes = require("../../../quad-roblox/luau_packages/quad_types")
local q = Setup.q
local D = q.Declaration

local hp = q.Source(100)

local label = D.TextLabel({
	Text = hp:Compute(function(self: QuadTypes.StateData<number>)
		return `HP {self:Get()}`
	end),
})
print(label)
