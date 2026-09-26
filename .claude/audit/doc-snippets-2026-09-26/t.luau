local Quad = require("../../../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../../../quad-roblox/src").QuadRoblox
local QuadTypes = require("../../../quad-roblox/luau_packages/quad_types")
print(Quad ~= nil, QuadRoblox ~= nil, QuadTypes ~= nil)
local q = Quad.New():UseProvider(QuadRoblox)
print(q.Declaration ~= nil)
