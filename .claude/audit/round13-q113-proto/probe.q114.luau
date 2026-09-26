--!nocheck
-- round13 P-Q114 — edge cases of the same-wave revalidation (a). Run from a variant root.
local H = require("./round13-e15-probe-setup")
local q, D = H.q, H.D
local function first(err) return (tostring(err):gsub("\n.*", ""):gsub("^.-(Quad%d%d%d%d)", "%1"):sub(1, 90)) end
local function writes(inst, prop)
	local c = { n = 0, vals = {} }
	inst:GetPropertyChangedSignal(prop):Connect(function() c.n += 1; table.insert(c.vals, tostring(inst[prop])) end)
	return c
end
local function show(label, l, w) print(("  %-34s Text=%s writes=%d [%s]"):format(label, tostring(l.Text), w.n, table.concat(w.vals, ","))) end
local function sec(name, fn) print("=== " .. name); local ok, err = pcall(fn); if not ok then print("  !! " .. first(err)) end end
local function kids(f) local t = {} for _, c in f:GetChildren() do table.insert(t, c.Name) end table.sort(t) return table.concat(t, ",") end

sec("K1 outer re-selects the SAME inner every wave (Compute re-emits a)", function()
	local src = q.Source(1)
	local a = src:Compute(function(s) return "a" .. s:Get() end)
	local outer = src:Compute(function(s) s:Get(); return a end)
	local l = D.TextLabel { Text = outer }; local w = writes(l, "Text")
	src:Set(2); show("src=2", l, w); src:Set(3); show("src=3", l, w)
end)
sec("K2 outer swaps a -> Source(a) (same inner, wrapped once more) while a changes", function()
	local src = q.Source(1)
	local a = src:Compute(function(s) return "a" .. s:Get() end)
	local wa = q.Source(a)
	local outer = src:Compute(function(s) return if s:Get() == 1 then a else wa end)
	local l = D.TextLabel { Text = outer }; local w = writes(l, "Text")
	src:Set(2); show("src=2 (-> Source(a))", l, w); src:Set(1); show("src=1 (-> a)", l, w)
end)
sec("K3 the same inner State bound at two levels of one chain (outer -> x, x -> a; outer later -> a)", function()
	local src = q.Source(1)
	local a = src:Compute(function(s) return "a" .. s:Get() end)
	local x = q.Source(a)
	local outer = src:Compute(function(s) return if s:Get() == 1 then x else a end)
	local l = D.TextLabel { Text = outer }; local w = writes(l, "Text")
	src:Set(2); show("src=2 (x -> a direct)", l, w); src:Set(1); show("src=1 (-> x)", l, w)
end)
sec("K4 Blocker directly on the outer (Gate node): inner of the OLD selection updates during the hold", function()
	local a, b = q.Source("A"), q.Source("B")
	local which = q.Source(a)
	local blk = q.Blocker(); local gated = which:Apply(blk)
	local l = D.TextLabel { Text = gated }; local w = writes(l, "Text")
	blk:On(); which:Set(b); a:Set("A2"); show("hold: which->b, a->A2", l, w)
	b:Set("B2"); show("hold: b->B2", l, w)
	blk:Off(); show("Off", l, w)
end)
sec("K5 Blocker UPSTREAM of a Compute outer (gate not on the bound State)", function()
	local a, b = q.Source("A"), q.Source("B")
	local which = q.Source(1)
	local blk = q.Blocker(); local gw = which:Apply(blk)
	local outer = gw:Compute(function(g) return if g:Get() == 1 then a else b end)
	local l = D.TextLabel { Text = outer }; local w = writes(l, "Text")
	blk:On(); which:Set(2); a:Set("A2"); show("hold: which->2, a->A2", l, w)
	blk:Off(); show("Off", l, w)
end)
sec("K6 Slot place, Blocker on the element State: hold, old branch updates", function()
	local fa1, fa2, fb = D.Frame { Name = "a1" }, D.Frame { Name = "a2" }, D.Frame { Name = "b" }
	local a, b = q.Source(fa1), q.Source(fb)
	local which = q.Source(a)
	local blk = q.Blocker(); local gated = which:Apply(blk)
	local sl = q.Slot { gated }; local host = D.Frame { sl }
	blk:On(); which:Set(b); a:Set(fa2); print("  hold: which->b, a->a2  kids", kids(host), "len", sl.Length:Get())
	blk:Off(); print("  Off  kids", kids(host), "len", sl.Length:Get())
end)
sec("K7 Slot place, user sl:Single(outer) (not a wrapper) same-wave race", function()
	local dist = {}
	for trial = 1, 300 do
		local src = q.Source(1)
		local pad = {}
		for i = 1, trial % 7 do pad[i] = src:Compute(function(s) return s:Get() end) end
		local fX, fY, fZ = D.Frame { Name = "X" }, D.Frame { Name = "Y" }, D.Frame { Name = "Z" }
		local other = D.Frame { Name = "other", fZ }
		local a = src:Compute(function(s) return if s:Get() == 1 then fX else fZ end)
		local b = src:Compute(function() return fY end)
		local outer = src:Compute(function(s) return if s:Get() == 1 then a else b end)
		local sl = q.Slot(); sl:Single(outer); local host = D.Frame { sl }
		local ok, err = pcall(function() src:Set(2) end)
		local key = (ok and "ok" or first(err)) .. " [" .. kids(host) .. "] len=" .. sl.Length:Get()
		dist[key] = (dist[key] or 0) + 1
	end
	for k, v in dist do print("  ", v, k) end
end)
sec("K8 Slot place wrapper: same-wave Slot-valued branches (State<Slot> swap with length change)", function()
	local src = q.Source(1)
	local sA = src:Compute(function(s) return q.Slot { D.Frame { Name = "a" .. s:Get() } } end)
	local sB = src:Compute(function(s) local t = {} for i = 1, s:Get() + 1 do t[i] = D.Frame { Name = "b" .. i } end return q.Slot(t) end)
	local outer = src:Compute(function(s) return if s:Get() % 2 == 1 then sA else sB end)
	local sl = q.Slot { outer, D.Frame { Name = "tail" } }; local host = D.Frame { sl }
	local ok, err = pcall(function() src:Set(2) end)
	print("  src=2", ok and "ok" or first(err), "kids", kids(host), "len", sl.Length:Get())
	ok, err = pcall(function() src:Set(3) end)
	print("  src=3", ok and "ok" or first(err), "kids", kids(host), "len", sl.Length:Get())
end)
sec("K9 Slot place, :List(data, updateFn) whose updateFn SELECTS a State (owner is not an identity Single) — not covered", function()
	local dist = {}
	for trial = 1, 300 do
		local src = q.Source(1)
		local pad = {}
		for i = 1, trial % 7 do pad[i] = src:Compute(function(s) return s:Get() end) end
		local fX, fY, fZ = D.Frame { Name = "X" }, D.Frame { Name = "Y" }, D.Frame { Name = "Z" }
		local other = D.Frame { Name = "other", fZ }
		local a = src:Compute(function(s) return if s:Get() == 1 then fX else fZ end)
		local b = src:Compute(function() return fY end)
		local data = src:Compute(function(s) return { s:Get() } end)
		local sl = q.Slot(); sl:List(data, function(ctx) if ctx.Item == q.KeyGone then return nil end return if ctx.Item == 1 then a else b end, function() return 1 end)
		local host = D.Frame { sl }
		local ok, err = pcall(function() src:Set(2) end)
		local key = (ok and "ok" or first(err)) .. " [" .. kids(host) .. "] len=" .. sl.Length:Get()
		dist[key] = (dist[key] or 0) + 1
	end
	for k, v in dist do print("  ", v, k) end
end)
