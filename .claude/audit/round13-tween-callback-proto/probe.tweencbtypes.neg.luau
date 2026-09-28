--!strict
-- PROTO probe (round13 tween-callback-structure §8-1): strict NEGATIVES — each N line should be diagnosed
local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local q = Quad.New():UseProvider(QuadRoblox)

local function _neg()
	-- N1 wrong value type in a three-arg callback (number Tween, string value)
	local n1 = q.Tween({ Value = 90, Completed = function(_inst: Instance, _prop: string, _value: string) end })
	-- N2 wrong first arg type
	local n2 = q.Tween({ Value = 90, Started = function(_inst: number) end })
	-- N3 wrap returning a non-table
	local n3 = q.Tween({ Value = 1 }):Wrapped(function(_cb) return 5 end)
	-- N4 Map with a g that returns a non-function
	local n4 = q.Tween({ Value = 1 }):Wrapped(function(cb) return cb:Map(function(_f) return 5 end) end)
	-- N5 wrap that is not a function
	local n5 = q.Tween({ Value = 1 }):Mapped(function(v: number): number return v end, 5)
	-- N6 wrong prop type
	local n6 = q.Tween({ Value = 90, Cancelled = function(_inst: Instance, _prop: number) end })
	return n1, n2, n3, n4, n5, n6
end
return _neg
