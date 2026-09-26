--!nocheck
-- round13 E18 probe E2 — second-copy State at a property key under quad-roblox. Run from repo root.
local Quad = require("../../quad-roblox/luau_packages/quad_base")
local Other = require("../../quad-base/src") -- second copy
local QuadRoblox = require("../../quad-roblox/src").QuadRoblox
local installProperty = require("../../quad-roblox/src/Handlers/Property")
local installEngineOps = require("../../quad-roblox/src/EngineOps")
local installEvent = require("../../quad-roblox/src/Handlers/Event")
local mock = require("../../quad-base/test/mock")
local W = { Write = "" }
local gameShim = mock.gameShim({ Frame = { { Name = "Name", Permits = W }, { Name = "Visible", Permits = W } } })
getfenv(installProperty).game = gameShim
getfenv(installProperty).TweenInfo = mock.tweenInfoShim
getfenv(installEvent).game = gameShim
getfenv(installEngineOps).game = gameShim
local q = Quad.New():UseProvider(QuadRoblox)
getfenv(q.Declaration.New).Instance = { new = mock.Instance.new }
q.Backend.isInst = mock.isMockInstance
local o = Other.New()
local ok, err = pcall(function()
	local f = q.Declaration.Frame { Name = o.Source("x") }
	print("mounted; f.Name =", f.Name, typeof(f.Name))
end)
print("string key other-copy Source:", ok, ok or tostring(err):sub(1, 250))
local ok2, err2 = pcall(function() q.Declaration.Frame { Visible = o.Source(true) } end)
print("Visible other-copy Source:", ok2, ok2 or tostring(err2):sub(1, 250))
local ok3, err3 = pcall(function() q.Declaration.Frame { o.Source(1):Observer(function() end) } end)
print("numeric other-copy Observer:", ok3, ok3 or tostring(err3):sub(1, 250))
