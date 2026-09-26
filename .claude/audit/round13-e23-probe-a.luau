--!nocheck
-- round13 E23 A — string-key property place: unwrap chain transitions, ghost subs, dedup, GC
-- Run from repo root: luau .claude/audit/round13-e23-probe-a.luau
local H = require("./round13-e15-probe-setup")
local q, D, mock, try = H.q, H.D, H.mock, H.try
local function first(err) return (tostring(err):gsub("\n.*", "")) end
local function nsubs(s) for _ = 1, 3 do collectgarbage("collect") end local n = 0 for _ in s._subs do n += 1 end return n end
local function rawsubs(s) local n = 0 for _ in s._subs do n += 1 end return n end
local function writes(inst, prop)
	local c = { n = 0, vals = {} }
	inst:GetPropertyChangedSignal(prop):Connect(function() c.n += 1; table.insert(c.vals, tostring(inst[prop])) end)
	return c
end
local function chainLen(inst, k)
	-- reach into dispatch chains via retractFrom probing is not possible; use listHandlers? skip
	return "?"
end
local function sec(name, fn) print("=== " .. name .. " ==="); local ok, err = pcall(fn); if not ok then print("  !! section error:", first(err)) end end

sec("A1 plain -> State -> plain (Text)", function()
	local s = q.Source("s1")
	local l = D.TextLabel { Text = "p0" }
	local w = writes(l, "Text")
	q.Dispatch.process(l, "Text", s, 1); print("  after State", l.Text)
	q.Dispatch.process(l, "Text", "p1", 1); print("  after plain", l.Text, "subs(s)", nsubs(s))
	s:Set("s2"); print("  s:Set after plain -> Text", l.Text, "writes", w.n, table.concat(w.vals, ","))
end)

sec("A2 State<State> swap inner, ghost old inner before/after GC, same-value dedup", function()
	local a, b = q.Source("A"), q.Source("B")
	local which = q.Source(a)
	local l = D.TextLabel { Text = which }
	local w = writes(l, "Text")
	which:Set(b)
	print("  after swap Text", l.Text, "raw subs(a) pre-GC", rawsubs(a))
	a:Set("A-ghost") -- before GC
	print("  a:Set pre-GC -> Text", l.Text)
	print("  subs(a) post-GC", nsubs(a), "subs(b)", nsubs(b), "subs(which)", nsubs(which))
	b:Set("B"); print("  b same-value Set: writes", w.n, table.concat(w.vals, ","))
	local c = q.Source("B") -- different State, same value
	which:Set(c); print("  swap to other State with same value: writes", w.n)
	which:Set(c); print("  which:Set(same State): writes", w.n)
	which:Emit(); print("  which:Emit(): writes", w.n)
end)

sec("A3 State<State> inner <-> plain value (outer switches kinds)", function()
	local a = q.Source("A")
	local which = q.Source(a)
	local l = D.TextLabel { Text = which }
	which:Set("plain"); print("  outer->plain Text", l.Text, "subs(a)", nsubs(a))
	a:Set("A2"); print("  a:Set after -> Text", l.Text)
	which:Set(a); print("  back to a Text", l.Text, "subs(a)", nsubs(a))
end)

sec("A4 triple nesting and collapse", function()
	local a = q.Source("A")
	local m = q.Source(a)
	local o = q.Source(m)
	local l = D.TextLabel { Text = o }
	print("  Text", l.Text)
	a:Set("A2"); print("  a:Set Text", l.Text)
	o:Set(a); print("  o:Set(a) (depth 3->2) Text", l.Text, "subs(m)", nsubs(m))
	m:Set("stray"); print("  m:Set after detach Text", l.Text)
	o:Set(m); print("  o:Set(m) again Text", l.Text)
end)

sec("A5 self-holding State s:Set(s) at property", function()
	local s = q.Source("x")
	local l = D.TextLabel { Text = s }
	local ok, err = pcall(function() s:Set(s) end)
	print("  s:Set(s)", ok, ok and "" or first(err))
	print("  Text", l.Text, "s:Get()==s", s:Get() == s)
	local ok2, err2 = pcall(function() s:Set("y") end)
	print("  recover s:Set('y')", ok2, ok2 and "" or first(err2), "Text", l.Text)
	local ok3, err3 = pcall(function() s:Set("z") end)
	print("  again s:Set('z')", ok3, ok3 and "" or first(err3), "Text", l.Text)
end)

sec("A6 two-State cycle via inner Set (a holds b, then b:Set(a))", function()
	local b = q.Source("B")
	local a = q.Source(b)
	local l = D.TextLabel { Text = a }
	local ok, err = pcall(function() b:Set(a) end)
	print("  b:Set(a)", ok, ok and "" or first(err), "Text", l.Text)
	local ok2, err2 = pcall(function() b:Set("B2") end)
	print("  b:Set('B2') recover", ok2, ok2 and "" or first(err2), "Text", l.Text)
	local ok3, err3 = pcall(function() a:Set("A") end)
	print("  a:Set('A')", ok3, ok3 and "" or first(err3), "Text", l.Text)
	local ok4 = pcall(function() b:Set("B3") end)
	print("  b:Set('B3') after a detached", ok4, "Text", l.Text)
end)

sec("A7 cycle created before binding (unbound pair) then bind", function()
	local a = q.Source(0); local b = q.Source(a); a:Set(b)
	local ok, err = pcall(function() return D.TextLabel { Text = a } end)
	print("  bind cyclic", ok, ok and "" or first(err))
end)

sec("A8 cycle not through bound state: a holds b, c unrelated cycle b->c->b", function()
	local c = q.Source("C")
	local b = q.Source(c)
	local a = q.Source(b)
	local l = D.TextLabel { Text = a }
	local ok, err = pcall(function() c:Set(b) end)
	print("  c:Set(b)", ok, ok and "" or first(err), "Text", l.Text)
end)

sec("A9 Compute returning a State (derived outer)", function()
	local a, b = q.Source("A"), q.Source("B")
	local flag = q.Source(true)
	local outer = flag:Compute(function(f) return if f:Get() then a else b end)
	local l = D.TextLabel { Text = outer }
	print("  Text", l.Text)
	flag:Set(false); print("  flag false Text", l.Text)
	a:Set("A2"); print("  a:Set ghost? Text", l.Text, "subs(a)", nsubs(a))
end)

sec("A10 State<None> / State<nil> at property, and State<State<None>>", function()
	local s = q.Source(q.None)
	local l = D.TextLabel { Text = "init" }
	local ok, err = pcall(function() q.Dispatch.process(l, "Text", s, 1) end)
	print("  State<None> at Text", ok, ok and "" or first(err), "Text", tostring(l.Text))
	local inner = q.Source(q.None)
	local outer = q.Source(inner)
	local l2 = D.TextLabel { Text = "init" }
	local ok2, err2 = pcall(function() q.Dispatch.process(l2, "Text", outer, 1) end)
	print("  State<State<None>> at Text", ok2, ok2 and "" or first(err2), "Text", tostring(l2.Text))
	inner:Set("v"); print("  inner:Set('v') Text", tostring(l2.Text))
	outer:Set(q.None); print("  outer:Set(None) Text", tostring(l2.Text), "subs(inner)", nsubs(inner))
end)

sec("A11 State holding a Store / Modifier / Tag / Ref at property", function()
	local st = q.Store({ x = q.Source(1) })
	local s = q.Source(st)
	local l = D.TextLabel { Text = "init" }
	local ok, err = pcall(function() q.Dispatch.process(l, "Text", s, 1) end)
	print("  State<Store> at Text", ok, ok and "" or first(err), "Text", tostring(l.Text))
	local s2 = q.Source(q.Tag("x"))
	local ok2, err2 = pcall(function() q.Dispatch.process(D.TextLabel{}, "Text", s2, 1) end)
	print("  State<Tag> at Text", ok2, ok2 and "" or first(err2))
	local s3 = q.Source(q.Ref())
	local ok3, err3 = pcall(function() q.Dispatch.process(D.TextLabel{}, "Text", s3, 1) end)
	print("  State<Ref> at Text", ok3, ok3 and "" or first(err3))
	local s4 = q.Source(q.Source("in"))
	local l4 = D.TextLabel {}
	q.Dispatch.process(l4, "Text", s4, 1)
	local ok4, err4 = pcall(function() s4:Set(q.Modifier({ Text = "m" })) end)
	print("  State<State> -> Modifier Set", ok4, ok4 and "" or first(err4), "Text", tostring(l4.Text))
end)

sec("A12 store field is a State; store field holding a State", function()
	local st = q.Store({ x = q.Source("X") })
	local l = D.TextLabel { Text = st.x }
	local other = q.Source("O")
	st.x:Set(other); print("  st.x:Set(other) Text", l.Text)
	other:Set("O2"); print("  other:Set Text", l.Text)
	st.x:Set("back"); print("  st.x:Set(plain) Text", l.Text, "subs(other)", nsubs(other))
	local ok, err = pcall(function() return q.Store({ y = q.Source(q.Source("nested")) }) end)
	print("  Store{y = Source(Source)}", ok, ok and "" or first(err))
	if ok then local st2 = err; local l2 = D.TextLabel { Text = st2.y }; print("  Text", l2.Text) end
end)
