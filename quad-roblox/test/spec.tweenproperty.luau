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
local function lastTween(): any
	return log[#log].tween
end

print("=== 1. 첫 세팅 스냅 — Tween 값이어도 엔진 트윈 없이 즉시 Value, plain도 동일 ===")
do
	mock.resetTweenLog()
	local f = q.Declaration.Frame({ Size = Tween({ Value = 10, Time = 0.3 }), Position = 5 }) :: any
	assert(f.Size == 10 and f.Position == 5, "snapped to Value / plain")
	assert(#log == 0, "no engine tween on first set")
	print("PASS")
end

print()
print("=== 2. 세팅된 뒤 Tween — Create·Play 1회, 슬롯에 {Tween, Value}; Info 우선·편의 필드 기본값 채움(H-333) ===")
do
	mock.resetTweenLog()
	local src = q.Source(0 :: any)
	local f = q.Declaration.Frame({ Size = src }) :: any
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
	local f = q.Declaration.Frame({ Size = src }) :: any
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
	local f = q.Declaration.Frame({ Size = src }) :: any
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
	local f = q.Declaration.Frame({ Size = src }) :: any
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
	local f = q.Declaration.Frame({ Size = src, Position = pos }) :: any
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
	local f = q.Declaration.Frame({ Size = src:Apply(q.Animate({ Time = 0.2 })) }) :: any
	src:Set(10)
	assert(#log == 1 and log[1].props.Size == 10, "first animated set")
	src:Set(10) -- H-391 재현 경로 — 같은 값 재발행(Animate는 매번 새 Tween 객체를 만든다)
	assert(#log == 1 and lastTween().cancels == 0, "Q25: same target VALUE — no cancel, no new engine tween")
	src:Set(q.None)
	assert(#log == 1 and f.Size == nil and lastTween().cancels == 1, "Q8: None passes Animate untouched → Property writes nil, active tween cancelled (Q33)")
	src:Set(nil)
	assert(#log == 1 and f.Size == nil, "Q8: nil passes Animate untouched → nil written (Q33)")
	local src2 = q.Source(0 :: any)
	q.Declaration.Frame({ Size = src2:Apply(q.Animate({ Time = 0.2, Dedup = false })) })
	src2:Set(10)
	src2:Set(10)
	assert(#log == 3 and log[3].props.Size == 10 and log[2].tween.cancels == 1, "Animate{ Dedup = false } → Tween.Dedup = false: the same target re-triggers (cancel + new tween)")
	-- hand-built Tweens, no Animate: equal Value folds regardless of object/options; Dedup=false restarts
	mock.resetTweenLog()
	local g = q.Declaration.Frame({ Size = Tween({ Value = 0, Time = 0.1 }) }) :: any -- snapped record { Value = 0 }
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
	local f = q.Declaration.Frame({ Size = src }) :: any
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
	local g = q.Declaration.Frame({ Size = Tween({ Value = 1, Time = 0.1 }) }) :: any
	g.Size = 5 -- external write
	q.Dispatch.process(g, "Size", Tween({ Value = 9, Time = 0.1, Override = "Finish" }), 1)
	assert(g.Size == 5 and #log == 1, "Finish over a snapped record: no re-snap of the old value, just the new Create")
	print("PASS")
end

print()
print("=== 9. 2026-09-08 round8 H-502/K-9 — Animate의 State 옵션 오류는 drive 깊이에서도 사용자 줄(D.Frame)을 blame ===")
do
	local src = q.Source(1)
	local badTime = q.Source("x")
	local ok, err = pcall(function()
		return q.Declaration.Frame({ Size = src:Apply(q.Animate({ Time = badTime })) })
	end)
	assert(not ok and string.find(tostring(err), "Time must be a number", 1, true) ~= nil, "State option validated at drive: " .. tostring(err))
	mock.assertBlamesUser(err, "spec.tweenproperty.luau", "drive-path blame")
	print("PASS")
end

print()
print("=== 10. round11 H-547 (2026-09-17) → Q65 (2026-09-18) — 기록은 (inst, k)에 인스턴스 수명 동안 남는다: 철거·핸들러 교체 뒤에도 '쓴 적 있음'이라 다음 Tween은 애니메이션; 진행 중이던 트윈만 Cancel 뒤 true; retractor는 GC를 견딘다 ===")
do
	mock.resetTweenLog()
	-- (1) plain → teardown → Tween: ANIMATES — the property was written once, that is what "first set" means
	local f = q.Declaration.Frame({ Size = 1 }) :: any
	q.Dispatch.retractFrom(f, "Size", 1)
	q.Dispatch.drive(f, { Size = Tween({ Value = 5, Time = 0.3 }) })
	assert(f.Size == 1 and #log == 1, "not a first set any more: engine tween, no snap")
	-- (1b) Q65's three paths — the handler switch (plain ↔ State, via None) no longer erases the record
	mock.resetTweenLog()
	local h = q.Declaration.Frame({ Size = 0 }) :: any
	q.Dispatch.drive(h, { Size = q.Source(Tween({ Value = 10, Time = 0.3 })) }) -- plain → State
	assert(#log == 1, "plain → State: animates (was: snapped)")
	local hs = q.Source(Tween({ Value = 20, Time = 0.3 }) :: any)
	q.Dispatch.drive(h, { Size = hs }) -- State → State (same handler, value swap): animates
	assert(#log == 2, "State swap animates")
	hs:Set(q.None) -- writes nil (Q33) — the mock accepts it; the running tween is cancelled
	hs:Set(Tween({ Value = 30, Time = 0.3 }))
	assert(#log == 3, "after None: still not a first set — animates (was: snapped)")
	-- (2) Tween → plain → (GC in the window) → teardown → Tween: still snaps
	mock.resetTweenLog()
	local src = q.Source(0 :: any)
	local g = q.Declaration.Frame({ Size = src }) :: any
	src:Set(Tween({ Value = 20, Time = 0.5 }))
	assert(#log == 1, "engine tween")
	-- GC INSIDE the process window (code-review): the mock fires the property-changed signal
	-- synchronously from `__newindex`, so an OnChange that collects runs while Dispatch has
	-- parked NOOP in the chain slot — the only moment the weak retractor cache is unanchored
	q.Dispatch.drive(g, { q.OnChange("Size", function()
		collectgarbage()
		collectgarbage()
	end) })
	src:Set(7) -- plain after a Tween: the retractor must not depend on the weak cache surviving
	q.Dispatch.retractFrom(g, "Size", 1)
	assert(log[1].tween.cancels >= 1, "teardown cancelled the running tween")
	q.Dispatch.drive(g, { Size = Tween({ Value = 9, Time = 0.5 }) })
	assert(g.Size == 7 and #log == 2, "re-driven Tween animates (the record survived teardown)")
	-- (3) a RUNNING tween at teardown: Cancel, and the record forgets the target (true) — a re-declared
	-- same-target Tween must play (G-7), not be deduped against a value the property never reached
	mock.resetTweenLog()
	local k = q.Declaration.Frame({ Size = 0 }) :: any
	q.Dispatch.drive(k, { Size = Tween({ Value = 50, Time = 1 }) })
	assert(#log == 1 and log[1].tween.cancels == 0, "running")
	q.Dispatch.retractFrom(k, "Size", 1)
	assert(log[1].tween.cancels == 1, "cancelled at teardown")
	q.Dispatch.drive(k, { Size = Tween({ Value = 50, Time = 1 }) })
	assert(#log == 2, "same target after a cancelled tween plays again (record was downgraded to true)")
	-- (4) code-review: a tween that COMPLETED before teardown (the property holds its target) keeps its
	-- { Value } record — a re-declared same target is deduped, not replayed as a no-op tween
	mock.resetTweenLog()
	local m = q.Declaration.Frame({ Size = 0 }) :: any
	q.Dispatch.drive(m, { Size = Tween({ Value = 60, Time = 1 }) })
	m.Size = 60 -- the mock does not interpolate: stand in for the engine reaching the target
	q.Dispatch.retractFrom(m, "Size", 1)
	q.Dispatch.drive(m, { Size = Tween({ Value = 60, Time = 1 }) })
	assert(#log == 1, "completed tween's target survives teardown: same-target re-declare is deduped")
	q.Dispatch.drive(m, { Size = Tween({ Value = 61, Time = 1 }) })
	assert(#log == 2, "a new target animates")
	print("PASS")
end

print("=== 11. [2026-09-21 docs-review 1-5] 콜백 Started/Completed/Cancelled — 스냅은 Started→Completed 동기, 교체는 이전 Cancelled→새 Started, 자연 완료는 엔진 Completed(Completed)에서만, 끝난 트윈의 Cancel(엔진 재발화)은 무시, 철거는 진행 중일 때만 Cancelled, Dedup 스킵은 무발화, Time=0은 엔진 트윈 없는 스냅 ===")
do
	mock.resetTweenLog()
	local order: { string } = {}
	local function cbs(tag: string): any
		return {
			Started = function() table.insert(order, tag .. ":started") end,
			Completed = function() table.insert(order, tag .. ":completed") end,
			Cancelled = function() table.insert(order, tag .. ":cancelled") end,
		}
	end
	local function tw(tag: string, value: any, extra: any?): any
		local opts: any = cbs(tag)
		opts.Value = value
		opts.Time = 0.3
		if extra then for k2, v2 in extra do opts[k2] = v2 end end
		return Tween(opts)
	end
	local src = q.Source(tw("a", 1) :: any)
	local f = q.Declaration.Frame({ Size = src }) :: any
	assert(f.Size == 1 and #log == 0, "first set snaps")
	assert(table.concat(order, ",") == "a:started,a:completed", "snap: Started then Completed, synchronously: " .. table.concat(order, ","))
	table.clear(order)
	-- replacement while running: old Cancelled → new Started, nothing else yet
	src:Set(tw("b", 2))
	local b = lastTween()
	assert(b.plays == 1 and table.concat(order, ",") == "b:started", "engine tween b started: " .. table.concat(order, ","))
	table.clear(order)
	src:Set(tw("c", 3))
	assert(b.cancels == 1 and table.concat(order, ",") == "b:cancelled,c:started", "order on replace: " .. table.concat(order, ","))
	table.clear(order)
	local c = lastTween()
	-- natural finish: engine Completed(Completed) → c:completed once; the connection is gone afterwards
	c:simulateCompleted()
	assert(table.concat(order, ",") == "c:completed", "natural finish: " .. table.concat(order, ","))
	table.clear(order)
	f.Size = 3 -- the engine wrote the target
	-- a finished tween replaced: NO Cancelled (Done), no engine Cancel either; new Started
	src:Set(tw("d", 4))
	assert(c.cancels == 0 and table.concat(order, ",") == "d:started", "finished tween is not cancelled again: " .. table.concat(order, ","))
	table.clear(order)
	local d = lastTween()
	-- the engine re-fires Completed(Cancelled) for a finished tween: quad ignores it (disconnected)
	c:Cancel()
	assert(#order == 0, "stray engine Cancelled after finish is ignored")
	-- teardown while running → Cancelled; teardown after finish → nothing
	q.Dispatch.retractFrom(f, "Size", 1)
	assert(d.cancels == 1 and table.concat(order, ",") == "d:cancelled", "teardown cancels a running tween: " .. table.concat(order, ","))
	table.clear(order)
	local g = q.Declaration.Frame({ Size = 0 }) :: any
	q.Dispatch.drive(g, { Size = tw("e", 5) })
	local e = lastTween()
	e:simulateCompleted()
	g.Size = 5
	table.clear(order)
	q.Dispatch.retractFrom(g, "Size", 1)
	assert(e.cancels == 0 and #order == 0, "teardown after a natural finish fires nothing")
	-- Dedup skip: same target → nothing fires, tween keeps running
	mock.resetTweenLog()
	local src2 = q.Source(0 :: any)
	local h = q.Declaration.Frame({ Size = src2 }) :: any
	src2:Set(tw("p", 7))
	table.clear(order)
	src2:Set(tw("q", 7))
	assert(#log == 1 and #order == 0, "dedup-skipped tween fires nothing")
	-- Time = 0 (Info-less) = snap with callbacks, no engine tween; a running tween before it is cancelled first
	table.clear(order)
	src2:Set(tw("z", 9, { Time = 0 }))
	assert(#log == 1 and h.Size == 9, "Time=0: no engine tween, value written")
	assert(table.concat(order, ",") == "p:cancelled,z:started,z:completed", "Time=0 order: " .. table.concat(order, ","))
	-- callback-less tweens make no connection (record shape unchanged)
	mock.resetTweenLog()
	local src3 = q.Source(0 :: any)
	local _i = q.Declaration.Frame({ Size = src3 }) :: any
	src3:Set(Tween({ Value = 1, Time = 0.3 }))
	assert(#lastTween().Completed.connections == 0, "no connection without Completed/Cancelled")
	-- code-review 2026-09-21 (a): deferred-notice window — PlaybackState already Completed but the signal not yet
	-- delivered; a synchronous replacement counts as a FINISH (Completed once, no Cancel/Cancelled), and the
	-- late engine notice is ignored
	mock.resetTweenLog()
	table.clear(order)
	local src4 = q.Source(0 :: any)
	local _j = q.Declaration.Frame({ Size = src4 }) :: any
	src4:Set(tw("w", 1))
	local w = lastTween()
	table.clear(order)
	w.PlaybackState = "Completed" -- engine reached the target; `Completed` still queued
	src4:Set(tw("x", 2))
	assert(w.cancels == 0 and table.concat(order, ",") == "w:completed,x:started", "window: finish, not cancel: " .. table.concat(order, ","))
	table.clear(order)
	w.Completed:Fire("Completed") -- the late notice
	assert(#order == 0, "late notice ignored")
	-- code-review (b): a throwing Cancelled callback settles the record first — the next write does not
	-- Cancel/fire the same tween again, and the new tween still starts.
	-- [관측 — 계약 아님] (2026-10-02 user decision, `architecture.md` "예외 안전성 계약"): the state after a
	-- throwing callback is pinned here as the current observation, not promised (roblox/06 says so too).
	mock.resetTweenLog()
	local src5 = q.Source(0 :: any)
	local _k = q.Declaration.Frame({ Size = src5 }) :: any
	src5:Set(Tween({ Value = 1, Time = 0.3, Cancelled = function() error("boom") end }))
	local boom = lastTween()
	local okB = pcall(function() src5:Set(Tween({ Value = 2, Time = 0.3 })) end)
	assert(not okB and boom.cancels == 1, "callback error propagates once")
	src5:Set(Tween({ Value = 3, Time = 0.3 }))
	assert(boom.cancels == 1 and #log == 3, "settled record is not cancelled again; new tween created")
	-- code-review (c): Time=0 with a delay/repeat/reverse still takes the engine path
	mock.resetTweenLog()
	local src6 = q.Source(0 :: any)
	local _l = q.Declaration.Frame({ Size = src6 }) :: any
	src6:Set(Tween({ Value = 1, Time = 0.3 }))
	src6:Set(Tween({ Value = 2, Time = 0, DelayTime = 1 }))
	assert(#log == 2, "Time=0 + DelayTime → engine tween, not a snap")
	-- code-review (d): Cb is released after the callback fired; no Cb without Completed/Cancelled
	mock.resetTweenLog()
	local src7 = q.Source(0 :: any)
	local m = q.Declaration.Frame({ Size = src7 }) :: any
	src7:Set(Tween({ Value = 1, Time = 0.3, Started = function() end }))
	local recS = (getfenv(installProperty) :: any) -- (no direct slot access; the Started-only value makes no connection)
	assert(#lastTween().Completed.connections == 0 and recS ~= nil, "Started alone: no connection")
	src7:Set(Tween({ Value = 2, Time = 0.3, Completed = function() end }))
	local n = lastTween()
	n:simulateCompleted()
	m.Size = 2
	q.Dispatch.retractFrom(m, "Size", 1)
	assert(n.cancels == 0, "finished tween not cancelled at teardown")
	-- round12 Q71 (`H-594`): Destroy runs no retractor — the tween finishes on the corpse; its Completed
	-- notice is ignored (isClaimed false: gcconn cut), and nothing is cancelled
	mock.resetTweenLog()
	table.clear(order)
	local src8 = q.Source(0 :: any)
	local o = q.Declaration.Frame({ Size = src8 }) :: any
	src8:Set(tw("d", 1))
	local dz = lastTween()
	table.clear(order)
	o:Destroy()
	dz:simulateCompleted()
	assert(#order == 0 and dz.cancels == 0, "destroyed Instance: Completed ignored, not cancelled: " .. table.concat(order, ","))
	print("PASS")
end

print()
print("=== 12. [round13 묶음 1 2026-09-28 round13 tween-callback-structure §8-1] 콜백 인자 (inst, prop, value) — 모든 발화 자리; 모으고→쓰고→부른다(옛 정산 콜백은 새 기록 뒤; Cancelled 안 재진입이 순서대로 한 트윈인 것은 관측 — 계약 아님, round14 Q163); 철거는 통지 창이어도 Cancelled(Q99 c); 시체 위 retractFrom은 콜백 없음(Q82 (a)) ===")
do
	mock.resetTweenLog()
	local seen: { string } = {}
	local function tw(tag: string, value: any, extra: any?): any
		local function mk(ev: string): any
			return function(inst: any, prop: string, v: any)
				table.insert(seen, `{tag}:{ev}({inst.Name},{prop},{tostring(v)})`)
			end
		end
		local opts: any = { Value = value, Time = 0.3, Started = mk("S"), Completed = mk("C"), Cancelled = mk("X") }
		if extra then for k2, v2 in extra do opts[k2] = v2 end end
		return Tween(opts)
	end
	local function take(): string
		local s = table.concat(seen, " ")
		table.clear(seen)
		return s
	end
	local src = q.Source(tw("a", 1) :: any)
	local f = q.Declaration.Frame({ Name = "F", Size = src }) :: any
	assert(take() == "a:S(F,Size,1) a:C(F,Size,1)", "snap args")
	src:Set(tw("b", 2))
	assert(take() == "b:S(F,Size,2)", "engine Started args")
	src:Set(tw("c", 3))
	assert(take() == "b:X(F,Size,2) c:S(F,Size,3)", "replacement: old Cancelled carries the OLD target")
	local c = lastTween()
	c.PlaybackState = "Completed" -- deferred-notice window
	src:Set(tw("d", 4))
	assert(take() == "c:C(F,Size,3) d:S(F,Size,4)", "window replacement: old Completed, then new Started")
	lastTween():simulateCompleted()
	assert(take() == "d:C(F,Size,4)", "natural finish args (read off the record)")
	-- teardown inside the window is Cancelled (Q99 c)
	src:Set(tw("e", 5))
	take()
	lastTween().PlaybackState = "Completed"
	q.Dispatch.retractFrom(f, "Size", 1)
	assert(take() == "e:X(F,Size,5)", "teardown in the window reports Cancelled: " .. table.concat(seen, " "))
	-- re-entry from the old Cancelled: lands after this write, one tween left, final = the inner value.
	-- OBSERVED — NOT A CONTRACT (round14 Q163 (a), user decision 2026-10-04): the next tween is chained from
	-- `Completed`; re-writing the same State from `Started`/`Cancelled` is undefined (consistent on this
	-- replacement path today, split on the teardown path). Kept as an observation of today's behaviour.
	mock.resetTweenLog()
	local s2 = q.Source(0 :: any)
	local g = q.Declaration.Frame({ Name = "G", Size = s2 }) :: any
	local once = false
	s2:Set(Tween({ Value = 10, Time = 0.3, Cancelled = function()
		if not once then once = true; s2:Set(Tween({ Value = 77, Time = 0.3 })) end
	end }))
	s2:Set(Tween({ Value = 20, Time = 0.3 }))
	local playing = 0
	for _, e in log do if e.tween.PlaybackState == "Playing" then playing += 1; assert(e.props.Size == 77, "the playing tween is the inner value") end end
	assert(playing == 1 and s2:Get().Value == 77, "observed (not a contract): Cancelled re-entry: one tween, toward 77")
	-- corpse: no callbacks, the engine tween is still cancelled
	mock.resetTweenLog()
	local h = q.Declaration.Frame({ Name = "H", Size = 0 }) :: any
	q.Dispatch.process(h, "Size", tw("z", 9), 1)
	take()
	local zt = lastTween()
	h:Destroy()
	q.Dispatch.retractFrom(h, "Size", 1)
	assert(take() == "" and zt.cancels == 1, "corpse retractFrom: Cancel, no callback")
	local _ = g
	print("PASS")
end

print()
print("=== 13. 프로바이더 브랜드 isTween은 모듈 BrandPredicates에 등록돼 있다(Q106 후속); 중괄호 잊은 Tween·배열 자리 Tween 안내 (시체 위 process의 새 값 콜백 차단(code-review 2026-09-28)은 round14 Q166 (a)로 걷힘 — UB 입력, q.debug는 Dispatch.process 입구가 알림) ===")
do
	assert(q.BrandPredicates:Is(q.isTween), "RobloxFactory registers isTween in the module's BrandPredicates")
	local okT, errT = pcall(function()
		q.Dispatch.drive(q.Declaration.Frame({}), Tween({ Value = 1 }) :: any)
	end)
	assert(not okT and string.find(tostring(errT), "Quad0083", 1, true) ~= nil and string.find(tostring(errT), "got Tween", 1, true) ~= nil, "braces-forgotten Tween is refused and named: " .. tostring(errT))
	-- [2026-10-01 user decision] a registered brand means its owner is installed: a Tween with no handler
	-- gets the quad-value hint, not "the provider (e.g. quad-roblox) is not initialized" — quad-roblox IS
	local okA, errA = pcall(function()
		q.Dispatch.process(q.Declaration.Frame({}), 1, Tween({ Value = 1 }), 1)
	end)
	assert(not okA and string.find(tostring(errA), "brand: Tween)", 1, true) ~= nil
		and string.find(tostring(errA), "no handler at an array position", 1, true) ~= nil
		and string.find(tostring(errA), "provider", 1, true) == nil, "Tween at an array position: quad-value hint: " .. tostring(errA))
	print("PASS")
end

print()
print("=== round14 Q161·Q182 (a) (2026-10-06) — Tween은 생성 때 q.Protocols.DispatchHint에 등록하고, 매치 실패 안내를 스스로 준다(문자 키: 필드가 아닐 수 있음 / 숫자 키: nil → 일반 꼬리) ===")
do
	local quadAny: any = q
	local t = Tween({ Value = 1 })
	assert(quadAny.Protocols.DispatchHint:Is(t), "registered at creation")
	assert(quadAny.Protocols.DispatchHint:Is((t :: any):Mapped(function(v: number): number return v end)), "copies too (newTween)")
	local frame = quadAny.Declaration.Frame({})
	local okS, errS = pcall(function()
		quadAny.Dispatch.process(frame, "Sise", t, 1)
	end)
	assert(not okS and string.find(tostring(errS), "brand: Tween)", 1, true) ~= nil
		and string.find(tostring(errS), "this key may not be a field of this element (a typo, a read-only field, or one from another class)", 1, true) ~= nil
		and string.find(tostring(errS), "belongs in a numeric (array) slot", 1, true) == nil, "string key: the Tween's own hint: " .. tostring(errS))
	local okN, errN = pcall(function()
		quadAny.Dispatch.process(frame, 1, t, 1)
	end)
	assert(not okN and string.find(tostring(errN), "no handler at an array position", 1, true) ~= nil, "numeric key: the hook returns nil → the generic tail: " .. tostring(errN))
	print("PASS")
end

print()
print("=== round14 Q174 보강 (b) (2026-10-06) — q.debug 되먹임 감지기: Completed에서 같은 원천에 다음 Tween을 잇는 연쇄는 스냅(동기)이어도 정의(Q163·Q164 (a′)) — 0줄; Started·Cancelled 안 되쓰기는 정의되지 않음(Q163) — 1줄 ===")
do
	local LINE = "Observer: a change reached this Observer while its own fn was running"
	-- the print lives in quad-base's Observer.luau — capture that module's env (spec.observer 14's technique)
	local env: any = getfenv((q.Source(0):Observer() :: any).WeakSubscribe)
	local lines: { string } = {}
	local function capture(f: () -> ())
		table.clear(lines)
		local old = rawget(env, "print")
		env.print = function(...: any)
			table.insert(lines, table.concat({ ... }, " "))
		end
		local ok, err = pcall(f)
		env.print = old
		assert(ok, tostring(err))
	end
	local function count(): number
		local n = 0
		for _, l in lines do
			if string.find(l, LINE, 1, true) ~= nil then
				n += 1
			end
		end
		return n
	end
	q.debug = true
	-- (a) a snap `Completed` chain (Info-less `Time = 0` — what `Animate` hands over with `CanAnimate = false`):
	-- each Completed sets the next Tween on the same Source, synchronously inside its dispatch; the chain ends
	local src = q.Source(0 :: any)
	local f = q.Declaration.Frame({ Name = "A", Size = src }) :: any
	local hops = 0
	local function step(): any
		return Tween({ Value = hops, Time = 0, Completed = function()
			if hops < 3 then
				hops += 1
				src:Set(step())
			end
		end })
	end
	capture(function()
		src:Set(step())
	end)
	assert(hops == 3 and f.Size == 3, "the chain ran to its end: hops " .. hops .. ", Size " .. tostring(f.Size))
	assert(count() == 0, "snap Completed chain: no line: " .. table.concat(lines, " | "))
	-- the first-set snap (mount) chains the same way — also no line
	capture(function()
		local hops0 = 0
		local src0 = q.Source(0 :: any)
		local function step0(): any
			return Tween({ Value = hops0, Time = 0.3, Completed = function()
				if hops0 < 2 then
					hops0 += 1
					src0:Set(step0())
				end
			end })
		end
		src0:Set(step0())
		q.Declaration.Frame({ Name = "M", Size = src0 })
	end)
	assert(count() == 0, "mount snap Completed: no line: " .. table.concat(lines, " | "))
	-- (b) negative controls: the same write from `Started`, and from the previous value's `Cancelled`
	capture(function()
		local s2 = q.Source(0 :: any)
		q.Declaration.Frame({ Name = "B", Size = s2 })
		local once = true
		s2:Set(Tween({ Value = 1, Time = 0.3, Started = function()
			if once then
				once = false
				s2:Set(Tween({ Value = 9, Time = 0.3 }))
			end
		end }))
	end)
	assert(count() == 1, "re-write from Started: one line: " .. table.concat(lines, " | "))
	capture(function()
		local s3 = q.Source(0 :: any)
		q.Declaration.Frame({ Name = "C", Size = s3 })
		local once = true
		s3:Set(Tween({ Value = 10, Time = 0.3, Cancelled = function()
			if once then
				once = false
				s3:Set(Tween({ Value = 77, Time = 0.3 }))
			end
		end }))
		s3:Set(Tween({ Value = 20, Time = 0.3 }))
	end)
	assert(count() == 1, "re-write from Cancelled: one line: " .. table.concat(lines, " | "))
	-- (c) round14 확인 패스 code-review 1: the registered `Completed` frame exempts only the NEAREST Observer outside
	-- it (S2's StateHandler Observer, which dispatched the Tween) — a user Observer O further out, whose fn set S2,
	-- whose snap Tween's `Completed` then writes O's own upstream S, is a real loop: one line (was 0 — the frame
	-- ended the whole walk)
	capture(function()
		local s = q.Source(0)
		local s2 = q.Source(0 :: any)
		q.Declaration.Frame({ Name = "O", Size = s2 })
		local wrote = false
		local o = s:Observer(function(_, _, from)
			if from == nil then
				return -- install run: nothing
			end
			s2:Set(Tween({ Value = 5, Time = 0, Completed = function()
				if not wrote then
					wrote = true
					s:Set(2) -- O's upstream, written under O's own run
				end
			end }))
		end):Subscribe()
		s:Set(1)
		assert(wrote, "the snap Completed ran inside O's run")
		o:Unsubscribe()
	end)
	assert(count() == 1, "a user Observer outside the Completed chain: one line: " .. table.concat(lines, " | "))
	q.debug = false
	print("PASS")
end

print()
print("=== round14 Q184 (a) — 쓰기가 동기로 일으킨 신호가 같은 자리에 다시 들어오면 바깥 처리가 물러난다(안쪽 기록이 남는다) ===")
-- Immediate signals (and this mock): `inst[k] = v` fires the changed signal synchronously, an `OnChange`
-- feeds the same source again, and that inner process records/plays its own tween BEFORE the outer one
-- writes its record. The outer process re-checks the slot right after each of its writes and yields when
-- it changed — the inner tween stays recorded, so teardown and the next write can still cancel it.
do
	local LOG: { string } = {}
	local function T(val: any, extra: any?): any
		local t: any = {
			Value = val,
			Started = function(_: any, _: any, v: any) table.insert(LOG, "S" .. tostring(v)) end,
			Cancelled = function(_: any, _: any, v: any) table.insert(LOG, "X" .. tostring(v)) end,
			Completed = function(_: any, _: any, v: any) table.insert(LOG, "C" .. tostring(v)) end,
		}
		for kk, vv in extra or {} do t[kk] = vv end
		return Tween(t)
	end
	local function playing(): string
		local ts = {}
		for _, e in log do
			if e.tween.PlaybackState == "Playing" then table.insert(ts, tostring(e.props.Size)) end
		end
		return table.concat(ts, ",")
	end
	-- `first`: what the source holds before the re-entering write (nil = stay at the first-set plain value)
	local function scene(name: string, first: any?, write: any, trigger: any, wantLog: string)
		mock.resetTweenLog()
		table.clear(LOG)
		local src = q.Source(0 :: any)
		local armed = false
		local f = q.Declaration.Frame({ Size = src, q.OnChange("Size", function(v: any)
			if armed and v == trigger then
				armed = false
				src:Set(T(99))
			end
		end) }) :: any
		if first ~= nil then src:Set(first) end
		armed = true
		src:Set(write)
		assert(not armed, name .. ": the write's signal re-entered")
		assert(playing() == "99", name .. ": exactly the inner tween plays, got [" .. playing() .. "]")
		assert(table.concat(LOG, " ") == wantLog, name .. ": callbacks " .. table.concat(LOG, " "))
		table.clear(LOG)
		q.Dispatch.retractFrom(f, "Size", 1)
		assert(playing() == "" and table.concat(LOG, " ") == "X99", name .. ": teardown cancels the inner tween: [" .. playing() .. "] " .. table.concat(LOG, " "))
	end
	-- plain value over an active tween
	scene("plain", T(10), 7, 7, "S10 X10 S99")
	-- Finish: the snap to the previous target is the write that re-enters; the outer tween (20) never starts
	scene("Finish", T(10), T(20, { Override = "Finish" }), 10, "S10 X10 S99")
	-- zero-time snap
	scene("zero-time", T(10), T(5, { Time = 0 }), 5, "S10 X10 S99")
	-- plain over a plain slot (no previous tween)
	scene("plain from plain", nil, 3, 3, "S99")
	-- and the next plain write still cancels what the re-entry left
	do
		mock.resetTweenLog()
		table.clear(LOG)
		local src = q.Source(0 :: any)
		local armed = false
		local f = q.Declaration.Frame({ Size = src, q.OnChange("Size", function(v: any)
			if armed and v == 7 then
				armed = false
				src:Set(T(99))
			end
		end) }) :: any
		src:Set(T(10))
		armed = true
		src:Set(7)
		src:Set(5)
		assert(playing() == "" and f.Size == 5, "a later plain write cancels the inner tween: [" .. playing() .. "]")
	end
	print("PASS")
end

print()
print("=== round14 Q154 — Info 없는 Time = 0의 스냅은 재생할 것이 아무것도 없을 때만: Reverses나 RepeatCount가 있으면 엔진 트윈, 0·false로 적은 것은 없는 것과 같다 ===")
-- Contract: roblox/06 options ("`Info` 없이 `Time = 0`이고 `DelayTime`/`RepeatCount`/`Reverses`도 없으면(또는
-- 0·거짓) … 값을 그 자리에서 씁니다 … 그 셋 중 하나라도 있으면 평소대로 엔진 트윈"). The spec had
-- `Time = 0` alone and with `DelayTime`. Mutant (E69 PR10): the `Reverses ~= true` term dropped.
do
	local function settled(): (any, any)
		local src = q.Source(0 :: any)
		local f = q.Declaration.Frame({ Size = src }) :: any -- first set: Size is written, later Tweens animate
		mock.resetTweenLog()
		return src, f
	end
	for name, extra in { Reverses = { Reverses = true }, RepeatCount = { RepeatCount = 2 }, DelayTime = { DelayTime = 0.5 } } :: { [string]: { [string]: any } } do
		local src, f = settled()
		local opts: { [string]: any } = { Value = 5, Time = 0 }
		for key, value in extra do
			opts[key] = value
		end
		src:Set(Tween(opts))
		assert(#log == 1 and lastTween().plays == 1, "Time = 0 with " .. name .. " plays an engine tween: " .. #log)
		assert(f.Size == 0, "…and does not snap (the mock engine does not interpolate): " .. tostring(f.Size))
	end
	local src, f = settled()
	src:Set(Tween({ Value = 7, Time = 0, Reverses = false, RepeatCount = 0, DelayTime = 0 }))
	assert(#log == 0 and f.Size == 7, "Time = 0 with the three written as 0 / false is the snap: " .. #log .. " / " .. tostring(f.Size))
	print("PASS")
end

print()
print("=== ALL PASS ===")
