--!strict
local Setup = require("./_setup")
local QuadTypes = require("../../../quad-roblox/luau_packages/quad_types")
local q = Setup.q

local alpha = q.Source(0)
local reduceMotion = q.Source(false)
local guarded = alpha:Apply(q.Animate({
	Time = 0.3,
	CanAnimate = reduceMotion:Compute(function(self: QuadTypes.StateData<boolean>): boolean
		return not self:Get()
	end),
}))
print(guarded)
