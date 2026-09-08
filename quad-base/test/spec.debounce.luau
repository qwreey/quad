--[[
	Debounce / Throttle 계약 — `.claude/base/debounce-throttle-plan.md` 1-1(한 비트 모델·사용자 시나리오),
	4((A) emit-gate), 5-2(옵션·State Time), 5-3(기본값 표), 5-4(제어 핸들), 6(주입 op), 8(유계 타이머),
	`.claude/base/gate-plan.md` 5번(Blocker 위임·두 경로). 시간은 mock의 가상 시계(`mock.advanceTime`)로 돈다.
]]

local Quad = require("../src")
local QuadTypes = require("../luau_packages/quad_types")
local mock = require("./mock")

type State<T> = QuadTypes.State<T>
type GateHandle = QuadTypes.GateHandle
type Probe = { count: number, last: any, _receive: (self: Probe, from: any) -> () }

local SPEC_FILE = "spec.debounce.luau"
local collectgarbage = (_G :: any).collectgarbage :: (...any) -> ...any

local q = mock.newQuad()
local Source, Debounce, Throttle, Ref = q.Source, q.Debounce, q.Throttle, q.Ref
local advance = mock.advanceTime
-- absolute stepping for loops (0.2 × 10 accumulates to 1.9999999999999998 < 2 — the cap at 2.0 would not fire)
local function advanceTo(t: number)
	advance(t - mock.now())
end

local function probe(target: any): Probe
	local p = { count = 0, last = nil :: any } :: Probe
	function p._receive(self: Probe, from: any)
		self.count += 1
		self.last = from
	end
	target._subs[p] = true
	return p
end

local function fresh()
	mock.resetTimers()
end

print("=== 1. 생성 게이트 — Time 필수·음수 거부, Leading/Trailing 둘 다 false 거부, Throttle MaxTime 거부, Handle은 Ref, Apply 대상은 State ===")
do
	fresh()
	local ok, err = pcall(function() return Debounce({}) end)
	assert(not ok and string.find(tostring(err), "Time is required", 1, true), "Time required")
	mock.assertBlamesUser(err, SPEC_FILE, "Time required blame")
	ok, err = pcall(function() return Debounce({ Time = -1 }) end)
	assert(not ok and string.find(tostring(err), "non%-negative"), "negative Time")
	ok, err = pcall(function() return Debounce({ Time = "0.3" }) end)
	assert(not ok and string.find(tostring(err), "got string", 1, true), "string Time")
	ok, err = pcall(function() return Throttle({ Time = 1, Leading = false, Trailing = false }) end)
	assert(not ok and string.find(tostring(err), "both false", 1, true), "both false")
	ok, err = pcall(function() return Throttle({ Time = 1, MaxTime = 2 }) end)
	assert(not ok and string.find(tostring(err), "Debounce%-only"), "Throttle MaxTime")
	ok, err = pcall(function() return Debounce({ Time = 1, Handle = {} }) end)
	assert(not ok and string.find(tostring(err), "Handle must be a Ref", 1, true), "Handle Ref")
	ok, err = pcall(function() return Debounce({ Time = 1, Leading = 1 }) end)
	assert(not ok and string.find(tostring(err), "Leading must be a boolean", 1, true), "flag type")
	local f = Debounce({ Time = 0.3 })
	ok, err = pcall(function() return f:__apply({}) end)
	assert(not ok and string.find(tostring(err), "Apply target must be a State", 1, true), "Apply non-State")
	assert(tostring(f) == "Debounce(Time=0.3)", `tostring: {tostring(f)}`)
	assert(tostring(Throttle({ Time = 1 })) == "Throttle(Time=1)", "tostring Throttle")
	print("PASS")
end

print()
print("=== 2. Debounce 기본(Leading=false, Trailing=true) — 버스트 중 침묵, 조용해지고 Time 뒤 1회; 창 안 :Get()은 최신값((A) emit-gate) ===")
do
	fresh()
	local s = Source(1)
	local g: State<number> = s:Apply(Debounce({ Time = 0.3 }))
	assert(q.isState(g) and g ~= s and g:Get() == 1, "a new gated State")
	local p = probe(g)
	s:Set(2)
	s:Set(3)
	assert(p.count == 0 and g:Get() == 3, "withheld, value live")
	advance(0.29)
	assert(p.count == 0, "still inside the window")
	advance(0.01)
	assert(p.count == 1 and p.last[s] == true, "fired once at 0.3 with the batch")
	-- 통과 뒤 창이 다시 열린다(다음 통과까지 최소 Time): 0.35의 신호는 0.65에 나간다(리셋)
	advance(0.05)
	s:Set(4)
	advance(0.29)
	assert(p.count == 1, "reopened window holds it")
	advance(0.01)
	assert(p.count == 2, "0.65: passed (window was reset by the 0.35 signal)")
	advance(1)
	assert(p.count == 2 and mock.pendingTimers() == 0, "idle again — no timer left (plan 8: bounded)")
	print("PASS")
end

print()
print("=== 3. Debounce 한 비트 — 신호가 창을 민다: 0/0.2/0.4에 신호, Time 0.3이면 0.7에 한 번 ===")
do
	fresh()
	local s = Source(0)
	local g: State<number> = s:Apply(Debounce({ Time = 0.3 }))
	local p = probe(g)
	s:Set(1)
	advance(0.2)
	s:Set(2)
	advance(0.2)
	s:Set(3)
	advance(0.29)
	assert(p.count == 0, "0.69: not yet")
	advance(0.01)
	assert(p.count == 1, "0.7: once")
	assert(table.concat(mock.timerLog(), ",") == "set(0.3)@0,clear@0.2,set(0.3)@0.2,clear@0.4,set(0.3)@0.4,fire@0.7,set(0.3)@0.7", table.concat(mock.timerLog(), ","))
	print("PASS")
end

print()
print("=== 4. Throttle 사용자 시나리오(1-1절) — 0.0 즉시(leading), 0.1 눌러둠, 1.0 통과(trailing)+창 재개방, 1.05 눌러둠, 2.0 통과, 3.0 idle, 3.5 즉시 ===")
do
	fresh()
	local s = Source(0)
	local g: State<number> = s:Apply(Throttle({ Time = 1 }))
	local p = probe(g)
	s:Set(1)
	assert(p.count == 1, "0.0: leading passes at once")
	advance(0.1)
	s:Set(2)
	assert(p.count == 1 and g:Get() == 2, "0.1: withheld (window fixed at 1.0)")
	advance(0.9)
	assert(p.count == 2, "1.0: trailing passes the latest")
	advance(0.05)
	s:Set(3)
	assert(p.count == 2, "1.05: inside the reopened window — no double fire")
	advance(0.95)
	assert(p.count == 3, "2.0: passes")
	advance(1)
	assert(p.count == 3 and mock.pendingTimers() == 0, "3.0: nothing withheld → idle, no timer")
	advance(0.5)
	s:Set(4)
	assert(p.count == 4, "3.5: idle → leading again")
	print("PASS")
end

print()
print("=== 5. Leading=true, Trailing=false — 버스트 시작에 한 번, 나머지는 창 끝에 버려진다(emit(false) — 집합이 빈다) ===")
do
	fresh()
	local s = Source(0)
	local g: State<number> = s:Apply(Debounce({ Time = 0.3, Leading = true, Trailing = false }))
	local p = probe(g)
	s:Set(1)
	assert(p.count == 1, "leading")
	s:Set(2)
	s:Set(3)
	advance(0.3)
	assert(p.count == 1 and next((g :: any)._withheld) == nil, "discarded, set emptied")
	assert(mock.pendingTimers() == 0, "idle")
	s:Set(4)
	assert(p.count == 2, "next burst leads again")
	-- Throttle{Leading=false}: 첫 신호도 눌렀다가 창 끝에 통과
	fresh()
	local s2 = Source(0)
	local g2: State<number> = s2:Apply(Throttle({ Time = 1, Leading = false }))
	local p2 = probe(g2)
	s2:Set(1)
	assert(p2.count == 0, "no leading")
	advance(1)
	assert(p2.count == 1, "trailing at 1.0")
	print("PASS")
end

print()
print("=== 6. MaxTime(Debounce 전용) — 신호가 안 끊겨도 MaxTime마다 통과, 창은 통과 뒤 재개방 ===")
do
	fresh()
	local s = Source(0)
	local g: State<number> = s:Apply(Debounce({ Time = 0.3, MaxTime = 1 }))
	local p = probe(g)
	for i = 1, 5 do -- 0, 0.2, 0.4, 0.6, 0.8
		s:Set(i)
		advanceTo(i * 0.2)
	end
	assert(p.count == 1 and mock.now() == 1, "cap fired at 1.0 while signals kept resetting the window")
	for i = 6, 10 do -- 1.0 … 1.8
		s:Set(i)
		advanceTo(i * 0.2)
	end
	assert(p.count == 2 and mock.now() == 2, "and again at 2.0 (the 1.8 signal rode that cap)")
	advance(1)
	assert(p.count == 2 and mock.pendingTimers() == 0, "reopened window (2.0→2.3) had nothing → idle, no timers (cap cleared with the commit)")
	print("PASS")
end

print()
print("=== 7. 제어 핸들 — Handle Ref가 Apply 시점에 채워짐; Flush는 즉시 커밋(+창 재개방)·idle이면 no-op, Cancel은 버림 ===")
do
	fresh()
	local s = Source(0)
	local h = Ref(nil :: GateHandle?)
	assert(h.Value == nil, "empty before Apply")
	local g: State<number> = s:Apply(Debounce({ Time = 1, Handle = h }))
	local handle = h.Value :: GateHandle
	assert(handle ~= nil and type(handle.Flush) == "function", "filled at Apply")
	local p = probe(g)
	s:Set(1)
	handle:Flush()
	assert(p.count == 1, "Flush committed at once")
	assert(mock.pendingTimers() == 1 and mock.timerLog()[#mock.timerLog()] == "set(1)@0", "commit restarted the window")
	handle:Flush()
	assert(p.count == 1 and #mock.timerLog() == 3, "nothing withheld → true no-op (the running window is untouched)")
	advance(1)
	assert(mock.pendingTimers() == 0, "idle")
	s:Set(2)
	handle:Cancel()
	assert(p.count == 1 and next((g :: any)._withheld) == nil and mock.pendingTimers() == 0, "Cancel: dropped, idle, no timer")
	s:Set(3)
	advance(1)
	assert(p.count == 2, "gate keeps working after Cancel")
	print("PASS")
end

print()
print("=== 7b. Flush는 Trailing과 무관(배너 (4)) — Trailing=false 게이트도 명시적 Flush면 보류분을 통과; 창 안 Time 오류는 상태를 안 남긴다(H-509) ===")
do
	fresh()
	local s = Source(0)
	local h = Ref(nil :: GateHandle?)
	local g: State<number> = s:Apply(Debounce({ Time = 1, Leading = true, Trailing = false, Handle = h }))
	local p = probe(g)
	s:Set(1) -- leading
	s:Set(2) -- withheld (would be discarded at 1.0)
	;(h.Value :: GateHandle):Flush()
	assert(p.count == 2, "explicit Flush passes the withheld batch even with Trailing=false")
	advance(1)
	assert(mock.pendingTimers() == 0, "idle")
	-- H-509: a schedule that throws (bad Time) leaves no half-state — the Blocker is not left On
	local t = Source(1 :: any)
	local s2 = Source(0)
	local g2: State<number> = s2:Apply(Throttle({ Time = t }))
	local p2 = probe(g2)
	t:Set("x")
	assert(not pcall(function() s2:Set(1) end), "throws at the schedule")
	t:Set(1)
	s2:Set(2)
	assert(p2.count == 2, "after the throw the gate is idle again: this signal leads (Blocker was not left On)")
	assert(mock.pendingTimers() == 1, "and exactly one window")
	print("PASS")
end

print()
print("=== 7c. (j) 같은 Handle Ref로 두 번 :Apply — 둘째가 조용히 덮어쓰지 않고 에러(사용자 결정, round9) ===")
do
	fresh()
	local h = Ref(nil :: GateHandle?)
	local f = Debounce({ Time = 1, Handle = h })
	local s = Source(0)
	local _a: State<number> = s:Apply(f)
	local first = h.Value
	local subs = 0
	for _ in (s :: any)._subs do
		subs += 1
	end
	local ok, err = pcall(function()
		local _b: State<number> = s:Apply(f)
	end)
	assert(not ok and string.find(tostring(err), "Handle is already filled", 1, true), tostring(err))
	mock.assertBlamesUser(err, SPEC_FILE, "Handle gate blame") -- `H-517`: outermost, not State.luau
	assert(h.Value == first, "first gate's handle untouched")
	local subs2 = 0
	for _ in (s :: any)._subs do
		subs2 += 1
	end
	assert(subs2 == subs, "`H-517`: the gate ran before state:Gate — no orphan subscriber left on the upstream")
	s:Set(1)
	assert(mock.pendingTimers() == 1, "one gate, one window")
	print("PASS")
end

print()
print("=== 8. 팩토리 브로드캐스트 — factory:Flush()/Cancel()은 그 팩토리로 만든 게이트 전부에; 레지스트리는 weak ===")
do
	fresh()
	local f = Debounce({ Time = 1 })
	local a, b = Source(0), Source(0)
	local ga: State<number> = a:Apply(f)
	local gb: State<number> = b:Apply(f)
	local pa, pb = probe(ga), probe(gb)
	a:Set(1)
	b:Set(1)
	f:Flush()
	assert(pa.count == 1 and pb.count == 1, "both flushed")
	advance(1)
	a:Set(2)
	b:Set(2)
	f:Cancel()
	assert(pa.count == 1 and pb.count == 1 and mock.pendingTimers() == 0, "both cancelled")
	-- weak: a gate nobody holds is collected (plan 5-4 — the factory must not pin it)
	local n = 0
	for _ in (f :: any)._instances do
		n += 1
	end
	assert(n == 2, "two registered")
	ga, gb, pa, pb = nil :: any, nil :: any, nil :: any, nil :: any
	collectgarbage()
	collectgarbage()
	n = 0
	for _ in (f :: any)._instances do
		n += 1
	end
	assert(n == 0, `weak registry: {n} left`)
	print("PASS")
end

print()
print("=== 9. Time = State<number> — 스케줄 시점에만 읽는다: 바꿔도 진행 중인 창은 그대로, 다음 창부터 ===")
do
	fresh()
	local t = Source(1)
	local s = Source(0)
	local g: State<number> = s:Apply(Throttle({ Time = t }))
	local p = probe(g)
	s:Set(1) -- leading, window 1.0
	t:Set(0.2) -- not applied to the running window
	s:Set(2)
	advance(0.5)
	assert(p.count == 1, "old window still running")
	advance(0.5)
	assert(p.count == 2, "1.0: trailing with the old length")
	s:Set(3) -- withheld in the reopened window — which now uses 0.2
	advance(0.2)
	assert(p.count == 3, "next window is 0.2")
	-- a State giving a non-number is the user's error at schedule time
	local bad = Source(0.1 :: any)
	local src = Source(0)
	local _g2: State<number> = src:Apply(Debounce({ Time = bad }))
	bad:Set("x")
	local ok, err = pcall(function()
		src:Set(1)
	end)
	assert(not ok and string.find(tostring(err), "Time must be a non%-negative number"), tostring(err))
	print("PASS")
end

print()
print("=== 10. 재진입 — flush 도중 하류가 상류를 :Set해도 창은 하나(타이머 하나), 두 번째 신호는 새 창으로 ===")
do
	fresh()
	local s = Source(0)
	local g: State<number> = s:Apply(Throttle({ Time = 1 }))
	local reentered = false
	local p = { count = 0 } :: any
	function p._receive(self: any, _from: any)
		self.count += 1
		if not reentered then
			reentered = true
			s:Set(100) -- re-enters the gate while it is flushing
		end
	end
	;(g :: any)._subs[p] = true
	s:Set(1)
	assert(p.count == 2, "leading pass, re-entrant set also passed (gate was idle/open at that instant)")
	assert(mock.pendingTimers() == 1, "exactly one window timer")
	advance(1)
	assert(mock.pendingTimers() == 0, "nothing withheld → idle")
	print("PASS")
end

print()
print("=== 10b. 타이머 경로 재진입 — 창 끝 flush 중 하류가 상류를 :Set하면 보류되고(창 하나), 다음 창에서 통과 ===")
do
	fresh()
	local s = Source(0)
	local g: State<number> = s:Apply(Debounce({ Time = 1 }))
	local reentered = false
	local p = { count = 0 } :: any
	function p._receive(self: any, _from: any)
		self.count += 1
		if not reentered then
			reentered = true
			s:Set(100)
		end
	end
	;(g :: any)._subs[p] = true
	s:Set(1)
	advance(1) -- window end: flush → re-entrant Set(100) lands in the fresh set, withheld
	assert(p.count == 1 and mock.pendingTimers() == 1, "one pass, the re-entrant signal is held, exactly one window")
	advance(1)
	assert(p.count == 2, "next window end passes it")
	advance(1)
	assert(mock.pendingTimers() == 0, "idle")
	print("PASS")
end

print()
print("=== 11. 미주입 백엔드 — 맨 Quad.New()에선 setTimeout 스텁이 안내 에러(첫 신호 때) ===")
do
	local bare = Quad.New()
	local s = bare.Source(0)
	local g: State<number> = s:Apply(bare.Debounce({ Time = 1 }))
	assert(g:Get() == 0, "Apply itself needs no timer")
	local ok, err = pcall(function()
		s:Set(1)
	end)
	assert(not ok and string.find(tostring(err), "setTimeout is not available", 1, true), tostring(err))
	print("PASS")
end

print()
print("ALL PASS")
