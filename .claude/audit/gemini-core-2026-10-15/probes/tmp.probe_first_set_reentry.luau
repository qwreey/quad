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
		if e.tween.PlaybackState == "Playing" then table.insert(ts, tostring(e.props.Size)) end
	end
	return table.concat(ts, ",")
end

mock.resetTweenLog()
table.clear(LOG)

-- Size의 첫 세팅 시점에 OnChange가 동기로 재진입하여 Tween을 넣는 시나리오
local src = q.Source(10 :: any)
local f: any
f = q.Declaration.Frame({
	q.OnChange("Size", function(v: any)
		if v == 10 then
			print("[OnChange fired with v=10]")
			-- 첫 세팅 10이 inst[k]에 쓰여진 직후 동기로 발화!
			-- 여기서 src에 Tween(99)를 넣는다!
			src:Set(T(99))
		end
	end),
	Size = src, -- Size의 첫 세팅이 여기서 일어남 (prev == nil)
})

print("Playing tweens after mount:", playing())
print("Callback log:", table.concat(LOG, " "))

print("--- Calling retractFrom ---")
table.clear(LOG)
q.Dispatch.retractFrom(f, "Size", 1)
print("Playing tweens after retract:", playing())
print("Callback log after retract:", table.concat(LOG, " "))
