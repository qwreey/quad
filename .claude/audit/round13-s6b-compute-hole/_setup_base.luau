--!strict
-- base-only setup (no Roblox provider) so luau-analyze 0.734 (no Roblox defs) sees clean types too.
local Quad = require("../../../quad-roblox/luau_packages/quad_base")
local QuadTypes = require("../../../quad-roblox/luau_packages/quad_types")
local q = Quad.New()
return { q = q, QuadTypes = QuadTypes }
