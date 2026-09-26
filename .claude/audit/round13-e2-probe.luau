--!nocheck
-- Moved from quad-roblox/test/probe.e2.luau; to rerun copy back there after ./scripts/relink.sh and run `luau quad-roblox/test/probe.e2.luau`.
-- round13 E2 probe (scratch) — Dispatch/Handlers defect hunt
local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installProperty = require("../src/Handlers/Property")
local installEvent = require("../src/Handlers/Event")
local mock = require("../../quad-base/test/mock")
local Instance = mock.Instance

local W = { Write = "" }
local REFLECTED = {
	Frame = { { Name = "Name", Permits = W }, { Name = "Size", Permits = W }, { Name = "Visible", Permits = W }, { Name = "Parent", Permits = W } },
	TextButton = { { Name = "Name", Permits = W }, { Name = "Text", Permits = W }, { Name = "Visible", Permits = W } },
	TextBox = { { Name = "Name", Permits = W }, { Name = "Text", Permits = W } },
	UICorner = { { Name = "Name", Permits = W }, { Name = "CornerRadius", Permits = W } },
	UIPadding = { { Name = "Name", Permits = W }, { Name = "PaddingLeft", Permits = W }, { Name = "PaddingRight", Permits = W }, { Name = "PaddingTop", Permits = W }, { Name = "PaddingBottom", Permits = W } },
}
mock.declareEvents("TextButton", { "Activated" })
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

UDim = { new = function(s, o) return { s = s, o = o } end }
;(getfenv(require("../src/Handlers/InstanceShorthand"))).UDim = UDim
local SECTION = ...
local function sec(name, fn)
	print("=== " .. name .. " ===")
	local ok, err = pcall(fn)
	if not ok then print("  !! section error:", first(err)) end
end

sec("E1 getHandler nil/odd inst", function()
	local ok, err = pcall(q.Dispatch.getHandler, nil, "Size", 1)
	print("  getHandler(nil,'Size',1):", ok, ok and "" or first(err))
	local ok2, err2 = pcall(q.Dispatch.getHandler, nil, 1, Instance.new("Frame"))
	print("  getHandler(nil,1,Frame):", ok2, ok2 and tostring(err2) or first(err2))
	local ok3, err3 = pcall(q.Dispatch.getHandler, {}, "Size", 1)
	print("  getHandler({},'Size',1):", ok3, ok3 and tostring(err3) or first(err3))
	local ok4, r4 = pcall(q.Dispatch.getHandler, Instance.new("Frame"), nil, 1)
	print("  getHandler(f,nil,1):", ok4, ok4 and tostring(r4 and r4.name) or first(r4))
end)

sec("E2 InstanceChild State swap to unclaimed — old child fate", function()
	local a = D.Frame({ Name = "A" })
	local src = q.Source(a)
	local host = D.Frame({ src })
	print("  mounted: a.Parent==host", a.Parent == host, "len", q.Bookkeeping.getOffsetAt(host, 2))
	local foreign = Instance.foreign("Frame")
	local ok, err = pcall(function() src:Set(foreign) end)
	print("  Set(foreign):", ok, ok and "" or first(err))
	print("  after reject: a.Parent==host", a.Parent == host, "a.Parent", tostring(a.Parent), "offset after seat", q.Bookkeeping.getOffsetAt(host, 2))
	-- can the user recover by setting back?
	local ok2, err2 = pcall(function() src:Set(a) end)
	print("  Set(a) back:", ok2, ok2 and "" or first(err2), "a.Parent==host", a.Parent == host, "offset", q.Bookkeeping.getOffsetAt(host, 2))
end)

sec("E3 InstanceChild State swap to child held elsewhere", function()
	local a = D.Frame({ Name = "A" })
	local b = D.Frame({ Name = "B" })
	local other = D.Frame({ b })
	local src = q.Source(a)
	local host = D.Frame({ src })
	local ok, err = pcall(function() src:Set(b) end)
	print("  Set(b held):", ok, ok and "" or first(err))
	print("  a.Parent==host", a.Parent == host, "b.Parent==other", b.Parent == other, "host offset(2)", q.Bookkeeping.getOffsetAt(host, 2))
	local ok3, err3 = pcall(function() src:Set(a) end)
	print("  Set(a) back:", ok3, ok3 and "" or first(err3), "a.Parent==host", a.Parent == host)
end)

sec("E4 Event State swap to non-function", function()
	local calls = 0
	local fn = function() calls += 1 end
	local src = q.Source(fn)
	local b = D.TextButton({ Activated = src })
	local sig = b.Activated
	local ok, err = pcall(function() src:Set(5) end)
	print("  Set(5):", ok, ok and "" or first(err), "live conns", #sig.connections)
	local ok2, err2 = pcall(function() src:Set(fn) end)
	print("  Set(fn) back:", ok2, ok2 and "" or first(err2), "live conns", #sig.connections)
	sig:Fire(); print("  calls", calls)
end)

sec("E5 Out echo & Source emits on bind", function()
	local src = q.Source("hi")
	local emits = 0
	local obs = src:Observer(function() emits += 1 end)
	obs:Subscribe()
	emits = 0
	local tb = D.TextBox({ Text = src, q.Out("Text", src) })
	print("  after bind emits", emits, "Text", tb.Text)
	tb.Text = "typed"
	print("  after typing src", src:Get(), "emits", emits)
	src:Set("prog")
	print("  after prog Set Text", tb.Text, "emits", emits)
end)

sec("E6 Property Tween dedup after teardown & rebind", function()
	local src = q.Source(q.Tween({ Value = 1, Time = 1 }))
	local f = D.Frame({ Size = src })
	src:Set(q.Tween({ Value = 2, Time = 1 }))
	print("  tweens", #mock.tweenLog)
	q.Dispatch.retractFrom(f, "Size", 1)
	print("  after retract Size", f.Size, "last cancels", mock.tweenLog[#mock.tweenLog].tween.cancels)
	q.Dispatch.process(f, "Size", q.Tween({ Value = 2, Time = 1 }), 1)
	print("  rebind same target tweens", #mock.tweenLog, "Size", f.Size)
end)

sec("E7 listHandlers mutation leaks into registry", function()
	local list = q.Dispatch.listHandlers()
	local prop
	for _, h in list do if h.name == "Property" then prop = h end end
	print("  frozen?", table.isfrozen(prop))
	local old = prop.isHandlable
	local okm = pcall(function() prop.isHandlable = function() return false end end)
	local ok, err = pcall(function() D.Frame({ Size = 1 }) end)
	print("  mutate ok", okm, "D.Frame{Size=1} after mutating returned handler:", ok, ok and "" or first(err))
	if okm then prop.isHandlable = old end
end)

sec("E8 UIPadding shared child — nil on one key while other static", function()
	local src = q.Source(8)
	local f = D.Frame({ UIPaddingOffset = src })
	local kids = f:GetChildren()
	print("  kids", #kids)
	src:Set(nil)
	print("  after nil kids", #f:GetChildren())
	src:Set(4)
	print("  after 4 kids", #f:GetChildren())
end)

sec("E9 None at index then Tween — first-set semantics after nil", function()
	local src = q.Source(1)
	local f = D.Frame({ Size = src })
	local n0 = #mock.tweenLog
	src:Set(q.None)
	print("  Size after None", f.Size)
	src:Set(q.Tween({ Value = 5, Time = 1 }))
	print("  tween created after None->Tween", #mock.tweenLog - n0, "Size", f.Size)
end)

sec("E10 Out + Animate feedback (engine frame writes simulated)", function()
	local pos = q.Source(0)
	local f = D.Frame({ Size = pos:Apply(q.Animate({ Time = 1 })), q.Out("Size", pos) })
	local n0 = #mock.tweenLog
	pos:Set(100)
	local t1 = mock.tweenLog[#mock.tweenLog].tween
	print("  after Set(100): new tweens", #mock.tweenLog - n0, "t1 target", mock.tweenLog[#mock.tweenLog].props.Size)
	f.Size = 10 -- the engine's first interpolation frame
	print("  after frame write: pos", pos:Get(), "t1 cancels", t1.cancels, "tweens", #mock.tweenLog - n0, "last target", mock.tweenLog[#mock.tweenLog].props.Size)
end)

sec("E11 drive twice: Modifier State field swap unsubscribes old", function()
	local a = q.Source(true); local b = q.Source(false)
	local f = D.Frame({ q.Modifier({ Visible = a }) })
	q.Dispatch.drive(f, { q.Modifier({ Visible = b }) })
	a:Set(false); print("  after a:Set(false) Visible", f.Visible, "(want false from b)")
	a:Set(true); print("  after a:Set(true) Visible", f.Visible, "(want false; true => old sub alive)")
end)

sec("E12 Attr / AttrKey nil & None", function()
	local src = q.Source(5)
	local f = D.Frame({ [q.AttrKey("Hp")] = src })
	print("  Hp", f:GetAttribute("Hp"))
	src:Set(q.None); print("  after None Hp", f:GetAttribute("Hp"))
	src:Set(7); print("  after 7 Hp", f:GetAttribute("Hp"))
	q.Dispatch.retractFrom(f, q.AttrKey("Hp"), 1)
	print("  after retract Hp (value persists by design)", f:GetAttribute("Hp"))
	local ok, err = pcall(function() q.Dispatch.process(f, q.AttrKey("Hp"), 9, 1) end)
	print("  re-process after retract", ok, ok and f:GetAttribute("Hp") or first(err))
end)

sec("E13 Tag State swap and retract", function()
	local src = q.Source(q.Tag("a", "b"))
	local f = D.Frame({ src, q.Tag("b") })
	print("  tags", table.concat(mock.getTags(f), ","))
	src:Set(q.Tag("c"))
	print("  after swap to c", table.concat(mock.getTags(f), ","))
	src:Set(q.None)
	print("  after None", table.concat(mock.getTags(f), ","))
	q.Dispatch.retractFrom(f, 2, 1)
	print("  after retract [2]", table.concat(mock.getTags(f), ","))
end)

sec("E14 UIPadding shared child", function()
	local src = q.Source(8)
	local f = D.Frame({ UIPaddingOffset = src, UIPadding = UDim.new(0, 3) })
	print("  kids", #f:GetChildren())
	src:Set(nil)
	print("  after UIPaddingOffset nil kids", #f:GetChildren(), "(UIPadding static still declared)")
	src:Set(4)
	local c = f:GetChildren()[1]
	print("  after 4 kids", #f:GetChildren(), c and tostring(c.PaddingLeft and c.PaddingLeft.o))
end)

sec("E15 Event: Source emits same function object — reconnect churn", function()
	local fn = function() end
	local src = q.Source(fn)
	local b = D.TextButton({ Activated = src })
	src:Set(fn)
	print("  conns after same-fn Set", #b.Activated.connections)
end)

sec("E16 Modifier transform returning a function", function()
	local hits = 0
	local mod = q.Modifier():Activated(function(_old) return function() hits += 1 end end)
	print("  Peek type", typeof(mod:Peek("Activated")))
	local ok0, e0 = pcall(function() return q.Modifier({ Activated = function() end }) end)
	print("  ctor with function:", ok0, ok0 and "" or first(e0))
	local b = D.TextButton({ mod })
	b.Activated:Fire(); print("  hits after fire", hits)
end)

sec("E17 retract with throwing Cancelled callback, then retry", function()
	local src = q.Source(q.Tween({ Value = 1, Time = 1 }))
	local f = D.Frame({ Size = src })
	src:Set(q.Tween({ Value = 2, Time = 1, Cancelled = function() error("user boom") end }))
	local t = mock.tweenLog[#mock.tweenLog].tween
	local ok, err = pcall(q.Dispatch.retractFrom, f, "Size", 1)
	print("  retract:", ok, ok and "" or first(err), "cancels", t.cancels)
	local ok2, err2 = pcall(q.Dispatch.retractFrom, f, "Size", 1)
	print("  retry:", ok2, ok2 and "" or first(err2), "cancels", t.cancels)
	-- is the StoreBind observer gone?
	src:Set(5); print("  after src:Set(5) Size", f.Size, "(5 => still bound)")
end)
