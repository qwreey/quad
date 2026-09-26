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

best("B1 leaf Add x1000, mounted", function() local q = mock.newQuad(); local l = {}; for i = 1, N do l[i] = F() end; return { mounted(q, q.Slot()), l } end,
	function(c) for i = 1, N do c[1]:Add(c[2][i]) end end)
best("B2 State(leaf) Add x1000, mounted", function() local q = mock.newQuad(); local l = {}; for i = 1, N do l[i] = q.Source(F()) end; return { mounted(q, q.Slot()), l } end,
	function(c) for i = 1, N do c[1]:Add(c[2][i]) end end)
best("B3 nil State Add x1000, unmounted", function() local q = mock.newQuad(); local l = {}; for i = 1, N do l[i] = q.Source(nil) end; return { q.Slot(), l } end,
	function(c) for i = 1, N do c[1]:Add(c[2][i]) end end)
best("B4 :List full replace (1000 -> 1000 new keys), one :Set", function() local q = mock.newQuad(); local d = mkList(q, range(1, N)); return { d, range(N + 1, 2 * N) } end,
	function(c) c[1]:Set(c[2]) end)
best("B5 :List full reverse (1000), one :Set", function() local q = mock.newQuad(); local d = mkList(q, range(1, N)); local r = {}; for i = 1, N do r[i] = N - i + 1 end; return { d, r } end,
	function(c) c[1]:Set(c[2]) end)
best("B6 :List half replace (odd keys new), one :Set", function() local q = mock.newQuad(); local d = mkList(q, range(1, N)); local r = {}; for i = 1, N do r[i] = if i % 2 == 1 then N + i else i end; return { d, r } end,
	function(c) c[1]:Set(c[2]) end)
best("B7 :List end-insert 1 (1000), one :Set", function() local q = mock.newQuad(); local d = mkList(q, range(1, N)); return { d, range(1, N + 1) } end,
	function(c) c[1]:Set(c[2]) end)
best("B8 :List middle-delete 1 (1000), one :Set", function() local q = mock.newQuad(); local d = mkList(q, range(1, N)); local r = range(1, N); table.remove(r, N // 2); return { d, r } end,
	function(c) c[1]:Set(c[2]) end)
best("B9 nested Set: st:Set(fresh Slot{leaf}) x1000, mounted State element", function() local q = mock.newQuad(); local st = q.Source(nil); mounted(q, q.Slot({ F(), st, F() })); local l = {}; for i = 1, N do l[i] = q.Slot({ F() }) end; return { st, l } end,
	function(c) for i = 1, N do c[1]:Set(c[2][i]) end end)
best("B10 nested Set: Slot{State<State<leaf>> x1000}, inner:Set x1000", function() local q = mock.newQuad(); local inn, out = {}, {}; for i = 1, N do inn[i] = q.Source(F()); out[i] = q.Source(inn[i]) end; mounted(q, q.Slot(out)); local l = {}; for i = 1, N do l[i] = F() end; return { inn, l } end,
	function(c) for i = 1, N do c[1][i]:Set(c[2][i]) end end)
best("B11 nested Set: Slot{State<Frame> x1000}, each :Set(new leaf)", function() local q = mock.newQuad(); local st = {}; for i = 1, N do st[i] = q.Source(F()) end; mounted(q, q.Slot(st)); local l = {}; for i = 1, N do l[i] = F() end; return { st, l } end,
	function(c) for i = 1, N do c[1][i]:Set(c[2][i]) end end)
for _, depth in { 1, 10, 100 } do
	best(`B12 Add+Extract of Slot\{leaf\} x1000 at depth {depth}, mounted`, function()
		local q = mock.newQuad(); local leafSlot = q.Slot(); local top = leafSlot
		for _ = 1, depth - 1 do top = q.Slot({ top }) end
		mounted(q, top); local l = {}; for i = 1, N do l[i] = q.Slot({ F() }) end; return { leafSlot, l } end,
		function(c) for i = 1, N do c[1]:Add(c[2][i]); c[1]:Extract(1) end end)
end
best("B13 chain: 1000 nested unmounted Slots built bottom-up", function() local q = mock.newQuad(); local l = {}; for i = 1, N do l[i] = q.Slot() end; return l end,
	function(l) for i = 2, N do l[i]:Add(l[i - 1]) end end)
best("B14 chain via States: 1000 levels Slot{State(prev)}", function() return mock.newQuad() end,
	function(q) local prev = q.Slot({ F() }); for _ = 2, N do local s = q.Slot(); s:Add(q.Source(prev)); prev = s end end)
