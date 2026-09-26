--!nocheck
-- round13 E18 probe G — are provider-installed / plugin-extended modules collectable? Run from repo root.
local Quad = require("../../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../../quad-roblox/src").QuadRoblox
local mock = require("../../quad-base/test/mock")
local cg = (_G :: any).collectgarbage or collectgarbage
local function gc() for _ = 1, 4 do cg("collect") end end
local weak = setmetatable({}, { __mode = "v" })
do weak.bare = Quad.New() end
do local m = Quad.New(); mock.installLifetime(m); weak.mock = m end
do local m = Quad.New(); m:UseProvider(QuadRoblox); weak.roblox = m end
local function topPlugin(q) return { P = 1 } end
do local m = Quad.New(); m:AddPlugin(topPlugin); weak.plugin = m end
do local m = Quad.New(); m:RunInit(function(q) q.X = 1 end); weak.runinitInline = m end
do local m = Quad.New(); m.debug = true; m:UseProvider(QuadRoblox); weak.robloxDebug = m end
do local m = Quad.New(); m:UseProvider(QuadRoblox); local s = m.Source(1); s:Observer(function() end); weak.robloxUsed = m end
gc()
for _, k in { "bare", "mock", "roblox", "plugin", "runinitInline", "robloxDebug", "robloxUsed" } do
	print(k, weak[k] == nil and "collected" or "ALIVE")
end
