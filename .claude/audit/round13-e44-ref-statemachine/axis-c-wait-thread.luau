--!nocheck
-- axis (c): Wait(thread) by thread status at :Set time — running / normal / suspended / dead / current;
-- Quad0130 / Quad0134 / Quad0133 conditions (core/07:244-246, :322-327; errors/04:210-240)
local H = require("./harness")
local q = H.q
local function id(e) return tostring(e):match("Quad%d%d%d%d") or ("RAW:" .. H.first(e)) end
local function try(label, f)
	local ok, e = pcall(f)
	print(label, ok and "ok" or id(e))
end

-- helper: callbacks counted; did the walk continue past the throw? is the waiter still registered?
local function mk()
	local r = q.Ref(0)
	local n = 0
	r:Callback(function(v) if v ~= 0 then n += 1 end end)
	return r, function() return n end
end
local function has(r, th) return r.Callbacks[th] == true end

-- 1. current (main) thread registered, Set from main
do
	local r, n = mk()
	local main = coroutine.running()
	r:Wait(main)
	print("1 main status at reg:", coroutine.status(main))
	try("1 Set from main (registered main):", function() r:Set(1) end)
	print("1  after: Value", r.Value, "cb calls", n(), "waiter still registered", has(r, main))
	try("1 second Set:", function() r:Set(2) end)
end

-- 2. current coroutine registered from inside a coroutine, Set from it (running)
do
	local r, n = mk()
	local co = coroutine.create(function()
		r:Wait(coroutine.running())
		local ok, e = pcall(function() r:Set(1) end)
		print("2 Set from the running registered coroutine:", ok and "ok" or id(e), "Value", r.Value)
	end)
	coroutine.resume(co)
end

-- 3. normal: outer coroutine A registered, A resumes B, B calls Set
do
	local r, n = mk()
	local A = coroutine.create(function()
		r:Wait(coroutine.running())
		local B = coroutine.create(function()
			local ok, e = pcall(function() r:Set(1) end)
			print("3 Set from B resumed by registered A (normal):", ok and "ok" or id(e))
		end)
		coroutine.resume(B)
	end)
	coroutine.resume(A)
end

-- 3b. normal, two levels up (A -> B -> C, A registered, C sets)
do
	local r = q.Ref(0)
	local A = coroutine.create(function()
		r:Wait(coroutine.running())
		coroutine.resume(coroutine.create(function()
			coroutine.resume(coroutine.create(function()
				local ok, e = pcall(function() r:Set(1) end)
				print("3b grand-ancestor registered (normal):", ok and "ok" or id(e))
			end))
		end))
	end)
	coroutine.resume(A)
end

-- 4. suspended: parked on a bare coroutine.yield (not in any Wait) — hijacked resume
do
	local r = q.Ref(0)
	local got = {}
	local co = coroutine.create(function()
		while true do
			local x = coroutine.yield()
			table.insert(got, typeof(x) == "table" and ("ref:" .. tostring(x.Value)) or tostring(x))
		end
	end)
	coroutine.resume(co)
	r:Wait(co)
	r:Set(7)
	r:Set(8)
	print("4 suspended parked coroutine: got", table.concat(got, ","), "status", coroutine.status(co), "still registered", has(r, co))
end

-- 4b. suspended on ANOTHER Ref's Wait(): Wait(thread) on r2 hijacks it
do
	local r1, r2 = q.Ref("r1-initial"), q.Ref("r2-initial")
	local out
	local co = coroutine.create(function()
		out = r1:Wait().Value
	end)
	coroutine.resume(co)
	r2:Wait(co)
	r2:Set("r2-new")
	print("4b thread waiting on r1, Wait(thread) on r2, r2:Set -> r1:Wait() returned Value", out, "status", coroutine.status(co), "r1 still holds waiter", has(r1, co))
	try("4b later r1:Set:", function() r1:Set("r1-new") end)
end

-- 4c. "wait for any of two refs" pattern: one thread registered on two refs
do
	local a, b = q.Ref(0), q.Ref(0)
	local fired
	local co = coroutine.create(function()
		local which = coroutine.yield()
		fired = which
	end)
	coroutine.resume(co)
	a:Wait(co); b:Wait(co)
	a:Set(1)
	print("4c after a:Set: status", coroutine.status(co), "fired==a", fired == a, "b still holds thread", has(b, co))
	local n = 0
	b:Callback(function(v) if v == 2 then n += 1 end end)
	try("4c b:Set(2) afterwards:", function() b:Set(2) end)
	print("4c  b.Value", b.Value, "b callback got 2?", n)
end

-- 5. dead thread
do
	local r, n = mk()
	local co = coroutine.create(function() end)
	coroutine.resume(co)
	r:Wait(co)
	try("5 Set with a dead registered thread:", function() r:Set(1) end)
	print("5  Value", r.Value, "still registered", has(r, co))
end

-- 6. Quad0134: Wait() from main / from a non-yieldable spot
print("6 top-level isyieldable:", coroutine.isyieldable())
do local ok,e = pcall(table.sort, {2,1}, function(a,b) q.Ref(0):Wait(); return a<b end); print("6 Wait() inside table.sort comparator (C boundary):", ok and "ok" or id(e)) end
do
	local r = q.Ref(0)
	local co = coroutine.create(function()
		-- inside a metamethod (C-call boundary in Luau? __index function is yieldable in Luau)
		local t = setmetatable({}, { __index = function() r:Wait(); return 1 end })
		local ok, e = pcall(function() return t.x end)
		print("6b Wait() inside pcall/__index in a coroutine:", ok and "ok(yielded?)" or id(e))
	end)
	print("6b resume:", coroutine.resume(co))
	print("6b status", coroutine.status(co))
end
try("7 Wait(123):", function() q.Ref(0):Wait(123) end)
do local ok,e = pcall(table.sort, {2,1}, function(a,b) q.Ref(0):Wait(nil); return a<b end); print("7 Wait(nil) in C boundary (== Wait()):", ok and "ok" or id(e)) end

-- 8. Wait() inside a :Callback running in a coroutine: yields the whole Set walk (doc: UB, :248)
do
	local r = q.Ref(0)
	local later = 0
	r:Callback(function(v) if v == 1 then later += 1 end end)
	local co = coroutine.create(function()
		local r2 = q.Ref(0)
		r:Callback(function(v) if v == 1 then r2:Wait() end end)
		r:Set(1)
	end)
	coroutine.resume(co)
	print("8 callback yields mid-walk: status", coroutine.status(co), "other cb ran", later)
end
