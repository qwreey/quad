--!nocheck
local mock = require("./mock")
local Instance = mock.Instance
local function F() return Instance.new("Frame") end
local N = 1000
local function best(label, setup, run)
	local t = math.huge
	for _ = 1, 5 do
		local ctx = setup()
		local t0 = os.clock()
		run(ctx)
		t = math.min(t, os.clock() - t0)
	end
	print(string.format("  %-58s %8.2f ms", label, t * 1000))
end
best("1000 leaf Add, unmounted", function() local q = mock.newQuad(); local l = {}; for i = 1, N do l[i] = F() end; return { q.Slot(), l } end,
	function(c) for i = 1, N do c[1]:Add(c[2][i]) end end)
best("1000 leaf Add, mounted", function() local q = mock.newQuad(); local s = q.Slot(); q.Dispatch.drive(Instance.new("Folder"), { s }); local l = {}; for i = 1, N do l[i] = F() end; return { s, l } end,
	function(c) for i = 1, N do c[1]:Add(c[2][i]) end end)
best("1000 Add of Slot{leaf,leaf}, mounted", function() local q = mock.newQuad(); local s = q.Slot(); q.Dispatch.drive(Instance.new("Folder"), { s }); local l = {}; for i = 1, N do l[i] = q.Slot({ F(), F() }) end; return { s, l } end,
	function(c) for i = 1, N do c[1]:Add(c[2][i]) end end)
best("1000 Add of nil State, unmounted", function() local q = mock.newQuad(); local l = {}; for i = 1, N do l[i] = q.Source(nil) end; return { q.Slot(), l } end,
	function(c) for i = 1, N do c[1]:Add(c[2][i]) end end)
best("1000 Add of State(leaf), mounted", function() local q = mock.newQuad(); local s = q.Slot(); q.Dispatch.drive(Instance.new("Folder"), { s }); local l = {}; for i = 1, N do l[i] = q.Source(F()) end; return { s, l } end,
	function(c) for i = 1, N do c[1]:Add(c[2][i]) end end)
best("chain: 1000 nested unmounted Slots built bottom-up", function() local q = mock.newQuad(); local l = {}; for i = 1, N do l[i] = q.Slot() end; return l end,
	function(l) for i = 2, N do l[i]:Add(l[i - 1]) end end)
best("chain via States: 1000 levels Slot{State(prev)}", function() local q = mock.newQuad(); return q end,
	function(q) local prev = q.Slot({ F() }); for _ = 2, N do local s = q.Slot(); s:Add(q.Source(prev)); prev = s end end)
best("wide: one Add of a Slot holding 1000 leaves (x1000 containers)", function() local q = mock.newQuad(); local big = {}; for i = 1, N do big[i] = F() end; local w = q.Slot(big); local cs = {}; for i = 1, N do cs[i] = q.Slot() end; return { w, cs } end,
	function(c) for i = 1, N do c[2][i]:Add(c[1]); c[2][i]:Extract(1) end end)
best("1000 st:Set(fresh Slot{leaf}) of a mounted State element", function() local q = mock.newQuad(); local st = q.Source(nil); local s = q.Slot({ F(), st, F() }); q.Dispatch.drive(Instance.new("Folder"), { s }); local l = {}; for i = 1, N do l[i] = q.Slot({ F() }) end; return { st, l } end,
	function(c) for i = 1, N do c[1]:Set(c[2][i]) end end)
best("1000 st:Set(fresh leaf) of a mounted State element", function() local q = mock.newQuad(); local st = q.Source(nil); local s = q.Slot({ F(), st, F() }); q.Dispatch.drive(Instance.new("Folder"), { s }); local l = {}; for i = 1, N do l[i] = F() end; return { st, l } end,
	function(c) for i = 1, N do c[1]:Set(c[2][i]) end end)
