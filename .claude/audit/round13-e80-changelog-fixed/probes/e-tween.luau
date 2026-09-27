--!nocheck
-- E80 group E: Tween/Property Fixed bullets (F3 F27 F28 F40) + Changed C26
local H = require("../harness")
local L = require("../lib")
local q, D, mock = H.q, H.D, H.mock
local log = mock.tweenLog
local Tween = q.Tween

print("--- F27/F3: 철거 때 진행 중 Tween 취소; 같은 목표 재선언 재생; 첫 설정 기준 ---")
L.section(function()
	mock.resetTweenLog()
	local f = D.Frame { Size = 0 }
	q.Dispatch.drive(f, { Size = Tween({ Value = 50, Time = 1 }) })
	local t1 = log[#log] and log[#log].tween
	L.check("F27 engine tween running", #log == 1 and t1.cancels == 0, #log)
	q.Dispatch.retractFrom(f, "Size", 1)
	L.check("F27 retract cancels running tween", t1.cancels == 1, t1 and t1.cancels)
	q.Dispatch.drive(f, { Size = Tween({ Value = 50, Time = 1 }) })
	L.check("F27 same target after retract replays", #log == 2, #log)
	-- first-set criterion: plain -> retract -> Tween animates (not a snap)
	mock.resetTweenLog()
	local g = D.Frame { Size = 1 }
	q.Dispatch.retractFrom(g, "Size", 1)
	q.Dispatch.drive(g, { Size = Tween({ Value = 5, Time = 0.3 }) })
	L.check("F27 after retract of a written prop, Tween animates", #log == 1 and g.Size == 1, "#log=" .. #log .. " Size=" .. tostring(g.Size))
	-- shorthand: UICorner managed child destroyed while a tween on it runs
	mock.resetTweenLog()
	local cr = q.Source(8)
	local h = D.Frame { UICorner = cr }
	local kid = h:FindFirstChild("_quad_round")
	print("  managed child:", kid)
	-- F3: plain chain after a tween (GC in window) still cancels
	mock.resetTweenLog()
	local src = q.Source(0)
	local k = D.Frame { Size = src }
	src:Set(Tween({ Value = 20, Time = 0.5 }))
	q.Dispatch.drive(k, { q.OnChange("Size", function() collectgarbage("collect"); collectgarbage("collect") end) })
	src:Set(7)
	q.Dispatch.retractFrom(k, "Size", 1)
	L.check("F3 teardown after GC window cancelled", log[1] and log[1].tween.cancels >= 1, log[1] and log[1].tween.cancels)
	-- Override=Finish after value-kind change mid-tween continues from mid value (bullet's one-caveat) — observe only
	mock.resetTweenLog()
	local seat = q.Source(Tween({ Value = 10, Time = 1 }))
	local m = D.Frame { Size = 0 }
	q.Dispatch.drive(m, { Size = seat })
	print("  caveat run: #log=" .. #log)
end)

print("--- F28: 미claim 거부 문구 꼬리 구절 ---")
L.section(function()
	local foreign = mock.Instance.new("Frame")
	local m1 = L.err("F28 Slot", function() q.Slot():Add(foreign) end)
	local m2 = L.err("F28 InstanceChild", function() D.Frame { foreign } end)
	L.check("F28 both carry cross-instance tail", L.has(m1, "another quad module instance") and L.has(m2, "another quad module instance"), "")
end)

print("--- F40: Animate State에 Tween/State를 넣으면 blame이 호출 줄 ---")
L.section(function()
	local src = q.Source(1)
	local anim = src:Apply(q.Animate({ Time = 0.3 }))
	local f = D.Frame { Size = anim }
	local m, id = L.err("F40 Set(Tween)", function() src:Set(Tween({ Value = 2, Time = 1 })) end)
	L.check("F40 blame user line", L.has(m, "e-tween.luau") and not L.has(m, "Animate.luau"), id)
	local src2 = q.Source(1)
	local f2 = D.Frame { Size = src2:Apply(q.Animate({ Time = 0.3 })) }
	local m2, id2 = L.err("F40 Set(State)", function() src2:Set(q.Source(3)) end)
	L.check("F40 State blame user line", L.has(m2, "e-tween.luau") and not L.has(m2, "Animate.luau"), id2)
end)

print("--- C26: Info 없이 Time=0 Tween은 엔진 트윈 없이 스냅; DelayTime 등 있으면 전과 같음 ---")
L.section(function()
	mock.resetTweenLog()
	local s = q.Source(0)
	local f = D.Frame { Size = s }
	s:Set(Tween({ Value = 9, Time = 0 }))
	L.check("C26 Time=0 snaps without engine tween", #log == 0 and f.Size == 9, "#log=" .. #log .. " Size=" .. tostring(f.Size))
	s:Set(Tween({ Value = 4, Time = 0, DelayTime = 0.1 }))
	L.check("C26 DelayTime → engine tween", #log == 1, #log)
	mock.resetTweenLog()
	s:Set(Tween({ Value = 5, Time = 0, RepeatCount = 1 }))
	L.check("C26 RepeatCount → engine tween", #log == 1, #log)
	mock.resetTweenLog()
	s:Set(Tween({ Value = 6, Time = 0, Reverses = true }))
	L.check("C26 Reverses → engine tween", #log == 1, #log)
	mock.resetTweenLog()
	s:Set(Tween({ Value = 7, Time = 0, DelayTime = 0 }))
	print("  C26 DelayTime = 0 explicit: #log=" .. #log .. " Size=" .. tostring(f.Size))
	mock.resetTweenLog()
	s:Set(Tween({ Value = 8, Time = 0, Reverses = false }))
	print("  C26 Reverses = false explicit: #log=" .. #log .. " Size=" .. tostring(f.Size))
	mock.resetTweenLog()
	s:Set(Tween({ Value = 9, Time = 0, RepeatCount = 0 }))
	print("  C26 RepeatCount = 0 explicit: #log=" .. #log .. " Size=" .. tostring(f.Size))
end)
L.done()
