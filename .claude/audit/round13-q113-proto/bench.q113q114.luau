--!nocheck
-- round13 P-Q113/Q114 bench — run from a variant root. Median of R rounds, ms.
local H = require("./round13-e15-probe-setup")
local q, D = H.q, H.D
local N, R = 1000, 9
local function median(t) table.sort(t) return t[(#t + 1) // 2] end
local function bench(name, setup, step)
	local times = {}
	local ctx = setup()
	for r = 1, R do
		local t0 = os.clock()
		step(ctx, r)
		times[r] = (os.clock() - t0) * 1000
	end
	print(("%-58s %8.2f ms"):format(name, median(times)))
end
-- 1) flat: Text = inner (index 1, no parent) — baseline path untouched by the hand-off except the upvalue reads
bench("P1 flat State<string> x1000, inner:Set", function()
	local c = {}
	for i = 1, N do local s = q.Source("x"); c[i] = { s = s, l = D.TextLabel { Text = s } } end
	return c
end, function(c, r) for i = 1, N do c[i].s:Set("v" .. r .. i) end end)
-- 2) nested: Text = Source(inner), Set inner (inner observer revalidates parent:Get())
bench("P2 nested State<State<string>> x1000, inner:Set", function()
	local c = {}
	for i = 1, N do local s = q.Source("x"); local o = q.Source(s); c[i] = { s = s, o = o, l = D.TextLabel { Text = o } } end
	return c
end, function(c, r) for i = 1, N do c[i].s:Set("v" .. r .. i) end end)
-- 3) nested: swap outer to a fresh inner (rebind path: hand-off set + Q113 chain walk)
bench("P3 nested x1000, outer:Set(new inner State)", function()
	local c = {}
	for i = 1, N do local s = q.Source("x"); local o = q.Source(s); c[i] = { o = o, l = D.TextLabel { Text = o } } end
	return c
end, function(c, r) for i = 1, N do c[i].o:Set(q.Source("n" .. r .. i)) end end)
-- 4) depth 3: Source(Source(Source(string))) innermost Set (two revalidations up the chain? no — one per level)
bench("P4 depth-3 x1000, innermost:Set", function()
	local c = {}
	for i = 1, N do local s = q.Source("x"); local o = q.Source(q.Source(s)); c[i] = { s = s, l = D.TextLabel { Text = o } } end
	return c
end, function(c, r) for i = 1, N do c[i].s:Set("v" .. r .. i) end end)
-- 5) same-wave selector (the Q114 shape) x1000: src:Set flips selection
bench("P5 selector Compute(a|b) x1000, src:Set", function()
	local c = {}
	for i = 1, N do
		local src = q.Source(1)
		local a = src:Compute(function(s) return "a" .. s:Get() end)
		local b = src:Compute(function(s) return "b" .. s:Get() end)
		local outer = src:Compute(function(s) return if s:Get() % 2 == 1 then a else b end)
		c[i] = { src = src, l = D.TextLabel { Text = outer } }
	end
	return c
end, function(c, r) for i = 1, N do c[i].src:Set(r + 1) end end)
-- 6) Slot: 1000 State elements in one Slot, Set each (wrapper reconcile revalidation + wrapElement chain walk on swap)
bench("S1 Slot{ State<Frame> x1000 }, each :Set(new Frame)", function()
	local st = {}
	for i = 1, N do st[i] = q.Source(D.Frame { Name = "f" .. i }) end
	local sl = q.Slot(st); local host = D.Frame { sl }
	return { st = st, host = host }
end, function(c, r) for i = 1, N do c.st[i]:Set(D.Frame { Name = "g" .. r .. i }) end end)
bench("S2 Slot{ State<State<Frame>> x1000 }, inner :Set", function()
	local st, outer = {}, {}
	for i = 1, N do st[i] = q.Source(D.Frame { Name = "f" .. i }); outer[i] = q.Source(st[i]) end
	local sl = q.Slot(outer); local host = D.Frame { sl }
	return { st = st, host = host }
end, function(c, r) for i = 1, N do c.st[i]:Set(D.Frame { Name = "g" .. r .. i }) end end)
bench("S3 Slot{} x1000 Add(State<Frame>) (CRUD pre-pass walk)", function() return {} end, function(c, r)
	local sl = q.Slot(); local host = D.Frame { sl }
	for i = 1, N do sl:Add(q.Source(D.Frame { Name = "h" .. i })) end
end)
