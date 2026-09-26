--!nocheck
-- round13 E23 E — unwrap timing: same-wave outer+inner change, glitches, Blocker, ghost within wave
local H = require("./round13-e15-probe-setup")
local q, D, mock = H.q, H.D, H.mock
local function first(err) return (tostring(err):gsub("\n.*", ""):gsub("^.-(Quad%d%d%d%d)", "%1"):sub(1, 160)) end
local function writes(inst, prop)
	local c = { n = 0, vals = {} }
	inst:GetPropertyChangedSignal(prop):Connect(function() c.n += 1; table.insert(c.vals, tostring(inst[prop])) end)
	return c
end
local function sec(name, fn) print("=== " .. name .. " ==="); local ok, err = pcall(fn); if not ok then print("  !! section error:", first(err)) end end

sec("E1 outer and inner both derived from one source (same wave)", function()
	local src = q.Source(1)
	local a = src:Compute(function(s) return "a" .. s:Get() end)
	local b = src:Compute(function(s) return "b" .. s:Get() end)
	local outer = src:Compute(function(s) return if s:Get() % 2 == 1 then a else b end)
	local l = D.TextLabel { Text = outer }
	local w = writes(l, "Text")
	src:Set(2); print("  src=2 Text", l.Text, "writes", w.n, table.concat(w.vals, ","))
	src:Set(3); print("  src=3 Text", l.Text, "writes", w.n, table.concat(w.vals, ","))
	src:Set(4); print("  src=4 Text", l.Text, "writes", w.n, table.concat(w.vals, ","))
end)

sec("E1b same but outer created BEFORE the inners (subscription order flipped)", function()
	local src = q.Source(1)
	local holder = {}
	local outer = src:Compute(function(s) return if s:Get() % 2 == 1 then holder.a else holder.b end)
	holder.a = src:Compute(function(s) return "a" .. s:Get() end)
	holder.b = src:Compute(function(s) return "b" .. s:Get() end)
	local l = D.TextLabel { Text = outer }
	local w = writes(l, "Text")
	src:Set(2); print("  src=2 Text", l.Text, "writes", w.n, table.concat(w.vals, ","))
	src:Set(3); print("  src=3 Text", l.Text, "writes", w.n, table.concat(w.vals, ","))
end)

sec("E2 inner stays the same object, both outer and inner notify in one wave", function()
	local src = q.Source(1)
	local a = src:Compute(function(s) return "a" .. s:Get() end)
	local outer = src:Compute(function(s) s:Get(); return a end) -- re-emits the same inner every wave
	local l = D.TextLabel { Text = outer }
	local w = writes(l, "Text")
	src:Set(2); print("  src=2 Text", l.Text, "writes", w.n, table.concat(w.vals, ","))
	src:Set(3); print("  src=3 Text", l.Text, "writes", w.n, table.concat(w.vals, ","))
end)

sec("E3 Observer on outer sets the OLD inner during the swap wave (ghost within wave?)", function()
	local a, b = q.Source("A"), q.Source("B")
	local which = q.Source(a)
	local l = D.TextLabel { Text = which }
	local w = writes(l, "Text")
	local obs = which:Observer(function(st) if st:Get() == b then a:Set("A-late") end end)
	which:Set(b); print("  Text", l.Text, "writes", w.n, table.concat(w.vals, ","))
	obs:WeakSubscribe()
end)

sec("E4 Blocker on outer: inner changes while outer swap is withheld", function()
	local a, b = q.Source("A"), q.Source("B")
	local which = q.Source(a)
	local blocker = q.Blocker()
	local gated = which:Apply(blocker)
	local l = D.TextLabel { Text = gated }
	local w = writes(l, "Text")
	blocker:On()
	which:Set(b); print("  which:Set(b) blocked Text", l.Text)
	a:Set("A2"); print("  a:Set while blocked Text", l.Text, "(gated:Get()==b?", gated:Get() == b, ")")
	b:Set("B2"); print("  b:Set while blocked Text", l.Text)
	blocker:Off(); print("  Off Text", l.Text, "writes", w.n, table.concat(w.vals, ","))
	blocker:On(); which:Set(a); blocker:OffWithoutEmit(); print("  OffWithoutEmit after swap back Text", l.Text)
	a:Set("A3"); print("  a:Set after OffWithoutEmit Text", l.Text)
	b:Set("B3"); print("  b:Set after OffWithoutEmit Text", l.Text)
end)

sec("E5 Blocker on inner; outer swaps away while inner holds a withheld emit", function()
	local a = q.Source("A")
	local blocker = q.Blocker()
	local ga = a:Apply(blocker)
	local c = q.Source("C")
	local which = q.Source(ga)
	local l = D.TextLabel { Text = which }
	local w = writes(l, "Text")
	blocker:On(); a:Set("A2"); which:Set(c); print("  swapped to c while ga blocked Text", l.Text)
	blocker:Off(); print("  Off Text", l.Text, "writes", w.n, table.concat(w.vals, ","))
end)

sec("E6 Blocker on BOTH (same blocker): swap + inner change, Off order", function()
	local a, b = q.Source("A"), q.Source("B")
	local blocker = q.Blocker()
	local ga, gb = a:Apply(blocker), b:Apply(blocker)
	local which = q.Source(ga)
	local gw = which:Apply(blocker)
	local l = D.TextLabel { Text = gw }
	local w = writes(l, "Text")
	blocker:On(); a:Set("A2"); which:Set(gb); b:Set("B2")
	blocker:Off(); print("  Off Text", l.Text, "writes", w.n, table.concat(w.vals, ","))
end)

sec("E7 numeric child: inner and outer change in same wave (Instance)", function()
	local src = q.Source(1)
	local fa, fb = D.Frame { Name = "fa1" }, D.Frame { Name = "fb1" }
	local a = src:Compute(function(s) return if s:Get() < 10 then fa else D.Frame { Name = "fa2" } end)
	local b = src:Compute(function(s) return fb end)
	local outer = src:Compute(function(s) return if s:Get() % 2 == 1 then a else b end)
	local host = D.Frame { Name = "host", outer }
	local log = {}
	host.ChildAdded = nil
	local function kids() local t = {} for _, c in host:GetChildren() do table.insert(t, c.Name) end return table.concat(t, ",") end
	print("  kids", kids())
	src:Set(11); print("  src=11 kids", kids(), "fa1 parent", tostring(fa.Parent and fa.Parent.Name))
end)
