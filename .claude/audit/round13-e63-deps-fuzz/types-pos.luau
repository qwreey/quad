--!strict
-- E63 axis (e): strict shapes that should type-check
local Quad = require("../../../quad-roblox/luau_packages/quad_base")
local QuadTypes = require("../../../quad-roblox/luau_packages/quad_types")
local q = Quad
local a = q.Source(1)
local b = q.Source("x")
local r = q.Ref(0)
local e = q.Effect(function(self)
	local _n: number = a:Get()
	return function(dying: boolean) end
end, a, b, r)
local _e2: QuadTypes.Effect = q.Effect(function() end, a, a)
local d: QuadTypes.State<number> = a:Depend(b)
local dd: QuadTypes.State<number> = a:Depend(b):Depend(r :: any)
local c: QuadTypes.State<string> = a:Compute(function(self, previous: string?, other: QuadTypes.StateData<string>)
	return tostring(self:Get()) .. other:Get()
end, b)
local _o = d:Observer(function(t, self, from)
	local _v: number = t:Get()
end)
print(e, d, dd, c)
