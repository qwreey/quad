--!nocheck
-- round13 E23 F2 — is the per-swap memory growth linear (leak) or bounded?
local H = require("./round13-e15-probe-setup")
local q, D, mock = H.q, H.D, H.mock
local function gc() for _ = 1, 6 do collectgarbage("collect") end end
local KEEP = {}
local function measure(label, setup, step, n)
	local ctx = setup()
	KEEP[#KEEP + 1] = ctx
	gc(); local base = collectgarbage("count")
	local out = {}
	for round = 1, 4 do
		for i = 1, n do step(ctx, i) end
		gc(); table.insert(out, ("%.0f"):format(collectgarbage("count") - base))
	end
	print(label, "KB growth after each", n, ":", table.concat(out, " "))
end
measure("M1 property inner swap", function() local w = q.Source(q.Source("0")); return { w = w, l = D.TextLabel { Text = w } } end,
	function(c, i) c.w:Set(q.Source("x")) end, 10000)
measure("M2 property plain Set (control)", function() local w = q.Source("0"); return { w = w, l = D.TextLabel { Text = w } } end,
	function(c, i) c.w:Set(tostring(i % 5)) end, 10000)
measure("M3 outer:Emit same inner", function() local w = q.Source(q.Source("0")); return { w = w, l = D.TextLabel { Text = w } } end,
	function(c, i) c.w:Emit() end, 10000)
measure("M4 plain<->State alternation", function() local s = q.Source("s"); local w = q.Source(s); return { w = w, s = s, l = D.TextLabel { Text = w } } end,
	function(c, i) if i % 2 == 0 then c.w:Set(c.s) else c.w:Set("p") end end, 10000)
measure("M5 unbound Source Set control", function() return { w = q.Source(0) } end, function(c, i) c.w:Set(i) end, 10000)
measure("M6 mock frames created only", function() return {} end, function(c, i) local f = D.Frame {} end, 2000)
