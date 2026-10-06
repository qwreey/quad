--[[
	M11 단위 ② 계약 — `Handlers/Property.luau`의 `isTween(realv)` 분기 + 3-상태
	릴레이션 슬롯 + override 정책(`base/tween-plan.md` "3-상태 저장" 분기 1~3,
	"override 정책" 절, "옵션 값 모양" 절). 엔진은 mock `TweenService`(보간 없음 —
	Create/Play/Cancel 기록)와 `TweenInfo` 심(인자 기록)으로 대체 — 실제 보간·
	Cancel 유지·Finish 스냅의 엔진 시맨틱은 Studio(brief Q7).

	CLI 실주행 심(spec.handlers 관용구): `getfenv(installProperty).game`(Reflection +
	TweenService), `getfenv(installProperty).TweenInfo`, `getfenv(D.New).Instance`, `q.Backend.isInst`.
]]

local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installProperty = require("../src/Handlers/Property")
local installEvent = require("../src/Handlers/Event")
local mock = require("../../quad-base/test/mock")
local _Instance = mock.Instance

local W = { Write = "" }
local REFLECTED: { [string]: { any } } = {
	Frame = {
		{ Name = "Name", Permits = W },
		{ Name = "Size", Permits = W },
		{ Name = "Position", Permits = W },
		{ Name = "BackgroundTransparency", Permits = W },
	},
}
local gameShim = mock.gameShim(REFLECTED)
local q: any = Quad.New():UseProvider(QuadRoblox)
;(getfenv(installProperty) :: any).game = gameShim
;(getfenv(installProperty) :: any).TweenInfo = mock.tweenInfoShim
-- `H-333`: absent convenience fields are filled with the engine defaults — the
-- enum defaults come from the `Enum` global, shimmed here with plain markers
;(getfenv(installProperty) :: any).Enum = { EasingStyle = { Quad = "Quad" }, EasingDirection = { Out = "Out" }, PlaybackState = { Completed = "Completed", Cancelled = "Cancelled" } }
;(getfenv(installEvent) :: any).game = gameShim
;(getfenv(q.Declaration.New) :: any).Instance = { new = mock.Instance.new }
q.Backend.isInst = mock.isMockInstance

local Tween = q.Tween
local collectgarbage = (_G :: any).collectgarbage :: () -> ()
local log = mock.tweenLog
-- Finish variant
mock.resetTweenLog()
local src = q.Source(0 :: any)
local armed = false
local f = q.Declaration.Frame({
	Size = src,
	q.OnChange("Size", function(v)
		if armed and v == 10 then armed = false; src:Set(Tween({ Value = 99 })) end
	end),
}) :: any
src:Set(Tween({ Value = 10 }))          -- tween1 active toward 10
armed = true
src:Set(Tween({ Value = 20, Override = "Finish" })) -- Finish writes 10 first -> signal -> nested Tween 99
local playing = 0
for i, e in log do print(i, e.props.Size, e.tween.PlaybackState, "cancels", e.tween.cancels); if e.tween.PlaybackState == "Playing" then playing += 1 end end
print("Finish variant: tweens playing =", playing, "(one expected)")
-- zero-time variant (Animate CanAnimate=false path hands Time=0)
mock.resetTweenLog()
local src3 = q.Source(0 :: any)
local armed3 = false
local g = q.Declaration.Frame({
	Size = src3,
	q.OnChange("Size", function(v)
		if armed3 and v == 5 then armed3 = false; src3:Set(Tween({ Value = 99 })) end
	end),
}) :: any
src3:Set(Tween({ Value = 10 }))
armed3 = true
src3:Set(Tween({ Value = 5, Time = 0 }))
playing = 0
for i, e in log do print(i, e.props.Size, e.tween.PlaybackState, "cancels", e.tween.cancels); if e.tween.PlaybackState == "Playing" then playing += 1 end end
print("zero-time variant: tweens playing =", playing)
