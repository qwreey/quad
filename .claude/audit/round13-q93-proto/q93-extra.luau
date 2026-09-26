-- P-Q93 extra cases. Copy to quad-base/test/ and run with luau.
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
	local st = { runs = 0, park = true }
	local c = s:Compute(function(h)
		local v = h:Get()
		st.runs += 1
		if st.park and coroutine.isyieldable() then coroutine.yield() end
		return v * 10
	end)
	return s, c, st
end

T("X1 B1 then B finishes: reads recover", function()
	local s, c, st = mk()
	local A = coroutine.create(function() return c:Get() end)
	coroutine.resume(A)
	s:Set(1)
	local B = coroutine.create(function() return c:Get() end)
	coroutine.resume(B)
	st.park = false
	print(" A", short(coroutine.resume(A)))
	print(" B", short(coroutine.resume(B)))
	print(" C", short(pcall(function() return c:Get() end)), "runs", st.runs, "_computing", c._computing)
end)

T("X2 B finishes BEFORE A returns (A's late gen1 result clobbers curr)", function()
	local s, c, st = mk()
	local A = coroutine.create(function() return c:Get() end)
	coroutine.resume(A)
	s:Set(1)
	local B = coroutine.create(function() return c:Get() end)
	coroutine.resume(B)
	st.park = false
	print(" B", short(coroutine.resume(B)))
	print(" A", short(coroutine.resume(A)), "runs", st.runs)
	print(" C", short(pcall(function() return c:Get() end)), "runs", st.runs)
end)

T("X3 B abandoned (never resumed): A errors; reads blocked until upstream Set", function()
	local s, c, st = mk()
	local A = coroutine.create(function() return c:Get() end)
	coroutine.resume(A)
	s:Set(1)
	local B = coroutine.create(function() return c:Get() end)
	coroutine.resume(B)
	st.park = false
	print(" A", short(coroutine.resume(A)))
	print(" C", short(pcall(function() return c:Get() end)), "runs", st.runs)
	s:Set(2)
	print(" C after Set(2)", short(pcall(function() return c:Get() end)), "runs", st.runs)
end)

T("X4 A's read goes through an internal reader (Operator) — blame", function()
	local s, c, st = mk()
	local x = Source(1)
	local o = x:Apply(q.Operator.Sum(c))
	local A = coroutine.create(function() return o:Get() end)
	coroutine.resume(A)
	s:Set(1)
	local B = coroutine.create(function() return c:Get() end)
	coroutine.resume(B)
	st.park = false
	print(" A", short(coroutine.resume(A)))
	print(" B", short(coroutine.resume(B)), "runs", st.runs)
	print(" o", short(pcall(function() return o:Get() end)))
end)

T("X5 same-coroutine UB: fn Sets its own dep, inner read throws, fn pcall-swallows", function()
	local s = Source(0)
	local runs = 0
	local c
	c = s:Compute(function(h)
		local v = h:Get()
		runs += 1
		if runs == 1 then
			pcall(function() s:Set(99); return c:Get() end) -- inner gen' fn: v=99 → throws below
		end
		if v == 99 and runs == 2 then error("boom-inner") end
		return v
	end)
	print(" Get", short(pcall(function() return c:Get() end)), "runs", runs, "_computing", c._computing)
	print(" Get2", short(pcall(function() return c:Get() end)), "runs", runs)
	s:Set(5)
	print(" after Set(5)", short(pcall(function() return c:Get() end)), "runs", runs)
end)

T("X6 fn yields, nothing moves, same coroutine resumes (plain yield OK)", function()
	local s, c, st = mk()
	local A = coroutine.create(function() return c:Get() end)
	coroutine.resume(A)
	st.park = false
	print(" A", short(coroutine.resume(A)), "runs", st.runs, "_computing", c._computing)
end)

T("X7 fn yields, upstream Set, NO other reader, A resumes (H-85 drift rerun)", function()
	local s, c, st = mk()
	local A = coroutine.create(function() return c:Get() end)
	coroutine.resume(A)
	s:Set(3)
	st.park = false
	print(" A", short(coroutine.resume(A)), "runs", st.runs, "_computing", c._computing)
end)
