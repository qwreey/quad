--!nocheck
-- E18 settings-module stand-in #2 — another team's config module with a plugin
local Quad = require("../../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../../quad-roblox/src").QuadRoblox
local function ThemePlugin(q) return { Theme = "dark" } end
return Quad:UseProvider(QuadRoblox):AddPlugin(ThemePlugin)
