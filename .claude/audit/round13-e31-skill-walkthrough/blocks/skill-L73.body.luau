-- source: SKILL.md:73-81
--!strict
-- install path depends on the project layout
local Quad = require(<quad-base module>)              -- already a live instance
local QuadRoblox = require(<quad-roblox module>).QuadRoblox
local QuadTypes = require(<quad-types module>)        -- types only
local q = Quad:UseProvider(QuadRoblox)                -- installs D / OnChange / Out / Animate / Tween / isTween
local D = q.Declaration
