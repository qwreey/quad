--!nocheck
-- E29 probe: Property handler state after a nil write that the engine would reject.
-- Run twice: against the unmodified mock (tree/) and the nilreject variant (t-nilreject/).
local Quad = require("../../../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../../../quad-roblox/src").QuadRoblox
local installProperty = require("../../../quad-roblox/src/Handlers/Property")
local installEvent = require("../../../quad-roblox/src/Handlers/Event")
local mock = require("../../../quad-base/test/mock")
local W = { Write = "" }
local gameShim = mock.gameShim({ Frame = { { Name = "Size", Permits = W }, { Name = "Name", Permits = W } } })
local q = Quad.New():UseProvider(QuadRoblox)
getfenv(installProperty).game = gameShim
getfenv(installProperty).TweenInfo = mock.tweenInfoShim
getfenv(installProperty).Enum = { EasingStyle = { Quad = "Quad" }, EasingDirection = { Out = "Out" }, PlaybackState = { Completed = "Completed", Cancelled = "Cancelled" } }
getfenv(installEvent).game = gameShim
getfenv(q.Declaration.New).Instance = { new = mock.Instance.new }
q.Backend.isInst = mock.isMockInstance
local log = mock.tweenLog
mock.resetTweenLog()
local src = q.Source(0)
local f = q.Declaration.Frame({ Size = src:Apply(q.Animate({ Time = 0.2 })) })
src:Set(10) -- engine tween #1 toward 10 (active)
print("after Set(10): tweens", #log, "Size", f.Size)
local ok, err = pcall(function() src:Set(q.None) end)
print("Set(None):", ok and "ok" or ("raised: " .. tostring(err)), "tween1 cancels", log[1].tween.cancels, "Size", f.Size)
src:Set(10) -- same target as the cancelled tween
print("Set(10) again: tweens", #log, "(2 = re-animated, 1 = deduped against the cancelled record)")
