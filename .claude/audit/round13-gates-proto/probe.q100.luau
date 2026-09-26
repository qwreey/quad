--!nocheck
-- P-gates Q100 probe: Time/MaxTime = math.huge (construction, State at signal, setTimeout direct)
local mock = require("./mock")
local q = mock.newQuad()
local Source, Debounce, Throttle = q.Source, q.Debounce, q.Throttle
local function E(f)
	local ok, err = pcall(f)
	if ok then return "ok" end
	local s = tostring(err)
	return (s:match("Quad%d+[^\n]*") or s:match("[^:]*: [^\n]*$") or s):sub(1, 200)
end
local function T(n, f) print(n .. " => " .. E(f)) end
local inf = math.huge
T("A1 Debounce{Time=inf}", function() return Debounce({ Time = inf }) end)
T("A2 Throttle{Time=inf}", function() return Throttle({ Time = inf }) end)
T("A3 Debounce{Time=1, MaxTime=inf}", function() return Debounce({ Time = 1, MaxTime = inf }) end)
T("A4 Debounce{Time=-inf}", function() return Debounce({ Time = -inf }) end)
T("A5 Debounce{Time=0/0}", function() return Debounce({ Time = 0 / 0 }) end)
T("A6 Debounce{Time=1e308} (finite, huge)", function() return Debounce({ Time = 1e308 }) end)
T("A7 Debounce{Time='x'}", function() return Debounce({ Time = "x" }) end)
T("A8 Debounce{Time=-1}", function() return Debounce({ Time = -1 }) end)
T("A9 Debounce{Time=0}", function() return Debounce({ Time = 0 }) end)
do -- State Time = inf at signal
	mock.resetTimers()
	local t = Source(inf)
	local s = Source(0)
	local g = s:Apply(Debounce({ Time = t }))
	T("B1 State Time=inf, signal", function() s:Set(1) end)
	print("   pending timers after B1:", mock.pendingTimers(), " g:", g:Get())
	local m = Source(inf)
	local s2 = Source(0)
	s2:Apply(Debounce({ Time = 0.3, MaxTime = m }))
	T("B2 State MaxTime=inf, signal", function() s2:Set(1) end)
	local t3 = Source(inf)
	local s3 = Source(0)
	local g3 = s3:Apply(Throttle({ Time = t3 }))
	T("B3 Throttle State Time=inf, signal (leading)", function() s3:Set(1) end)
	print("   g3 after B3:", g3:Get())
	-- Trailing=false Debounce: MaxTime not read (H-542) — still not validated
	local m4 = Source(inf)
	local s4 = Source(0)
	s4:Apply(Debounce({ Time = 0.3, MaxTime = m4, Leading = true, Trailing = false }))
	T("B4 Trailing=false MaxTime State=inf (not read, H-542)", function() s4:Set(1) end)
end
mock.resetTimers()
T("C1 mock setTimeout(f, inf) direct", function() return q.Backend.setTimeout(function() end, inf) end)
T("C2 mock setTimeout(f, -1) direct", function() return q.Backend.setTimeout(function() end, -1) end)
