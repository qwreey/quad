--!nocheck
-- E37 nil/None matrix runtime probe (mock). Each row prints: label | result
local H = require("./harness")
local q, D, None = H.q, H.D, H.None
UDim2 = H.EG.UDim2; Color3 = H.EG.Color3; Enum = H.EG.Enum; UDim = H.EG.UDim
local CS = H.CollectionService

local function show(v)
	if v == nil then return "nil" elseif v == None then return "None" end
	return tostring(v)
end
local function try(label, fn)
	local ok, err = pcall(fn)
	if ok then print(label .. " | ok" .. (err ~= nil and (" -> " .. tostring(err)) or ""))
	else print(label .. " | THROW " .. H.first(err)) end
end
local function kids(inst)
	local t = {}
	for _, c in inst:GetChildren() do table.insert(t, c.ClassName .. ":" .. c.Name) end
	return "[" .. table.concat(t, ",") .. "]"
end
local function attrs(inst)
	local t = {}
	for k, v in inst:GetAttributes() do table.insert(t, k .. "=" .. show(v)) end
	table.sort(t)
	return "{" .. table.concat(t, ",") .. "}"
end
local function tags(inst) local t = CS:GetTags(inst); table.sort(t); return "{" .. table.concat(t, ",") .. "}" end

print("== P: Property (TextLabel.Text, Frame.NextSelectionUp)")
try("P1 literal Text=nil", function() local l = D.TextLabel { Text = nil }; return "Text=" .. show(l.Text) end)
try("P2 literal Text=None", function() local l = D.TextLabel { Text = None }; return "Text=" .. show(l.Text) end)
try("P2b literal Text=None after Modifier sets Text", function()
	local l = D.TextLabel { q.Modifier():Text("mod"), Text = None }; return "Text=" .. show(l.Text) end)
try("P3 State initially nil", function() local s = q.Source(nil); local l = D.TextLabel { Text = s }; return "Text=" .. show(l.Text) end)
try("P4 State a -> nil", function() local s = q.Source("a"); local l = D.TextLabel { Text = s }; local a = l.Text; s:Set(nil); return "Text " .. show(a) .. " -> " .. show(l.Text) end)
try("P5 State a -> None", function() local s = q.Source("a"); local l = D.TextLabel { Text = s }; s:Set(None); return "Text -> " .. show(l.Text) end)
try("P5b State a -> None -> b", function() local s = q.Source("a"); local l = D.TextLabel { Text = s }; s:Set(None); s:Set("b"); return "Text -> " .. show(l.Text) end)
try("P6 State initially None", function() local s = q.Source(None); local l = D.TextLabel { Text = s }; return "Text=" .. show(l.Text) end)
try("P7 Compute returns nil", function()
	local s = q.Source(1); local c = s:Compute(function(h) if h:Get() > 1 then return nil end return "one" end)
	local l = D.TextLabel { Text = c }; s:Set(2); return "Text -> " .. show(l.Text) end)
try("P7b Compute previous after nil result", function()
	local s = q.Source(1); local seen = {}
	local c = s:Compute(function(h, prev) table.insert(seen, show(prev)); if h:Get() == 2 then return nil end return "v" .. h:Get() end)
	local l = D.TextLabel { Text = c }; s:Set(2); s:Set(3); return "prevs=" .. table.concat(seen, ",") .. " Text=" .. show(l.Text) end)
try("P8 object ref literal None", function() local f = D.Frame {}; local g = D.Frame { NextSelectionUp = f }; local a = g.NextSelectionUp; local s = q.Source(f); local h = D.Frame{ NextSelectionUp = s }; s:Set(nil); return "lit=" .. show(a) .. " State->nil=" .. show(h.NextSelectionUp) end)
try("P9 Tween{Value=nil}", function() D.TextLabel { TextTransparency = q.Tween { Value = nil, Time = 1 } } end)
try("P9b Tween{Value=None}", function() D.TextLabel { TextTransparency = q.Tween { Value = None, Time = 1 } } end)
try("P9c State emits Tween{Value=nil} later", function() local s = q.Source(q.Tween{Value=0.5,Time=1}); local l = D.TextLabel{ TextTransparency = s }; s:Set(q.Tween{ Value = nil }) end)
try("P10 Animate: nil passes", function()
	local s = q.Source(0.5); local cb = 0
	local l = D.TextLabel { TextTransparency = s:Apply(q.Animate { Time = 1, Completed = function() cb += 1 end }) }
	local a = l.TextTransparency; s:Set(nil); local b = l.TextTransparency; H.runTask(2)
	return "0.5 snap=" .. show(a) .. " ->nil=" .. show(b) .. " completedCalls=" .. cb end)
try("P10b Animate: None passes", function()
	local s = q.Source(0.5)
	local l = D.TextLabel { TextTransparency = s:Apply(q.Animate { Time = 1 }) }
	s:Set(None); return "->None=" .. show(l.TextTransparency) end)
try("P10c Animate CanAnimate=false + Completed, nil emit", function()
	local s = q.Source(0.5); local cb = 0
	local l = D.TextLabel { TextTransparency = s:Apply(q.Animate { Time = 1, CanAnimate = false, Completed = function() cb += 1 end }) }
	local c0 = cb; s:Set(0.2); local c1 = cb; s:Set(nil); return "cb after 0.5=" .. c0 .. " after 0.2=" .. c1 .. " after nil=" .. cb .. " val=" .. show(l.TextTransparency) end)
try("P10d Animate initially nil", function()
	local s = q.Source(nil); local l = D.TextLabel { TextTransparency = s:Apply(q.Animate { Time = 1 }) }
	s:Set(0.3); local a = l.TextTransparency; return "nil -> 0.3 val=" .. show(a) .. " (snap?)" end)
try("P11 State<Modifier> Text then None (retract)", function()
	local s = q.Source(q.Modifier():Text("m")); local l = D.TextLabel { s }; local a = l.Text; s:Set(None); return "Text " .. show(a) .. " -> " .. show(l.Text) end)
try("P11b State<Modifier> Text then nil", function()
	local s = q.Source(q.Modifier():Text("m")); local l = D.TextLabel { s }; s:Set(nil); return "Text -> " .. show(l.Text) end)

print("== M: Modifier fields")
try("M1 mod:Text(nil) then Peek", function() local m = q.Modifier():Text(nil); return "Peek=" .. show(m:Peek("Text")) end)
try("M2 mod:Text(None) applied", function() local l = D.TextLabel { Text = "x", q.Modifier():Text(None) }; return "Text=" .. show(l.Text) .. " (inline wins)" end)
try("M2b mod None over earlier mod", function() local l = D.TextLabel { q.Modifier():Text("a"), q.Modifier():Text(None) }; return "Text=" .. show(l.Text) end)
try("M2c mod nil over earlier mod", function() local l = D.TextLabel { q.Modifier():Text("a"), q.Modifier():Text(nil) }; return "Text=" .. show(l.Text) end)
try("M3 transform returns nil (plain)", function() local l = D.TextLabel { q.Modifier():Text("a"), q.Modifier():Text(function(old) return nil end) }; return "Text=" .. show(l.Text) end)
try("M3b transform returns nil (State old)", function() local l = D.TextLabel { q.Modifier():Text(q.Source("a")), q.Modifier():Text(function(old) return nil end) }; return "Text=" .. show(l.Text) end)

print("== E: Event")
try("E1 literal Activated=None", function() D.TextButton { Activated = None } end)
try("E2 State<cb> -> nil disconnect", function()
	local n = 0; local s = q.Source(function() n += 1 end); local b = D.TextButton { Activated = s }
	b.Activated:Fire(); s:Set(nil); b.Activated:Fire(); s:Set(None); b.Activated:Fire(); return "calls=" .. n end)
try("E3 State initially nil", function() local s = q.Source(nil); D.TextButton { Activated = s } end)

print("== S: Shorthand UICorner")
try("S1 literal UICorner=None", function() local f = D.Frame { UICorner = None }; return kids(f) end)
try("S2 State 8 -> nil -> 4", function() local s = q.Source(8); local f = D.Frame { UICorner = s }; local a = kids(f); s:Set(nil); local b = kids(f); s:Set(4); return a .. " -> " .. b .. " -> " .. kids(f) end)
try("S3 State 8 -> None", function() local s = q.Source(8); local f = D.Frame { UICorner = s }; s:Set(None); return kids(f) end)
try("S4 State initially nil", function() local s = q.Source(nil); local f = D.Frame { UICorner = s }; return kids(f) end)
try("S5 Animate nil on shorthand", function() local s = q.Source(8); local f = D.Frame { UICorner = s:Apply(q.Animate{Time=1}) }; s:Set(nil); return kids(f) end)
try("S6 Tween{Value=nil} on shorthand", function() D.Frame { UICorner = q.Tween { Value = nil } } end)

print("== C: numeric child seat")
try("C1 hole mid", function() local a = D.Frame{}; D.Frame { a, nil, D.Frame{} } end)
try("C1b trailing nil", function() local f = D.Frame { D.Frame{}, nil }; return kids(f) end)
try("C2 None seat", function() local f = D.Frame { None, D.Frame{} }; return kids(f) end)
try("C3 State<Instance?> nil -> inst -> nil -> inst2", function()
	local s = q.Source(nil); local f = D.Frame { s }; local r = { kids(f) }
	local c = D.TextLabel {}; s:Set(c); table.insert(r, kids(f)); s:Set(nil); table.insert(r, kids(f) .. " c.Parent=" .. show(c.Parent) .. " c.alive=" .. tostring(q.Backend.isClaimed(c)))
	s:Set(c); table.insert(r, kids(f)); return table.concat(r, " -> ") end)
try("C3b State<Instance?> -> None", function()
	local c = D.TextLabel {}; local s = q.Source(c); local f = D.Frame { s }; s:Set(None); return kids(f) .. " c.Parent=" .. show(c.Parent) .. " claimed=" .. tostring(q.Backend.isClaimed(c)) end)
try("C4 State<Slot> -> nil", function()
	local c = D.TextLabel {}; local sl = q.Slot { c }; local s = q.Source(sl); local f = D.Frame { s }; s:Set(nil); return kids(f) .. " c.Parent=" .. show(c.Parent) .. " claimed=" .. tostring(q.Backend.isClaimed(c)) end)
try("C5 State<Tag> -> nil", function()
	local s = q.Source(q.Tag("A")); local f = D.Frame { s }; local a = tags(f); s:Set(nil); local b = tags(f); s:Set(None); return a .. " -> " .. b .. " -> None " .. tags(f) end)
try("C6 State<Attr> -> nil", function()
	local s = q.Source(q.Attr { A = 1 }); local f = D.Frame { s }; local a = attrs(f); s:Set(nil); return a .. " -> " .. attrs(f) .. " (Attr retract leaves engine?)" end)
try("C7 State<Ref> -> nil", function()
	local r = q.Ref(nil); local s = q.Source(r); local f = D.Frame { s }; local a = show(r.Value); s:Set(nil); return a .. " -> " .. show(r.Value) end)

print("== SL: Slot elements")
try("SL1 q.Slot{None}", function() q.Slot { None } end)
try("SL2 slot:Add(nil)", function() q.Slot{}:Add(nil) end)
try("SL3 slot:Add(None)", function() q.Slot{}:Add(None) end)
try("SL4 q.Slot{a,nil,b}", function() local a, b = D.Frame{}, D.Frame{}; local sl = q.Slot { a, nil, b }; return "Length=" .. show(sl.Length:Get()) end)
try("SL5 Slot element State<Instance?> nil->c->nil->c->None", function()
	local s = q.Source(nil); local sl = q.Slot{}; sl:Add(s); local f = D.Frame { sl }; local r = { "len=" .. sl.Length:Get() .. kids(f) }
	local c = D.TextLabel{}; s:Set(c); table.insert(r, "len=" .. sl.Length:Get() .. kids(f))
	s:Set(nil); table.insert(r, "len=" .. sl.Length:Get() .. kids(f) .. " cParent=" .. show(c.Parent) .. " claimed=" .. tostring(q.Backend.isClaimed(c)))
	s:Set(c); table.insert(r, "len=" .. sl.Length:Get() .. kids(f))
	s:Set(None); table.insert(r, "None len=" .. sl.Length:Get() .. kids(f) .. " claimed=" .. tostring(q.Backend.isClaimed(c)))
	return table.concat(r, " -> ") end)
try("SL5b slot initial State<Instance?> starting nil", function()
	local s = q.Source(nil); local sl = q.Slot { s }; return "len=" .. sl.Length:Get() end)
try("SL6 slot:Single(nil state) nil->c->nil", function()
	local s = q.Source(nil); local sl = q.Slot(); sl:Single(s); local f = D.Frame { sl }
	local c = D.TextLabel{}; s:Set(c); local a = kids(f); s:Set(nil); return a .. " -> " .. kids(f) .. " claimed=" .. tostring(q.Backend.isClaimed(c)) end)
try("SL6b :Single with updateFn, KeyGone on nil", function()
	local s = q.Source("x"); local sl = q.Slot(); local gone = 0
	sl:Single(s, function(ctx) if ctx.Item == q.KeyGone then gone += 1; return nil end return ctx.Prev or D.TextLabel { Text = ctx.Item } end)
	local f = D.Frame { sl }; s:Set(nil); local a = kids(f); s:Set("y"); local b = kids(f); s:Set(None); return "gone=" .. gone .. " " .. a .. " " .. b .. " " .. kids(f) end)
try("SL7 :List updateFn returns nil for present key", function()
	local data = q.Source({ "a", "b" }); local sl = q.Slot()
	sl:List(data, function(ctx) if ctx.Item == "a" then return nil end return ctx.Prev or D.TextLabel { Text = ctx.Item } end)
	local f = D.Frame { sl }; return "len=" .. sl.Length:Get() .. kids(f) end)
try("SL7b :List updateFn returns None for present key", function()
	local data = q.Source({ "a", "b" }); local sl = q.Slot()
	sl:List(data, function(ctx) if ctx.Item == "a" then return None end return ctx.Prev or D.TextLabel { Text = ctx.Item } end)
	local f = D.Frame { sl }; return "len=" .. sl.Length:Get() .. kids(f) end)
try("SL7c :List KeyGone returns element", function()
	local data = q.Source({ "a" }); local sl = q.Slot()
	sl:List(data, function(ctx) return ctx.Prev or D.TextLabel {} end)
	local f = D.Frame { sl }; data:Set({}) end)
try("SL7d :List data nil", function() local data = q.Source(nil); local sl = q.Slot(); sl:List(data, function(ctx) return D.Frame{} end); return "len=" .. sl.Length:Get() end)
try("SL7e :List data None", function() local data = q.Source(None); local sl = q.Slot(); sl:List(data, function(ctx) return D.Frame{} end); return "len=" .. sl.Length:Get() end)
try("SL7f :List data {..} -> nil", function() local data = q.Source({"a"}); local sl = q.Slot(); sl:List(data, function(ctx) return ctx.Prev or D.Frame{} end); data:Set(nil); return "len=" .. sl.Length:Get() end)
try("SL7g :List keyFn returns nil", function() local data = q.Source({"a"}); local sl = q.Slot(); sl:List(data, function(ctx) return D.Frame{} end, { Key = function() return nil end }) end)

print("== T: Tag")
try("T1 q.Tag(nil)", function() local t = q.Tag(nil); local f = D.Frame { t }; return tags(f) end)
try("T2 q.Tag('A', nil, 'B')", function() local f = D.Frame { q.Tag("A", nil, "B") }; return tags(f) end)
try("T3 q.Tag({'A', nil, 'B'})", function() q.Tag({ "A", nil, "B" }) end)
try("T4 q.Tag(None)", function() q.Tag(None) end)
try("T5 tag:Added(None)", function() q.Tag("A"):Added(None) end)
try("T6 tag:Contains(nil)", function() return q.Tag("A"):Contains(nil) end)
try("T7 State<Tag> via Compute returning nil", function()
	local s = q.Source(1); local f = D.Frame { s:Compute(function(h) if h:Get() == 1 then return q.Tag("One") end return nil end) }
	local a = tags(f); s:Set(2); return a .. " -> " .. tags(f) end)

print("== A: Attr")
try("A1 q.Attr{A=nil}", function() local f = D.Frame { q.Attr { A = nil, B = 1 } }; return attrs(f) end)
try("A2 q.Attr{A=None} after set", function() local f = D.Frame { q.Attr { A = 1 } }; local g = q.Claim and nil; local f2 = D.Frame { q.Attr { A = None } }; return attrs(f2) end)
try("A3 State nil initially", function() local s = q.Source(nil); local f = D.Frame { q.Attr { A = s } }; return attrs(f) end)
try("A4 State 1 -> nil -> 2 -> None", function() local s = q.Source(1); local f = D.Frame { q.Attr { A = s } }; local r = { attrs(f) }; s:Set(nil); table.insert(r, attrs(f)); s:Set(2); table.insert(r, attrs(f)); s:Set(None); table.insert(r, attrs(f)); return table.concat(r, " -> ") end)
try("A5 StringAttr(nil)", function() q.StringAttr("L", nil) end)
try("A5b NumberAttr(None)", function() local f = D.Frame { q.NumberAttr("N", None) }; return attrs(f) end)
try("A5c NumberAttr State -> nil", function() local s = q.Source(1); local f = D.Frame { q.NumberAttr("N", s) }; s:Set(nil); return attrs(f) end)
try("A6 [AttrKey]=None", function() local f = D.Frame { [q.AttrKey("K")] = None }; return attrs(f) end)
try("A6b [AttrKey]=State->nil", function() local s = q.Source(1); local f = D.Frame { [q.AttrKey("K")] = s }; s:Set(nil); return attrs(f) end)
try("A7 Attr State 'x' -> Tween", function() local s = q.Source(1); local f = D.Frame { q.Attr { A = s } }; s:Set(q.Tween{Value=2}) end)
try("A8 Attr from Store with Source(nil)", function() local st = q.Store { hp = q.Source(nil), mp = q.Source(3) }; local f = D.Frame { q.Attr(st) }; local a = attrs(f); st.mp:Set(nil); return a .. " -> " .. attrs(f) end)

print("== ST: Store / Source")
try("ST1 Store{hp=None}", function() q.Store { hp = None } end)
try("ST2 Store{hp=nil}", function() local st = q.Store { hp = nil }; return tostring(st) end)
try("ST3 Source(nil):Get", function() return show(q.Source(nil):Get()) end)
try("ST4 Source(None):Get", function() return show(q.Source(None):Get()) end)
try("ST5 Source():Get", function() return show(q.Source():Get()) end)
try("ST6 Source dedup nil->nil fires?", function() local s = q.Source(nil); local n = 0; local o = s:Observer(function() n += 1 end); s:Set(nil); s:Set(None); s:Set(None); return "fires=" .. n end)

print("== R: Ref")
try("R1 Ref:Set(nil)", function() local r = q.Ref(1); r:Set(nil); return show(r.Value) end)
try("R2 Ref:Set(None)", function() local r = q.Ref(1); r:Set(None); return show(r.Value) end)
try("R3 Ref in seat, then State seat -> None", function() local r = q.Ref(nil); local s = q.Source(r); local f = D.Frame { s }; s:Set(None); return show(r.Value) end)

print("== CX: Context")
try("CX1 ctx:Set(p, nil)", function() local P = q.Context.Provider("P"); q.Context():Set(P, nil) end)
try("CX2 ctx:Set(p, None)", function() local P = q.Context.Provider("P"); local c = q.Context():Set(P, None); return show(c:Get(P)) end)
try("CX3 ctx:Get missing", function() local P = q.Context.Provider("P"); return show(q.Context():Get(P)) end)
try("CX4 ctx:Peek missing", function() local P = q.Context.Provider("P"); return show(q.Context():Peek(P)) end)

print("== O: Out / OnChange")
try("O1 Out Text: engine writes nil", function()
	local src = q.Source("a"); local tb = D.TextBox { q.Out("Text", src) } end)
try("O2 Out Text: engine sets nil, src gets", function()
	local src = q.Source("a"); local tb = D.TextBox { Text = "a", q.Out("Text", src) }; tb.Text = nil; return "src=" .. show(src:Get()) end)
try("O3 Out NextSelectionUp nil", function()
	local f = D.Frame{}; local src = q.Source(f); local g = D.Frame { q.Out("NextSelectionUp", src) }; g.NextSelectionUp = f; local a = show(src:Get()); g.NextSelectionUp = nil; return a .. " -> " .. show(src:Get()) end)
try("O4 OnChange Text nil emit None?", function() local seen = {}; local tb = D.TextBox { q.OnChange("Text", function(v) table.insert(seen, show(v)) end) }; tb.Text = "x"; tb.Text = nil; return table.concat(seen, ",") end)
try("O5 OnChange literal None", function() D.TextBox { q.OnChange("Text", None) } end)
try("O6 Out with src None -> ?", function() D.TextBox { q.Out("Text", None) } end)

print("== OP: Operator")
local Op = q.Operator
try("OP1 Alternative self None", function() local s = q.Source(None); return show(s:Apply(Op.Alternative("d")):Get()) end)
try("OP2 Alternative self nil", function() local s = q.Source(nil); return show(s:Apply(Op.Alternative("d")):Get()) end)
try("OP3 Not None", function() local s = q.Source(None); return show(s:Apply(Op.Not()):Get()) end)
try("OP4 Not nil", function() local s = q.Source(nil); return show(s:Apply(Op.Not()):Get()) end)

print("== DS: dispose")
try("DS1 q.dispose(nil)", function() q.dispose(nil) end)
try("DS2 q.dispose(None)", function() q.dispose(None) end)
