--!strict
local Setup = require("./_setup")
local QuadTypes = require("../../../quad-roblox/luau_packages/quad_types")
local q = Setup.q
local D = q.Declaration

local hovered = q.Source(false)
local label = q.Source("확인")
local ref = q.PreRef<<TextButton?>>(nil)

local button = D.TextButton({
	Text = label,
	Size = UDim2.fromOffset(120, 36),
	BackgroundColor3 = hovered:Compute(function(self: QuadTypes.StateData<boolean>): Color3
		return if self:Get() then Color3.fromRGB(60, 130, 255) else Color3.fromRGB(30, 30, 30)
	end),
	ref,
})
print(button)
