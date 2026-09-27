--!nocheck
-- E75 group E: 05-tag-attr.md + 06-module-backend.md (main session)
local H = require("../harness")
local R = require("../runner")
local q, D = H.q, H.D
local M = D.Mapper
local mock = H.mock
local CS = H.CollectionService
local QuadRoblox = H.QuadRoblox
local function fresh()
	local m = H.Quad.New()
	m:UseProvider(QuadRoblox)
	m.Backend.isInst = mock.isMockInstance
	return m
end

-- ===== 05 Attr =====
R.case({ id = "Quad0001",
	trigger = function() q.AttrKey("") end,
	fix = function()
		local k = q.AttrKey("Hp")
		local f = D.Frame({ [k] = 5 })
		return f:GetAttribute("Hp") == 5, "Hp=" .. tostring(f:GetAttribute("Hp"))
	end })
R.case({ id = "Quad0002", note = "two groups same name",
	trigger = function() D.Frame({ q.Attr({ Hp = 5 }), q.Attr({ Hp = 9 }) }) end,
	fix = function()
		local f = D.Frame({ q.Attr.Overridden(q.Attr({ Hp = 5 }), q.Attr({ Hp = 9 })) })
		return f:GetAttribute("Hp") == 9, "Overridden Hp=" .. tostring(f:GetAttribute("Hp"))
	end })
R.case({ id = "Quad0002", note = "fix b: vacate first then place on the NEXT :Set (two State<Attr> seats)",
	trigger = function()
		local a = q.Source(q.Attr({ Hp = 5 }))
		local b = q.Source(nil)
		D.Frame({ a, b })
		b:Set(q.Attr({ Hp = 9 }))
	end,
	fix = function()
		local a = q.Source(q.Attr({ Hp = 5 }))
		local b = q.Source(nil)
		local f = D.Frame({ a, b })
		a:Set(nil)
		b:Set(q.Attr({ Hp = 9 }))
		return f:GetAttribute("Hp") == 9, "Hp=" .. tostring(f:GetAttribute("Hp"))
	end })
R.case({ id = "Quad0002", note = "group + AttrKey same name",
	trigger = function() D.Frame({ q.Attr({ Hp = 5 }), [q.AttrKey("Hp")] = 9 }) end })
R.case({ id = "Quad0003",
	trigger = function()
		local st = q.Store({ a = q.Source(1) })
		st[""] = q.Source(2)
		q.Attr(st)
	end,
	fix = function()
		local st = q.Store({ a = q.Source(1) })
		st:Of("b"):Set(2)
		local f = D.Frame({ q.Attr(st) })
		return f:GetAttribute("a") == 1 and f:GetAttribute("b") == 2, ("a=%s b=%s"):format(tostring(f:GetAttribute("a")), tostring(f:GetAttribute("b")))
	end })
R.case({ id = "Quad0005",
	trigger = function() q.Attr.Merged(q.Attr({ Hp = 1 }), q.Attr({ Hp = 2 })) end,
	fix = function()
		local m1 = q.Attr.Merged(q.Attr({ Hp = 1 }), q.Attr({ Mp = 2 }))
		local m2 = q.Attr.Overridden(q.Attr({ Hp = 1 }), q.Attr({ Hp = 2 }))
		local f = D.Frame({ m1 }); local g = D.Frame({ m2 })
		return f:GetAttribute("Mp") == 2 and g:GetAttribute("Hp") == 2, "merged Mp, overridden Hp=" .. tostring(g:GetAttribute("Hp"))
	end })
R.case({ id = "Quad0006",
	trigger = function() q.Attr({ [1] = 5 }) end,
	fix = function() local f = D.Frame({ q.Attr({ One = 5 }) }); return f:GetAttribute("One") == 5 end })
R.case({ id = "Quad0007",
	trigger = function() q.Attr({ Hp = function() return 5 end }) end,
	fix = function()
		local s = q.Source(5)
		local f = D.Frame({ q.Attr({ Hp = s, Mp = 3 }) })
		s:Set(6)
		return f:GetAttribute("Hp") == 6 and f:GetAttribute("Mp") == 3, "Hp=" .. tostring(f:GetAttribute("Hp"))
	end })
R.case({ id = "Quad0008",
	trigger = function() q.Attr({ Pos = { 1, 2 } }) end,
	fix = function() local f = D.Frame({ q.Attr({ Pos = q.None, X = 1 }) }); return f:GetAttribute("X") == 1 end })
R.case({ id = "Quad0010",
	trigger = function() q.Attr(5) end,
	fix = function() local f = D.Frame({ q.Attr({ V = 5 }) }); return f:GetAttribute("V") == 5 end })
R.case({ id = "Quad0011",
	trigger = function() q.Attr.Merged({ Hp = 1 }) end,
	fix = function() local f = D.Frame({ q.Attr.Merged(q.Attr({ Hp = 1 })) }); return f:GetAttribute("Hp") == 1 end })
R.case({ id = "Quad0012",
	trigger = function() q.Attr.Overridden({ Hp = 1 }) end,
	fix = function() local f = D.Frame({ q.Attr.Overridden(q.Attr({ Hp = 1 })) }); return f:GetAttribute("Hp") == 1 end })
R.case({ id = "Quad0013",
	trigger = function() q.NumberAttr("", 1) end,
	fix = function() local f = D.Frame({ q.NumberAttr("Hp", 1) }); return f:GetAttribute("Hp") == 1 end })
R.case({ id = "Quad0014",
	trigger = function() q.StringAttr("Name", nil) end,
	fix = function()
		local f = D.Frame({ q.StringAttr("Name", "x") })
		local g = D.Frame({ q.StringAttr("Name", q.None) })
		return f:GetAttribute("Name") == "x" and g:GetAttribute("Name") == nil, "None accepted, deletes"
	end })
R.case({ id = "Quad0015",
	trigger = function() q.BooleanAttr("On", 1) end,
	fix = function()
		local s = q.Source(true)
		local f = D.Frame({ q.BooleanAttr("On", s), q.BooleanAttr("Off", false) })
		s:Set(false)
		return f:GetAttribute("On") == false and f:GetAttribute("Off") == false
	end })
R.case({ id = "Quad0016",
	trigger = function() local a = q.Attr({ Hp = 1 }); D.Frame({ a, a }) end,
	fix = function()
		-- "separate q.Attr(...) calls per seat" — but two seats with the SAME name -> Quad0002?
		local ok, err = pcall(function() D.Frame({ q.Attr({ Hp = 1 }), q.Attr({ Hp = 1 }) }) end)
		if not ok then return false, "separate calls, same name -> " .. R.first(err) end
		return true, "ok"
	end })
R.case({ id = "Quad0016", note = "separate calls with DIFFERENT names (what the user may have wanted: same group twice)",
	trigger = nil,
	fix = function()
		local f = D.Frame({ q.Attr({ Hp = 1 }), q.Attr({ Mp = 1 }) })
		return f:GetAttribute("Hp") == 1, "distinct names fine"
	end })

-- ===== 05 Tag =====
R.case({ id = "Quad0199",
	trigger = function() q.Tag("") end,
	fix = function() local f = D.Frame({ q.Tag("Card") }); return CS:HasTag(f, "Card") end })
R.case({ id = "Quad0200",
	trigger = function() q.Tag(q.AttrKey("Card")) end,
	fix = function() local f = D.Frame({ q.Tag({ "Card", q.Tag("X") }) }); return CS:HasTag(f, "Card") and CS:HasTag(f, "X") end })
R.case({ id = "Quad0201",
	trigger = function() local l = {}; l[1] = l; q.Tag(l) end,
	fix = function() local l = { "A", { "B" } }; local f = D.Frame({ q.Tag(l) }); return CS:HasTag(f, "B") end })
R.case({ id = "Quad0202",
	trigger = function() q.Tag({ a = "A" }) end,
	fix = function() local f = D.Frame({ q.Tag({ "A" }) }); return CS:HasTag(f, "A") end })
R.case({ id = "Quad0203",
	trigger = function() q.Tag({ "A", nil, "C" }) end,
	fix = function() local f = D.Frame({ q.Tag({ "A", "C" }) }); return CS:HasTag(f, "C") end })
R.case({ id = "Quad0204",
	trigger = function() q.Tag(5) end,
	fix = function() local f = D.Frame({ q.Tag("5") }); return CS:HasTag(f, "5") end })
R.case({ id = "Quad0205",
	trigger = function() q.Tag("A"):Contains("A", 5) end,
	fix = function() return q.Tag("A"):Contains("A") == true end })
R.case({ id = "Quad0205", note = "nil arg",
	trigger = function() q.Tag("A"):Contains(nil) end })
R.case({ id = "Quad0206",
	trigger = function() q.Tag("A"):Apply("x") end,
	fix = function() local t = q.Tag("A"):Apply(function(t) return t:Added("B") end); return t:Contains("B") end })
R.case({ id = "Quad0207",
	trigger = function() q.Tag.Merged(q.Tag("A"), "B") end,
	fix = function()
		local a = q.Tag.Merged(q.Tag("A"), q.Tag("B"))
		local b = q.Tag(q.Tag("A"), "B")
		return a:Contains("A", "B") and b:Contains("A", "B")
	end })
R.case({ id = "Quad0237",
	trigger = function() local s = q.Source("Even"); q.Tag(s) end,
	fix = function()
		-- literal fix: strings only -> tag no longer follows the State (user intent was reactive)
		local s = q.Source("Even")
		local f = D.Frame({ q.Tag("Even") })
		s:Set("Odd")
		local literal = CS:HasTag(f, "Odd")
		-- the working route the page does not name: a State<Tag> in the array seat
		local g = D.Frame({ s:Compute(function(h) return q.Tag(h:Get()) end) })
		s:Set("Even")
		local ok = CS:HasTag(g, "Even") and not CS:HasTag(g, "Odd")
		return literal, ("literal follows state=%s; State<Tag> route works=%s"):format(tostring(literal), tostring(ok))
	end })
R.case({ id = "Quad0237", note = "None", trigger = function() q.Tag("A"):Added(q.None) end,
	fix = function() local t = q.Tag("A"):Added(nil); return t:Contains("A") end })

-- ===== 06 Claim =====
R.case({ id = "Quad0026",
	trigger = function() q.newMapperClass("") end,
	fix = function()
		local MyFrame = q.newMapperClass("Frame")
		local t = mock.Instance.foreign("Frame")
		q.Claim(t, MyFrame(q.MapperRoot)({ Visible = false }))
		return t.Visible == false, "Visible=" .. tostring(t.Visible)
	end })
R.case({ id = "Quad0027",
	trigger = function()
		local d = M.Frame(M.Root)({})
		q.Claim(mock.Instance.foreign("Frame"), d)
		q.Claim(mock.Instance.foreign("Frame"), d)
	end,
	fix = function()
		local function make() return M.Frame(M.Root)({ Visible = false }) end
		local a, b = mock.Instance.foreign("Frame"), mock.Instance.foreign("Frame")
		q.Claim(a, make()); q.Claim(b, make())
		return a.Visible == false and b.Visible == false
	end })
local function tpl()
	local root = mock.Instance.foreign("Frame")
	local c = mock.Instance.foreign("TextLabel"); c.Name = "Title"; c.Parent = root
	return root, c
end
R.case({ id = "Quad0028",
	trigger = function()
		local root = tpl()
		q.Claim(root, M.Frame(M.Root)({ M.TextLabel("Title")({}), M.TextLabel("Title")({ Text = "x" }) }))
	end,
	fix = function()
		local root, c = tpl()
		q.Claim(root, M.Frame(M.Root)({ M.TextLabel("Title")({ Text = "x" }) }))
		return c.Text == "x"
	end })
R.case({ id = "Quad0029",
	trigger = function()
		local root = mock.Instance.foreign("Frame")
		local child = D.TextLabel({ Name = "Title" })
		child.Parent = root
		q.Claim(root, M.Frame(M.Root)({ M.TextLabel("Title")({ Text = "x" }) }))
	end,
	fix = function()
		-- (a) leave the Declaration-made child out of the descriptor, drive it separately
		local root = mock.Instance.foreign("Frame")
		local text = q.Source("x")
		local child = D.TextLabel({ Name = "Title", Text = text })
		child.Parent = root
		q.Claim(root, M.Frame(M.Root)({ Visible = false }))
		text:Set("y")
		-- (b) dispose and rebuild: dispose the D-made instance, then build a fresh one
		local root2 = mock.Instance.foreign("Frame")
		local c2 = D.TextLabel({ Name = "Title" }); c2.Parent = root2
		q.dispose(c2)
		local fresh2 = mock.Instance.foreign("TextLabel"); fresh2.Name = "Title"; fresh2.Parent = root2
		q.Claim(root2, M.Frame(M.Root)({ M.TextLabel("Title")({ Text = "z" }) }))
		return child.Text == "y" and root.Visible == false and fresh2.Text == "z", ("a text=%s b=%s"):format(tostring(child.Text), tostring(fresh2.Text))
	end })
R.case({ id = "Quad0030",
	trigger = function() q.Claim(mock.Instance.foreign("Frame"), M.Frame(M.Root)(5)) end,
	fix = function() local t = mock.Instance.foreign("Frame"); q.Claim(t, M.Frame(M.Root)({ Visible = false })); return t.Visible == false end })
R.case({ id = "Quad0031",
	trigger = function()
		local root = tpl()
		q.Claim(root, M.Frame(M.Root)({ [0] = M.TextLabel("Title")({ Text = "x" }) }))
	end,
	fix = function()
		local root, c = tpl()
		q.Claim(root, M.Frame(M.Root)({ [1] = M.TextLabel("Title")({ Text = "x" }) }))
		return c.Text == "x"
	end })
R.case({ id = "Quad0032",
	trigger = function() local root = tpl(); q.Claim(root, M.Frame(M.Root)({ M.TextLabel("Titel")({}) })) end,
	fix = function() local root, c = tpl(); q.Claim(root, M.Frame(M.Root)({ M.TextLabel("Title")({ Text = "k" }) })); return c.Text == "k" end })
R.case({ id = "Quad0032", note = "name right, class wrong",
	trigger = function() local root = tpl(); q.Claim(root, M.Frame(M.Root)({ M.Frame("Title")({}) })) end })
R.case({ id = "Quad0033",
	trigger = function() q.Claim({}, M.Frame(M.Root)({})) end,
	fix = function() local t = mock.Instance.foreign("Frame"); return q.Claim(t, M.Frame(M.Root)({})) == t end })
R.case({ id = "Quad0034",
	trigger = function() q.Claim(mock.Instance.foreign("Frame"), { Visible = false }) end,
	fix = function() local t = mock.Instance.foreign("Frame"); q.Claim(t, M.Frame(M.Root)({ Visible = false })); return t.Visible == false end })

-- ===== 06 lifetime =====
R.case({ id = "Quad0102",
	trigger = function() q.Backend.bindLifetime(nil, {}) end,
	fix = function() q.Backend.bindLifetime(D.Frame({}), {}); return true end })
R.case({ id = "Quad0103",
	trigger = function() q.Backend.bindLifetime(D.Frame({}), nil) end,
	fix = function()
		local n = 0
		local e = q.Effect(function() n += 1 end)
		q.Backend.bindLifetime(D.Frame({}), e)
		return n >= 1, "Effect bound runs n=" .. n
	end })
R.case({ id = "Quad0104",
	trigger = function() local e = q.Effect(function() end); e:Subscribe(); D.Frame({ e }) end,
	fix = function()
		local n = 0
		local e = q.Effect(function() n += 1 end); e:Subscribe()
		local e2 = q.Effect(function() n += 1 end)
		D.Frame({ e2 })
		return n == 2, "n=" .. n
	end })
R.case({ id = "Quad0105",
	trigger = function() q.Backend.unbindLifetime(nil) end,
	fix = function() local e = q.Effect(function() end); local f = D.Frame({}); q.Backend.bindLifetime(f, e); q.Backend.unbindLifetime(e); return true end })
R.case({ id = "Quad0232",
	trigger = function() local e = q.Effect(function() end); D.Frame({ e, e }) end,
	fix = function()
		local n = 0
		local s = q.Source(0)
		local function mk() return q.Effect(function(h) s:Get(); n += 1 end) end
		D.Frame({ mk(), mk() })
		return n == 2, "n=" .. n
	end })
R.case({ id = "Quad0233",
	trigger = function() local e = q.Effect(function() end); D.Frame({ e }); D.Frame({ e }) end,
	fix = function()
		local n = 0
		local function mk() return q.Effect(function() n += 1 end) end
		D.Frame({ mk() }); D.Frame({ mk() })
		return n == 2, "n=" .. n
	end })

-- ===== 06 Relate =====
R.case({ id = "Quad0138",
	trigger = function() q.Relate():SetStrong(nil, "k", 1) end,
	fix = function() local r = q.Relate(); local f = D.Frame({}); r:SetStrong(f, "k", 1); return r:GetStrong(f, "k") == 1 end })
R.case({ id = "Quad0139",
	trigger = function() q.Relate():GetWeak(D.Frame({}), nil) end,
	fix = function() local r = q.Relate(); local f = D.Frame({}); local v = {}; r:SetWeak(f, "k", v); return r:GetWeak(f, "k") == v end })

-- ===== 06 module =====
R.case({ id = "Quad0106",
	trigger = function() local B = fresh(); D.Frame({ B.Effect(function() end) }) end,
	fix = function()
		local B = fresh()
		local n = 0
		local f = B.Declaration.Frame({ B.Effect(function() n += 1 end) })
		return n == 1, "same instance n=" .. n
	end })
R.case({ id = "Quad0106", note = "State in property seat",
	trigger = function() local B = fresh(); D.Frame({ Visible = B.Source(true) }) end })
R.case({ id = "Quad0108",
	trigger = function() local bare = H.Quad.New(); bare.Claim(mock.Instance.foreign("Frame"), M.Frame(M.Root)({})) end,
	fix = function()
		local m = H.Quad.New()
		m:UseProvider(QuadRoblox); m.Backend.isInst = mock.isMockInstance
		local t = mock.Instance.foreign("Frame")
		m.Claim(t, m.Declaration.Mapper.Frame(m.MapperRoot)({ Visible = false }))
		return t.Visible == false
	end })
R.case({ id = "Quad0208",
	trigger = function() H.Quad.New():RunInit(5) end,
	fix = function() local m = H.Quad.New(); local r = m:RunInit(function(mod) return 7 end); return true, "ret=" .. tostring(r) end })
R.case({ id = "Quad0209",
	trigger = function() H.Quad.New():UseProvider(function(m) end) end,
	fix = function() local m = H.Quad.New(); m:UseProvider(function(mm) return {} end); return true end })
R.case({ id = "Quad0210",
	trigger = function() H.Quad.New():AddPlugin(5) end,
	fix = function() local m = H.Quad.New(); m:AddPlugin(function(mm) return { Hello = 1 } end); return m.Hello == 1, "Hello=" .. tostring(m.Hello) end })
R.case({ id = "Quad0211",
	trigger = function() H.Quad.New():AddPlugin(function(m) m.X = 1 end) end,
	fix = function()
		local m = H.Quad.New()
		m:AddPlugin(function(mm) mm.X = 1; return {} end)
		return m.X == 1, "X=" .. tostring(m.X)
	end })
R.case({ id = "Quad0212",
	trigger = function() H.Quad.New():UseProvider(nil) end,
	fix = function() local m = H.Quad.New(); m:UseProvider(function(mm) return { P = 1 } end); return m.P == 1 end })
R.case({ id = "Quad0213",
	trigger = function() local m = H.Quad.New(); m:UseProvider(function() return {} end); m:UseProvider(function() return {} end) end,
	fix = function()
		local m = H.Quad.New(); m:UseProvider(function() return { A = 1 } end)
		local m2 = m.New(); m2:UseProvider(function() return { B = 2 } end)
		return m2.B == 2 and m.A == 1, "q.New() on instance ok"
	end })
R.done()
