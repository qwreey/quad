--!strict
-- E63 axis (e): shapes whose rejection we probe (each line annotated with what a reader might expect)
local Quad = require("../../../quad-roblox/luau_packages/quad_base")
local q = Quad
local QuadTypes = require("../../../quad-roblox/luau_packages/quad_types")
local a = q.Source(1)
local b = q.Source("x")
local N1: QuadTypes.State<string> = a:Depend(b)               -- expect ERROR: Depend keeps receiver type (number)
local _e = q.Effect(function() end, 5, "str", {})     -- runtime Quad0096; static?  (deps are ...any)
local _c = a:Compute(function(self) return 1 end, q.Ref(0)) -- runtime Quad0183; static?
local _d = a:Depend(q.Ref(0))                          -- runtime Quad0183; static?
local _o = a:Observer(function() end, b)              -- extra arg silently ignored at runtime; static?
local _e3 = q.Effect(function() return 5 end, a)      -- runtime Quad0086; static?
print(N1)
