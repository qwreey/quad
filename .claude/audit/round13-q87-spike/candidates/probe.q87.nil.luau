--!strict
local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local q = Quad.New():UseProvider(QuadRoblox)
local function _()
	local a = q.Out("Adornee", q.Source(nil :: Instance?)) -- Z1 nilable Source into Instance-typed name
	local b = q.Out("Transparency", q.Source(NumberSequence.new(0))) -- Z2 conflict name, the OTHER class type
	local c = q.Out("Padding", q.Source(UDim.new())) -- Z3 conflict name UDim
	local d = q.Out("Style", q.Source(Enum.ButtonStyle.Custom)) -- Z4 conflict name enum
	return a, b, c, d
end
