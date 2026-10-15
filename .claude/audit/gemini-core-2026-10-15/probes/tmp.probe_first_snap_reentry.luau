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

local LOG: { string } = {}
local function T(val: any): any
	return Tween({
		Value = val,
		Started = function(_: any, _: any, v: any) table.insert(LOG, "S" .. tostring(v)) end,
		Cancelled = function(_: any, _: any, v: any) table.insert(LOG, "X" .. tostring(v)) end,
		Completed = function(_: any, _: any, v: any) table.insert(LOG, "C" .. tostring(v)) end,
	})
end

local function playing(): string
	local ts = {}
	for _, e in mock.tweenLog do
		if e.tween.PlaybackState == "Playing" then table.insert(ts, tostring(e.props.Position)) end
	end
	return table.concat(ts, ",")
end

mock.resetTweenLog()
table.clear(LOG)

local inst = mock.Instance.new("Frame")
q.Backend.nativeClaim(inst)

-- OnChange on Position
q.Dispatch.drive(inst, {
	q.OnChange("Position", function(v: any)
		if v == 10 then
			print("[OnChange Position=10 fired]")
			-- Re-enter during first snap and start a real tween!
			q.Dispatch.process(inst, "Position", T(50), 1)
		end
	end),
})

-- First set Position with Tween(10) (first set snap)
print("--- Calling Dispatch.process with first set Tween(10) ---")
q.Dispatch.process(inst, "Position", T(10), 1)

print("Playing tweens after first snap + inner tween:", playing())
print("Callback log so far:", table.concat(LOG, " "))

print("--- Now tearing down or writing plain 0 to cancel ---")
table.clear(LOG)
mock.resetTweenLog()
q.Dispatch.process(inst, "Position", 0, 1)
print("Playing tweens after plain 0:", playing())
print("Callback log:", table.concat(LOG, " "))