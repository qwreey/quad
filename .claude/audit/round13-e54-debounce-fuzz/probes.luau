--!nocheck
-- round13 E54 — targeted probes for axes (a)~(f) and the undecided cells. Run from repo root:
--   luau .claude/audit/round13-e54-debounce-fuzz/probes.luau
local mock = require("../../../quad-base/test/mock")
local q = mock.newQuad()
local Source, Debounce, Throttle, Ref, Blocker = q.Source, q.Debounce, q.Throttle, q.Ref, q.Blocker
local adv = mock.advanceTime
local function to(t) adv(t - mock.now()) end

local function watch(node, read)
	local log = {}
	node:Observer(function(target, _, from)
		if from == nil then return end
		log[#log + 1] = `{mock.now()}:{if read then tostring(target:Get()) else "-"}`
	end):Subscribe()
	return log
end
local function P(label, log) print(`{label}: [{table.concat(log, " ")}] pending={mock.pendingTimers()}`) end

print("== X1 gate→gate: downstream gate swallows a revision it already emitted — only if its value was read ==")
for _, read in { true, false } do
	mock.resetTimers()
	local s = Source(0)
	local g1 = s:Apply(Debounce({ Time = 0.5 }))
	local g2 = g1:Apply(Debounce({ Time = 0.25 }))
	local log = watch(g2, read)
	s:Set(1)
	to(0.5) -- g1 passes rev1 → g2 withholds (window → 0.75)
	to(0.625); s:Set(2) -- g1 withholds rev2 (restart → 1.125)
	to(0.75) -- g2 passes; emit map Synced with the LIVE rev (2)
	to(1.125) -- g1 passes rev2 → g2: already emitted rev2
	to(5)
	P(`observer reads={tostring(read)}`, log)
end

print("== X1b same with an upstream user Blocker (Source→Blocker→Throttle) ==")
for _, read in { true, false } do
	mock.resetTimers()
	local s = Source(0)
	local b = Blocker()
	local g = s:Apply(b):Apply(Throttle({ Time = 1 }))
	local log = watch(g, read)
	s:Set(1) -- leading pass
	b:On()
	s:Set(2) -- held by the Blocker
	adv(0.5); s:Set(3) -- held by the Blocker
	-- nothing withheld in the throttle → window end at 1.0 is empty → idle
	adv(2)
	b:Off() -- delivers rev(3)
	adv(5)
	P(`observer reads={tostring(read)}`, log)
end

print("== X1c Throttle window end with the value moved by an upstream held Blocker: downstream sees values the Blocker still holds ==")
do
	mock.resetTimers()
	local s = Source(0)
	local b = Blocker()
	local g = s:Apply(b):Apply(Throttle({ Time = 1 }))
	local log = watch(g, true)
	s:Set(1) -- leading
	s:Set(2) -- withheld by throttle
	b:On()
	s:Set(3) -- held by the Blocker (not the throttle)
	adv(1) -- throttle trailing: target:Get() = 3 (live) although the Blocker holds rev3
	b:Off() -- rev3: throttle already emitted rev3 (live Sync) and read → swallowed
	adv(5)
	P("reads", log)
end

print("== (a) passed value: always the LIVE value at pass time (Debounce trailing / Throttle trailing / MaxTime / Flush) ==")
do
	mock.resetTimers()
	local s = Source("x0")
	local h = Ref(nil)
	local g = s:Apply(Debounce({ Time = 1, MaxTime = 1.5, Handle = h }))
	local log = watch(g, true)
	s:Set("a"); adv(0.5); s:Set("b"); adv(0.5); s:Set("c") -- cap at 1.5 fires with "c"
	adv(0.5)
	s:Set("d"); h.Value:Flush()
	adv(5)
	P("debounce values", log)
end

print("== (b) state after Flush: withheld → pass + NEW window from now (Throttle: next signal is withheld, not leading) ==")
do
	mock.resetTimers()
	local s = Source(0)
	local h = Ref(nil)
	local g = s:Apply(Throttle({ Time = 1, Handle = h }))
	local log = watch(g, true)
	s:Set(1) -- leading @0, window → 1
	adv(0.25); s:Set(2) -- withheld
	adv(0.25); h.Value:Flush() -- @0.5: pass 2, window → 1.5
	adv(0.25); s:Set(3) -- @0.75 withheld (window from Flush)
	adv(5)
	P("throttle flush", log)
	-- Flush with nothing withheld inside a window: no-op (window untouched)
	mock.resetTimers()
	local s2 = Source(0)
	local h2 = Ref(nil)
	local g2 = s2:Apply(Throttle({ Time = 1, Handle = h2 }))
	local log2 = watch(g2, true)
	s2:Set(1); adv(0.5); h2.Value:Flush(); s2:Set(2); adv(0.5)
	adv(5)
	P("throttle empty flush", log2)
end

print("== (c) Cancel then the first signal: leading passes at once (Throttle default / Debounce Leading) ==")
do
	for _, mk in { function(h) return Throttle({ Time = 1, Handle = h }) end, function(h) return Debounce({ Time = 1, Leading = true, Handle = h }) end } do
		mock.resetTimers()
		local s = Source(0)
		local h = Ref(nil)
		local g = s:Apply(mk(h))
		local log = watch(g, true)
		s:Set(1); adv(0.25); s:Set(2); h.Value:Cancel(); adv(0.25); s:Set(3)
		adv(5)
		P(tostring(g) .. " cancel→leading", log)
	end
end

print("== (d) Time State changed mid-window: running window keeps its delay; Debounce restart at the next signal uses the new value ==")
do
	mock.resetTimers()
	local t = Source(1)
	local s = Source(0)
	local g = s:Apply(Debounce({ Time = t }))
	local log = watch(g, true)
	s:Set(1) -- window → 1.0
	adv(0.25); t:Set(0.25) -- no signal: window stays → 1.0
	adv(0.5) -- @0.75
	P("  before next signal", log)
	s:Set(2) -- restart with 0.25 → 1.0
	adv(5)
	P("debounce time state", log)
	-- Throttle: a signal inside the window reads the new Time but the window is fixed; the reopen uses it
	mock.resetTimers()
	local t2 = Source(1)
	local s2 = Source(0)
	local g2 = s2:Apply(Throttle({ Time = t2 }))
	local log2 = watch(g2, true)
	s2:Set(1); t2:Set(0.25); adv(0.5); s2:Set(2) -- window stays → 1.0 ; sample now 0.25
	adv(0.5); s2:Set(3); adv(5)
	P("throttle time state", log2)
end

print("== (e) coarse vs fine advance (one probe; the fuzzer does both drives on every seed) ==")
for _, fine in { false, true } do
	mock.resetTimers()
	local s = Source(0)
	local g = s:Apply(Debounce({ Time = 0.25, MaxTime = 0.5, Leading = true }))
	local log = watch(g, true)
	for i = 1, 20 do s:Set(i); if fine then for _ = 1, 8 do adv(1 / 64) end else adv(0.125) end end
	adv(5)
	P(`fine={tostring(fine)}`, log)
end

print("== U1 same instant: two signals at the same time ==")
do
	mock.resetTimers()
	local s = Source(0)
	local g = s:Apply(Throttle({ Time = 1 }))
	local log = watch(g, true)
	s:Set(1); s:Set(2) -- leading 1, 2 withheld
	adv(5)
	P("throttle same-instant", log)
end

print("== U2 signal at exactly the window end (timer fires first in the mock) ==")
for _, mk in { function() return Throttle({ Time = 1 }) end, function() return Debounce({ Time = 1 }) end, function() return Debounce({ Time = 1, Leading = true, Trailing = false }) end } do
	mock.resetTimers()
	local s = Source(0)
	local g = s:Apply(mk())
	local log = watch(g, true)
	s:Set(1); adv(0.5); s:Set(2); to(1.5); s:Set(3) -- the 0.5 window ends at 1.5 exactly
	adv(5)
	P(tostring(g), log)
end

print("== U3 Time = 0 ==")
for _, mk in { function() return Throttle({ Time = 0 }) end, function() return Debounce({ Time = 0 }) end, function() return Debounce({ Time = 0, Leading = true }) end } do
	mock.resetTimers()
	local s = Source(0)
	local g = s:Apply(mk())
	local log = watch(g, true)
	s:Set(1); s:Set(2); P(tostring(g) .. " before advance(0)", log); adv(0); P("  after advance(0)", log)
	s:Set(3); adv(0); P("  next", log)
end

print("== U4 MaxTime == Time and MaxTime < Time (gap between passes shorter than Time) ==")
for _, mt in { 1, 0.5, 0 } do
	mock.resetTimers()
	local s = Source(0)
	local g = s:Apply(Debounce({ Time = 1, MaxTime = mt }))
	local log = watch(g, true)
	for i = 1, 12 do s:Set(i); adv(0.25) end
	adv(5)
	P(`MaxTime={mt}`, log)
end

print("== U5 Throttle Trailing=false: signal right after the leading pass is dropped at the window end ==")
do
	mock.resetTimers()
	local s = Source(0)
	local g = s:Apply(Throttle({ Time = 1, Trailing = false }))
	local log = watch(g, true)
	s:Set(1); adv(0.5); s:Set(2); adv(0.5); s:Set(3); adv(0.25); s:Set(4); adv(5)
	P("throttle trailing=false", log)
end

print("== U6 MaxTime State changed while a cap is armed ==")
do
	mock.resetTimers()
	local m = Source(2)
	local s = Source(0)
	local g = s:Apply(Debounce({ Time = 0.5, MaxTime = m }))
	local log = watch(g, true)
	s:Set(1) -- cap → 2
	m:Set(0.75)
	for i = 2, 12 do adv(0.25); s:Set(i) end
	adv(5)
	P("maxtime state", log)
end

print("== (f) perf: 10k signals ==")
for _, mk in { function() return Debounce({ Time = 0.05, MaxTime = 0.2 }) end, function() return Throttle({ Time = 0.05 }) end } do
	mock.resetTimers()
	local s = Source(0)
	local g = s:Apply(mk())
	local log = watch(g, true)
	local t0 = os.clock()
	for i = 1, 10000 do s:Set(i); adv(0.01) end
	adv(1)
	print(`{tostring(g)}: 10000 signals, {#log} passes, {string.format("%.1f", (os.clock() - t0) * 1000)} ms (mock timer list is linear — timing includes the mock)`)
end

print("== U7 MaxTime State invalid at a signal: is the Time sample already replaced? (Debounce.luau:263-265 says 'before anything changes') ==")
do
	mock.resetTimers()
	local t = Source(1)
	local m = Source(5)
	local s = Source(0)
	local h = Ref(nil)
	local g = s:Apply(Debounce({ Time = t, MaxTime = m, Handle = h }))
	local log = watch(g, true)
	s:Set(1) -- window → 1 (sample 1)
	t:Set(0.25); m:Set(-1)
	local ok, err = pcall(function() s:Set(2) end)
	print("  signal threw:", not ok, tostring(err):match("Quad%d+[^\n]*"))
	print("  h._time now =", h.Value._time)
	m:Set(5)
	h.Value:Flush() -- passes the merged signal and reopens with h._time
	print("  timerLog tail:", mock.timerLog()[#mock.timerLog()])
	adv(5)
	P("  log", log)
end
