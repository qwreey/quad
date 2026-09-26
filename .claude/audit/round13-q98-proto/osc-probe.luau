--!nocheck
-- P-Q98 (2): oscillation during Observer install — base / Q73 (a) / (a') ; Effect symmetry.
-- fn stops oscillating by itself after LIMIT runs so an uncapped loop terminates.
local mock = require("./mock")
local q = mock.newQuad()
local Source, Effect = q.Source, q.Effect
local LIMIT = tonumber((... :: any)) or 100000
local function T(name, f)
	local t0 = os.clock()
	local ok, err = pcall(f)
	print(`--- {name}: {ok and "ok" or ("ERR " .. tostring(err):sub(1, 140))}  ({string.format("%.1f", (os.clock() - t0) * 1e3)} ms)`)
end

T("O1 Observer fn Sets own State to a NEW value every run (install)", function()
	local s, n = Source(0), 0
	local o = s:Observer(function(st) n += 1; if n < LIMIT then st:Set(st:Get() + 1) end end)
	print(` runs {n} s {s:Get()} rerunReq {o._rerunRequired}`)
	o:Subscribe()
	print(` after Subscribe runs {n}`)
end)

T("O2 Observer 2-cycle toggle (install): fn Sets s = 1 - s", function()
	local s, n = Source(0), 0
	local o = s:Observer(function(st) n += 1; if n < LIMIT then st:Set(1 - st:Get()) end end)
	print(` runs {n} s {s:Get()}`)
	local _ = o
end)

T("O3 Observer oscillation through ANOTHER subscribed Observer (install)", function()
	local s, t, n = Source(0), Source(0), 0
	local relay = t:Observer(function(_, _, from) if from ~= nil then s:Set(s:Get() + 1) end end):Subscribe()
	local o = s:Observer(function(st) n += 1; if n < LIMIT then t:Set(t:Get() + 1) end end)
	print(` runs {n} s {s:Get()} t {t:Get()}`)
	local _ = { relay, o }
end)

T("O4 converging self-Set (clamp) — install runs", function()
	local s, n = Source(50), 0
	local o = s:Observer(function(st) n += 1; if st:Get() > 10 then st:Set(10) end end)
	print(` runs {n} s {s:Get()}`)
	local _ = o
end)

T("E1 Effect fn Sets its own dep to a NEW value every run (install)", function()
	local s, n = Source(0), 0
	local e = Effect(function() n += 1; if n < LIMIT then s:Set(s:Get() + 1) end end, s)
	print(` runs {n} s {s:Get()} running {e._running} pending {e._pending}`)
end)

T("E2 Effect 2-cycle toggle (install)", function()
	local s, n = Source(0), 0
	local e = Effect(function() n += 1; if n < LIMIT then s:Set(1 - s:Get()) end end, s)
	print(` runs {n} s {s:Get()}`)
	local _ = e
end)

T("E3 Effect oscillation through another subscribed Observer (install)", function()
	local s, t, n = Source(0), Source(0), 0
	local relay = t:Observer(function(_, _, from) if from ~= nil then s:Set(s:Get() + 1) end end):Subscribe()
	local e = Effect(function() n += 1; if n < LIMIT then t:Set(t:Get() + 1) end end, s)
	print(` runs {n} s {s:Get()} t {t:Get()}`)
	local _ = { relay, e }
end)

T("E4 Effect converging clamp — install runs", function()
	local s, n = Source(50), 0
	local e = Effect(function() n += 1; if s:Get() > 10 then s:Set(10) end end, s)
	print(` runs {n} s {s:Get()}`)
	local _ = e
end)

-- post-install (subscribed) oscillation, for context: same in every variant (untouched code)
T("S1 SUBSCRIBED Observer oscillates on a later Set (reentrant _receive = recursion)", function()
	local s, n = Source(0), 0
	local armed = false
	local o = s:Observer(function(st, _, from) if not armed or from == nil then return end; n += 1; if n < LIMIT then st:Set(st:Get() + 1) end end):Subscribe()
	armed = true
	s:Set(1)
	print(` runs {n} s {s:Get()}`)
	local _ = o
end)

T("S2 SUBSCRIBED Effect oscillates on a later Set (_pending loop)", function()
	local s, n = Source(0), 0
	local armed = false
	local e = Effect(function() if not armed then return end; n += 1; if n < LIMIT then s:Set(s:Get() + 1) end end, s):Subscribe()
	armed = true
	s:Set(1)
	print(` runs {n} s {s:Get()}`)
	local _ = e
end)
