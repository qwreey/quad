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

local function playing(): string
	local ts = {}
	for _, e in mock.tweenLog do
		if e.tween.PlaybackState == "Playing" then table.insert(ts, tostring(e.props.Position)) end
	end
	return table.concat(ts, ",")
end

mock.resetTweenLog()
local inst = mock.Instance.new("Frame")
q.Backend.nativeClaim(inst)

q.Dispatch.drive(inst, {
	q.OnChange("Position", function(v: any)
		if v == 10 then
			-- inner sets plain 20 (sets prev=true) then starts engine tween 99
			q.Dispatch.process(inst, "Position", 20, 1)
			q.Dispatch.process(inst, "Position", Tween({ Value = 99 }), 1)
		end
	end),
})

-- First set plain 10
q.Dispatch.process(inst, "Position", 10, 1)

print("Playing tweens after outer return:", playing())

-- Now try to teardown via retractFrom:
print("--- Calling q.Dispatch.retractFrom(inst, Position, 1) ---")
q.Dispatch.retractFrom(inst, "Position", 1)
print("Playing tweens after retractFrom:", playing())

-- Now try to set a plain value 0:
print("--- Calling q.Dispatch.process(inst, Position, 0, 1) ---")
q.Dispatch.process(inst, "Position", 0, 1)
print("Playing tweens after process plain 0:", playing())