local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installProperty = require("../src/Handlers/Property")
local installEvent = require("../src/Handlers/Event")
local mock = require("../../quad-base/test/mock")

local W = { Write = "" }
local REFLECTED: { [string]: { any } } = {
	Frame = {
		{ Name = "Position", Permits = W },
	},
}
local gameShim = mock.gameShim(REFLECTED)
local q: any = Quad.New():UseProvider(QuadRoblox)
;(getfenv(installProperty) :: any).game = gameShim
;(getfenv(installProperty) :: any).TweenInfo = mock.tweenInfoShim
;(getfenv(installProperty) :: any).Enum = { EasingStyle = { Quad = "Quad" }, EasingDirection = { Out = "Out" }, PlaybackState = { Completed = "Completed", Cancelled = "Cancelled" } }
;(getfenv(installEvent) :: any).game = gameShim
;(getfenv(q.Declaration.New) :: any).Instance = { new = mock.Instance.new }
q.Backend.isInst = mock.isMockInstance

local Tween = q.Tween

local inst = mock.Instance.new("Frame")
q.Backend.nativeClaim(inst)

q.Dispatch.drive(inst, {
	q.OnChange("Position", function(v: any)
		if v == 10 then
			q.Dispatch.process(inst, "Position", Tween({ Value = 50 }), 1)
		end
	end),
})

q.Dispatch.process(inst, "Position", Tween({ Value = 10 }), 1)

print("inst.Position =", inst.Position)
-- Now try to set Tween({ Value = 10 }) again:
local engineTweensBefore = #mock.tweenLog
q.Dispatch.process(inst, "Position", Tween({ Value = 10 }), 1)
print("Did it think 10 was already set (Dedup)? engine tweens count change =", #mock.tweenLog - engineTweensBefore)
-- Now try to set Tween({ Value = 50 }) again:
local engineTweensBefore50 = #mock.tweenLog
q.Dispatch.process(inst, "Position", Tween({ Value = 50 }), 1)
print("Did it think 50 was already set? engine tweens count change =", #mock.tweenLog - engineTweensBefore50)