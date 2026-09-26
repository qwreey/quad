-- P-Q98 probe. Copy to quad-base/test/ of a patched copy and run with luau.
local mock = require("./mock")
local q = mock.newQuad()
local Source = q.Source
local function T(name, f)
	mock.resetTimers()
	local ok, err = pcall(f)
	print(`--- {name}: {ok and "ok" or ("ERR " .. tostring(err))}`)
end
local function short(ok, v) return `{ok} {tostring(v):sub(1, 70)}` end

local function mk()
	local s = Source(0)
	local st = { runs = 0, park = true, log = {} }
	local c = s:Compute(function(h, prev)
		local v = h:Get()
		st.runs += 1
		table.insert(st.log, `v={v} prev={tostring(prev)} gen={h and 0 or 0}`)
		if st.park and coroutine.isyieldable() then coroutine.yield() end
		return v * 10
	end)
	return s, c, st
end
local function state(c) return `curr={c._cacheCurrCount} target={c._cacheTargetCount} cache={tostring(c._cache)} computing={c._computing}` end

T("X2 B finishes gen2 BEFORE A (gen1) returns", function()
	local s, c, st = mk()
	local A = coroutine.create(function() return c:Get() end)
	coroutine.resume(A)
	s:Set(1)
	local B = coroutine.create(function() return c:Get() end)
	coroutine.resume(B)
	st.park = false
	print(" B", short(coroutine.resume(B)), "runs", st.runs, state(c))
	print(" A", short(coroutine.resume(A)), "runs", st.runs, state(c))
	print(" C", short(pcall(function() return c:Get() end)), "runs", st.runs, state(c))
	print(" log", table.concat(st.log, " | "))
end)

T("X2b gen1 A parked, TWO upstream Sets, B finishes gen3, A returns", function()
	local s, c, st = mk()
	local A = coroutine.create(function() return c:Get() end)
	coroutine.resume(A)
	s:Set(1); s:Set(2)
	local B = coroutine.create(function() return c:Get() end)
	coroutine.resume(B)
	st.park = false
	print(" B", short(coroutine.resume(B)), "runs", st.runs, state(c))
	print(" A", short(coroutine.resume(A)), "runs", st.runs, state(c))
	print(" C", short(pcall(function() return c:Get() end)), "runs", st.runs, state(c))
end)

T("X2c A parked gen1, Set, NOBODY reads gen2, A returns (A's loop must run gen2 itself)", function()
	local s, c, st = mk()
	local A = coroutine.create(function() return c:Get() end)
	coroutine.resume(A)
	s:Set(1)
	st.park = false
	print(" A", short(coroutine.resume(A)), "runs", st.runs, state(c))
	print(" log", table.concat(st.log, " | "))
end)

T("R1 same coroutine, fn Sets its own dep once (no yield) — `previous` seen by the rerun", function()
	local s = Source(0)
	local log = {}
	local once = true
	local c = s:Compute(function(h, prev)
		local v = h:Get()
		table.insert(log, `v={v} prev={tostring(prev)}`)
		if once then once = false; s:Set(7) end
		return v + 100
	end)
	print(" Get", short(pcall(function() return c:Get() end)), state(c))
	print(" log", table.concat(log, " | "))
end)

T("R2 fn reads through a closed Blocker; upstream moves during fn (drift branch)", function()
	local s = Source(0)
	local bl = q.Blocker(); bl:On()
	local gated = s:Apply(bl)
	local log = {}
	local once = true
	local c = gated:Compute(function(h, prev)
		local v = h:Get()
		table.insert(log, `v={v} prev={tostring(prev)}`)
		if once then once = false; s:Set(5) end
		return v
	end)
	print(" Get", short(pcall(function() return c:Get() end)), state(c))
	print(" log", table.concat(log, " | "))
end)

T("R3 previous across normal generations (sanity)", function()
	local s = Source(1)
	local log = {}
	local c = s:Compute(function(h, prev) local v = h:Get(); table.insert(log, `v={v} prev={tostring(prev)}`); return v * 2 end)
	c:Get(); s:Set(2); c:Get(); s:Set(3); c:Get()
	print(" log", table.concat(log, " | "))
end)
