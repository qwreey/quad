--!nocheck
-- E66 axes (a)~(l): one-off measurements on the prov harness (env.luau). usage: luau axes.luau
local E = require("./env")
local function cnt(sig) return #sig.connections end
local function hdr(s) print("== " .. s) end
local function try(f) local ok, e = pcall(f); return ok, ok and "ok" or E.id(e), e end

-- (a) callback that throws inside an engine event
do
	hdr("(a) throwing Event callback")
	local q = E.newProv(); local D = q.Declaration
	local fired = {}
	local b = D.TextButton({ Activated = function() error("user boom") end })
	b.Activated:Connect(function() table.insert(fired, "raw-before?") end)
	local ok, id, raw = try(function() b.Activated:Fire() end)
	print("fire ok", ok, "raw", raw, "conns", cnt(b.Activated), "raw-other fired", #fired)
	local ok2 = try(function() b.Activated:Fire() end)
	print("second fire ok", ok2, "(connection survives in mock = still throws)")
	-- throwing OnChange callback during a Property write inside process
	local s = q.Source("a")
	local t = D.TextButton({ q.OnChange("Text", function(v) if v == "bad" then error("onchange boom") end end), Text = s })
	local ok3, id3, raw3 = try(function() s:Set("bad") end)
	print("OnChange throw via Set ok", ok3, raw3, "Text=", t.Text)
	local ok4, id4 = try(function() s:Set("fine") end)
	print("next Set ok", ok4, id4, "Text=", t.Text)
end

-- (b) callback that Sets the State that drives it
do
	hdr("(b) callback re-seats itself")
	local q = E.newProv(); local D = q.Declaration
	local log = {}
	local s = q.Source(nil)
	local fB = function() table.insert(log, "B") end
	local fA = function() table.insert(log, "A"); s:Set(fB) end
	s:Set(fA)
	local b = D.TextButton({ Activated = s })
	b.Activated:Fire(); b.Activated:Fire()
	print("log", table.concat(log, ","), "conns", cnt(b.Activated))
	-- self-replacing N deep: A1 sets A2 sets ... within one fire
	local s2 = q.Source(nil); local log2 = {}
	local fns = {}
	for i = 1, 5 do fns[i] = function() table.insert(log2, i); if fns[i + 1] then s2:Set(fns[i + 1]) end end end
	s2:Set(fns[1])
	local b2 = D.TextButton({ Activated = s2 })
	for _ = 1, 6 do b2.Activated:Fire() end
	print("chain log", table.concat(log2, ","), "conns", cnt(b2.Activated))
	-- callback sets the State to nil (disconnect itself) then back
	local s3 = q.Source(nil); local n3 = 0
	local f3; f3 = function() n3 += 1; s3:Set(nil) end
	s3:Set(f3)
	local b3 = D.TextButton({ Activated = s3 })
	b3.Activated:Fire(); b3.Activated:Fire()
	print("self-nil fired", n3, "conns", cnt(b3.Activated))
end

-- (c) Destroy while a State-driven callback is pending (Set after Destroy; Destroy inside callback)
do
	hdr("(c) destroy while pending")
	local q = E.newProv(); local D = q.Declaration
	local s = q.Source(function() end)
	local b = D.TextButton({ Activated = s })
	b:Destroy()
	s:Set(function() end)
	print("after destroy + Set conns", cnt(b.Activated), "observers of s", s._observers and #s._observers or "?")
	-- callback destroys its own instance, then sets State
	local s2 = q.Source(nil); local b2
	s2:Set(function() b2:Destroy(); s2:Set(function() end) end)
	b2 = D.TextButton({ Activated = s2 })
	local ok, id, raw = try(function() b2.Activated:Fire() end)
	print("destroy-in-callback ok", ok, raw, "conns", cnt(b2.Activated))
	-- process on a destroyed instance directly
	local b3 = D.TextButton({})
	b3:Destroy()
	local ok3, id3, raw3 = try(function() q.Dispatch.process(b3, "Activated", function() end, 1) end)
	print("process Event on destroyed ok", ok3, raw3, "conns", cnt(b3.Activated))
	local ok4, id4, raw4 = try(function() q.Dispatch.process(b3, 1, q.OnChange("Text", function() end), 1) end)
	print("process OnChange on destroyed ok", ok4, raw4)
	local ok5, id5, raw5 = try(function() q.Dispatch.process(b3, "Text", "x", 1) end)
	print("process Property on destroyed ok", ok5, raw5)
	local ok6, id6, raw6 = try(function() q.Dispatch.process(b3, "UIScale", 2, 1) end)
	print("process Shorthand on destroyed ok", ok6, raw6)
end

-- (d) OnChange on a property the chain itself writes (feedback)
do
	hdr("(d) feedback loops")
	local q = E.newProv(); local D = q.Declaration
	-- d1 clamp with guard
	local s = q.Source(1)
	local calls = 0
	local f = D.Frame({ q.OnChange("ZIndex", function(v) calls += 1; if calls > 50 then error("runaway") end; local c = math.min(v, 5); if c ~= v then s:Set(c) end end), ZIndex = s })
	local ok, id, raw = try(function() s:Set(9) end)
	print("d1 clamp guarded ok", ok, raw, "ZIndex", f.ZIndex, "src", s:Get(), "calls", calls)
	-- d2 unguarded write-back (05-onchange caution workaround: function(v) src:Set(v) end)
	local s2 = q.Source(1); local calls2 = 0
	local f2 = D.Frame({ q.OnChange("ZIndex", function(v) calls2 += 1; if calls2 > 200 then error("runaway") end; s2:Set(v) end), ZIndex = s2 })
	print("d2 after bind calls", calls2)
	local ok2, id2, raw2 = try(function() s2:Set(3) end)
	print("d2 unguarded Set ok", ok2, id2, "calls", calls2, "ZIndex", f2.ZIndex)
	-- d3 q.Out + same Source: Set emits
	local s3 = q.Source("a"); local emits = 0
	s3:Observer(function() emits += 1 end)
	local before = emits
	local t = D.TextButton({ Text = s3, q.Out("Text", s3) })
	t.Text = "typed"
	print("d3 Out: src", s3:Get(), "emits(bind+typing)", emits - before)
	-- d4 Out clamp chained via Compute on another prop (two-way through two props)
	local a = q.Source(1)
	local g = D.Frame({ ZIndex = a, q.Out("ZIndex", a), Visible = a:Compute(function(x) return x:Get() > 2 end) })
	g.ZIndex = 7
	print("d4 Out a", a:Get(), "Visible", g.Visible)
end

-- (e) rapid replace N times then GC
do
	hdr("(e) rapid replace + GC")
	local q = E.newProv(); local D = q.Declaration
	local b = D.TextButton({})
	local weak = setmetatable({}, { __mode = "v" })
	local s = q.Source(nil)
	q.Dispatch.process(b, "Activated", s, 1)
	for i = 1, 1000 do local fn = function() return i end; weak[i] = fn; s:Set(fn) end
	collectgarbage(); collectgarbage()
	local alive = 0; for _ in weak do alive += 1 end
	print("State path: conns", cnt(b.Activated), "closures alive", alive)
	local weak2 = setmetatable({}, { __mode = "v" })
	for i = 1, 1000 do local fn = function() return i end; weak2[i] = fn; q.Dispatch.process(b, "MouseEnter", fn, 1) end
	collectgarbage(); collectgarbage()
	local alive2 = 0; for _ in weak2 do alive2 += 1 end
	print("direct process path: conns", cnt(b.MouseEnter), "closures alive", alive2)
	-- OnChange State swap
	local sd = q.Source(q.None); local weak3 = setmetatable({}, { __mode = "v" })
	q.Dispatch.process(b, 1, sd, 1)
	for i = 1, 1000 do local fn = function() return i end; weak3[i] = fn; sd:Set(q.OnChange("Text", fn)) end
	collectgarbage(); collectgarbage()
	local alive3 = 0; for _ in weak3 do alive3 += 1 end
	print("OnChange swap: Text conns", cnt(b:GetPropertyChangedSignal("Text")), "alive", alive3)
	-- retract after all
	q.Dispatch.retractFrom(b, "Activated", 1); q.Dispatch.retractFrom(b, "MouseEnter", 1); q.Dispatch.retractFrom(b, 1, 1)
	print("after retract conns", cnt(b.Activated), cnt(b.MouseEnter), cnt(b:GetPropertyChangedSignal("Text")))
	-- Set after retract must not reconnect
	s:Set(function() end); sd:Set(q.OnChange("Text", function() end))
	print("Set after retract conns", cnt(b.Activated), cnt(b:GetPropertyChangedSignal("Text")))
end

-- (f) Event name the class does not have / other odd keys
do
	hdr("(f) missing signal")
	local q = E.newProv(); local D = q.Declaration
	local f = D.Frame({})
	local ok, id, raw = try(function() q.Dispatch.process(f, "Activated", function() end, 1) end)
	print("Frame.Activated", ok, id, raw)
	local ok2, id2, raw2 = try(function() q.Dispatch.process(f, "Activated", nil, 1) end)
	print("Frame.Activated nil", ok2, id2, raw2)
	local b = D.TextButton({})
	local ok3, id3, raw3 = try(function() q.Dispatch.process(b, "Activated", setmetatable({}, { __call = function() end }), 1) end)
	print("callable table", ok3, id3)
	local ok4, id4 = try(function() q.Dispatch.process(b, "Activated", q.None, 1) end)
	print("None", ok4, id4, cnt(b.Activated))
	-- OnChange on a name that is an event
	local ok5, id5, raw5 = try(function() q.Dispatch.process(b, 1, q.OnChange("Activated", function() end), 1) end)
	print("OnChange(event name) mock", ok5, id5, "(engine: GetPropertyChangedSignal raises — unmeasured here)")
end

-- (g) static child destroyed while seated, then swap / retract
do
	hdr("(g) seated child destroyed")
	local q = E.newProv(); local D = q.Declaration
	local c1 = D.Frame({ Name = "c1" }); local c2 = D.Frame({ Name = "c2" })
	local s = q.Source(c1)
	local p = D.Frame({ s, D.Frame({ Name = "sib" }) })
	c1:Destroy()
	print("c1 parent after destroy", c1.Parent)
	local ok, id, raw = try(function() s:Set(c2) end)
	print("swap after child destroyed", ok, raw, "c2.Parent==p", c2.Parent == p, "c1.Parent", c1.Parent)
	-- re-seat destroyed c1 into another parent
	local p2 = D.Frame({})
	local ok2, id2, raw2 = try(function() q.Dispatch.process(p2, 1, c1, 1) end)
	print("re-seat destroyed c1", ok2, id2)
	-- dispose of destroyed seated? static seat with plain value then destroy then retractFrom
	local c3 = D.Frame({}); local p3 = D.Frame({ c3 })
	c3:Destroy()
	local ok3, id3, raw3 = try(function() q.Dispatch.retractFrom(p3, 1, 1) end)
	print("retractFrom after destroyed child", ok3, raw3)
	local ok4, id4, raw4 = try(function() q.dispose(p3) end)
	print("dispose parent", ok4, raw4)
end

-- (h) reparented externally then same-value re-emit (dedup)
do
	hdr("(h) external reparent + same-value re-emit")
	local q = E.newProv(); local D = q.Declaration
	local c = D.Frame({}); local s = q.Source(c)
	local p = D.Frame({ s }); local other = D.Frame({})
	c.Parent = other
	s:Set(c)
	print("after same re-emit c.Parent==p", c.Parent == p, "==other", c.Parent == other)
	s:Set(nil)
	print("after nil c.Parent", c.Parent, "(other lost its child)")
end

-- (i) property write count per emit (plain values: no dedup)
do
	hdr("(i) Property write count")
	local q = E.newProv(); local D = q.Declaration
	local s = q.Source(1)
	local f = D.Frame({ ZIndex = s })
	local writes = 0
	f:GetPropertyChangedSignal("ZIndex"):Connect(function() writes += 1 end)
	s:Set(1); s:Set(1); s:Set(2); s:Set(2)
	print("4 Sets (1,1,2,2) writes", writes)
	local sh = q.Source(2)
	local g = D.Frame({ UIScale = sh })
	local child = g:FindFirstChild("_quad_scale")
	local w2 = 0
	child:GetPropertyChangedSignal("Scale"):Connect(function() w2 += 1 end)
	sh:Set(2); sh:Set(3)
	print("shorthand writes", w2)
	sh:Set(nil)
	print("shorthand nil destroyed", E.mock.isDestroyed(child), g:FindFirstChild("_quad_scale"))
	sh:Set(4)
	local c2 = g:FindFirstChild("_quad_scale")
	print("recreated", c2 ~= nil and c2 ~= child, c2 and c2.Scale)
end

-- (j) Out when the Source is also held elsewhere and the instance is destroyed
do
	hdr("(j) Out/OnChange after destroy")
	local q = E.newProv(); local D = q.Declaration
	local s = q.Source("a")
	local t = D.TextButton({ Text = s, q.Out("Text", s) })
	local sig = t:GetPropertyChangedSignal("Text")
	t:Destroy()
	print("Text conns after destroy", cnt(sig))
	t.Text = "post"  -- mock: writes still allowed on corpse
	print("src after corpse write", s:Get())
end

-- (k) same OnChange descriptor value in two seats / same fn twice
do
	hdr("(k) one descriptor in two seats")
	local q = E.newProv(); local D = q.Declaration
	local n = 0
	local d = q.OnChange("Text", function() n += 1 end)
	local t = D.TextButton({ d, d })
	t.Text = "x"
	print("fired", n, "conns", cnt(t:GetPropertyChangedSignal("Text")))
	local fn = function() n += 1 end
	local u = D.TextButton({})
	q.Dispatch.process(u, "Activated", fn, 1)
	q.Dispatch.process(u, "Activated", fn, 1)
	print("same fn re-process conns", cnt(u.Activated))
end

-- (g2) same as (g) under a harness-side Parent-lock variant. Two shapes:
--   "all"    — every Parent write on a corpse raises (what E66 first assumed from memory — WRONG for the engine)
--   "nonnil" — only a non-nil Parent raises; `corpse.Parent = nil` passes silently. This is the Studio-measured
--              engine behaviour (base/lifecycle-pattern.md:986, round11 H′, sandbox place, user-confirmed 2026-09-18)
local LOCKMODE = "all"
local function lockParent(inst)
	local mt = getmetatable(inst)
	if mt.__e66locked then return end
	local old = mt.__newindex
	mt.__newindex = function(self, k, v)
		if k == "Parent" and E.mock.isDestroyed(self) and (LOCKMODE == "all" or v ~= nil) then
			error(`The Parent property of {tostring(self)} is locked, current parent: NULL, new parent {v and tostring(v) or "NULL"}`, 2)
		end
		return old(self, k, v)
	end
	mt.__e66locked = true
end
for _, mode in { "all", "nonnil" } do
	LOCKMODE = mode
	hdr("(g2) seated child destroyed, Parent-lock variant = " .. mode)
	local q = E.newProv(); local D = q.Declaration
	local c1 = D.Frame({ Name = "c1" }); local c2 = D.Frame({ Name = "c2" }); lockParent(c1)
	local s = q.Source(c1)
	local p = D.Frame({ s })
	c1:Destroy()
	local ok, id, raw = try(function() s:Set(c2) end)
	print("swap after child destroyed", ok, raw, "c2.Parent==p", c2.Parent == p)
	local ok1, id1, raw1 = try(function() s:Set(nil) end)
	print("second Set(nil)", ok1, id1)
	local ok2, id2, raw2 = try(function() q.dispose(p) end)
	print("dispose parent", ok2, id2, raw2)
	-- plain static seat
	local c3 = D.Frame({ Name = "c3" }); lockParent(c3)
	local p3 = D.Frame({ c3 })
	c3:Destroy()
	local ok3, id3, raw3 = try(function() p3:Destroy() end)
	print("parent Destroy after child destroyed (no retract path)", ok3, raw3)
	local c4 = D.Frame({ Name = "c4" }); lockParent(c4)
	local p4 = D.Frame({ c4 })
	c4:Destroy()
	local ok4, id4, raw4 = try(function() q.Dispatch.retractFrom(p4, 1, 1) end)
	print("retractFrom", ok4, raw4)
	local ok5, id5 = try(function() q.Dispatch.retractFrom(p4, 1, 1) end)
	print("retractFrom again", ok5, id5)
end
