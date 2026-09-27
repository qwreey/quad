--!nocheck
-- E80 group D: dispatch/handler/module Fixed bullets + Changed C25 C38 C56 C64
local H = require("../harness")
local L = require("../lib")
local q, D, mock = H.q, H.D, H.mock

print("--- F5: 정적 자식 자리에 부모 자신/조상 → InstanceChild 거부 ---")
L.section(function()
	local src = q.Source(nil)
	local host = D.Frame { src }
	local m, id = L.err("F5 Set(host)", function() src:Set(host) end)
	L.check("F5 message", L.has(m, "InstanceChild: cannot place an Instance inside itself or one of its own descendants"), id)
	local anc = D.Frame {}
	local src2 = q.Source(nil)
	local mid = D.Frame { src2 }
	mid.Parent = anc
	local m2, id2 = L.err("F5 Set(ancestor)", function() src2:Set(anc) end)
	L.check("F5 ancestor rejected", id2 == id, id2)
	local okAfter, eA = pcall(function() local c = D.Frame {}; src:Set(c) end)
	L.check("F5 seat usable after rejection (no stuck owner)", okAfter, okAfter and "ok" or L.first(eA))
	-- the bullet says 'State 자리라면 옛 자식은 거부 전에 이미 내려가 있습니다'
	local old = D.Frame {}
	local src3 = q.Source(old)
	local h3 = D.Frame { src3 }
	pcall(function() src3:Set(h3) end)
	L.check("F5 old child already retracted", old.Parent == nil, tostring(old.Parent))
end)

print("--- F7: claimOwnerAt/releaseOwner nil → must not be nil ---")
L.section(function()
	local f = D.Frame {}
	local m1, i1 = L.err("F7 claimOwnerAt(nil,…)", function() q.Bookkeeping.claimOwnerAt(nil, f, 1) end)
	local m2, i2 = L.err("F7 claimOwnerAt(e,nil,…)", function() q.Bookkeeping.claimOwnerAt(D.Frame {}, nil, 1) end)
	local m3, i3 = L.err("F7 claimOwnerAt(e,i,nil)", function() q.Bookkeeping.claimOwnerAt(D.Frame {}, f, nil) end)
	local m4, i4 = L.err("F7 releaseOwner(nil,…)", function() q.Bookkeeping.releaseOwner(nil, f) end)
	local m5, i5 = L.err("F7 releaseOwner(e,nil)", function() q.Bookkeeping.releaseOwner(D.Frame {}, nil) end)
	L.check("F7 all five 'must not be nil' at user line", L.has(m1, "must not be nil") and L.has(m2, "must not be nil") and L.has(m3, "must not be nil") and L.has(m4, "must not be nil") and L.has(m5, "must not be nil") and L.has(m1, "d-dispatch") and L.has(m2, "d-dispatch"), table.concat({ i1 or "-", i2 or "-", i3 or "-", i4 or "-", i5 or "-" }, ","))
end)

print("--- F12: 서로를 담은 State 사슬 → StoreBind circular ---")
L.section(function()
	local a, b = q.Source(nil), q.Source(nil)
	a:Set(b); b:Set(a)
	local m, id = L.err("F12 a<->b in slot", function() D.Frame { a } end)
	L.check("F12 message", L.has(m, "StoreBind: the State's value chain is circular"), id)
	local s = q.Source(nil); s:Set(s)
	local m2, id2 = L.err("F12 s:Set(s) in slot", function() D.Frame { s } end)
	L.check("F12 self chain", id2 == id, id2)
	local s3 = q.Source(nil); s3:Set(s3)
	local m3, id3 = L.err("F12 self chain at string key", function() D.Frame { Name = s3 } end)
end)

print("--- F14: is* 헬퍼가 얹혀도 D.<Class>{}가 죽지 않는다 ---")
L.section(function()
	q.isEmpty = function(t) return type(t) == "table" and next(t) == nil end
	q.isMobile = function() return true end
	local ok, e = pcall(function() return D.Frame {} end)
	L.check("F14 isEmpty/isMobile ignored", ok, ok and "ok" or L.first(e))
	q.isEmpty, q.isMobile = nil, nil
	q.isNonEmptyList = function(t) return type(t) == "table" and next(t) ~= nil end
	local ok2, e2 = pcall(function() return D.Frame { Name = "x" } end)
	L.check("F14 caveat: isNonEmptyList still breaks (as the bullet says)", not ok2, ok2 and "no error" or L.first(e2))
	q.isNonEmptyList = nil
end)

print("--- F16: PreRef/PostRef 잘못 놓았을 때 주어 ---")
L.section(function()
	local m1 = L.err("F16 PreRef at string key", function() D.Frame { Foo = q.PreRef() } end)
	local m2 = L.err("F16 PostRef at string key", function() D.Frame { Foo = q.PostRef() } end)
	local m3 = L.err("F16 PreRef in State", function() D.Frame { q.Source(q.PreRef()) } end)
	local m4 = L.err("F16 PostRef in State", function() D.Frame { q.Source(q.PostRef()) } end)
	L.check("F16 subjects are PreRef:/PostRef:", L.has(m1, "PreRef:") and L.has(m2, "PostRef:") and L.has(m3, "PreRef:") and L.has(m4, "PostRef:"), "")
end)

print("--- F17: tostring(store) with rawset numeric key ---")
L.section(function()
	local st = q.Store({ a = q.Source(1) })
	rawset(st, 1, "x")
	local ok, s = pcall(tostring, st)
	L.check("F17 tostring does not throw", ok, ok and s or L.first(s))
end)

print("--- F18/F19: Context/Provider·Slot/Ref at wrong seat hints ---")
L.section(function()
	local m1 = L.err("F18 Context at string key", function() D.Frame { Thing = q.Context() } end)
	local m2 = L.err("F18 Provider at string key", function() D.Frame { Thing = q.Context.Provider() } end)
	local m1n = L.err("F18 Context at numeric key", function() D.Frame { q.Context() } end)
	L.check("F18 no provider-init hint", not L.has(m1, "provider") and not L.has(m2, "provider") and L.has(m1, "numeric"), "")
	local m3, i3 = L.err("F19 Children = slot", function() D.Frame { Children = q.Slot() } end)
	local m4, i4 = L.err("F19 Ref = ref", function() D.Frame { Ref = q.Ref() } end)
	local m5 = L.err("F19 Tag at string key", function() D.Frame { Thing = q.Tag() } end)
	L.check("F19 Slot message", L.has(m3, "Slot: must be an array item, not the value of a string key"), i3)
	L.check("F19 Ref same shape", L.has(m4, "must be an array item, not the value of a string key"), i4)
	L.check("F19 Tag: numeric hint, no provider hint", L.has(m5, "numeric") and not L.has(m5, "provider"), "")
end)

print("--- F20: process index gap / nil key / NaN priority / mapper name / addHandler dedup / getHandler nil ---")
L.section(function()
	local inst = D.Frame {}
	q.Dispatch.addHandler({ name = "E80K", keyType = "string", isHandlable = function(_i, k) return k == "E80K" end, priority = q.Dispatch.HANDLER_PRIORITY_NORMAL + 7, process = function() return H.Quad.Void end })
	local m1, i1 = L.err("F20 index gap", function() q.Dispatch.process(inst, "E80K", 1, 3) end)
	L.check("F20 gap message", L.has(m1, "index 3 would leave a gap in the chain"), i1)
	local m2 = L.err("F20 process nil key", function() q.Dispatch.process(inst, nil, 1, 1) end)
	local m3 = L.err("F20 retractFrom nil key", function() q.Dispatch.retractFrom(inst, nil, 1) end)
	local m4 = L.err("F20 NaN priority", function() q.Dispatch.addHandler({ isHandlable = function() return false end, priority = 0 / 0, process = function() return H.Quad.Void end }) end)
	local m5 = L.err("F20 inf priority", function() q.Dispatch.addHandler({ isHandlable = function() return false end, priority = math.huge, process = function() return H.Quad.Void end }) end)
	local m6 = L.err("F20 newMapperClass(5)", function() q.newMapperClass(5) end)
	local h = { name = "Twice", isHandlable = function() return false end, priority = -5, process = function() return H.Quad.Void end }
	local n0 = #q.Dispatch.listHandlers()
	q.Dispatch.addHandler(h); q.Dispatch.addHandler(h)
	L.check("F20 dedup", #q.Dispatch.listHandlers() == n0 + 1, (#q.Dispatch.listHandlers() - n0))
	local m7 = L.err("F20 getHandler(nil, k)", function() q.Dispatch.getHandler(nil, "Name", 1) end)
	local m8 = L.err("F20 getHandler(inst, nil)", function() q.Dispatch.getHandler(inst, nil, 1) end)
	L.check("F20 getHandler nil gates are quad messages at user line", L.id(m7) ~= nil and L.id(m8) ~= nil and L.has(m7, "d-dispatch") and L.has(m8, "d-dispatch"), tostring(L.id(m7)) .. " " .. tostring(L.id(m8)))
	L.check("F20 all gated", m2 and m3 and m4 and m5 and m6 and true or false, "")
end)

print("--- F21: RunInit(nil)/RunInit(5) ---")
L.section(function()
	local m1, i1 = L.err("F21 RunInit(nil)", function() q:RunInit(nil) end)
	local m2 = L.err("F21 RunInit(5)", function() q:RunInit(5) end)
	L.check("F21 message", L.has(m1, "Quad:RunInit: initFn must be a function") and L.has(m1, "d-dispatch"), i1)
end)

print("--- F42: 인자 모양 검사 입구 ---")
L.section(function()
	local inst = D.Frame {}
	L.err("F42 process index 0", function() q.Dispatch.process(inst, "Name", "x", 0) end)
	L.err("F42 retractFrom index 1.5", function() q.Dispatch.retractFrom(inst, "Name", 1.5) end)
	L.err("F42 Modifier:Apply(5)", function() q.Modifier({ Name = "x" }):Apply(5) end)
	local s = q.Slot()
	local mo = L.err("F42 :List opts string", function() s:List(q.Source({}), function() return nil end, nil, "OwnsElements") end)
	L.err("F42 AddPlugin(5)", function() q:AddPlugin(5) end)
	L.err("F42 AddPlugin returns 5", function() q:AddPlugin(function() return 5 end) end)
	local mu, iu = L.err("F42 UseProvider(nil)", function() H.Quad.New():UseProvider(nil) end)
	L.err("F42 UseProvider returns 5", function() H.Quad.New():UseProvider(function() return 5 end) end)
	L.check("F42 UseProvider(nil) now errors", mu ~= nil, iu)
	L.check("F42 opts string rejected", mo ~= nil, mo)
end)

print("--- C25: Tag 인자 nil = 없음 ---")
L.section(function()
	local base = q.Tag("A")
	local ok, t = pcall(function() return base:Added(nil) end)
	L.check("C25 Added(nil) ok", ok and q.isTag(t), ok and "ok" or L.first(t))
	local ok2 = pcall(function() return q.Tag(nil) end)
	local ok3 = pcall(function() return base:Removed(nil) end)
	local ok4 = pcall(function() return q.Tag.Merged(base, nil) end)
	L.check("C25 Tag(nil)/Removed(nil)/Merged(…,nil) ok", ok2 and ok3 and ok4, tostring(ok2) .. tostring(ok3) .. tostring(ok4))
	local m1 = L.err("C25 list hole still errors", function() q.Tag({ "a", nil, "b" }) end)
	local m2 = L.err("C25 Contains(nil) still errors", function() base:Contains(nil) end)
	L.check("C25 hole & Contains(nil) error", m1 ~= nil and m2 ~= nil, "")
end)

print("--- C38: Event/OnChange 우선순위, debug tie 안내 사라짐 ---")
L.section(function()
	local ev, oc
	for _, h in q.Dispatch.listHandlers() do
		if h.name == "Event" then ev = h.priority end
		if h.name == "OnChange" then oc = h.priority end
	end
	L.check("C38 Event/OnChange = NORMAL-1", ev == q.Dispatch.HANDLER_PRIORITY_NORMAL - 1 and oc == q.Dispatch.HANDLER_PRIORITY_NORMAL - 1, tostring(ev) .. "/" .. tostring(oc))
	local log = {}
	local Q2 = H.Quad.New()
	Q2.debug = true
	local fenv = getfenv(Q2.Dispatch.addHandler)
	local op = fenv.print
	fenv.print = function(...) table.insert(log, table.concat({ ... }, " ")) end
	Q2:UseProvider(H.QuadRoblox)
	local afterInstall = #log
	-- control: the interception does catch a real tie
	Q2.Dispatch.addHandler({ name = "E80TieA", keyType = "string", isHandlable = function() return false end, priority = 123, process = function() return H.Quad.Void end })
	Q2.Dispatch.addHandler({ name = "E80TieB", keyType = "string", isHandlable = function() return false end, priority = 123, process = function() return H.Quad.Void end })
	fenv.print = op
	print("  C38 control tie lines captured: " .. (#log - afterInstall))
	local ties = 0
	for i = 1, afterInstall do local l = log[i]; if L.has(l, "priority tie") then ties += 1; print("  tie: " .. l) end end
	L.check("C38 no priority tie lines at install", ties == 0, "ties=" .. ties .. " lines=" .. #log)
end)

print("--- C56: 다른 quad 인스턴스 값 → 교차 거부 ---")
L.section(function()
	local B = H.Quad.New():UseProvider(H.QuadRoblox)
	local m1, i1 = L.err("C56 other Observer in numeric slot", function() D.Frame { B.Source(1):Observer(function() end) } end)
	local m2 = L.err("C56 other Effect", function() D.Frame { B.Effect(function() end) } end)
	local m3 = L.err("C56 other State as property", function() D.Frame { Name = B.Source("x") } end)
	local m4 = L.err("C56 :List data other State", function() local s = q.Slot(); s:List(B.Source({}), function() return nil end); D.Frame { s } end)
	L.check("C56 all cross-instance", L.has(m1, "another quad module instance") and L.has(m2, "another quad module instance") and L.has(m3, "another quad module instance") and L.has(m4, "another quad module instance"), i1)
	local bs = B.Source(1); local runs = 0
	local e = q.Effect(function() runs += 1 end, bs):Subscribe()
	bs:Set(2)
	L.check("C56 cross-instance dep edge still works", runs == 2, runs)
	e:Unsubscribe()
end)

print("--- C64: AddPlugin dedup, 던진 플러그인은 설치 안 된 것으로 ---")
L.section(function()
	local n = 0
	local function plug(qq) n += 1; return {} end
	q:AddPlugin(plug); q:AddPlugin(plug)
	L.check("C64 dedup", n == 1, n)
	local t = 0
	local function bad(qq) t += 1; if t == 1 then error("boom") end; return {} end
	pcall(function() q:AddPlugin(bad) end)
	local ok = pcall(function() q:AddPlugin(bad) end)
	L.check("C64 thrown plugin reruns", ok and t == 2, t)
end)
L.done()
