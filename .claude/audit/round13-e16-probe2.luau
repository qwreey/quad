--!nocheck
-- round13 E16 probe 2 (2026-09-27) — Attr/AttrKey. Run from repo root: luau .claude/audit/round13-e16-probe2.luau
local Quad = require("../../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../../quad-roblox/src").QuadRoblox
local installProperty = require("../../quad-roblox/src/Handlers/Property")
local installEvent = require("../../quad-roblox/src/Handlers/Event")
local installEngineOps = require("../../quad-roblox/src/EngineOps")
local mock = require("../../quad-base/test/mock")
local Instance = mock.Instance
local W = { Write = "" }
local REFLECTED = {
	Frame = { { Name = "Name", Permits = W }, { Name = "Size", Permits = W }, { Name = "Visible", Permits = W } },
	TextLabel = { { Name = "Name", Permits = W }, { Name = "Text", Permits = W } },
}
local gameShim = mock.gameShim(REFLECTED)
local q: any = Quad.New():UseProvider(QuadRoblox)
getfenv(installProperty).game = gameShim
getfenv(installProperty).TweenInfo = mock.tweenInfoShim
getfenv(installProperty).Enum = { EasingStyle = { Quad = "Quad" }, EasingDirection = { Out = "Out" } }
getfenv(installEvent).game = gameShim
getfenv(installEngineOps).game = gameShim
getfenv(q.Declaration.New).Instance = { new = mock.Instance.new }
q.Backend.isInst = mock.isMockInstance
local D, None = q.Declaration, q.None
local log = {}
local osa = q.Backend.setAttr
q.Backend.setAttr = function(i, k, v) table.insert(log, k .. "=" .. tostring(v)); return osa(i, k, v) end
local function L() local s = table.concat(log, " "); table.clear(log); return s end
local function attrs(i) local t = {} for k, v in mock.getAttributes(i) do table.insert(t, k .. "=" .. tostring(v)) end table.sort(t) return table.concat(t, ",") end
local function first(e) return (tostring(e):gsub("\n.*", "")) end
local function sec(name, f) print("=== " .. name .. " ==="); local ok, e = pcall(f); if not ok then print("  !! ERR:", first(e)) end end
local function try(label, f) local ok, e = pcall(f); print("  " .. label, ok and "ok" or ("ERR " .. first(e))); return ok end
local function nsubs(s) collectgarbage("collect"); collectgarbage("collect"); local n = 0 for _ in s._subs do n += 1 end return n end
local K = q.AttrKey

sec("A1 three spellings of the same name on one instance", function()
	try("group then AttrKey hash", function() D.Frame({ q.Attr({ X = 1 }), [K("X")] = 2 }) end)
	try("StringAttr then group", function() D.Frame({ q.StringAttr("X", "a"), q.Attr({ X = 1 }) }) end)
	try("two AttrKey objects? (same cache)", function() local f = D.Frame({ [K("X")] = 2 }); print("    attrs", attrs(f)) end)
	L()
end)

sec("A2 Modifier carrying AttrKey + props AttrKey same name", function()
	local ok = try("Modifier{[AttrKey X]=1}", function()
		local m = q.Modifier({ [K("X")] = 1 })
		local f = D.Frame({ m, [K("X")] = 2 })
		print("    attrs", attrs(f), "log", L())
	end)
	try("Modifier{[AttrKey X]=1} + group Attr{X}", function()
		local m = q.Modifier({ [K("X")] = 1 })
		local f = D.Frame({ m, q.Attr({ X = 3 }) })
		print("    attrs", attrs(f), "log", L())
	end)
	try("Overridden(m1{X=1}, m2{X=2})", function()
		local m1 = q.Modifier({ [K("X")] = 1 }); local m2 = q.Modifier({ [K("X")] = 2 })
		local f = D.Frame({ q.Modifier.Overridden(m1, m2) })
		print("    attrs", attrs(f), "log", L())
	end)
end)

sec("A3 State<Attr> swap with overlapping names; old State unsubscribed; back and forth", function()
	local s1, s2 = q.Source(1), q.Source(2)
	local G1, G2 = q.Attr({ X = s1, Only1 = "o" }), q.Attr({ X = s2 })
	local st = q.Source(G1)
	local f = D.Frame({ st })
	print("  init", attrs(f), "log", L())
	st:Set(G2); print("  ->G2", attrs(f), "log", L(), "s1 subs", nsubs(s1), "s2 subs", nsubs(s2))
	s1:Set(11); print("  s1:Set(11) after swap", attrs(f), "log", L())
	st:Set(nil); print("  ->nil", attrs(f), "log", L(), "s2 subs", nsubs(s2))
	st:Set(G1); print("  ->G1 again", attrs(f), "log", L())
	st:Set(G1); print("  ->G1 same obj re-emit", attrs(f), "log", L())
end)

sec("A4 group with State field value nil then re-set; None literal vs None State", function()
	local s = q.Source(5)
	local f = D.Frame({ q.Attr({ X = s, Y = None }) })
	print("  init", attrs(f), "log", L())
	s:Set(nil); print("  s nil", attrs(f), L())
	s:Set(7); print("  s 7", attrs(f), L())
end)

sec("A5 Attr vs Property same name 'Name'", function()
	local f = D.Frame({ Name = "prop", q.StringAttr("Name", "attr") })
	print("  prop", f.Name, "attrs", attrs(f))
	local f2 = D.Frame({ Name = "prop", [K("Name")] = "k" })
	print("  prop", f2.Name, "attrs", attrs(f2)); L()
end)

sec("A6 names: RBX prefix, spaces, 101 chars, non-ascii (engine rules not modelled)", function()
	for _, n in { "RBXThing", "has space", string.rep("a", 101), "한글", "a.b" } do
		try(("name %q"):format(#n > 20 and (n:sub(1, 10) .. "...") or n), function() local f = D.Frame({ q.StringAttr(n, "v") }); print("    set:", attrs(f) ~= "") end)
	end
	L()
end)

sec("A7 Store group: store:Of late key; Store field re-bound via props; two stores overlapping name", function()
	local st1 = q.Store({ hp = 1 })
	local st2 = q.Store({ hp = 2, mp = 3 })
	try("Attr(st1, st2) overlap -> last wins", function() local f = D.Frame({ q.Attr(st1, st2) }); print("    attrs", attrs(f)) end)
	try("Attr.Merged(Attr(st1), Attr(st2)) overlap", function() q.Attr.Merged(q.Attr(st1), q.Attr(st2)) end)
	L()
end)

sec("A8 same group object on two instances, then swap on one", function()
	local s = q.Source(1)
	local G = q.Attr({ X = s })
	local a = D.Frame({ G }); local b = D.Frame({ G })
	print("  a", attrs(a), "b", attrs(b), L())
	s:Set(2); print("  s=2", attrs(a), attrs(b), L(), "subs", nsubs(s))
	a:Destroy(); collectgarbage("collect"); collectgarbage("collect")
	s:Set(3); print("  after a Destroy s=3", attrs(a), attrs(b), L(), "subs", nsubs(s))
end)

sec("A9 re-drive with position shift (q.Dispatch.drive): Attr G from [2] to [1]; Tag same; Ref same", function()
	local G = q.Attr({ X = 1 })
	local f = D.Frame({ q.Tag("t"), G })
	try("Attr shift 2->1", function() q.Dispatch.drive(f, { G, q.Tag("t") }) end)
	local r = q.Ref(nil)
	local g = D.Frame({ q.Tag("t"), r })
	try("Ref shift 2->1", function() q.Dispatch.drive(g, { r, q.Tag("t") }) end)
	local T = q.Tag("t")
	local h = D.Frame({ q.Attr({ Y = 1 }), T })
	try("Tag shift 2->1", function() q.Dispatch.drive(h, { T, q.Attr({ Y = 1 }) }) end)
	L()
end)

sec("A10 AttrKey State emitting table (H-659) and function; group State emitting table", function()
	local s = q.Source(1)
	local f = D.Frame({ [K("X")] = s })
	try("AttrKey State -> {}", function() s:Set({}) end)
	print("  attrs", attrs(f))
	try("AttrKey State -> 2 (recover)", function() s:Set(2) end)
	print("  attrs", attrs(f))
	local s2 = q.Source(1)
	local g = D.Frame({ q.NumberAttr("N", s2) })
	try("NumberAttr State -> 'str' (typed sugar, runtime)", function() s2:Set("str") end)
	print("  attrs", attrs(g)); L()
end)

sec("A11 group partial conflict then State swap recovery", function()
	local st = q.Source(q.Attr({ A = 1, X = 1 }))
	local f = D.Frame({ st, [K("B")] = 0 })
	L()
	try("-> group{A,B} (B owned by hash key)", function() st:Set(q.Attr({ A = 2, B = 2 })) end)
	print("  attrs", attrs(f), L())
	try("-> group{A=3} (recover)", function() st:Set(q.Attr({ A = 3 })) end)
	print("  attrs", attrs(f), L())
	try("-> group{A=4,C=4}", function() st:Set(q.Attr({ A = 4, C = 4 })) end)
	print("  attrs", attrs(f), L())
end)

sec("A12 partial-failure poisoning detail: leaked State subscription + disjoint recovery + static literal variant", function()
	local sA = q.Source(10)
	local st = q.Source(q.Attr({ X = 1 }))
	local f = D.Frame({ st, [K("B")] = 0 })
	L()
	local bad = q.Attr({ A = sA, B = 2 })
	try("-> bad{A=State,B}", function() st:Set(bad) end)
	print("  attrs", attrs(f), L())
	sA:Set(11); print("  sA:Set(11) after failure", attrs(f), L(), "sA subs", nsubs(sA))
	try("-> disjoint {C=5}", function() st:Set(q.Attr({ C = 5 })) end)
	print("  attrs", attrs(f), L())
	sA:Set(12); print("  sA:Set(12) after recovery", attrs(f), L())
	try("-> {A=1}", function() st:Set(q.Attr({ A = 1 })) end)
	try("-> StringAttr('A') on same seat", function() st:Set(q.StringAttr("A", "z")) end)
	print("  attrs", attrs(f), L())
end)

sec("A13 State<Ref> a -> b(bound elsewhere) fails; recovery with c", function()
	local a, b, c = q.Ref(nil), q.Ref(nil), q.Ref(nil)
	local other = D.Frame({ b })
	local st = q.Source(a)
	local f = D.Frame({ st })
	try("-> b (bound elsewhere)", function() st:Set(b) end)
	print("  a.Value", a.Value, "b.Value==other", b.Value == other)
	try("-> c", function() st:Set(c) end)
	print("  c.Value==f", c.Value == f)
end)
