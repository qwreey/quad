--[[
	M11 단위 ② 계약 — `Handlers/Property.luau`의 `isTween(realv)` 분기 + 3-상태
	릴레이션 슬롯 + override 정책(`base/tween-plan.md` "3-상태 저장" 분기 1~3,
	"override 정책" 절, "옵션 값 모양" 절). 엔진은 mock `TweenService`(보간 없음 —
	Create/Play/Cancel 기록)와 `TweenInfo` 심(인자 기록)으로 대체 — 실제 보간·
	Cancel 유지·Finish 스냅의 엔진 시맨틱은 Studio(brief Q7).

	CLI 실주행 심(spec.handlers 관용구): `getfenv(installProperty).game`(Reflection +
	TweenService), `getfenv(installProperty).TweenInfo`, `getfenv(D.New).Instance`, `q.isInst`.
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
;(getfenv(installProperty) :: any).Enum = { EasingStyle = { Quad = "Quad" }, EasingDirection = { Out = "Out" } }
;(getfenv(installEvent) :: any).game = gameShim
;(getfenv(q.D.New) :: any).Instance = { new = mock.Instance.new }
q.isInst = mock.isMockInstance

local Tween = q.Tween
local log = mock.tweenLog
local function lastTween(): any
	return log[#log].tween
end

print("=== 1. 첫 세팅 스냅 — Tween 값이어도 엔진 트윈 없이 즉시 Value, plain도 동일 ===")
do
	mock.resetTweenLog()
	local f = q.D.Frame({ Size = Tween({ Value = 10, Time = 0.3 }), Position = 5 }) :: any
	assert(f.Size == 10 and f.Position == 5, "snapped to Value / plain")
	assert(#log == 0, "no engine tween on first set")
	print("PASS")
end

print()
print("=== 2. 세팅된 뒤 Tween — Create·Play 1회, 슬롯에 {Tween, Value}; Info 우선·편의 필드 기본값 채움(H-333) ===")
do
	mock.resetTweenLog()
	local src = q.Source(0 :: any)
	local f = q.D.Frame({ Size = src }) :: any
	assert(f.Size == 0 and #log == 0, "first set via State: snap")
	src:Set(Tween({ Value = 20, Time = 0.5, Style = "S" }))
	assert(#log == 1 and lastTween().plays == 1, "engine tween created and played once")
	assert(log[1].props.Size == 20 and log[1].inst == f, "target property table")
	local info = log[1].info
	assert(info.__mockTweenInfo and info.args[1] == 0.5 and info.args[2] == "S", "given fields passed positionally")
	assert(info.args[3] == "Out" and info.args[4] == 0 and info.args[5] == false and info.args[6] == 0 and info.args.n == 6, "absent fields filled with the engine defaults (H-333)")
	assert(f.Size == 0, "no interpolation in the mock — property untouched until the engine writes")
	local myInfo = { custom = true }
	src:Set(Tween({ Value = 30, Info = myInfo, Time = 9 }))
	assert(#log == 2 and log[2].info == myInfo, "Info wins over convenience fields")
	print("PASS")
end

print()
print("=== 3. Tween→Tween 기본(Cancel) — 이전 Cancel 1, 스냅 없음, 새 Create ===")
do
	mock.resetTweenLog()
	local src = q.Source(0 :: any)
	local f = q.D.Frame({ Size = src }) :: any
	src:Set(Tween({ Value = 10 }))
	local first = lastTween()
	f.Size = 4 -- pretend the engine interpolated to 4
	src:Set(Tween({ Value = 20 }))
	assert(first.cancels == 1 and first.PlaybackState == "Cancelled", "previous tween cancelled first")
	assert(f.Size == 4, "Cancel keeps the interpolated value (no snap)")
	assert(#log == 2 and lastTween().plays == 1 and log[2].props.Size == 20, "new tween started")
	print("PASS")
end

print()
print("=== 4. Tween→Tween Finish — 이전 Cancel 뒤 prev.Value로 스냅, 그 다음 새 Create ===")
do
	mock.resetTweenLog()
	local src = q.Source(0 :: any)
	local f = q.D.Frame({ Size = src }) :: any
	src:Set(Tween({ Value = 10 }))
	local first = lastTween()
	f.Size = 4
	src:Set(Tween({ Value = 20, Override = "Finish" }))
	assert(first.cancels == 1, "previous cancelled")
	assert(f.Size == 10, "snapped to the previous target before the new tween")
	assert(#log == 2 and log[2].props.Size == 20, "new tween started after the snap")
	print("PASS")
end

print()
print("=== 5. Tween→plain — Cancel 뒤 즉시 덮어쓰기, Create 없음; plain→plain은 슬롯 true 유지 ===")
do
	mock.resetTweenLog()
	local src = q.Source(0 :: any)
	local f = q.D.Frame({ Size = src }) :: any
	src:Set(Tween({ Value = 10 }))
	local first = lastTween()
	src:Set(7)
	assert(first.cancels == 1 and f.Size == 7 and #log == 1, "cancel then overwrite, no new engine tween")
	src:Set(8)
	assert(f.Size == 8 and #log == 1, "plain after plain: direct write")
	src:Set(Tween({ Value = 9 }))
	assert(#log == 2, "tween after plain: animates (slot was true)")
	print("PASS")
end

print()
print("=== 6. Mapped 값·None 재디스패치(nil 쓰기 + 활성 트윈 취소 — Q33, H-352 역전)·다른 프로퍼티는 독립 슬롯 ===")
do
	mock.resetTweenLog()
	local src = q.Source(0 :: any)
	local pos = q.Source(1 :: any)
	local f = q.D.Frame({ Size = src, Position = pos }) :: any
	local FAST = Tween({ Value = 0, Time = 0.1 })
	src:Set(FAST:Mapped(function() return 50 end))
	assert(#log == 1 and log[1].props.Size == 50 and log[1].info.args[1] == 0.1, "Mapped keeps options, swaps Value")
	pos:Set(Tween({ Value = 2 }))
	assert(#log == 2 and log[2].props.Position == 2, "independent slot per property")
	src:Set(q.None)
	assert(f.Size == nil and log[1].tween.cancels == 1, "None → nil is WRITTEN and the active tween is cancelled (Q33)")
	src:Set(7)
	assert(f.Size == 7 and #log == 2, "a plain value after the release writes without a new engine tween")
	print("PASS")
end

print("=== 7. Q8 (a) Animate 아래 nil/None 통과(해제 가능); Q25 (2026-09-08, 옛 Q12 신원 모델 대체) 값 dedup: 같은 목표 Value면 무동작(취소·재시작 0 — 새 객체여도), Dedup=false면 재시작 ===")
do
	mock.resetTweenLog()
	local src = q.Source(0 :: any)
	local f = q.D.Frame({ Size = src:Apply(q.Animate({ Time = 0.2 })) }) :: any
	src:Set(10)
	assert(#log == 1 and log[1].props.Size == 10, "first animated set")
	src:Set(10) -- H-391 재현 경로 — 같은 값 재발행(Animate는 매번 새 Tween 객체를 만든다)
	assert(#log == 1 and lastTween().cancels == 0, "Q25: same target VALUE — no cancel, no new engine tween")
	src:Set(q.None)
	assert(#log == 1 and f.Size == nil and lastTween().cancels == 1, "Q8: None passes Animate untouched → Property writes nil, active tween cancelled (Q33)")
	src:Set(nil)
	assert(#log == 1 and f.Size == nil, "Q8: nil passes Animate untouched → nil written (Q33)")
	local src2 = q.Source(0 :: any)
	q.D.Frame({ Size = src2:Apply(q.Animate({ Time = 0.2, Dedup = false })) })
	src2:Set(10)
	src2:Set(10)
	assert(#log == 3 and log[3].props.Size == 10 and log[2].tween.cancels == 1, "Animate{ Dedup = false } → Tween.Dedup = false: the same target re-triggers (cancel + new tween)")
	-- hand-built Tweens, no Animate: equal Value folds regardless of object/options; Dedup=false restarts
	mock.resetTweenLog()
	local g = q.D.Frame({ Size = Tween({ Value = 0, Time = 0.1 }) }) :: any -- snapped record { Value = 0 }
	q.Dispatch.process(g, "Size", Tween({ Value = 10, Time = 0.9 }), 1)
	assert(#log == 1, "new target: Create")
	q.Dispatch.process(g, "Size", Tween({ Value = 10, Time = 0.2 }), 1)
	assert(#log == 1 and log[1].tween.cancels == 0, "options differ (Time) but Value is equal — not a comparison target, folded")
	q.Dispatch.process(g, "Size", Tween({ Value = 10, Time = 0.2, Dedup = false }), 1)
	assert(#log == 2 and log[1].tween.cancels == 1, "Tween{ Dedup = false }: restart even with the same Value")
	print("PASS")
end

print()
print("=== 8. Q26 (a) (2026-09-08) — 첫 스냅도 { Value }: 같은 목표 재발행은 엔진 트윈 0, 다른 목표는 Create 1, plain은 여전히 true ===")
do
	mock.resetTweenLog()
	local t1 = Tween({ Value = 10, Time = 0.3 })
	local src = q.Source(t1 :: any)
	local f = q.D.Frame({ Size = src }) :: any
	assert(f.Size == 10 and #log == 0, "first set: snap, no engine tween")
	src:Set(t1) -- before Q26 this made a same→same engine tween
	assert(#log == 0, "same target re-emitted after the snap: folded (no Create)")
	src:Set(Tween({ Value = 10, Time = 0.3 })) -- a different object, equal Value — Q25 value dedup
	assert(#log == 0, "equal Value in a fresh object: still folded")
	local t2 = Tween({ Value = 20, Time = 0.3 })
	src:Set(t2)
	assert(#log == 1 and lastTween().cancels == 0, "a different Tween after a snapped record: Create 1, nothing to cancel")
	-- Finish against a snapped record has nothing to snap to (the property already holds Value)
	mock.resetTweenLog()
	local g = q.D.Frame({ Size = Tween({ Value = 1, Time = 0.1 }) }) :: any
	g.Size = 5 -- external write
	q.Dispatch.process(g, "Size", Tween({ Value = 9, Time = 0.1, Override = "Finish" }), 1)
	assert(g.Size == 5 and #log == 1, "Finish over a snapped record: no re-snap of the old value, just the new Create")
	print("PASS")
end

print("=== ALL PASS ===")
