--!nocheck
-- p-slot-bundle bench (scratch). Run from <variant>/quad-base: luau -O2 test/bench.slot-bundle.luau
-- Each row: min over R fresh builds of the timed step (ms). N = 1000.
local mock = require("./mock")
local Instance = mock.Instance
local function F(n) local f = Instance.new("Frame"); if n then f.Name = n end; return f end
local N, R = 1000, 7
local function best(label, setup, run)
	local t = math.huge
	for _ = 1, R do
		local ctx = setup()
		local t0 = os.clock()
		run(ctx)
		t = math.min(t, os.clock() - t0)
	end
	print(string.format("%-62s %9.3f ms", label, t * 1000))
end
local function mounted(q, s) q.Dispatch.drive(Instance.new("Folder"), { s }); return s end
local function mkList(q, ids)
	local data = q.Source(ids)
	local s = q.Slot()
	s:List(data, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		if ctx.Prev then return ctx.Prev end
		return F(tostring(ctx.Item))
	end, function(it) return it end)
	mounted(q, s)
	return data, s
end
local function range(a, b) local t = {} for i = a, b do t[#t + 1] = i end return t end

best("B9 nested Set: st:Set(fresh Slot{leaf}) x1000, mounted State element", function() local q = mock.newQuad(); local st = q.Source(nil); mounted(q, q.Slot({ F(), st, F() })); local l = {}; for i = 1, N do l[i] = q.Slot({ F() }) end; return { st, l } end,
	function(c) for i = 1, N do c[1]:Set(c[2][i]) end end)
best("B10 nested Set: Slot{State<State<leaf>> x1000}, inner:Set x1000", function() local q = mock.newQuad(); local inn, out = {}, {}; for i = 1, N do inn[i] = q.Source(F()); out[i] = q.Source(inn[i]) end; mounted(q, q.Slot(out)); local l = {}; for i = 1, N do l[i] = F() end; return { inn, l } end,
	function(c) for i = 1, N do c[1][i]:Set(c[2][i]) end end)
best("B13 chain: 1000 nested unmounted Slots built bottom-up", function() local q = mock.newQuad(); local l = {}; for i = 1, N do l[i] = q.Slot() end; return l end,
	function(l) for i = 2, N do l[i]:Add(l[i - 1]) end end)
best("B14 chain via States: 1000 levels Slot{State(prev)}", function() return mock.newQuad() end,
	function(q) local prev = q.Slot({ F() }); for _ = 2, N do local s = q.Slot(); s:Add(q.Source(prev)); prev = s end end)
