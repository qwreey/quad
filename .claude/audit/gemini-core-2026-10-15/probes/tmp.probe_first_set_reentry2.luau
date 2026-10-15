local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installProperty = require("../src/Handlers/Property")
local installEvent = require("../src/Handlers/Event")
local mock = require("../../quad-base/test/mock")

local W = { Write = "" }
local REFLECTED: { [string]: { any } } = {
	Frame = {
		{ Name = "Name", Permits = W },
		{ Name = "Size", Permits = W },
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

-- OnChange를 inst에 걸어둔다 (Position 감시)
q.Dispatch.drive(inst, {
	q.OnChange("Position", function(v: any)
		if v == 10 then
			print("[OnChange Position=10 fired]")
			-- Position의 첫 세팅 시점에 재진입하여 Position에 Tween(99)를 넣는다!
			q.Dispatch.process(inst, "Position", T(99), 1)
		end
	end),
})

-- 이제 inst의 Position에 "처음으로" plain value 10을 쓴다! (prev == nil)
print("--- Calling Dispatch.process with plain 10 ---")
q.Dispatch.process(inst, "Position", 10, 1)

print("Playing tweens after first set + inner snap:", playing())
print("Callback log so far:", table.concat(LOG, " "))

print("--- Calling Dispatch.process with SAME Tween(99) ---")
table.clear(LOG)
mock.resetTweenLog()
q.Dispatch.process(inst, "Position", T(99), 1)
print("Playing tweens after re-declaring same Tween(99):", playing())
print("Callback log:", table.concat(LOG, " "))
