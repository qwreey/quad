--!strict
-- E26: unlabeled type-level narrowing candidates
local q = require("./t-settings")
local QuadTypes = require("../../../quad-roblox/luau_packages/quad_types")
local function _x()
	local o: QuadTypes.DebounceOptions = { Time = 0.3 }
	o.Leading = true -- ?D1 build-then-mutate an annotated options table (fields became read)
	local k = q.AttrKey("Hp")
	local _n: string = k.Name -- OK
	local ep: QuadTypes.Epoch = { Revision = 0 }
	ep.Revision += 1 -- E? Epoch read (labeled)
	local cleanups: { () -> () } = {}
	local _e = q.Effect(function()
		return function() for _, c in cleanups do c() end end
	end) -- OK expected
	type Cleanup = () -> ()
	local function mk(): Cleanup return function() end end
	local _e2 = q.Effect(function() return mk() end) -- ?F: typed alias `() -> ()`
end
