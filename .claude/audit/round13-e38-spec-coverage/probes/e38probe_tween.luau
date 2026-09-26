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
local log = mock.tweenLog
local function args(i) local a = log[i].info.args; local t = {} for j = 1, a.n do t[j] = tostring(a[j]) end return table.concat(t, ",") end
print("--- T1 Tween convenience fields → TweenInfo args (Time,Style,Direction,RepeatCount,Reverses,DelayTime)")
do
	mock.resetTweenLog()
	local src = q.Source(0 :: any)
	local f = q.Declaration.Frame({ Size = src }) :: any
	src:Set(Tween({ Value = 1, Time = 0.5, Direction = "In", RepeatCount = 2, Reverses = true, DelayTime = 0.25 }))
	print("#log", #log, "args", #log > 0 and args(#log) or "-")
end
print("--- T2 Animate passes Info/Direction/RepeatCount/Reverses/DelayTime/Started/Cancelled")
do
	mock.resetTweenLog()
	local st, ca = 0, 0
	local dir = q.Source("InOut")
	local src = q.Source(0)
	local anim = src:Apply(q.Animate({ Time = 0.2, Direction = dir, RepeatCount = 1, Reverses = true, DelayTime = 0.1, Started = function() st += 1 end, Cancelled = function() ca += 1 end }))
	local f = q.Declaration.Frame({ Size = anim }) :: any
	src:Set(5)
	print("#log", #log, "args", #log > 0 and args(#log) or "-", "started", st)
	dir:Set("Out"); print("after dir State change (no value change) #log", #log)
	src:Set(6); print("after src:Set(6) #log", #log, "args", args(#log), "cancelled", ca, "started", st)
	mock.resetTweenLog()
	local anim2 = q.Source(0):Apply(q.Animate({ Info = mock.tweenInfoShim.new(9) }))
end
print("--- T3 Tween{Info=..., Time=0}: Info wins → engine path (not zero-time snap)?")
do
	mock.resetTweenLog()
	local src = q.Source(0 :: any)
	local f = q.Declaration.Frame({ Size = src }) :: any
	src:Set(Tween({ Value = 3, Time = 0, Info = mock.tweenInfoShim.new(0.7) }))
	print("#log", #log, #log > 0 and args(#log) or "-", "Size", f.Size)
end
print("--- T4 first-set snap fires Started/Completed?")
do
	local st, co, ca = 0, 0, 0
	local f = q.Declaration.Frame({ Size = Tween({ Value = 2, Time = 0.3, Started = function() st += 1 end, Completed = function() co += 1 end, Cancelled = function() ca += 1 end }) }) :: any
	print("Size", f.Size, "started", st, "completed", co, "cancelled", ca)
end
print("--- T5 CanAnimate=false with Cancelled only")
do
	mock.resetTweenLog()
	local ca = 0
	local src = q.Source(0)
	local f = q.Declaration.Frame({ Size = src:Apply(q.Animate({ Time = 0.3, CanAnimate = false, Cancelled = function() ca += 1 end })) }) :: any
	src:Set(4); print("Size", f.Size, "#log", #log, "cancelled", ca)
end
print("--- T6 Dedup default: same Value re-sent while running → no new tween; DelayTime=0 & RepeatCount=0 & Time=0 snap")
do
	mock.resetTweenLog()
	local src = q.Source(0 :: any)
	local f = q.Declaration.Frame({ Size = src }) :: any
	src:Set(Tween({ Value = 1, Time = 0.5 })); src:Set(Tween({ Value = 1, Time = 0.9 }))
	print("#log (expect 1)", #log)
	local co = 0
	src:Set(Tween({ Value = 2, Time = 0, DelayTime = 0, RepeatCount = 0, Completed = function() co += 1 end }))
	print("zero-time: #log (expect still 1)", #log, "Size", f.Size, "completed", co, "old cancelled", log[1].tween.cancels)
end
