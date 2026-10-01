--!nocheck
-- Q135 (+Q137 ②) probe: misuse at string keys (A) and normal paths that must NOT be intercepted (B).
-- Run from repo root after relink: `mise exec -- luau .claude/audit/round13-q135-priority/probe.luau`
local H = require("../round13-e44-ref-statemachine/harness")
local q, D = H.q, H.D
local CS = H.CollectionService
local function id(e) local s = tostring(e); return s:match("Quad%d%d%d%d") or ("RAW:" .. H.first(e)) end
local function try(label, f)
	local ok, e = pcall(f)
	print(label, if ok then ("ok" .. (if e ~= nil then "  -> " .. tostring(e) else "")) else (id(e) .. "  | " .. H.first(e)))
end

print("== A. misuse at string keys (literal) ==")
local makers = {
	Ref = function() return q.Ref(nil) end,
	PreRef = function() return q.PreRef(nil) end,
	PostRef = function() return q.PostRef(nil) end,
	Observer = function() return q.Source(1):Observer(function() end) end,
	Effect = function() return q.Effect(function() end) end,
	Slot = function() return q.Slot() end,
	Tag = function() return q.Tag("t") end,
	Attr = function() return q.Attr({ a = 1 }) end,
}
local order = { "Ref", "PreRef", "PostRef", "Observer", "Effect", "Slot", "Tag", "Attr" }
for _, kind in order do
	local mk = makers[kind]
	try(kind .. " @Name(prop)", function() D.Frame { Name = mk() } end)
	try(kind .. " @Size(prop)", function() local v = mk(); local f = D.Frame { Size = v }; return if f.Size == v then "Size holds the value (silent)" else nil end)
	try(kind .. " @Visible(prop)", function() local v = mk(); local f = D.Frame { Visible = v }; return if f.Visible == v then "Visible holds the value (silent)" else nil end)
	try(kind .. " @Activated(event)", function() D.TextButton { Activated = mk() } end)
	try(kind .. " @UICorner(shorthand)", function() D.Frame { UICorner = mk() } end)
	try(kind .. " @Parent", function() D.Frame { Parent = mk() } end)
	try(kind .. " @Foo(unknown)", function() D.Frame { Foo = mk() } end)
end

print("== A2. misuse at string keys via State / Store ==")
for _, kind in order do
	local mk = makers[kind]
	try(kind .. " Source @Name", function() D.Frame { Name = q.Source(mk()) } end)
	try(kind .. " Source @Size", function() local v = mk(); local f = D.Frame { Size = q.Source(v) }; return if f.Size == v then "Size holds the value (silent)" else nil end)
	try(kind .. " Source @Activated", function() D.TextButton { Activated = q.Source(mk()) } end)
	try(kind .. " Store field @Name", function() local s = q.Store({ x = q.Source(mk()) }); D.Frame { Name = s.x } end)
	try(kind .. " Source(\"x\")->Set(v) @Name", function() local s = q.Source("x"); D.Frame { Name = s }; s:Set(mk()) end)
end

print("== A3. Q137 ② Modifier fields ==")
try("Modifier{Name=Tag} create", function() return tostring(q.Modifier { Name = q.Tag("a") }) end)
try("Modifier{Name=Tag} mount", function() D.Frame { q.Modifier { Name = q.Tag("a") } } end)
try("Modifier{Size=Tag} mount", function() local f = D.Frame { q.Modifier { Size = q.Tag("a") } }; return tostring(f.Size) end)
try("Modifier():Name(Attr) create", function() return tostring(q.Modifier():Name(q.Attr({ a = 1 }))) end)
try("Modifier():Name(Attr) mount", function() D.Frame { q.Modifier():Name(q.Attr({ a = 1 })) } end)
try("Modifier{Foo=Tag} mount", function() D.Frame { q.Modifier { Foo = q.Tag("a") } } end)
try("Modifier{Name=Source(Tag)} mount", function() D.Frame { q.Modifier { Name = q.Source(q.Tag("a")) } } end)
try("Modifier{Name=Ref} create (control)", function() return tostring(q.Modifier { Name = q.Ref(nil) }) end)
try("Modifier{Name=Source(Ref)} mount", function() D.Frame { q.Modifier { Name = q.Source(q.Ref(nil)) } } end)

print("== B. normal paths (must stay ok) ==")
do
	local r = q.Ref(nil); local f = D.Frame { r }; print("B1 Ref literal numeric", r.Value == f)
	local pr = q.PreRef(nil); local f2 = D.Frame { pr }; print("B2 PreRef literal numeric", pr.Value == f2)
	local po = q.PostRef(nil); local f3 = D.Frame { po }; print("B3 PostRef literal numeric", po.Value == f3)
	local r2 = q.Ref(nil); local f4 = D.Frame { q.Source(r2) }; print("B4 Ref via Source numeric", r2.Value == f4)
	local r3 = q.Ref(nil); local st = q.Store({ x = q.Source(r3) }); local f5 = D.Frame { st.x }; print("B5 Ref via Store numeric", r3.Value == f5)
	local n = 0; local s = q.Source(1); D.Frame { s:Observer(function() n += 1 end) }; s:Set(2); print("B6 Observer literal numeric fires", n)
	local n2 = 0; local s2 = q.Source(1); D.Frame { q.Source(s2:Observer(function() n2 += 1 end)) }; s2:Set(2); print("B7 Observer via Source numeric", n2)
	local n3 = 0; local s3 = q.Source(1); D.Frame { q.Effect(function() n3 += 1; s3:Get() end, s3) }; s3:Set(2); print("B8 Effect literal numeric", n3)
	local n4 = 0; local s4 = q.Source(1); D.Frame { q.Source(q.Effect(function() n4 += 1 end, s4)) }; s4:Set(2); print("B9 Effect via Source numeric", n4)
	local f8 = D.Frame { q.Tag("a", "b") }; print("B10 Tag literal numeric", CS:HasTag(f8, "a"), CS:HasTag(f8, "b"))
	local ts = q.Source(q.Tag("x")); local f9 = D.Frame { ts }; local b1 = CS:HasTag(f9, "x"); ts:Set(q.Tag("y")); print("B11 Tag via Source numeric", b1, CS:HasTag(f9, "x"), CS:HasTag(f9, "y"))
	local f10 = D.Frame { q.Attr({ hp = 5 }) }; print("B12 Attr literal numeric", f10:GetAttribute("hp"))
	local as = q.Source(q.Attr({ hp = 1 })); local f11 = D.Frame { as }; as:Set(q.Attr({ hp = 2 })); print("B13 Attr via Source numeric", f11:GetAttribute("hp"))
	local f12 = D.Frame { [q.AttrKey("Hp")] = 100 }; print("B14 AttrKey literal", f12:GetAttribute("Hp"))
	local hs = q.Source(1); local f13 = D.Frame { [q.AttrKey("Hp")] = hs }; hs:Set(7); print("B15 AttrKey via Source", f13:GetAttribute("Hp"))
	local f14 = D.Frame { q.StringAttr("nm", "v") }; print("B16 StringAttr", f14:GetAttribute("nm"))
	local child = D.Frame {}; local sl = q.Slot { child }; local f15 = D.Frame { sl }; print("B17 Slot literal numeric", child.Parent == f15)
	local c2 = D.Frame {}; local sl2 = q.Slot { c2 }; local f16 = D.Frame { q.Source(sl2) }; print("B18 Slot via Source numeric", c2.Parent == f16)
	local f17 = D.Frame { q.Modifier { Name = "mod" } }; print("B19 Modifier normal field", f17.Name)
	local ms = q.Source("m1"); local f18 = D.Frame { q.Modifier { Name = ms } }; ms:Set("m2"); print("B20 Modifier State field", f18.Name)
	local hit = 0; local b = D.TextButton { Activated = function() hit += 1 end }; b.Activated:Fire(); print("B21 Event literal fn", hit)
	local hit2 = 0; local fs = q.Source(function() hit2 += 1 end); local b2 = D.TextButton { Activated = fs }; b2.Activated:Fire(); print("B22 Event via Source fn", hit2)
	local ns = q.Source("n1"); local f19 = D.Frame { Name = ns, Visible = true }; ns:Set("n2"); print("B23 Property via Source", f19.Name, f19.Visible)
	local f20 = D.Frame { UICorner = 8 }; print("B24 Shorthand", f20:FindFirstChild("_quad_round") ~= nil)
	local ss = q.Source(q.None); local f21 = D.Frame { UICorner = ss }; ss:Set(4); print("B25 Shorthand None->4 via Source", f21:FindFirstChild("_quad_round") ~= nil)
	local c3 = D.Frame {}; local f22 = D.Frame { c3, Name = "p" }; print("B26 Instance child + prop", c3.Parent == f22)
	local oc = 0; local tb = D.TextButton { q.OnChange("Text", function() oc += 1 end) }; tb.Text = "z"; print("B27 OnChange", oc)
end

print("== C. other-key misuse (message must stay as before or improve) ==")
try("PreRef via Source numeric", function() D.Frame { q.Source(q.PreRef(nil)) } end)
try("PostRef via Source numeric", function() D.Frame { q.Source(q.PostRef(nil)) } end)
try("Slot at [0] raw process", function() q.Dispatch.process(D.Frame {}, 0, q.Slot(), 1) end)
try("Ref at AttrKey key", function() D.Frame { [q.AttrKey("k")] = q.Ref(nil) } end)
try("Tag at AttrKey key", function() D.Frame { [q.AttrKey("k")] = q.Tag("a") } end)
try("Ref at boolean key", function() q.Dispatch.process(D.Frame {}, true, q.Ref(nil), 1) end)
try("PreRef at AttrKey key", function() D.Frame { [q.AttrKey("k2")] = q.PreRef(nil) } end)
try("Observer at AttrKey key", function() D.Frame { [q.AttrKey("k3")] = q.Source(1):Observer(function() end) } end)
try("Effect at AttrKey key", function() D.Frame { [q.AttrKey("k4")] = q.Effect(function() end) } end)
try("Attr at AttrKey key", function() D.Frame { [q.AttrKey("k5")] = q.Attr({ a = 1 }) } end)
try("Modifier transform returns Tag", function() return tostring(q.Modifier():Name(function() return q.Tag("a") end)) end)

print("== D. handler order ==")
for i, h in q.Dispatch.listHandlers() do
	print(i, h.name, h.priority, h.keyType)
end

print("== E. provider override at NORMAL (spec.leaf §7 shape — the FALLBACK contract) ==")
do
	local log = {}
	q.Dispatch.addHandler({
		name = "ProbeNamedObserverAtNormal",
		isHandlable = function(_inst, k, v) return type(k) == "string" and q.isObserver(v) end,
		priority = q.Dispatch.HANDLER_PRIORITY_NORMAL,
		process = function(_inst, k) table.insert(log, k); return q.Void end,
	})
	try("NORMAL override for Observer@MyThing", function() q.Dispatch.drive(D.Frame {}, { MyThing = q.Source(1):Observer(function() end) }); return #log end)
end
