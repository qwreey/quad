-- source: references/code-recipes.md:6-14
--!strict
-- install path depends on the project layout
local Quad = require(<quad-base module>)              -- already a live instance
local QuadRoblox = require(<quad-roblox module>).QuadRoblox
local QuadTypes = require(<quad-types module>)        -- types only: State<T>, Source<T>, Slot<T>, Provider<T>
local q = Quad:UseProvider(QuadRoblox)                -- installs D / OnChange / Animate / Tween / isTween
local D = q.Declaration
