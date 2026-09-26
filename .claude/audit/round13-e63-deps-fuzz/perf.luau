--!nocheck
-- E63 axis (d): wide dependency sets
local H = require("./harness")
local q = H.q
local clock = os.clock
local function t(label, f) local t0 = clock(); local ok, e = pcall(f); print(string.format("%-58s %8.2f ms %s", label, (clock() - t0) * 1000, ok and "" or ("ERR " .. tostring(e):gsub("\n.*", "")))) end
for _, N in { 100, 1000, 7000, 10000 } do
	local srcs = {}
	for i = 1, N do srcs[i] = q.Source(i) end
	local runs = 0
	local e
	t(`Effect ctor, {N} distinct Source deps`, function() e = q.Effect(function() runs += 1 end, table.unpack(srcs)):Subscribe() end)
	if e then
		t(`  one dep :Set (x100)`, function() for i = 1, 100 do srcs[1 + (i % N)]:Set(-i) end end)
		print("    runs", runs)
		e:Unsubscribe()
	end
	local dup = {}
	for i = 1, N do dup[i] = srcs[1] end
	local r2 = 0
	local e2
	t(`Effect ctor, {N} copies of one dep`, function() e2 = q.Effect(function() r2 += 1 end, table.unpack(dup)):Subscribe() end)
	if e2 then t(`  :Set (x100)`, function() for i = 1, 100 do srcs[1]:Set(i) end end); print("    runs", r2); e2:Unsubscribe() end
	local c
	t(`Compute ctor, {N - 1} trailing deps`, function() c = srcs[1]:Compute(function(s, _, ...) local acc = s:Get() for i = 1, select("#", ...) do acc += (select(i, ...)):Get() end return acc end, table.unpack(srcs, 2)) end)
	if c then t(`  first Get`, function() c:Get() end); t(`  Set one + Get (x100)`, function() for i = 1, 100 do srcs[N]:Set(i); c:Get() end end) end
	local d
	t(`Depend ctor, {N - 1} deps`, function() d = srcs[1]:Depend(table.unpack(srcs, 2)) end)
	local ob = 0
	if d then d:Observer(function() ob += 1 end):Subscribe(); t(`  Set each dep once (N Sets)`, function() for i = 2, N do srcs[i]:Set(0) end end); print("    observer", ob) end
end
