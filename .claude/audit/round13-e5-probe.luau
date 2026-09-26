--!nocheck
local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installProperty = require("../src/Handlers/Property")
local installEvent = require("../src/Handlers/Event")
local installShorthand = require("../src/Handlers/InstanceShorthand")
local mock = require("../../quad-base/test/mock")
local W = { Write = "" }
local REFLECTED = {
	Frame = { { Name = "Name", Permits = W }, { Name = "Size", Permits = W } },
	TextLabel = { { Name = "Name", Permits = W }, { Name = "Text", Permits = W } },
}
local gameShim = mock.gameShim(REFLECTED)
local q: any = Quad.New():UseProvider(QuadRoblox)
getfenv(installProperty).game = gameShim
getfenv(installProperty).TweenInfo = mock.tweenInfoShim
getfenv(installProperty).Enum = { EasingStyle = { Quad = "Quad" }, EasingDirection = { Out = "Out" } }
getfenv(installEvent).game = gameShim
getfenv(installShorthand).UDim = { new = function(s, o) return { Scale = s, Offset = o } end }
getfenv(q.Declaration.New).Instance = { new = mock.Instance.new }
q.Backend.isInst = mock.isMockInstance
local D, None = q.Declaration, q.None
local function try(label, f)
	local ok, err = pcall(f)
	if not ok then print(label, "ERR:", tostring(err)) end
end

print("--- R1 Ref reuse after host Destroy ---")
try("R1", function()
	local r = q.Ref(nil)
	local a = D.Frame({ r })
	print("r.Value==a", r.Value == a)
	a:Destroy()
	print("after destroy r.Value==a", r.Value == a, "isHeld", q.Backend.isHeld and q.Backend.isHeld(r))
	local b = D.Frame({ r })
	print("replaced into b ok, r.Value==b", r.Value == b)
end)

print("--- R2 same Ref twice in one array ---")
try("R2", function()
	local r = q.Ref(nil)
	local a = D.Frame({ r, r })
	print("placed twice ok", r.Value == a)
end)

print("--- R3 Ref twice via State seat + literal ---")
try("R3", function()
	local r = q.Ref(nil)
	local s = q.Source(r)
	local a = D.Frame({ r, s })
	print("r + State(r) ok", r.Value == a)
	s:Set(q.None)
	print("after state seat leaves: r.Value==a", r.Value == a)
end)

print("--- R4 Wait on Ref whose host gets destroyed ---")
try("R4", function()
	local r = q.Ref(nil)
	local a = D.Frame({ r })
	local woke = "no"
	local co = coroutine.create(function() local x = r:Wait(); woke = tostring(x.Value) end)
	coroutine.resume(co)
	a:Destroy()
	print("waiter woke after destroy?", woke, coroutine.status(co))
end)

print("--- R5 Callback that throws at registration stays registered ---")
try("R5", function()
	local r = q.Ref(1)
	local n = 0
	local fn = function(v) n += 1; if v == 1 then error("boom") end end
	local ok = pcall(function() r:Callback(fn) end)
	print("registration threw", not ok, "still registered", r.Callbacks[fn] == true)
	r:Set(2); print("calls", n)
end)

print("--- R6 PreRef in Slot elements / Modifier ---")
try("R6a Slot{pre}", function()
	local pre = q.PreRef(nil)
	local s = q.Slot({ pre })
	local a = D.Frame({ s })
	print("Slot{pre} ok, pre.Value", pre.Value)
end)
try("R6b Modifier{pre}", function()
	local pre = q.PreRef(nil)
	local m = q.Modifier({ pre })
	local a = D.Frame({ m })
	print("Modifier{pre} ok", pre.Value == a)
end)
try("R6c Slot:Add(pre)", function()
	local pre = q.PreRef(nil)
	local s = q.Slot()
	local a = D.Frame({ s })
	s:Add(pre)
	print("Slot:Add(pre) ok, pre.Value", pre.Value)
end)
try("R6d Slot:Add(ref)", function()
	local r = q.Ref(nil)
	local s = q.Slot()
	local a = D.Frame({ s })
	s:Add(r)
	print("Slot:Add(ref) ok, r.Value==a", r.Value == a)
end)

print("--- R7 PostRef burned when drive throws in body ---")
try("R7", function()
	local post = q.PostRef(nil)
	local ok, e = pcall(function() return D.Frame({ post, Size = {} , Nope = 1 }) end)
	print("drive threw", not ok, tostring(e):sub(1,80))
	print("post._fired", post._fired, "Value", post.Value)
	local ok2, e2 = pcall(function() return D.Frame({ post }) end)
	print("reuse:", ok2, tostring(e2):sub(1,100))
end)

print("--- R8 second PreRef already-fired aborts after first PreRef fired ---")
try("R8", function()
	local p1 = q.PreRef(nil)
	local used = q.PreRef(nil); D.Frame({ used })
	local ok, e = pcall(function() return D.Frame({ p1, used }) end)
	print("threw", not ok, "p1._fired", p1._fired, "p1.Value set", p1.Value ~= nil)
end)

print("--- H1 hook order ---")
try("H1", function()
	local log = {}
	local f = D.Frame({
		q.OnDestroyed(function() table.insert(log, "D") end),
		q.OnRendered(function() table.insert(log, "R") end),
		q.OnCreated(function() table.insert(log, "C") end),
		Size = 1,
	})
	f:Destroy()
	print(table.concat(log, ","))
end)

print("--- F1 Fallback multi-return ---")
try("F1", function()
	local fb = q.Fallback(function() return 1, 2, 3 end, function() return "e" end)
	print("Fallback returns", fb())
	local tb = q.Traceback(function() return 1, 2, 3 end, function() return "e" end)
	print("Traceback returns", tb())
	local fb2 = q.Fallback(function() error("x") end, function() return "a", "b" end)
	print("onError returns", fb2())
end)
print("--- F2 Traceback trace content, table error, nested ---")
try("F2", function()
	local function deep() error({ code = 7 }) end
	local function mid() deep() end
	local tb = q.Traceback(function() mid() end, function(err, trace) print("err type", typeof(err), err.code); print("TRACE<<"..trace..">>") end)
	tb()
	local tb2 = q.Traceback(function() local x = nil; return x.y end, function(err, trace) print("vm err", err); print("TRACE2<<"..trace..">>") end)
	tb2()
end)
print("--- F3 onError throws ---")
try("F3", function()
	q.Fallback(function() error("a") end, function(e) error("b: "..tostring(e)) end)()
end)

print("--- C1 Context ---")
try("C1", function()
	local P = q.Context.Provider("X")
	local P2 = q.Context.Provider("X")
	local ctx = q.Context():Set(P, 1):Set(P, 2)
	print("same provider twice ->", ctx:Get(P), "tostring", tostring(ctx))
	print("Peek P2", ctx:Peek(P2))
	local ok, e = pcall(function() return ctx:Get(P2) end)
	print("Get P2", tostring(e))
	local ok2, e2 = pcall(function() return ctx.Set(P, 3) end)
	print("dot-call", tostring(e2))
	local ok3, e3 = pcall(function() return ctx:Set(P, false) end)
	print("false value", ok3, ctx:Peek(P))
end)
try("C2 Context in props", function()
	local ctx = q.Context()
	local f = D.Frame({ Context = ctx })
	print("D.Frame{Context=ctx} ok?")
end)
print("--- C3 is* on module ---")
local names = {}
for k, v in q do if type(k)=="string" and k:sub(1,2)=="is" and type(v)=="function" then table.insert(names,k) end end
table.sort(names); print(table.concat(names, " "))
try("C3 Provider in props", function() D.Frame({ q.Context.Provider("T") }) end)
try("C3b Context at array", function() D.Frame({ q.Context() }) end)
try("C3c Debounce", function() D.Frame({ Size = q.Debounce and nil }) end)
print("--- R9 Ref callback throws during leaf bind; reuse of Ref afterwards ---")
try("R9", function()
	local r = q.Ref(nil)
	local armed = true
	r:Callback(function(v) if v ~= nil and armed then armed = false; error("cb boom") end end)
	local ok, e = pcall(function() return D.Frame({ r }) end)
	print("first drive threw", not ok, tostring(e):sub(1,60), "r.Value set", r.Value ~= nil)
	local ok2, e2 = pcall(function() return D.Frame({ r }) end)
	print("reuse ok?", ok2, tostring(e2):sub(1,140))
	collectgarbage("collect"); collectgarbage("collect")
	local ok3, e3 = pcall(function() return D.Frame({ r }) end)
	print("after GC reuse ok?", ok3, tostring(e3):sub(1,100))
end)
print("--- R10 PreRef callback throws (Fallback retry w/ same PreRef) ---")
try("R10", function()
	local pre = q.PreRef(nil)
	local armed = true
	pre:Callback(function(v) if v and armed then armed=false; error("pre boom") end end)
	local ok = pcall(function() return D.Frame({ pre }) end)
	print("threw", not ok, "_fired", pre._fired)
end)
print("--- R11 Wait yieldable / Wait on filled / Unwrap blame ---")
try("R11b", function() q.Ref(nil):Unwrap() end)
try("R11c", function() print("Unwrap false ->", q.Ref(false):Unwrap()) end)
try("R11d", function()
	local r = q.Ref(5)
	local got
	local co = coroutine.create(function() got = r:Wait().Value end)
	coroutine.resume(co)
	print("filled Ref Wait -> status", coroutine.status(co))
	r:Set(6); print("got", got)
end)
print("--- R12 PreRef timing vs props, PostRef sees props+children ---")
try("R12", function()
	local log = {}
	local f = D.Frame({
		D.TextLabel({ Text = "c" }),
		q.OnRendered(function(i) table.insert(log, "R size="..tostring(i.Size).." kids="..#i:GetChildren()) end),
		q.OnCreated(function(i) table.insert(log, "C size="..tostring(i.Size).." kids="..#i:GetChildren()) end),
		Size = 3,
	})
	print(table.concat(log, " | "))
end)
print("--- R13 OnDestroyed in State seat, then seat leaves, then Destroy ---")
try("R13", function()
	local n = 0
	local od = q.OnDestroyed(function() n += 1 end)
	local s = q.Source(od)
	local f = D.Frame({ s })
	s:Set(q.None); print("after seat leaves n", n)
	s:Set(od); f:Destroy(); print("after reseat+destroy n", n)
end)
print("--- R14 Ref Wait waiter throws on Set(nil) from retract; Ref reusable? ---")
try("R14", function()
	local r = q.Ref(nil)
	local s = q.Source(r)
	local f = D.Frame({ s })
	local co = coroutine.create(function() local x = r:Wait(); if x.Value == nil then error("waiter nil") end end)
	coroutine.resume(co)
	local ok, e = pcall(function() s:Set(q.None) end)
	print("retract threw", not ok, tostring(e):sub(1,60))
	local ok2, e2 = pcall(function() s:Set(r) end)
	print("reseat ok", ok2, tostring(e2):sub(1,120), "r.Value==f", r.Value == f)
end)
print("--- R15 outer Ref bound into a tree that throws later (Fallback) ---")
try("R15", function()
	local parentRef = q.Ref(nil)
	local function Comp(props) return D.Frame({ props.Ref, D.Frame({ Nope = 1 }) }) end
	local function Comp2(props) return D.Frame({ props.Ref, Nope = 1 }) end
	local safe = q.Fallback(Comp2, function(err) return "fallback" end)
	print("first", safe({ Ref = parentRef }), "bound?", parentRef.Value ~= nil)
	local ok, e = pcall(function() return D.Frame({ parentRef }) end)
	print("parent reuses its Ref in a fresh frame:", ok, tostring(e):sub(1,110))
	local r2 = q.Ref(nil)
	local safe2 = q.Fallback(Comp, function() return "fb" end)
	print("Comp (child throws before outer frame built):", safe2({ Ref = r2 }), "r2 bound?", r2.Value ~= nil)
end)
print("--- R16 OnRendered reads Slot Offset/Length ---")
try("R16", function()
	local a = q.Slot({ D.TextLabel({ Text = "a1" }), D.TextLabel({ Text = "a2" }) })
	local b = q.Slot({ D.TextLabel({ Text = "b1" }) })
	local seen
	local f = D.Frame({ a, b, q.OnRendered(function() seen = { a.Offset:Get(), a.Length:Get(), b.Offset:Get(), b.Length:Get() } end) })
	print("in OnRendered: aOff aLen bOff bLen", table.unpack(seen))
	print("after drive:", a.Offset:Get(), a.Length:Get(), b.Offset:Get(), b.Length:Get())
	local names = {}
	for _, c in f:GetChildren() do table.insert(names, c.Text) end
	print("physical", table.concat(names, ","))
end)
print("--- F4 Traceback on quad error ---")
try("F4", function()
	q.Traceback(function() q.Ref(nil):Unwrap() end, function(err, trace) print("ERR", err); print("TRACE<<"..trace..">>") end)()
	q.Traceback(function() D.Frame({ Nope = 1 }) end, function(err, trace) print("ERR", err); print("TRACE<<"..trace..">>") end)()
end)
print("--- F5 Traceback nested Traceback / error(msg, 0) / non-string ---")
try("F5", function()
	q.Traceback(function() error(nil) end, function(err, trace) print("nil err ->", err, #trace > 0) end)()
end)
print("--- F6 callable tables as base ---")
print("typeof D.Frame", typeof(D.Frame), "typeof q.Slot", typeof(q.Slot), "q.Tag", typeof(q.Tag), "q.Attr", typeof(q.Attr))
try("F6", function() local s = q.Fallback(D.Frame, function() return nil end); print("Fallback(D.Frame) ok", s({ Nope = 1 })) end)
try("F6b", function() local s = q.Fallback(q.Attr, function() return nil end); print("Fallback(q.Attr) ok") end)
print("--- R17 OnRendered/OnCreated mutating a slot of the same inst ---")
try("R17", function()
	local a = q.Slot({ D.TextLabel({ Text = "a1" }) })
	local b = q.Slot({ D.TextLabel({ Text = "b1" }) })
	local f = D.Frame({ a, b, q.OnRendered(function() a:Add(D.TextLabel({ Text = "a2" })) end) })
	local names = {}
	for _, c in f:GetChildren() do table.insert(names, c.Text) end
	print("physical", table.concat(names, ","), "bOff", b.Offset:Get(), "aLen", a.Length:Get())
end)
try("R17b OnCreated adds to slot before mount", function()
	local a = q.Slot({ D.TextLabel({ Text = "a1" }) })
	local b = q.Slot({ D.TextLabel({ Text = "b1" }) })
	local f = D.Frame({ q.OnCreated(function() a:Add(D.TextLabel({ Text = "a0" })) end), a, b })
	local names = {}
	for _, c in f:GetChildren() do table.insert(names, c.Text) end
	print("physical", table.concat(names, ","), "bOff", b.Offset:Get(), "aLen", a.Length:Get())
end)
try("R17c OnCreated destroys the inst", function()
	local f = D.Frame({ q.OnCreated(function(i) i:Destroy() end), D.TextLabel({ Text = "x" }), Size = 2 })
	print("survived; destroyed?", mock.isDestroyed(f), "kids", #f:GetChildren())
end)
try("R17d OnRendered destroys the inst", function()
	local s = q.Slot({ D.TextLabel({ Text = "x" }) })
	local f = D.Frame({ s, q.OnRendered(function(i) i:Destroy() end) })
	print("survived; destroyed?", mock.isDestroyed(f))
end)
print("--- R18 offsets passed to nativeInsert from OnRendered (batch gate on) ---")
try("R18", function()
	local orig = q.Backend.nativeInsert
	local log = {}
	q.Backend.nativeInsert = function(t, off, els) table.insert(log, els[1].Text .. "@" .. tostring(off)); return orig(t, off, els) end
	local a = q.Slot({ D.TextLabel({ Text = "a1" }) })
	local b = q.Slot({ D.TextLabel({ Text = "b1" }) })
	local c = q.Slot({ D.TextLabel({ Text = "c1" }) })
	local f = D.Frame({ a, b, c, q.OnRendered(function() a:Add(D.TextLabel({ Text = "a2" })); c:Add(D.TextLabel({ Text = "c2" })) end) })
	print(table.concat(log, " "), "| final offsets", a.Offset:Get(), b.Offset:Get(), c.Offset:Get())
	q.Backend.nativeInsert = orig
end)
