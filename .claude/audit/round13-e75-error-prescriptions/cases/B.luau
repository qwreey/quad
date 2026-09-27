--!nocheck
-- E75 group B: docs/reference/errors/02-dispatch-bookkeeping.md (44 sections)
local H = require("../harness")
local R = require("../runner")
local q, D = H.q, H.D
local BK = q.Bookkeeping
local DP = q.Dispatch

local function owner() return D.Frame({}) end

-- ===== Bookkeeping =====
R.case({ id = "Quad0019",
	trigger = function() local f = owner(); BK.setEmpty(f, 0) end,
	fix = function()
		local f = owner(); BK.setEmpty(f, 1)
		return BK.getOffsetAt(f, 2) == 0, "offset@2=" .. tostring(BK.getOffsetAt(f, 2))
	end })
R.case({ id = "Quad0019", note = "b: getOffsetAt(f, 1.5)",
	trigger = function() local f = owner(); BK.setEmpty(f, 1); return BK.getOffsetAt(f, 1.5) end,
	fix = function() local f = owner(); BK.setEmpty(f, 1); return BK.getOffsetAt(f, 1) == 0, "offset@1=" .. tostring(BK.getOffsetAt(f, 1)) end })

R.case({ id = "Quad0020",
	trigger = function() BK.getBlocker(nil) end,
	fix = function() local f = owner(); local b = BK.getBlocker(f); return b ~= nil and BK.getBlocker(f) == b, "blocker stable" end })

R.case({ id = "Quad0021", note = "a: constant",
	trigger = function() local f = owner(); BK.setOffsetSource(f, 1, q.None); BK.setLength(f, 1, -1) end,
	fix = function()
		local f = owner(); BK.setOffsetSource(f, 1, q.None); BK.setLength(f, 1, 2)
		BK.setEmpty(f, 2)
		return BK.getOffsetAt(f, 2) == 2, "offset@2=" .. tostring(BK.getOffsetAt(f, 2))
	end })
R.case({ id = "Quad0021", note = "b: State value turns 1.5",
	trigger = function()
		local f = owner(); local len = q.Source(1)
		BK.setOffsetSource(f, 1, q.None); BK.setLength(f, 1, len)
		len:Set(1.5)
	end,
	fix = function()
		local f = owner(); local len = q.Source(1)
		BK.setOffsetSource(f, 1, q.None); BK.setLength(f, 1, len); BK.setEmpty(f, 2)
		len:Set(3)
		return BK.getOffsetAt(f, 2) == 3, "offset@2=" .. tostring(BK.getOffsetAt(f, 2))
	end })

-- 0022 a: query past N+1 on fresh owner; fix literal "setLength로 먼저 등록"
R.case({ id = "Quad0022", note = "a: getOffsetAt(f,3) fresh; fix = register 1..2 with setLength (literal first arm)",
	trigger = function() local f = owner(); return BK.getOffsetAt(f, 3) end,
	fix = function()
		local f = owner()
		BK.setLength(f, 1, 2); BK.setLength(f, 2, 3)
		return BK.getOffsetAt(f, 3) == 5, "offset@3=" .. tostring(BK.getOffsetAt(f, 3))
	end })
R.case({ id = "Quad0022", note = "b: same; fix = register 1..2 with setEmpty (second arm)",
	trigger = function() local f = owner(); return BK.getOffsetAt(f, 3) end,
	fix = function()
		local f = owner()
		BK.setEmpty(f, 1); BK.setEmpty(f, 2)
		return BK.getOffsetAt(f, 3) == 0, "offset@3=" .. tostring(BK.getOffsetAt(f, 3))
	end })
R.case({ id = "Quad0022", note = "c: nonzero lengths, handler order setOffsetSource→setLength per position (contract order)",
	trigger = function() local f = owner(); return BK.getOffsetAt(f, 3) end,
	fix = function()
		local f = owner()
		BK.setOffsetSource(f, 1, q.None); BK.setLength(f, 1, 2)
		BK.setOffsetSource(f, 2, q.None); BK.setLength(f, 2, 3)
		return BK.getOffsetAt(f, 3) == 5, "offset@3=" .. tostring(BK.getOffsetAt(f, 3))
	end })
R.case({ id = "Quad0022", note = "d: setOffsetSource(f,3,src) fresh; fix = setEmpty 1..2 first",
	trigger = function() local f = owner(); BK.setOffsetSource(f, 3, q.Source(-1)) end,
	fix = function()
		local f = owner(); local src = q.Source(-1)
		BK.setEmpty(f, 1); BK.setEmpty(f, 2)
		BK.setOffsetSource(f, 3, src); BK.setLength(f, 3, 1)
		return src:Get() == 0, "src=" .. tostring(src:Get())
	end })
R.case({ id = "Quad0022", note = "e: range fix — query within 1..N+1",
	trigger = function() local f = owner(); BK.setEmpty(f, 1); return BK.getOffsetAt(f, 3) end,
	fix = function() local f = owner(); BK.setEmpty(f, 1); return BK.getOffsetAt(f, 2) == 0, "offset@2 ok" end })

R.case({ id = "Quad0023", note = "a: user { a, nil, b }",
	trigger = function()
		local a, b = D.TextLabel({ Text = "a" }), D.TextLabel({ Text = "b" })
		D.Frame({ a, nil, b })
	end,
	fix = function()
		local a, b = D.TextLabel({ Text = "a" }), D.TextLabel({ Text = "b" })
		local f = D.Frame({ a, q.None, b })
		return #f:GetChildren() == 2 and a.Parent == f and b.Parent == f, "children=" .. #f:GetChildren()
	end })
R.case({ id = "Quad0023", note = "b: handler setLength without setOffsetSource",
	trigger = function() local f = owner(); BK.setLength(f, 1, 1) end,
	fix = function()
		local f = owner(); BK.setOffsetSource(f, 1, q.None); BK.setLength(f, 1, 1)
		return BK.getOffsetAt(f, 2) == 1, "offset@2=" .. tostring(BK.getOffsetAt(f, 2))
	end })

R.case({ id = "Quad0024",
	trigger = function() local f = owner(); BK.setOffsetSource(f, 1, q.None); BK.setEmpty(f, 2) end,
	fix = function()
		local f = owner(); BK.setOffsetSource(f, 1, q.None); BK.setLength(f, 1, 1); BK.setEmpty(f, 2)
		return BK.getOffsetAt(f, 3) == 1, "offset@3=" .. tostring(BK.getOffsetAt(f, 3))
	end })

R.case({ id = "Quad0025",
	trigger = function() local f = owner(); BK.setOffsetSource(f, 1, { Value = 0 }) end,
	fix = function()
		local f = owner(); local s1, s2 = q.Source(-1), q.Source(-1)
		BK.setOffsetSource(f, 1, s1); BK.setLength(f, 1, 2)
		BK.setOffsetSource(f, 2, s2); BK.setLength(f, 2, 1)
		return s1:Get() == 0 and s2:Get() == 2, ("s1=%s s2=%s"):format(tostring(s1:Get()), tostring(s2:Get()))
	end })

R.case({ id = "Quad0229",
	trigger = function()
		local f = owner(); local b = BK.getBlocker(f); b:On()
		BK.setOffsetSource(f, 3, q.None); BK.setLength(f, 3, 0)
		b:OffWithoutEmit()
		return BK.getOffsetAt(f, 2)
	end,
	fix = function()
		local f = owner(); local b = BK.getBlocker(f); b:On()
		BK.setEmpty(f, 1); BK.setOffsetSource(f, 2, q.None); BK.setLength(f, 2, 4)
		BK.setOffsetSource(f, 3, q.None); BK.setLength(f, 3, 0)
		b:OffWithoutEmit()
		return BK.getOffsetAt(f, 3) == 4, "offset@3=" .. tostring(BK.getOffsetAt(f, 3))
	end })

-- ===== Modifier =====
R.case({ id = "Quad0049",
	trigger = function() local m = q.Modifier({ Visible = false }); return m:Peek(1) end,
	fix = function() local m = q.Modifier({ Visible = false }); return m:Peek("Visible") == false, "Peek=" .. tostring(m:Peek("Visible")) end })
R.case({ id = "Quad0050",
	trigger = function() local m = q.Modifier(); return m:Apply(5) end,
	fix = function()
		local m = q.Modifier():Apply(function(mm) return mm:Visible(false) end)
		return m:Peek("Visible") == false, "Peek=" .. tostring(m:Peek("Visible"))
	end })
R.case({ id = "Quad0051",
	trigger = function() return q.Modifier({ Visible = false }):As(5) end,
	fix = function()
		local m1 = q.Modifier({ Visible = false }):As("Frame")
		local m2 = q.Modifier({ Visible = false }):As()
		local f = D.Frame({ m1 }); local g = D.Frame({ m2 })
		return f.Visible == false and g.Visible == false, "both applied"
	end })
R.case({ id = "Quad0052",
	trigger = function() return q.Modifier():As("E75Btn") end,
	fix = function()
		q.Modifier.TypedFactory("E75Btn")
		local m = q.Modifier({ Visible = false }):As("E75Btn")
		local m2 = m:AsE75Btn()
		return m2:Peek("Visible") == false, "cast ok"
	end })
R.case({ id = "Quad0052", note = "b: DefineSubtype arm",
	trigger = function() return q.Modifier():As("E75Card") end,
	fix = function()
		q.Modifier.DefineSubtype("Frame", "E75Card")
		local m = q.Modifier({ Visible = false }):As("E75Card")
		local down = D.Modifier.Frame({ Visible = false }):AsE75Card() -- checked downcast Frame -> E75Card
		return m:Peek("Visible") == false and down:Peek("Visible") == false, "As(name) + downcast ok"
	end })
R.case({ id = "Quad0053",
	trigger = function() return q.Modifier.Overridden() end,
	fix = function() local m = q.Modifier.Overridden(q.Modifier({ Visible = false })); return m:Peek("Visible") == false, "ok" end })
R.case({ id = "Quad0053", note = "b: colon form claimed in page to NOT raise",
	trigger = function() local r = q.Modifier():Overridden(); return "no error: " .. tostring(r) end,
	fixnote = "page says colon form doesn't raise — expect TRIG=noerr" })
R.case({ id = "Quad0054",
	trigger = function() return q.Modifier.Overridden(q.Modifier({ Visible = true }), { Visible = false }) end,
	fix = function()
		local a = q.Modifier.Overridden(q.Modifier({ Visible = true }), q.Modifier({ Visible = false }))
		local b = q.Modifier(q.Modifier({ Visible = true }), { Visible = false })
		return a:Peek("Visible") == false and b:Peek("Visible") == false, "later wins in both"
	end })
R.case({ id = "Quad0055", note = "a: register first",
	trigger = function() return q.Modifier():AsE75Unreg() end,
	fix = function() q.Modifier.TypedFactory("E75Unreg"); local m = q.Modifier({ Visible = false }):AsE75Unreg(); return m:Peek("Visible") == false, "cast ok" end })
R.case({ id = "Quad0055", note = "b: message hint :As(name) — page says it raises Quad0052",
	trigger = function() return q.Modifier():AsE75Unreg2() end,
	fix = function()
		local raised, msg = R.raises(function() return q.Modifier():As("E75Unreg2") end, "Quad0052")
		return raised, "page claim (0052) holds: " .. tostring(msg)
	end, fixnote = "" })
R.case({ id = "Quad0056", note = "a: force with :As(name)",
	trigger = function()
		local A = q.Modifier.TypedFactory("E75A"); q.Modifier.TypedFactory("E75B")
		return A({ Visible = false }):AsE75B()
	end,
	fix = function()
		local A = q.Modifier.TypedFactory("E75A")
		local m = A({ Visible = false }):As("E75B")
		local m2 = m:AsE75B() -- now tag is E75B
		return m2:Peek("Visible") == false, "forced"
	end })
R.case({ id = "Quad0056", note = "b: fix the ancestry (DefineSubtype) then checked cast",
	trigger = function()
		local A = q.Modifier.TypedFactory("E75C"); q.Modifier.TypedFactory("E75P")
		return A({ Visible = false }):AsE75P()
	end,
	fix = function()
		local A = q.Modifier.TypedFactory("E75C")
		q.Modifier.DefineSubtype("E75C", "E75P") -- E75P ⊂ E75C: casting a C modifier to P is a downcast
		local m = A({ Visible = false }):AsE75P()
		return m:Peek("Visible") == false, "upcast ok"
	end })
R.case({ id = "Quad0057",
	trigger = function() return q.Modifier():Hook(q.PreRef(nil)) end,
	fix = function()
		local r = q.PreRef(nil)
		local m = q.Modifier({ Visible = false })
		local f = D.Frame({ m, r })
		return r.Value == f and f.Visible == false, "PreRef set=" .. tostring(r.Value == f)
	end })
R.case({ id = "Quad0058",
	trigger = function() local k = q.AttrKey("Hp"); return q.Modifier()[k](q.Modifier(), 5) end,
	fix = function()
		local k = q.AttrKey("Hp")
		local f = D.Frame({ [k] = 5 })
		return f:GetAttribute("Hp") == 5, "Hp=" .. tostring(f:GetAttribute("Hp"))
	end })
R.case({ id = "Quad0059",
	trigger = function() return q.Modifier({ [1] = 5 }) end,
	fix = function() local m = q.Modifier({ LayoutOrder = 5 }); local f = D.Frame({ m }); return f.LayoutOrder == 5, "LayoutOrder=" .. tostring(f.LayoutOrder) end })
R.case({ id = "Quad0059", note = "b: empty string key",
	trigger = function() return q.Modifier({ [""] = 5 }) end,
	fix = function() local m = q.Modifier({ LayoutOrder = 5 }); return m:Peek("LayoutOrder") == 5, "ok" end })
R.case({ id = "Quad0060",
	trigger = function() return q.Modifier({ Peek = 1 }) end,
	fix = function() local m = q.Modifier({ PeekValue = 1 }); return m:Peek("PeekValue") == 1, "renamed field held" end,
	fixnote = "" })
R.case({ id = "Quad0061",
	trigger = function() return q.Modifier({ AsFoo = 1 }) end,
	fix = function() local m = q.Modifier({ Foo = 1 }); return m:Peek("Foo") == 1, "renamed" end })
R.case({ id = "Quad0062",
	trigger = function() return q.Modifier({ __apply = 1 }) end,
	fix = function() local m = q.Modifier({ Apply1 = 1 }); return m:Peek("Apply1") == 1, "renamed" end })
R.case({ id = "Quad0063", note = "a: event handler → inline key on Declaration",
	trigger = function() return q.Modifier({ Activated = function() end }) end,
	fix = function()
		local n = 0
		local m = q.Modifier({ Text = "x" })
		local b = D.TextButton({ m, Activated = function() n += 1 end })
		b.Activated:Fire()
		return n == 1 and b.Text == "x", "fired " .. n
	end })
R.case({ id = "Quad0063", note = "b: event handler → wrap in a State (inside the Modifier)",
	trigger = function() return q.Modifier({ Activated = function() end }) end,
	fix = function()
		local n = 0
		local m = q.Modifier({ Activated = q.Source(function() n += 1 end) })
		local b = D.TextButton({ m })
		b.Activated:Fire()
		return n == 1, "fired " .. n
	end })
R.case({ id = "Quad0063", note = "c: transform → mod:{k}(fn)",
	trigger = function() return q.Modifier({ LayoutOrder = function(old) return (old or 0) + 1 end }) end,
	fix = function()
		local m = q.Modifier({ LayoutOrder = 1 }):LayoutOrder(function(old) return (old or 0) + 1 end)
		return m:Peek("LayoutOrder") == 2, "LayoutOrder=" .. tostring(m:Peek("LayoutOrder"))
	end })
R.case({ id = "Quad0064",
	trigger = function() return q.Modifier({ Ref = q.PreRef(nil) }) end,
	fix = function()
		local r = q.PreRef(nil)
		local f = D.Frame({ q.Modifier({ Visible = false }), r })
		return r.Value == f and f.Visible == false, "set"
	end })
R.case({ id = "Quad0065",
	trigger = function() return q.Modifier(q.Source(1)) end,
	fix = function() local m = q.Modifier({ LayoutOrder = q.Source(1) }); local f = D.Frame({ m }); return f.LayoutOrder == 1, "LayoutOrder=" .. tostring(f.LayoutOrder) end })
R.case({ id = "Quad0066",
	trigger = function() return q.Modifier.TypedFactory("") end,
	fix = function() local c = q.Modifier.TypedFactory("E75Named"); return type(c) == "function", "ctor" end })
R.case({ id = "Quad0066", note = "b: DefineSubtype parent non-string",
	trigger = function() return q.Modifier.DefineSubtype(5, "E75X") end,
	fix = function() q.Modifier.DefineSubtype("E75Base", "E75X"); local m = q.Modifier.TypedFactory("E75Base")({}):AsE75X(); return m ~= nil, "ok" end })
R.case({ id = "Quad0067",
	trigger = function() q.Modifier.DefineSubtype("E75Y", "E75Z"); q.Modifier.DefineSubtype("E75Z", "E75Y") end,
	fix = function() q.Modifier.DefineSubtype("E75Y2", "E75Z2"); local m = q.Modifier.TypedFactory("E75Y2")({}):AsE75Z2(); return m ~= nil, "one direction" end })
R.case({ id = "Quad0068", note = "a: string key",
	trigger = function() D.Frame({ Style = q.Modifier({ Visible = false }) }) end,
	fix = function() local f = D.Frame({ q.Modifier({ Visible = false }) }); return f.Visible == false, "Visible=" .. tostring(f.Visible) end })
R.case({ id = "Quad0068", note = "b: sparse numeric [5]",
	trigger = function() D.Frame({ [5] = q.Modifier({ Visible = false }) }) end,
	fix = function() local f = D.Frame({ [1] = q.Modifier({ Visible = false }) }); return f.Visible == false, "ok" end })

-- ===== Ref / StoreBind =====
R.case({ id = "Quad0069",
	trigger = function() local p = q.PreRef(nil); D.Frame({ p }); D.Frame({ p }) end,
	fix = function()
		local ra, rb = q.PreRef(nil), q.PreRef(nil)
		local a = D.Frame({ ra }); local b = D.Frame({ rb })
		return ra.Value == a and rb.Value == b, "both set"
	end })
R.case({ id = "Quad0069", note = "b: PostRef, same props twice",
	trigger = function() local p = q.PostRef(nil); D.Frame({ p, p }) end,
	fix = function() local r1, r2 = q.PostRef(nil), q.PostRef(nil); local f = D.Frame({ r1, r2 }); return r1.Value == f and r2.Value == f, "both set" end })
R.case({ id = "Quad0070",
	trigger = function() local a, b = q.Source(true), q.Source(true); a:Set(b); b:Set(a); D.Frame({ Visible = a }) end,
	fix = function() local a, b = q.Source(true), q.Source(false); a:Set(b); local f = D.Frame({ Visible = a }); b:Set(true); local v1 = f.Visible; b:Set(false); return v1 == true and f.Visible == false, "reactive through chain" end })

-- ===== Dispatch =====
-- 0071: attempt via a public handler whose retractor re-enters retractFrom on the same key
R.case({ id = "Quad0071", note = "via addHandler: inner retractor calls q.Dispatch.retractFrom(inst,k,1) (same-key re-entry)",
	trigger = function()
		local KEY = "E75ReKey"
		local busy = false
		DP.addHandler({ name = "E75Outer", priority = DP.HANDLER_PRIORITY_HIGH + 7, keyType = "string",
			isHandlable = function(_, k, v) return k == KEY and type(v) == "table" and v.wrap ~= nil end,
			process = function(inst, k, v, index) DP.process(inst, k, v.wrap, index + 1); return q.Void end })
		DP.addHandler({ name = "E75Inner", priority = DP.HANDLER_PRIORITY_HIGH + 6, keyType = "string",
			isHandlable = function(_, k, v) return k == KEY and v == "leaf" end,
			process = function(inst, k, v, index)
				return function()
					if busy then return end
					busy = true
					DP.retractFrom(inst, k, 1)
					busy = false
				end
			end })
		local f = owner()
		DP.process(f, KEY, { wrap = "leaf" }, 1)
		DP.retractFrom(f, KEY, 1)
	end,
	fixnote = "page: (문서 미정) 리포트 — no prescription to apply" })

R.case({ id = "Quad0072",
	trigger = function() DP.process(nil, "Visible", false, 1) end,
	fix = function() local f = owner(); DP.process(f, "Visible", false, 1); return f.Visible == false, "Visible=" .. tostring(f.Visible) end })
R.case({ id = "Quad0072", note = "b: getHandler",
	trigger = function() return DP.getHandler(nil, "Visible", false) end,
	fix = function() return DP.getHandler(owner(), "Visible", false) ~= nil, "handler" end })
R.case({ id = "Quad0073",
	trigger = function() DP.process(owner(), "Visible", false, 0) end,
	fix = function() local f = owner(); DP.process(f, "Visible", false, 1); return f.Visible == false, "ok" end })
R.case({ id = "Quad0074",
	trigger = function() DP.process(owner(), nil, false, 1) end,
	fix = function() local f = owner(); DP.process(f, "Visible", false, 1); return f.Visible == false, "ok" end })
R.case({ id = "Quad0075", note = "delegating handler passes index+2",
	trigger = function()
		DP.addHandler({ name = "E75Skip", priority = DP.HANDLER_PRIORITY_HIGH + 5, keyType = "string",
			isHandlable = function(_, k, v) return k == "Visible" and type(v) == "table" and v.skip ~= nil end,
			process = function(inst, k, v, index) DP.process(inst, k, v.skip, index + 2); return q.Void end })
		D.Frame({ Visible = { skip = false } })
	end,
	fix = function()
		DP.addHandler({ name = "E75Skip1", priority = DP.HANDLER_PRIORITY_HIGH + 4, keyType = "string",
			isHandlable = function(_, k, v) return k == "Visible" and type(v) == "table" and v.skip1 ~= nil end,
			process = function(inst, k, v, index) DP.process(inst, k, v.skip1, index + 1); return q.Void end })
		local f = D.Frame({ Visible = { skip1 = false } })
		return f.Visible == false, "Visible=" .. tostring(f.Visible)
	end })
R.case({ id = "Quad0076", note = "a: typo prop name (provider installed)",
	trigger = function() D.Frame({ Visibel = false }) end,
	fix = function() local f = D.Frame({ Visible = false }); return f.Visible == false, "ok" end })
R.case({ id = "Quad0076", note = "b: Parent in props",
	trigger = function() local p = D.Frame({}); D.Frame({ Parent = p }) end,
	fix = function() local p = D.Frame({}); local c = D.Frame({}); c.Parent = p; return c.Parent == p, "parented" end })
R.case({ id = "Quad0076", note = "c: quad value (Tag) at string key",
	trigger = function() D.Frame({ Tags = q.Tag("Enemy") }) end,
	fix = function() local f = D.Frame({ q.Tag("Enemy") }); return H.CollectionService:HasTag(f, "Enemy"), "tagged" end })
R.case({ id = "Quad0076", note = "d: Store at a key",
	trigger = function() local s = q.Store({ Name = q.Source("x") }); D.Frame({ s }) end,
	fix = function() local s = q.Store({ Name = q.Source("x") }); local f = D.Frame({ Name = s.Name }); return f.Name == "x", "Name=" .. tostring(f.Name) end })
R.case({ id = "Quad0076", note = "e: Store at string key; literal page fix = move it to a numeric (array) key",
	trigger = function() local s = q.Store({ Name = q.Source("x") }); D.Frame({ Info = s }) end,
	fix = function()
		local s = q.Store({ Name = q.Source("x") })
		local ok, e = pcall(function() D.Frame({ s }) end)
		if not ok then error(e, 0) end
		return true, "array ok"
	end })
R.case({ id = "Quad0076", note = "f: Store — message hint arm q.Attr(store)",
	trigger = function() local s = q.Store({ Name = q.Source("x") }); D.Frame({ Info = s }) end,
	fix = function() local s = q.Store({ Hp = q.Source(3) }); local f = D.Frame({ q.Attr(s) }); return f:GetAttribute("Hp") == 3, "Hp=" .. tostring(f:GetAttribute("Hp")) end })
R.case({ id = "Quad0077",
	trigger = function()
		DP.addHandler({ name = "E75NoRet", priority = DP.HANDLER_PRIORITY_NORMAL + 3, keyType = "string",
			isHandlable = function(_, k) return k == "E75NoRetKey" end,
			process = function() return nil end })
		DP.process(owner(), "E75NoRetKey", 1, 1)
	end,
	fix = function()
		local log = {}
		DP.addHandler({ name = "E75Ret", priority = DP.HANDLER_PRIORITY_NORMAL + 2, keyType = "string",
			isHandlable = function(_, k) return k == "E75RetKey" end,
			process = function(_, _, v) table.insert(log, v); return q.Void end })
		local f = owner(); DP.process(f, "E75RetKey", 1, 1); DP.process(f, "E75RetKey", 2, 1); DP.retractFrom(f, "E75RetKey", 1)
		return #log == 2, "processed " .. #log
	end })
R.case({ id = "Quad0079",
	trigger = function() DP.addHandler({ isHandlable = function() return false end, process = function() return q.Void end }) end,
	fix = function()
		local h = { name = "E75Shape", isHandlable = function(_, k) return k == "E75ShapeKey" end, process = function() return q.Void end, priority = DP.HANDLER_PRIORITY_NORMAL + 1, keyType = "string" }
		DP.addHandler(h)
		return DP.getHandler(owner(), "E75ShapeKey", 1) == h, "registered+matched"
	end })
R.case({ id = "Quad0080",
	trigger = function() DP.addHandler({ isHandlable = function() return false end, process = function() return q.Void end, priority = 0 / 0 }) end,
	fix = function()
		local h = { name = "E75Fin", isHandlable = function(_, k) return k == "E75FinKey" end, process = function() return q.Void end, priority = DP.HANDLER_PRIORITY_LOW + 1 }
		DP.addHandler(h)
		return DP.getHandler(owner(), "E75FinKey", 1) == h, "matched"
	end })
R.case({ id = "Quad0081",
	trigger = function() DP.addHandler({ isHandlable = function() return false end, process = function() return q.Void end, priority = 1, keyType = "numbr" }) end,
	fix = function()
		local h = { name = "E75Kt", isHandlable = function(_, k) return k == "E75KtKey" end, process = function() return q.Void end, priority = DP.HANDLER_PRIORITY_NORMAL + 9, keyType = "string" }
		DP.addHandler(h)
		return DP.getHandler(owner(), "E75KtKey", 1) == h, "matched"
	end })
R.case({ id = "Quad0082",
	trigger = function() DP.drive(owner(), 5) end,
	fix = function() local f = owner(); DP.drive(f, { Visible = false }); return f.Visible == false, "ok" end })
R.case({ id = "Quad0083", note = "a: page example D.Frame(q.Source(1)) → D.Frame { q.Source(1) }",
	trigger = function() return D.Frame(q.Source(1)) end,
	fix = function() local f = D.Frame({ q.Source(1) }); return f ~= nil, "built" end })
R.case({ id = "Quad0083", note = "b: realistic — D.Frame(q.Attr{Hp=1}) → D.Frame { q.Attr{Hp=1} }",
	trigger = function() return D.Frame(q.Attr({ Hp = 1 })) end,
	fix = function() local f = D.Frame({ q.Attr({ Hp = 1 }) }); return f:GetAttribute("Hp") == 1, "Hp=" .. tostring(f:GetAttribute("Hp")) end })
R.case({ id = "Quad0083", note = "c: forgotten braces around a child D.Frame(D.TextLabel{})",
	trigger = function() return D.Frame(D.TextLabel({ Text = "a" })) end,
	fix = function() local c = D.TextLabel({ Text = "a" }); local f = D.Frame({ c }); return c.Parent == f, "child" end })
R.case({ id = "Quad0084",
	trigger = function() DP.drive(nil, {}) end,
	fix = function() local f = owner(); DP.drive(f, { Visible = false }); return f.Visible == false, "ok" end })
R.case({ id = "Quad0085",
	trigger = function() local c = D.TextLabel({ Text = "a" }); D.Frame({ [0] = c }) end,
	fix = function() local c = D.TextLabel({ Text = "a" }); local f = D.Frame({ [1] = c }); return c.Parent == f, "child" end })
R.done()
