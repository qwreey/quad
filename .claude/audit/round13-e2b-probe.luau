--!nocheck
-- Moved from quad-roblox/test/probe.e2b.luau; to rerun copy back there after ./scripts/relink.sh and run `luau quad-roblox/test/probe.e2b.luau`.
-- round13 E2-2 probe (scratch) — InstanceShorthand / Modifier+StoreBind / Event
local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installProperty = require("../src/Handlers/Property")
local installEvent = require("../src/Handlers/Event")
local installShorthand = require("../src/Handlers/InstanceShorthand")
local mock = require("../../quad-base/test/mock")
local Instance = mock.Instance

local W = { Write = "" }
local REFLECTED = {
	Frame = { { Name = "Name", Permits = W }, { Name = "Size", Permits = W }, { Name = "Visible", Permits = W }, { Name = "Parent", Permits = W }, { Name = "BackgroundTransparency", Permits = W } },
	TextButton = { { Name = "Name", Permits = W }, { Name = "Text", Permits = W }, { Name = "Visible", Permits = W }, { Name = "Size", Permits = W } },
	UICorner = { { Name = "Name", Permits = W }, { Name = "CornerRadius", Permits = W } },
	UIPadding = { { Name = "Name", Permits = W }, { Name = "PaddingLeft", Permits = W }, { Name = "PaddingRight", Permits = W }, { Name = "PaddingTop", Permits = W }, { Name = "PaddingBottom", Permits = W } },
	UIScale = { { Name = "Name", Permits = W }, { Name = "Scale", Permits = W } },
}
mock.declareEvents("TextButton", { "Activated", "MouseEnter" })
mock.declareEvents("Frame", { "Changed", "MouseEnter" })
local gameShim = mock.gameShim(REFLECTED)
local q = Quad.New():UseProvider(QuadRoblox)
;(getfenv(installProperty)).game = gameShim
;(getfenv(installProperty)).TweenInfo = mock.tweenInfoShim
;(getfenv(installProperty)).Enum = { EasingStyle = { Quad = "Quad" }, EasingDirection = { Out = "Out" }, PlaybackState = { Completed = "Completed", Cancelled = "Cancelled" } }
;(getfenv(installEvent)).game = gameShim
;(getfenv(require("../src/EngineOps"))).game = gameShim
;(getfenv(q.Declaration.New)).Instance = { new = mock.Instance.new }
q.Backend.isInst = mock.isMockInstance
q.errorNamespace.setFuncLevel(require("../luau_packages/quad_types").ERROR_LEVEL_SURFACE, q.Backend.isInst)
local D = q.Declaration
local function first(err) return (tostring(err):gsub("\n.*", "")) end
local UDIM_MT = { __eq = function(a, b) return a.Scale == b.Scale and a.Offset == b.Offset end,
	__tostring = function(a) return ("UDim(%s,%s)"):format(a.Scale, a.Offset) end }
UDim = { new = function(s, o) return setmetatable({ Scale = s, Offset = o }, UDIM_MT) end }
;(getfenv(installShorthand)).UDim = UDim
local function sec(name, fn)
	print("=== " .. name .. " ===")
	local ok, err = pcall(fn)
	if not ok then print("  !! section error:", first(err)) end
end
local function kids(f) local t = {} for _, c in f:GetChildren() do table.insert(t, c.ClassName .. ":" .. c.Name) end return table.concat(t, ",") end
local function nsubs(s) collectgarbage("collect"); collectgarbage("collect"); local n = 0 for _ in s._subs do n += 1 end return n end
local function named(f, n) for _, c in f:GetChildren() do if c.Name == n then return c end end end

-- ===================== (1) InstanceShorthand =====================
sec("S1 UICorner State: Tween -> nil -> Tween (recreated child snaps?)", function()
	local s = q.Source(q.Tween({ Value = 4, Time = 1 }))
	local f = D.Frame({ UICorner = s })
	local c1 = named(f, "_quad_round")
	print("  c1 radius", tostring(c1.CornerRadius))
	local n0 = #mock.tweenLog
	s:Set(q.Tween({ Value = 10, Time = 1 }))
	local t = mock.tweenLog[#mock.tweenLog].tween
	print("  tweens after 10", #mock.tweenLog - n0)
	s:Set(nil)
	print("  after nil kids", kids(f), "tween cancels", t.cancels, "c1 destroyed", mock.isDestroyed(c1))
	s:Set(q.Tween({ Value = 20, Time = 1 }))
	local c2 = named(f, "_quad_round")
	print("  after Tween 20 kids", kids(f), "new tweens", #mock.tweenLog - n0, "c2 radius", tostring(c2 and c2.CornerRadius))
end)

sec("S2 UIPadding(State) + UIPaddingOffset(State): one goes nil, other emits later", function()
	local a = q.Source(UDim.new(0, 3))
	local b = q.Source(8)
	local f = D.Frame({ UIPadding = a, UIPaddingOffset = b })
	local c = named(f, "_quad_padding")
	print("  kids", kids(f), "PaddingLeft", tostring(c.PaddingLeft))
	a:Set(UDim.new(0, 5)); print("  a=5 PaddingLeft", tostring(c.PaddingLeft))
	b:Set(9); print("  b=9 PaddingLeft", tostring(c.PaddingLeft))
	a:Set(nil); print("  a=nil kids", kids(f))
	b:Set(11); local c2 = named(f, "_quad_padding"); print("  b=11 kids", kids(f), "PaddingLeft", tostring(c2 and c2.PaddingLeft))
	a:Set(UDim.new(0, 1)); print("  a=1 kids", kids(f), "PaddingLeft", tostring(named(f, "_quad_padding").PaddingLeft))
end)

sec("S3 UIPadding Tween + UIPaddingOffset static on shared child", function()
	local f = D.Frame({ UIPadding = UDim.new(0, 2), UIPaddingOffset = 4 })
	local c = named(f, "_quad_padding")
	print("  PaddingLeft (hash order decides)", tostring(c.PaddingLeft))
	local n0 = #mock.tweenLog
	q.Dispatch.process(f, "UIPadding", q.Tween({ Value = UDim.new(0, 30), Time = 1 }), 1)
	print("  new tweens (4 props expected)", #mock.tweenLog - n0)
	local t = mock.tweenLog[#mock.tweenLog].tween
	q.Dispatch.process(f, "UIPaddingOffset", 6, 1)
	print("  after static Offset=6: PaddingLeft", tostring(c.PaddingLeft), "running tween cancels", t.cancels)
end)

sec("S4 retractFrom(inst,'UICorner') — child persists (Void), subscription gone", function()
	local s = q.Source(4)
	local f = D.Frame({ UICorner = s })
	q.Dispatch.retractFrom(f, "UICorner", 1)
	print("  after retract kids", kids(f), "subs", nsubs(s))
	s:Set(9); print("  after s=9 radius", tostring(named(f, "_quad_round").CornerRadius))
	-- re-process nil now: child destroyed?
	q.Dispatch.process(f, "UICorner", nil, 1)
	print("  process nil after retract: kids", kids(f))
end)

sec("S5 parent Destroy with managed child + live State", function()
	local s = q.Source(4)
	local f = D.Frame({ UICorner = s })
	local c = named(f, "_quad_round")
	f:Destroy()
	print("  child destroyed", mock.isDestroyed(c))
	local ok, err = pcall(function() s:Set(6) end)
	print("  s:Set after destroy", ok, ok and "" or first(err), "radius", tostring(c.CornerRadius))
	print("  subs", nsubs(s))
end)

sec("S6 q.dispose(parent) — managed child & seat", function()
	local s = q.Source(4)
	local f = D.Frame({ UICorner = s })
	local c = named(f, "_quad_round")
	local ok, err = pcall(q.dispose, f)
	print("  dispose parent", ok, ok and "" or first(err), "child destroyed", mock.isDestroyed(c), "parent destroyed", mock.isDestroyed(f))
	local ok2, err2 = pcall(function() s:Set(7) end)
	print("  s:Set after dispose", ok2, ok2 and "" or first(err2))
end)

sec("S7 Claim instance that already has a user UICorner / a child named _quad_round", function()
	local raw = Instance.foreign("Frame")
	local u = Instance.foreign("UICorner"); u.Parent = raw
	local u2 = Instance.foreign("UICorner"); u2.Name = "_quad_round"; u2.Parent = raw
	local ok, err = pcall(function() return q.Claim(raw, D.Mapper.Frame(D.Mapper.Root)({ UICorner = 6 })) end)
	print("  claim", ok, ok and "" or first(err), "kids", kids(raw))
	print("  user u radius", tostring(u.CornerRadius), "user _quad_round radius", tostring(u2.CornerRadius))
end)

sec("S8 Shorthand inside Modifier / D.Modifier.Frame", function()
	local ok, m = pcall(function() return q.Modifier({ UICorner = 8 }) end)
	print("  q.Modifier{UICorner}", ok, ok and "" or first(m))
	if ok then local f = D.Frame({ m }); print("  frame kids", kids(f)) end
	local ok2, m2 = pcall(function() return D.Modifier.Frame({ UICorner = 8 }) end)
	print("  D.Modifier.Frame{UICorner}", ok2, ok2 and "" or first(m2))
	local ok3, m3 = pcall(function() return q.Modifier():UICorner(8) end)
	print("  chain :UICorner(8)", ok3, ok3 and "" or first(m3))
end)

sec("S9 UICorner = State<State<number>> swap inner", function()
	local inner1 = q.Source(3); local inner2 = q.Source(5)
	local outer = q.Source(inner1)
	local f = D.Frame({ UICorner = outer })
	outer:Set(inner2)
	inner1:Set(99)
	print("  radius (want 5)", tostring(named(f, "_quad_round").CornerRadius), "inner1 subs", nsubs(inner1))
	inner2:Set(7); print("  radius (want 7)", tostring(named(f, "_quad_round").CornerRadius))
end)

sec("S10 UICorner None -> recreate: Relate entry & seat", function()
	local s = q.Source(4)
	local f = D.Frame({ UICorner = s })
	for i = 1, 3 do s:Set(q.None); s:Set(i) end
	print("  kids after 3 cycles", kids(f))
	local c = named(f, "_quad_round")
	local ok, err = pcall(q.dispose, c)
	print("  dispose managed child", ok, ok and "" or first(err))
end)

sec("S11 same Tween object for UICorner on two frames + UIScale", function()
	local tw = q.Tween({ Value = 6, Time = 1 })
	local f1 = D.Frame({ UICorner = tw, UIScale = q.Tween({ Value = 2, Time = 1 }) })
	local f2 = D.Frame({ UICorner = tw })
	print("  f1", kids(f1), tostring(named(f1, "_quad_round").CornerRadius), "scale", named(f1, "_quad_scale").Scale, "f2", tostring(named(f2, "_quad_round").CornerRadius))
end)

-- ===================== (2) Modifier + StoreBind =====================
sec("M1 string key State vs Modifier State same field", function()
	local ks = q.Source(1); local ms = q.Source(2)
	local f = D.Frame({ q.Modifier({ Size = ms }), Size = ks })
	print("  Size", f.Size, "ks subs", nsubs(ks), "ms subs", nsubs(ms))
	ms:Set(20); print("  after ms=20 Size", f.Size)
	ks:Set(10); print("  after ks=10 Size", f.Size)
end)

sec("M2 Overridden(A,B) both State; later B wins, A unsubscribed", function()
	local sa = q.Source(true); local sb = q.Source(false)
	local A = q.Modifier({ Visible = sa }); local B = q.Modifier({ Visible = sb })
	local f = D.Frame({ A:Overridden(B) })
	print("  Visible", f.Visible, "sa subs", nsubs(sa), "sb subs", nsubs(sb))
	local f2 = D.Frame({ A, B })
	print("  array {A,B} Visible", f2.Visible, "sa subs", nsubs(sa), "sb subs", nsubs(sb))
	local f3 = D.Frame({ A, q.Modifier({ Visible = q.None }) })
	print("  {A, Modifier{Visible=None}} Visible", f3.Visible, "sa subs", nsubs(sa))
end)

sec("M3 same Modifier object on two instances and twice on one", function()
	local s = q.Source(3)
	local mod = q.Modifier({ Size = s })
	local f1 = D.Frame({ mod }); local f2 = D.Frame({ mod }); local f3 = D.Frame({ mod, mod })
	print("  subs", nsubs(s), "f3 len@1,2", q.Bookkeeping.getOffsetAt(f3, 3))
	s:Set(4); print("  sizes", f1.Size, f2.Size, f3.Size)
	f1:Destroy(); print("  subs after f1 destroy", nsubs(s))
	s:Set(5); print("  sizes", f1.Size, f2.Size, f3.Size)
	print("  mod fields intact Peek", tostring(mod:Peek("Size") == s))
end)

sec("M4 Modifier field State -> None / nil : property written nil? restored?", function()
	local s = q.Source(true)
	local f = D.Frame({ Visible = false, q.Modifier({ Size = s }) })
	s:Set(q.None); print("  Size after None", tostring(f.Size))
	s:Set(nil); print("  Size after nil", tostring(f.Size))
	s:Set(7); print("  Size after 7", tostring(f.Size))
	local ok, e = pcall(function() return q.Modifier({ Size = q.None }) end)
	print("  Modifier{Size=None}", ok, ok and "" or first(e))
	if ok then local g = D.Frame({ Size = 3 }); q.Dispatch.drive(g, { e }); print("  re-drive with None field Size", tostring(g.Size)) end
end)

sec("M5 Store field as property / q.Attr(store)", function()
	local ok, store = pcall(function() return q.Store({ size = q.Source(3), hp = q.Source(10) }) end)
	print("  Store", ok, ok and "" or first(store))
	if not ok then return end
	local okf, f = pcall(function() return D.Frame({ Size = store.size }) end)
	print("  Size = store.size", okf, okf and tostring(f.Size) or first(f))
	if okf then store.size:Set(9); print("  after set Size", tostring(f.Size)) end
	local oka, g = pcall(function() return D.Frame({ q.Attr(store) }) end)
	print("  q.Attr(store)", oka, oka and "" or first(g))
	if oka then print("  attrs size,hp", tostring(g:GetAttribute("size")), tostring(g:GetAttribute("hp"))) end
	local okm, m = pcall(function() return D.Frame({ q.Modifier({ Size = store.size }) }) end)
	print("  Modifier{Size=store.size}", okm, okm and tostring(m.Size) or first(m))
	local okw, w = pcall(function() return D.Frame({ Size = store }) end)
	print("  Size = store (whole)", okw, okw and tostring(w.Size) or first(w))
end)

sec("M6 re-drive: Modifier State field replaced by plain; subscription count", function()
	local s = q.Source(1)
	local f = D.Frame({ q.Modifier({ Size = s }) })
	for i = 1, 3 do q.Dispatch.drive(f, { q.Modifier({ Size = s }) }) end
	print("  subs after 3 re-drives same state", nsubs(s))
	q.Dispatch.drive(f, { q.Modifier({ Size = 50 }) })
	print("  subs after plain", nsubs(s), "Size", f.Size)
	s:Set(2); print("  after s=2 Size (want 50)", f.Size)
end)

sec("M7 State<Modifier> at array position", function()
	local mod = q.Modifier({ Size = 5 })
	local ok, e = pcall(function() return D.Frame({ q.Source(mod) }) end)
	print("  D.Frame{Source(mod)}", ok, ok and tostring(e.Size) or first(e))
end)

sec("M8 Modifier transform over State field (chain setter)", function()
	local s = q.Source(2)
	local mod = q.Modifier({ Size = s })
	local ok, m2 = pcall(function() return mod:Size(function(old) return old end) end)
	print("  :Size(identity)", ok, ok and tostring(m2:Peek("Size") == s) or first(m2))
	local ok2, m3 = pcall(function() return mod:Size(function(old) return old:Get() * 10 end) end)
	print("  :Size(compute)", ok2, ok2 and "" or first(m3))
	if ok2 then local f = D.Frame({ m3 }); s:Set(3); print("  Size", f.Size) end
end)

-- ===================== (3) Event =====================
sec("V1 swap callback during fire", function()
	local log = {}
	local src
	local fn2 = function() table.insert(log, "fn2") end
	local fn1 = function() table.insert(log, "fn1"); src:Set(fn2) end
	src = q.Source(fn1)
	local b = D.TextButton({ Activated = src })
	b.Activated:Fire(); print("  fire1 log", table.concat(log, ","), "conns", #b.Activated.connections)
	b.Activated:Fire(); print("  fire2 log", table.concat(log, ","), "conns", #b.Activated.connections)
end)

sec("V2 None<->fn round trips", function()
	local fn = function() end
	local src = q.Source(fn)
	local b = D.TextButton({ Activated = src })
	for i = 1, 5 do src:Set(q.None); src:Set(fn) end
	print("  conns", #b.Activated.connections)
	src:Set(nil); print("  after nil conns", #b.Activated.connections)
	src:Set(fn); print("  after fn conns", #b.Activated.connections)
end)

sec("V3 event name typo / Changed / same name as event & property? ", function()
	local ok, e = pcall(function() return D.TextButton({ Activatd = function() end }) end)
	print("  typo", ok, ok and "" or first(e))
	local hits = 0
	local ok2, f = pcall(function() return D.Frame({ Changed = function(p) hits += 1 end }) end)
	print("  Frame Changed", ok2, ok2 and "" or first(f))
	if ok2 then f.Changed:Fire("Size"); print("  hits", hits) end
	local ok3, e3 = pcall(function() return D.Frame({ Activated = function() end }) end)
	print("  Frame Activated (other class event)", ok3, ok3 and "" or first(e3))
end)

sec("V4 self not passed; args pass-through", function()
	local got
	local b = D.TextButton({ Activated = function(...) got = table.pack(...) end })
	b.Activated:Fire("x", 2)
	print("  n", got.n, got[1], got[2])
end)

sec("V5 retract Event chain, re-process; event in Modifier via State", function()
	local hits = 0
	local fn = function() hits += 1 end
	local ok, m = pcall(function() return q.Modifier({ Activated = q.Source(fn) }) end)
	print("  Modifier{Activated=Source(fn)}", ok, ok and "" or first(m))
	if ok then local b = D.TextButton({ m }); b.Activated:Fire(); print("  hits", hits) end
	local b2 = D.TextButton({ Activated = fn })
	q.Dispatch.retractFrom(b2, "Activated", 1)
	print("  conns after retract", #b2.Activated.connections)
	local ok3, e3 = pcall(function() return D.Modifier.TextButton({ Activated = q.Source(fn) }) end)
	print("  D.Modifier.TextButton{Activated=Source}", ok3, ok3 and "" or first(e3))
end)

sec("V6 callback destroys its own instance mid-fire, then State Set", function()
	local src
	local b
	local fn = function() b:Destroy() end
	src = q.Source(fn)
	b = D.TextButton({ Activated = src })
	local ok, e = pcall(function() b.Activated:Fire() end)
	print("  fire", ok, ok and "" or first(e), "conns", #b.Activated.connections)
	local ok2, e2 = pcall(function() src:Set(function() end) end)
	print("  Set after destroy", ok2, ok2 and "" or first(e2), "conns", #b.Activated.connections, "subs", nsubs(src))
end)

sec("V7 callback throws -> connection survives?", function()
	local n = 0
	local b = D.TextButton({ Activated = function() n += 1; error("boom") end })
	pcall(function() b.Activated:Fire() end)
	pcall(function() b.Activated:Fire() end)
	print("  n", n, "conns", #b.Activated.connections)
end)

sec("X1 re-drive without the Modifier's field — old State keeps driving?", function()
	local s = q.Source(1)
	local f = D.Frame({ q.Modifier({ Size = s }) })
	q.Dispatch.drive(f, { q.Modifier({ Visible = true }) })
	s:Set(2); print("  Size after s=2 (drive lacked Size)", f.Size, "subs", nsubs(s))
end)

sec("X2 Modifier with array part / Out inside Modifier / Out on shorthand key", function()
	local src = q.Source(1)
	local ok, e = pcall(function() return q.Modifier({ q.Out("Size", src) }) end)
	print("  Modifier{Out}", ok, ok and "" or first(e))
	local ok2, e2 = pcall(function() return D.Frame({ UICorner = 4, q.Out("UICorner", src) }) end)
	print("  Out('UICorner')", ok2, ok2 and "" or first(e2))
	local ok3, e3 = pcall(function() return D.Frame({ q.OnChange("UICorner", function() end) }) end)
	print("  OnChange('UICorner')", ok3, ok3 and "" or first(e3))
end)

sec("X3 shorthand key State inside Modifier, string key UICorner wins; nil in modifier state", function()
	local ms = q.Source(4)
	local f = D.Frame({ q.Modifier({ UICorner = ms }), UICorner = 10 })
	print("  radius", tostring(named(f, "_quad_round").CornerRadius), "ms subs", nsubs(ms))
	local ms2 = q.Source(4)
	local g = D.Frame({ q.Modifier({ UICorner = ms2 }) })
	ms2:Set(q.None); print("  after None kids", kids(g))
	ms2:Set(6); print("  after 6", kids(g), tostring(named(g, "_quad_round").CornerRadius))
end)

sec("X4 Event State emits same fn inside its own fire", function()
	local calls = 0
	local src
	local fn; fn = function() calls += 1; src:Set(fn) end
	src = q.Source(fn)
	local b = D.TextButton({ Activated = src })
	b.Activated:Fire(); b.Activated:Fire()
	print("  calls", calls, "conns", #b.Activated.connections)
end)

sec("X5 Event State -> None inside own fire, then other connection in same fire", function()
	local log = {}
	local src = q.Source(nil)
	local a = function() table.insert(log, "a"); src:Set(q.None) end
	src:Set(a)
	local b = D.TextButton({ Activated = src, MouseEnter = function() end })
	b.Activated:Fire(); b.Activated:Fire()
	print("  log", table.concat(log, ","), "conns", #b.Activated.connections)
end)

sec("X6 State<fn> for Event initially nil (Source(nil))", function()
	local src = q.Source(nil)
	local ok, b = pcall(function() return D.TextButton({ Activated = src }) end)
	print("  bind with nil", ok, ok and "" or first(b))
	if ok then local n = 0; src:Set(function() n += 1 end); b.Activated:Fire(); print("  n", n, "conns", #b.Activated.connections) end
end)

sec("X7 Modifier Tween field on two instances; Dedup record per instance", function()
	local mod = q.Modifier({ Size = q.Tween({ Value = 5, Time = 1 }) })
	local n0 = #mock.tweenLog
	local f1 = D.Frame({ Size = 1 }); q.Dispatch.drive(f1, { mod })
	local f2 = D.Frame({ Size = 1 }); q.Dispatch.drive(f2, { mod })
	print("  tweens created", #mock.tweenLog - n0)
end)

sec("T1 Tween callbacks on UIPadding / UIPaddingOffset / UICorner (one Tween -> N props)", function()
	for _, key in { "UIPadding", "UIPaddingOffset", "UICorner" } do
		local c = { S = 0, C = 0, X = 0 }
		local v0 = if key == "UIPadding" then UDim.new(0, 1) else 1
		local v1 = if key == "UIPadding" then UDim.new(0, 9) else 9
		local v2 = if key == "UIPadding" then UDim.new(0, 20) else 20
		local s = q.Source(v0)
		local f = D.Frame({ [key] = s })
		local n0 = #mock.tweenLog
		s:Set(q.Tween({ Value = v1, Time = 1, Started = function() c.S += 1 end, Completed = function() c.C += 1 end, Cancelled = function() c.X += 1 end }))
		local n1 = #mock.tweenLog
		print(("  %s: engine tweens %d, Started %d"):format(key, n1 - n0, c.S))
		for i = n0 + 1, n1 do mock.tweenLog[i].tween:simulateCompleted() end
		print(("  %s: after natural finish Completed %d"):format(key, c.C))
		s:Set(q.Tween({ Value = v2, Time = 1, Cancelled = function() c.X += 1 end }))
		s:Set(q.Tween({ Value = v1, Time = 1 }))
		print(("  %s: after replace, Cancelled %d"):format(key, c.X))
	end
end)

sec("T2 UIPaddingOffset: Completed chains next Tween (docs' chaining idiom), engine-like simultaneous finish", function()
	local s = q.Source(0)
	local f = D.Frame({ UIPaddingOffset = s })
	local sets, completes = 0, 0
	local step = 0
	local function mk(v)
		return q.Tween({ Value = v, Time = 1, Completed = function()
			completes += 1
			if step < 3 then step += 1; sets += 1; s:Set(mk(100 + step)) end
		end })
	end
	s:Set(mk(10))
	local n0 = #mock.tweenLog
	-- engine: all four reach the target on the same frame; notifications are delivered afterwards
	local batch = {}
	for i = n0 - 3, n0 do table.insert(batch, mock.tweenLog[i].tween) end
	for _, t in batch do t.PlaybackState = "Completed" end
	local ok, err = pcall(function() for _, t in batch do t.Completed:Fire("Completed") end end)
	print("  fire ok", ok, ok and "" or first(err))
	print("  Completed calls", completes, "chained Sets", sets, "step", step, "new engine tweens", #mock.tweenLog - n0)
	local c = named(f, "_quad_padding")
	print("  PaddingLeft now", tostring(c.PaddingLeft), "(target of latest record?)")
end)

sec("T3 same as T2 — state of the 12 engine tweens, and single-prop UICorner control", function()
	for _, key in { "UIPaddingOffset", "UICorner" } do
		local s = q.Source(0)
		local f = D.Frame({ [key] = s })
		local completes, step = 0, 0
		local function mk(v)
			return q.Tween({ Value = v, Time = 1, Completed = function()
				completes += 1
				if step < 3 then step += 1; s:Set(mk(100 + step)) end
			end })
		end
		s:Set(mk(10))
		local n0 = #mock.tweenLog
		local per = if key == "UICorner" then 1 else 4
		local batch = {}
		for i = n0 - per + 1, n0 do table.insert(batch, mock.tweenLog[i].tween) end
		for _, t in batch do t.PlaybackState = "Completed" end
		for _, t in batch do t.Completed:Fire("Completed") end
		local playing, targets = 0, {}
		for i = n0 + 1, #mock.tweenLog do
			local e = mock.tweenLog[i]
			if e.tween.PlaybackState == "Playing" then playing += 1 end
			for _, v in e.props do table.insert(targets, tostring(v.Offset) .. ":" .. e.tween.PlaybackState) end
		end
		print(("  %s: Completed %d, steps %d, playing %d"):format(key, completes, step, playing))
		print("   ", table.concat(targets, " "))
	end
end)

sec("T4 per-property playing tweens after the T2 cascade (UIPaddingOffset)", function()
	local s = q.Source(0)
	local f = D.Frame({ UIPaddingOffset = s })
	local step = 0
	local function mk(v)
		return q.Tween({ Value = v, Time = 1, Completed = function()
			if step < 3 then step += 1; s:Set(mk(100 + step)) end
		end })
	end
	s:Set(mk(10))
	local n0 = #mock.tweenLog
	local batch = {}
	for i = n0 - 3, n0 do table.insert(batch, mock.tweenLog[i].tween) end
	for _, t in batch do t.PlaybackState = "Completed" end
	for _, t in batch do t.Completed:Fire("Completed") end
	local per = {}
	for i = n0 + 1, #mock.tweenLog do
		local e = mock.tweenLog[i]
		for p, v in e.props do
			per[p] = per[p] or {}
			if e.tween.PlaybackState == "Playing" then table.insert(per[p], tostring(v.Offset)) end
		end
	end
	for _, p in { "PaddingLeft", "PaddingRight", "PaddingTop", "PaddingBottom" } do print("  ", p, "playing ->", table.concat(per[p] or {}, ",")) end
	-- now the user moves on: does a new value cancel all of them?
	s:Set(q.Tween({ Value = 500, Time = 1 }))
	local still = 0
	for i = n0 + 1, #mock.tweenLog do local e = mock.tweenLog[i]; for _, v in e.props do if e.tween.PlaybackState == "Playing" and v.Offset ~= 500 then still += 1 end end end
	print("  after Set(500): stale tweens still playing", still)
	s:Set(nil)
	local still2 = 0
	for i = n0 + 1, #mock.tweenLog do local e = mock.tweenLog[i]; if e.tween.PlaybackState == "Playing" then still2 += 1 end end
	print("  after nil (child destroyed): tweens still playing", still2)
end)

sec("T5 plain properties: one Source on two props (Size, BackgroundTransparency), Completed chains", function()
	local s = q.Source(0)
	local f = D.Frame({ Size = s, BackgroundTransparency = s })
	local step, completes = 0, 0
	local function mk(v)
		return q.Tween({ Value = v, Time = 1, Completed = function()
			completes += 1
			if step < 3 then step += 1; s:Set(mk(100 + step)) end
		end })
	end
	s:Set(mk(10))
	local n0 = #mock.tweenLog
	local batch = { mock.tweenLog[n0 - 1].tween, mock.tweenLog[n0].tween }
	for _, t in batch do t.PlaybackState = "Completed" end
	for _, t in batch do t.Completed:Fire("Completed") end
	local per = {}
	for i = n0 + 1, #mock.tweenLog do local e = mock.tweenLog[i]; for p, v in e.props do per[p] = per[p] or {}; if e.tween.PlaybackState == "Playing" then table.insert(per[p], tostring(v)) end end end
	print("  Completed", completes, "steps", step)
	for p, l in per do print("  ", p, "playing ->", table.concat(l, ",")) end
end)

sec("T6 single property: user Set inside the deferred-notice window, old Completed chains", function()
	local s = q.Source(0)
	local f = D.Frame({ Size = s })
	local chained = false
	s:Set(q.Tween({ Value = 10, Time = 1, Completed = function() if not chained then chained = true; s:Set(q.Tween({ Value = 77, Time = 1 })) end end }))
	local n0 = #mock.tweenLog
	mock.tweenLog[n0].tween.PlaybackState = "Completed" -- reached target, notice pending
	s:Set(q.Tween({ Value = 20, Time = 1 })) -- user's own replacement in the window
	local playing = {}
	for i = n0 + 1, #mock.tweenLog do local e = mock.tweenLog[i]; if e.tween.PlaybackState == "Playing" then table.insert(playing, tostring(e.props.Size)) end end
	print("  playing Size tweens:", table.concat(playing, ","), "(1 expected)")
	s:Set(nil)
	local still = 0
	for i = n0 + 1, #mock.tweenLog do if mock.tweenLog[i].tween.PlaybackState == "Playing" then still += 1 end end
	print("  after Set(nil) playing", still)
end)
