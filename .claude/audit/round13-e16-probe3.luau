--!nocheck
-- round13 E16 probe 3 (2026-09-27) — Ref/PreRef/PostRef/hooks × Slot/Claim/dispose. Run from repo root: luau .claude/audit/round13-e16-probe3.luau
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
local ev = {}
local function E() local s = table.concat(ev, " "); table.clear(ev); return s end
local function hooks(tag)
	return q.OnCreated(function(i) table.insert(ev, "C:" .. tag) end),
		q.OnRendered(function(i) table.insert(ev, "R:" .. tag) end),
		q.OnDestroyed(function() table.insert(ev, "D:" .. tag) end)
end
local function item(tag, ref)
	local c, r, d = hooks(tag)
	return D.Frame({ Name = tag, c, r, d, ref })
end

sec("R1 Slot element hooks across Add / Move / Swap / Extract / re-Add / Remove / Clear", function()
	local sl = q.Slot()
	local host = D.Frame({ sl })
	local refA = q.Ref(nil)
	local a, b = item("a", refA), item("b")
	print("  built", E())
	sl:Add(a); sl:Add(b); print("  Add a,b", E(), "refA==a", refA.Value == a)
	sl:Move(1, 2); print("  Move 1->2", E())
	sl:Swap(1, 2); print("  Swap", E())
	local ok, e = pcall(function() return sl:Extract(1) end)
	print("  Extract a", ok and "ok" or first(e), E(), "a destroyed", mock.isDestroyed(a), "refA==a", refA.Value == a)
	pcall(function() sl:Add(a) end); print("  re-Add a", E())
	sl:Remove(2); print("  Remove a", E(), "a destroyed", mock.isDestroyed(a), "refA==a (corpse)", refA.Value == a)
	sl:Clear(); print("  Clear", E())
end)

sec("R2 State<Instance> element swap: hooks + Ref of the swapped-out child", function()
	local r1 = q.Ref(nil)
	local c1, c2 = item("s1", r1), item("s2")
	E()
	local st = q.Source(c1)
	local host = D.Frame({ st })
	print("  mount", E())
	st:Set(c2); print("  swap to s2", E(), "c1 destroyed", mock.isDestroyed(c1), "c1.Parent", c1.Parent, "r1==c1", r1.Value == c1)
	st:Set(c1); print("  swap back to s1", E())
	host:Destroy(); print("  host Destroy", E())
end)

sec("R3 :List element hooks on reorder / key drop / remount", function()
	local data = q.Source({ "a", "b" })
	local sl = q.Slot():List(data, function(ctx) if ctx.Item == q.KeyGone then return nil end; if ctx.Prev then return ctx.Prev end; return item(ctx.Item) end, function(it) return it end)
	local host = D.Frame({ sl })
	print("  mount", E())
	data:Set({ "b", "a" }); print("  reorder", E())
	data:Set({ "b" }); print("  drop a", E())
	data:Set({ "b", "a" }); print("  re-add a (new?)", E())
	local d2 = q.Source({ "p" })
	local s2 = q.Slot():List(d2, function(ctx) if ctx.Item == q.KeyGone then return q.Detach end; if ctx.Prev then return ctx.Prev end; return item(ctx.Item) end, function(it) return it end)
	local h2 = D.Frame({ s2 }); E()
	d2:Set({}); print("  Detach p", E())
	d2:Set({ "p" }); print("  re-attach p", E())
	h2:Destroy(); print("  host Destroy (owner Slot of detached?)", E())
end)

sec("R4 OnDestroyed order among several on one instance (docs: numeric-key order)", function()
	local order = {}
	for trial = 1, 5 do
		table.clear(order)
		local list = {}
		for i = 1, 8 do list[i] = q.OnDestroyed(function() table.insert(order, i) end) end
		local f = D.Frame(list)
		f:Destroy()
		print("  trial", trial, table.concat(order, ","))
	end
	local f2 = D.Frame({ q.OnCreated(function() table.insert(order, "C1") end), q.OnRendered(function() table.insert(order, "R1") end), q.OnCreated(function() table.insert(order, "C2") end), q.OnRendered(function() table.insert(order, "R2") end) })
	print("  mixed C/R", table.concat(order, ",", 9))
end)

sec("R5 Claim: hooks & refs on a pre-existing instance (Parent already set)", function()
	local parent = Instance.new("Frame")
	local root = Instance.new("Frame"); root.Parent = parent
	local kid = Instance.new("TextLabel"); kid.Name = "Title"; kid.Parent = root
	local M = q.Declaration.Mapper
	local pre, post = q.PreRef(nil), q.PostRef(nil)
	local parentAtPost
	post:Callback(function(i) if i then parentAtPost = i.Parent end end)
	local c, r, d = hooks("claim")
	q.Claim(root, M.Frame(M.Root)({ pre, post, c, r, d, M.TextLabel("Title")({ item and q.OnCreated(function(i) table.insert(ev, "C:kid") end) }) }))
	print("  claim", E(), "pre==root", pre.Value == root, "Parent at post==parent", parentAtPost == parent)
	root:Destroy(); print("  root Destroy", E())
end)

sec("R6 Ref across component boundary (parent passes props.Ref, child places in root and nested)", function()
	local function Child(props) return D.Frame({ props.Ref, D.TextLabel({ props.Inner }) }) end
	local outer, inner = q.Ref(nil), q.Ref(nil)
	local c = Child({ Ref = outer, Inner = inner })
	print("  outer==c", outer.Value == c, "inner is TextLabel", inner.Value and inner.Value.ClassName)
	try("same Ref passed to two Child calls", function() Child({ Ref = outer, Inner = q.Ref(nil) }) end)
	try("None for optional Ref", function() Child({ Ref = None, Inner = None }) end)
	try("nil for optional Ref (hole)", function() Child({ Ref = nil, Inner = q.Ref(nil) }) end)
end)

sec("R7 State<Ref> a -> b order of callbacks; -> None; Ref Wait woken with nil", function()
	local a, b = q.Ref(nil), q.Ref(nil)
	a:Callback(function(v) table.insert(ev, "a:" .. (v and "inst" or "nil")) end)
	b:Callback(function(v) table.insert(ev, "b:" .. (v and "inst" or "nil")) end)
	E()
	local st = q.Source(a)
	local f = D.Frame({ st })
	print("  mount", E())
	st:Set(b); print("  a->b", E())
	st:Set(None); print("  ->None", E())
	st:Set(a); print("  ->a", E())
	q.dispose(f); print("  q.dispose host", E(), "a.Value==f", a.Value == f)
end)

sec("R8 Ref at a string key / PreRef through State (doc core/07 lists Quad0076 for Ref at unhandled string key)", function()
	try("D.Frame{ Foo = Ref }", function() D.Frame({ Foo = q.Ref(nil) }) end)
	try("D.Frame{ Size = Ref }", function() D.Frame({ Size = q.Ref(nil) }) end)
	try("State<PreRef> at [1]", function() D.Frame({ q.Source(q.PreRef(nil)) }) end)
	try("State<PostRef> at [1]", function() D.Frame({ q.Source(q.PostRef(nil)) }) end)
	try("Modifier{ OnDestroyed }", function() q.Modifier({ q.OnDestroyed(function() end) }) end)
	try("Modifier{ Foo = OnDestroyed }", function() q.Modifier({ Foo = q.OnDestroyed(function() end) }) end)
end)

sec("R8b guard subjects at hash keys + Size = Ref runtime", function()
	try("Foo = PreRef", function() D.Frame({ Foo = q.PreRef(nil) }) end)
	try("Foo = PostRef", function() D.Frame({ Foo = q.PostRef(nil) }) end)
	try("Foo = OnCreated", function() D.Frame({ Foo = q.OnCreated(function() end) }) end)
	local r = q.Ref(nil)
	local f = D.Frame({ Size = r })
	print("  Size = Ref -> f.Size is the Ref table:", f.Size == r, "r.Value", r.Value)
	print("  handlers:"); for _, h in q.Dispatch.listHandlers() do if (h.name or ""):find("Guard") then print("    ", h.name, h.priority) end end
end)

sec("R9 hook factories reused: one OnDestroyed Effect on two instances; one OnCreated on two", function()
	local d = q.OnDestroyed(function() table.insert(ev, "D") end)
	local x = D.Frame({ d })
	try("same OnDestroyed on 2nd inst", function() D.Frame({ d }) end)
	local c = q.OnCreated(function() table.insert(ev, "C") end)
	local y = D.Frame({ c })
	try("same OnCreated on 2nd inst", function() D.Frame({ c }) end)
	x:Destroy(); print("  x Destroy", E())
	try("OnDestroyed reuse after its host died", function() local z = D.Frame({ d }); z:Destroy() end)
	print("  ", E())
end)

sec("R10 dispose / Destroy of an instance whose PreRef/PostRef/hooks: .Value retained?", function()
	local pre, post = q.PreRef(nil), q.PostRef(nil)
	local f = D.Frame({ pre, post })
	q.dispose(f)
	print("  pre==f", pre.Value == f, "post==f", post.Value == f)
	local wk = setmetatable({ f }, { __mode = "v" }); f = nil
	collectgarbage("collect"); collectgarbage("collect")
	print("  corpse collectible while pre/post alive?", wk[1] == nil)
end)

sec("R11 Claim resolution failure: PreRef/PostRef/Ref at root not consumed? retry with same", function()
	local root = Instance.new("Frame")
	local M = q.Declaration.Mapper
	local pre, post, r = q.PreRef(nil), q.PostRef(nil), q.Ref(nil)
	try("claim with missing child", function() q.Claim(root, M.Frame(M.Root)({ pre, post, r, M.TextLabel("Nope")({}) })) end)
	print("  pre._fired", pre._fired, "post._fired", post._fired, "r.Value", r.Value)
	try("retry same refs, fixed", function() q.Claim(root, M.Frame(M.Root)({ pre, post, r })) end)
	print("  pre==root", pre.Value == root, "post==root", post.Value == root, "r==root", r.Value == root)
end)
