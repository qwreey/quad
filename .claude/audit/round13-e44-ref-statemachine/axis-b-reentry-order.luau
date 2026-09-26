--!nocheck
-- axis (a) callback order, (b) re-entrant :Set inside a callback (core/07:240-242, :248)
local H = require("./harness")
local q = H.q
local function id(e) return tostring(e):match("Quad%d%d%d%d") or ("RAW:" .. H.first(e)) end

-- (a) order: register 8 callbacks, see iteration order vs registration order across several Sets
do
	local r = q.Ref(0)
	local order = {}
	for i = 1, 8 do
		r:Callback(function(v) if v ~= 0 then table.insert(order, i) end end)
	end
	r:Set(1)
	print("(a) order after 8 regs:", table.concat(order, " "))
end

-- (b) re-entry: count deliveries per callback, value seen, whether outer resumes
for trial = 1, 5 do
	local r = q.Ref(0)
	local got = {}
	local fired = false
	local names = {}
	for i = 1, 6 do
		local name = "c" .. i
		names[i] = name
		got[name] = {}
		r:Callback(function(v)
			table.insert(got[name], v)
			if i == 3 and v == 1 and not fired then
				fired = true
				r:Set(2)
			end
		end)
	end
	for _, n in names do got[n] = {} end
	r:Set(1)
	local line = {}
	local stale = false
	for _, n in names do
		table.insert(line, n .. "=[" .. table.concat(got[n], ",") .. "]")
		local last = got[n][#got[n]]
		if last ~= 2 then stale = true end
	end
	print("(b) trial", trial, table.concat(line, " "), "final", r.Value, "anyLastNot2", stale)
end

-- (b2) re-entrant Set inside a Wait() waiter (thread branch), outer still walking
do
	local r = q.Ref(0)
	local seen = {}
	r:Callback(function(v) table.insert(seen, "cb:" .. tostring(v)) end)
	local co = coroutine.create(function()
		local ref = r:Wait()
		table.insert(seen, "waiter:" .. tostring(ref.Value))
		ref:Set(99)
	end)
	coroutine.resume(co)
	seen = {}
	local ok, e = pcall(function() r:Set(5) end)
	print("(b2) waiter re-enters Set:", ok, ok or id(e), table.concat(seen, ","), "final", r.Value)
end

-- (b3) unregister-then-reregister during a walk: double call?
do
	for trial = 1, 4 do
		local r = q.Ref(0)
		local counts = { a = 0, b = 0 }
		local fb
		local fa = function(v)
			if v == 1 then
				counts.a += 1
				r:Uncallback(fb)
				r:Callback(fb)
			end
		end
		fb = function(v) if v == 1 then counts.b += 1 end end
		r:Callback(fa); r:Callback(fb)
		r:Set(1)
		print("(b3) trial", trial, "a", counts.a, "b", counts.b)
	end
end

-- (b4) Set(same value) fires? Set(q.None) stored as-is?
do
	local r = q.Ref(1)
	local n = 0
	r:Callback(function() n += 1 end)
	local rev = r.Revision
	r:Set(1)
	print("(b4) same value: calls", n, "rev changed", r.Revision ~= rev)
	r:Set(q.None)
	print("(b4) Set(None): Value==None", r.Value == q.None, "Unwrap==None", r:Unwrap() == q.None)
	r:Set(false)
	print("(b4) Set(false): Unwrap", r:Unwrap())
end
