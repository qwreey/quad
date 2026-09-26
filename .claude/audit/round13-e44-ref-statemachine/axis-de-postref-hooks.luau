--!nocheck
-- axis (d) PostRef consumed without firing; (e) lifecycle hooks on top of the Ref state machine
local H = require("./harness")
local q, D = H.q, H.D
local UDim2 = H.EG.UDim2
local function id(e) return tostring(e):match("Quad%d%d%d%d") or ("RAW:" .. H.first(e)) end
local function thrower() return q.Ref(nil):Callback(function(v) if v ~= nil then error("boom", 0) end end) end
local function fires(p) local n = 0; p:Callback(function(v) if v ~= nil then n += 1 end end); return function() return n end end
local function reuse(p)
	local ok, e = pcall(function() return D.Frame { p } end)
	return ok and "reusable" or id(e)
end
local function case(label, build, p)
	local n = fires(p)
	local ok, e = pcall(build)
	print(label, "build:", ok and "ok" or id(e), "| fired:", n(), "| _fired:", p._fired, "| reuse:", reuse(p))
end

do local p = q.PostRef(nil); case("d1 {post, throwingRef}", function() return D.Frame { p, thrower() } end, p) end
do local p = q.PostRef(nil); case("d2 {throwingPreRef, post}", function() return D.Frame { q.PreRef(nil):Callback(function(v) if v then error("boom", 0) end end), p } end, p) end
do local p = q.PostRef(nil); case("d3 {post, throwingPreRef}", function() return D.Frame { p, q.PreRef(nil):Callback(function(v) if v then error("boom", 0) end end) } end, p) end
do local p = q.PostRef(nil); case("d4 {throwingRef, post} (post after throw pos)", function() return D.Frame { thrower(), p } end, p) end
do local p = q.PostRef(nil); case("d5 State<PostRef>", function() return D.Frame { q.Source(p) } end, p) end
do local p = q.PostRef(nil); case("d6 string key", function() return D.Frame { Foo = p } end, p) end
do local p = q.PostRef(nil); case("d7 {p, p}", function() return D.Frame { p, p } end, p) end
do
	local p = q.PostRef(nil)
	local n = fires(p)
	local safe = q.Fallback(function() return D.Frame { p, thrower() } end, function() return "fallback" end)
	print("d8 Fallback boundary:", safe(), "| fired:", n(), "| reuse:", reuse(p))
end
do -- d9: PreRef callback destroys the instance before the body runs ("마운트 전 파괴")
	local p = q.PostRef(nil)
	local got
	p:Callback(function(v) if v then got = v end end)
	local ok, e = pcall(function()
		return D.Frame { q.PreRef(nil):Callback(function(v) if v then v:Destroy() end end), p, D.Frame {}, Size = UDim2.fromOffset(1, 1) }
	end)
	print("d9 PreRef destroys inst:", ok and "ok" or id(e), "| PostRef fired:", got ~= nil, got and ("Parent-destroyed? " .. tostring(got.Parent)))
end
do -- d10: PostRef callback that throws: fired flag + remaining PostRefs
	local p1, p2 = q.PostRef(nil), q.PostRef(nil)
	p1:Callback(function(v) if v then error("boom", 0) end end)
	local n2 = fires(p2)
	local ok, e = pcall(function() return D.Frame { p1, p2 } end)
	print("d10 first PostRef throws:", ok and "ok" or id(e), "| second fired:", n2(), "| second reuse:", reuse(p2))
end
do -- d11: plain Ref after a thrown build: dispose orphan -> reusable (core/07:70)
	local r = q.Ref(nil)
	pcall(function() return D.Frame { r, thrower() } end)
	local orphan = r.Value
	print("d11 Ref bound to orphan:", orphan ~= nil, "| reuse:", reuse(q.Ref(nil)) )
	local ok, e = pcall(function() return D.Frame { r } end)
	print("d11 re-place before dispose:", ok and "ok" or id(e))
	q.dispose(orphan)
	local ok2, e2 = pcall(function() return D.Frame { r } end)
	print("d11 re-place after dispose:", ok2 and "ok" or id(e2))
end

-- (e) hooks
do
	local log = {}
	local plain = q.Ref(nil):Callback(function(v) if v then table.insert(log, "Ref(size=" .. tostring(v.Size) .. ")") end end)
	local child
	local f = D.Frame {
		q.OnRendered(function(inst) table.insert(log, "R1(kids=" .. #inst:GetChildren() .. ")") end),
		q.OnCreated(function(inst) table.insert(log, "C1(size=" .. tostring(inst.Size) .. ",kids=" .. #inst:GetChildren() .. ")") end),
		plain,
		D.Frame {
			q.OnCreated(function(inst) table.insert(log, "childC") end),
			q.OnRendered(function(inst) table.insert(log, "childR(parent=" .. tostring(inst.Parent) .. ")") end),
		},
		q.OnCreated(function(inst, ref) table.insert(log, "C2(ref.isPreRef=" .. tostring(q.isPreRef(ref)) .. ")") end),
		q.OnRendered(function(inst) table.insert(log, "R2") end),
		q.OnDestroyed(function() table.insert(log, "D1") end),
		q.OnDestroyed(function() table.insert(log, "D2") end),
		Size = UDim2.fromOffset(10, 10),
	}
	table.insert(log, "|built")
	f:Destroy()
	table.insert(log, "|destroyed")
	print("e1", table.concat(log, " "))
end
do -- e2: OnDestroyed in a State seat: unseat (dying=false) does not run, reseat, then death runs once
	local n = 0
	local hook = q.OnDestroyed(function() n += 1 end)
	local st = q.Source(hook)
	local f = D.Frame { st }
	st:Set(q.None)
	local a = n
	st:Set(hook)
	f:Destroy()
	print("e2 OnDestroyed unseat/reseat/destroy:", a, n)
end
do -- e3: hooks reuse
	local h = q.OnCreated(function() end)
	D.Frame { h }
	local ok, e = pcall(function() return D.Frame { h } end)
	print("e3 OnCreated reuse:", ok and "ok" or id(e))
	local ok2, e2 = pcall(function() return D.Frame { q.Source(q.OnRendered(function() end)) } end)
	print("e3 OnRendered in State seat:", ok2 and "ok" or id(e2))
	local ok3, e3 = pcall(function() return q.OnCreated(5) end)
	print("e3 OnCreated(5):", ok3 and "ok" or id(e3))
end
do -- e4: user calls hookRef:Set(nil) / Set(inst) manually (inst non-nil guarantee)
	local calls = {}
	local h = q.OnCreated(function(inst) table.insert(calls, tostring(inst)) end)
	h:Set(nil)
	h:Set("not-an-instance")
	print("e4 manual Set on hook PreRef:", table.concat(calls, ","), "_fired", h._fired)
end
do -- e5: OnDestroyed with q.dispose
	local n = 0
	local f = D.Frame { q.OnDestroyed(function() n += 1 end) }
	q.dispose(f)
	print("e5 OnDestroyed on q.dispose:", n)
end
do -- e6: OnRendered in a Claim'd... skipped; OnRendered on a child placed into a Slot after build
	local slot = q.Slot()
	local parent = D.Frame { slot }
	local par
	local c = D.Frame { q.OnRendered(function(inst) par = inst.Parent end) }
	slot:Add(c)
	print("e6 OnRendered for a Slot child: Parent at fire", par, "Parent now", c.Parent == parent)
end
