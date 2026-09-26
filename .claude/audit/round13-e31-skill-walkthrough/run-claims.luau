--!nocheck
-- E31: runtime check of the prose claims in SKILL.md / references (not tied to one fenced block).
local H = require("./harness")
local q = H.q
local D = q.Declaration
local mock = require("../../../quad-base/test/mock")
UDim2 = H.EG.UDim2; Color3 = H.EG.Color3; Enum = H.EG.Enum; Vector2 = H.EG.Vector2; UDim = H.EG.UDim
local function try(label, fn, ...)
	local ok, err = pcall(fn, ...)
	print(string.format("%-58s %s", label, ok and "OK(no error)" or ("ERR " .. H.first(err):gsub("^[^Q]*(Quad%d+)", "%1"):sub(1, 150))))
end
local function kids(p) local t = {} for _, c in p:GetChildren() do table.insert(t, c.Name) end return table.concat(t, ",") end

print("--- §2.1 dep handle misuse")
local a, b = q.Source("x"), q.Source("yz")
local r = a:Compute(function(self, prev, dep) return #dep end, b)
print("#handle =", r:Get())
try("dep .. '' on a handle (skill: 'does not error')", function() local s = a:Compute(function(self, prev, dep) return dep .. "" end, b); return s:Get() end)

print("--- §2.2 nesting")
local inner = q.Source("in1"); local outer = q.Source(inner)
local lbl = D.TextLabel { Text = outer }
inner:Set("in2"); print("State<State> prop follows inner:", lbl.Text)
local viaCompute = outer:Compute(function(self) return self:Get():Get() end)
print("Compute first read:", viaCompute:Get())
inner:Set("in3"); print("Compute over outer after inner:Set (skill: not recomputed):", viaCompute:Get())
local st = q.Store { N = q.Source(1) }; local holder = q.Source(st); local fired = 0
holder:Observer(function() fired += 1 end):Subscribe(); local base0 = fired; st.N:Set(2); print("Store-in-Source outer fires on field Set (skill: no) — extra fires:", fired - base0)
try("Modifier inside Source (Quad0182)", function() q.Source(q.Modifier { }) end)

print("--- §2.3 Operators")
local Op = q.Operator
print("Not", q.Source(true):Apply(Op.Not):Get(), "Sum", q.Source(100):Apply(Op.Sum(q.Source(5), 3)):Get(),
	"Clamp", q.Source(150):Apply(Op.Clamp(0, q.Source(100))):Get(), "Alt", q.Source(nil):Apply(Op.Alternative("Guest")):Get(),
	"Indexed", q.Source({ Primary = "red" }):Apply(Op.Indexed("Primary")):Get())
print("And/Or/Sub/Div exist?", Op.And, Op.Or, Op.Sub, Op.Div)
try("Operator on plain value (rules Quad0123)", function() Op.Sum(1)(5) end)

print("--- §3.1 props table mutated in place")
local mod = q.Modifier { }
local props = { mod }
D.Frame(props)
print("props[1] still the Modifier?", props[1] == mod, "type:", typeof(props[1]))

print("--- §3.2 priority")
local m1 = D.Modifier.Frame { BackgroundTransparency = 0.1, ZIndex = 1 }
local m2 = D.Modifier.Frame { BackgroundTransparency = 0.2 }
local f = D.Frame { m1, m2, ZIndex = 5 }
print("later mod wins:", f.BackgroundTransparency, "inline wins:", f.ZIndex)
local ov = q.Modifier.Overridden(D.Modifier.Frame { ZIndex = 3 }, D.Modifier.Frame { ZIndex = 4 })
print("Overridden(A,B) B wins:", D.Frame { ov }.ZIndex, " A:Overridden(B):", D.Frame { D.Modifier.Frame { ZIndex = 3 }:Overridden(D.Modifier.Frame { ZIndex = 7 }) }.ZIndex)

print("--- §3.3 table-form typos fail at drive")
try("{ Sise = 1 } table form", function() D.Frame { D.Modifier.Frame { Sise = 1 } } end)
try("{ Size = 'x' } table form", function() D.Frame { D.Modifier.Frame { Size = "x" } } end)
try("{ Activated = fn } table form (Quad0063?)", function() D.TextButton { D.Modifier.TextButton { Activated = function() end } } end)
try(":As('Nope') unknown class (Quad0052)", function() D.Modifier.GuiObject():As("Nope") end)
try(":As('TextLabel') known class only retags", function() return D.Modifier.GuiObject():As("TextLabel") end)

print("--- §3.4 Context")
local P = q.Context.Provider("Theme")
local ctx = q.Context()
print("Set returns bag:", ctx:Set(P, 1) == ctx, "Get:", ctx:Get(P))
try("ctx:Set(provider, nil) (Quad0037)", function() ctx:Set(P, nil) end)
try("ctx:Get(unset) (Quad0038)", function() q.Context():Get(P) end)
print("Peek unset:", q.Context():Peek(P))

print("--- §4 Slot")
local s = q.Slot()
local host = D.Frame { s }
local e1 = D.TextLabel { Name = "e1" }; s:Add(e1)
try("slot:Remove(instance) (Quad0168)", function() s:Remove(e1) end)
print("IndexOf:", s:IndexOf(e1)); s:Remove(s:IndexOf(e1)); print("after Remove destroyed:", mock.isDestroyed(e1))
local ls = q.Slot(); local _h = D.Frame { ls }
try("List duplicate key (Quad0145)", function() ls:List({ { Id = "a" }, { Id = "a" } }, function(ctx) return D.Frame {} end, function(i) return i.Id end) end)
local sa, sb = q.Slot(), q.Slot(); sa:Add(sb)
try("A:Add(B); B:Add(A) (Quad0173)", function() sb:Add(sa) end)
local sel = q.Source(nil); local ss = q.Slot(); local _hs = D.Frame { ss }
ss:Single(sel, nil, { OwnsElements = false })
local x1, x2 = D.Frame { Name = "x1" }, D.Frame { Name = "x2" }
sel:Set(x1); sel:Set(x2)
print("Single OwnsElements=false: old destroyed?", mock.isDestroyed(x1), "old Parent:", x1.Parent)
local ctxSeen
local s2 = q.Slot(); local _h2 = D.Frame { s2 }
local cur = q.Source("a")
s2:Single(cur, function(c) ctxSeen = c; if c.Item == q.KeyGone then return nil end return c.Prev or D.Frame { Name = c.Item } end)
print("Single ctx.Index on value:", ctxSeen.Index)
cur:Set(nil); print("Single on nil: Item is KeyGone?", ctxSeen.Item == q.KeyGone, "Index:", ctxSeen.Index)

print("--- §5 Claim")
local tmpl = mock.Instance.new("Frame"); tmpl.Name = "Card"
local nm = mock.Instance.new("TextLabel"); nm.Name = "ItemName"; nm.Parent = tmpl
local M = D.Mapper
local desc = M.Frame(M.Root)({ M.TextLabel("ItemName")({ Text = "hi" }), BackgroundTransparency = 0.25 })
local ret = q.Claim(tmpl, desc)
print("Claim returns same inst:", ret == tmpl, "child text:", nm.Text, "root bt:", tmpl.BackgroundTransparency)
local tmpl2 = mock.Instance.new("Frame")
try("descriptor reuse (Quad0027)", function() q.Claim(tmpl2, desc) end)
try("claim D-made instance (Quad0029)", function() q.Claim(D.Frame {}, M.Frame(M.Root)({})) end)
try("Claim one arg (Quad0034)", function() q.Claim(mock.Instance.new("Frame")) end)
local tmpl3 = mock.Instance.new("Frame"); local wrong = mock.Instance.new("ImageLabel"); wrong.Name = "Kid"; wrong.Parent = tmpl3
try("mapper class mismatch (Quad0032)", function() q.Claim(tmpl3, M.Frame(M.Root)({ M.TextLabel("Kid")({}) })) end)

print("--- §7 / rules table")
try("nil hole {a,nil,b} (Quad0023)", function() D.Frame { D.Frame {}, nil, D.Frame {} } end)
try("Modifier as hash key (Quad0068)", function() D.Frame { M1 = q.Modifier {} } end)
try("Ref as hash key (Quad0137)", function() D.Frame { R = q.Ref(nil) } end)
try("PreRef as hash key (Quad0137)", function() D.Frame { R = q.PreRef(nil) } end)
try("Slot as hash key (Quad0141)", function() D.Frame { S = q.Slot() } end)
try("Effect as hash key (Quad0097)", function() D.Frame { E = q.Effect(function() end) } end)
try("Observer as hash key (Quad0116)", function() D.Frame { O = q.Source(1):Observer() } end)
try("Tag as hash key (Quad0076 brand: Tag)", function() D.Frame { T = q.Tag("a") } end)
try("Tween Value = State (Quad0250)", function() q.Tween { Value = q.Source(1), Time = 1 } end)
try("Parent = inst (Quad0076)", function() D.Frame { Parent = D.Frame {} } end)
try("Activated on Frame (Quad0076)", function() D.Frame { Activated = function() end } end)
try("Store default not Source (Quad0198)", function() q.Store { k = 1 } end)
try("static child foreign Instance (Quad0219)", function() D.Frame { mock.Instance.new("TextLabel") } end)
try("Slot foreign Instance (Quad0241)", function() q.Slot():Add(mock.Instance.new("TextLabel")) end)
local shared = D.Frame {}; D.Frame { shared }
try("same inst under two parents (Quad0160)", function() D.Frame { shared } end)
local src0 = q.Source(0)
local cyc; cyc = src0:Compute(function(self) return cyc and cyc:Get() or 0 end)
try("Compute reads own result (Quad0184)", function() src0:Set(1); cyc:Get() end)
try("UseProvider different provider (Quad0213)", function() q:UseProvider(function() return {} end) end)
local obs = q.Source(1):Observer(function() end); D.Frame { obs }
try("Subscribe on bound Observer (Quad0235)", function() obs:Subscribe() end)
print("bound observer Subscribed:", obs.Subscribed)

print("--- §6.2 Tag/Attr")
try("Tag name list nil hole (Quad0203)", function() q.Tag({ "a", nil, "b" }) end)
try("Tag(q.None) (skill §6.2 says Quad0203)", function() q.Tag(q.None) end)
try("tag:Added(nil) is fine", function() q.Tag("a"):Added(nil) end)
local av = q.Source(5)
local af = D.Frame { q.Attr { Level = 3, Gone = 1 }, q.NumberAttr("Hp", av), [q.AttrKey("Mp")] = q.Source(7) }
print("attrs:", af:GetAttribute("Level"), af:GetAttribute("Hp"), af:GetAttribute("Mp"))
av:Set(nil); print("State->nil deletes attr (skill: yes):", af:GetAttribute("Hp"))
try("StringAttr nil (Quad0014)", function() q.StringAttr("Title", nil) end)
local grp = q.Source(q.Attr { A = 1, B = 2 })
local gf = D.Frame { grp }
grp:Set(q.Attr { A = 1 }); print("group key disappeared from replaced group (skill: NOT unset):", gf:GetAttribute("B"))

print("--- §6.3 Ref / hooks / Observer / Effect")
try("Unwrap empty (Quad0135)", function() q.Ref(nil):Unwrap() end)
local order = {}
local card = D.TextButton { q.OnCreated(function(i) table.insert(order, "created") end), q.OnRendered(function(i) table.insert(order, "rendered parent=" .. tostring(i.Parent)) end), D.Frame { Name = "child" } }
print("hooks:", table.concat(order, " | "))
local src = q.Source(1); local n = 0
local o = src:Observer(function() n += 1 end)
print("Observer fired at registration:", n, "Subscribed:", o.Subscribed)
src:Set(2); src:Set(3); print("after two Sets unbound:", n); o:Subscribe(); print("after Subscribe (one replay):", n)
local log = {}
local host2 = D.Frame {}
local dep = q.Source(0)
local eff = q.Effect(function() return function(dying) table.insert(log, tostring(dying)) end end, dep)
local efHost = D.Frame { eff }
dep:Set(1); print("cleanup on rerun:", table.concat(log, ","))
q.dispose(efHost)
print("cleanup on destroy:", table.concat(log, ","))

print("--- §6.4 Debounce/Throttle")
try("Debounce Time = -1 (Quad0041)", function() q.Source(1):Apply(q.Debounce { Time = -1 }) end)
try("Debounce Leading=false Trailing=false", function() q.Source(1):Apply(q.Debounce { Time = 1, Leading = false, Trailing = false }) end)
try("Throttle MaxTime (Debounce-only)", function() q.Source(1):Apply(q.Throttle { Time = 1, MaxTime = 2 }) end)
try("Debounce Handle = q.Ref(nil)", function() q.Source(1):Apply(q.Debounce { Time = 1, Handle = q.Ref(nil) }) end)
try("Handle reused across two Apply", function() local h = q.Ref(nil); q.Source(1):Apply(q.Debounce { Time = 1, Handle = h }); q.Source(1):Apply(q.Debounce { Time = 1, Handle = h }) end)

print("--- §6.5 Fallback")
local Safe = q.Fallback(function(id) error({ code = id }) end, function(err) return D.TextLabel { Text = "failed " .. typeof(err) } end)
print("Fallback result:", Safe(3).Text)
