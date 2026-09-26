-- round13 E8 probe (error code / blame level). Run from quad-roblox/test/ as probe.e8.luau after ./scripts/relink.sh.
-- Sections: (A) direct-surface + nested/callback table, (B) Quad0184 internal-Get leaf blame + message subjects + Fallback/Traceback, (C) errorBefore sites called inside Observer, (D) Ref Quad0130 via handler.
local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installProperty = require("../src/Handlers/Property")
local installEvent = require("../src/Handlers/Event")
local installShorthand = require("../src/Handlers/InstanceShorthand")
local mock = require("../../quad-base/test/mock")

local W = { Write = "" }
local REFLECTED: { [string]: { any } } = {
	Frame = { { Name = "Name", Permits = W }, { Name = "Size", Permits = W }, { Name = "BackgroundTransparency", Permits = W } },
	TextButton = { { Name = "Name", Permits = W }, { Name = "Text", Permits = W }, { Name = "Size", Permits = W } },
	TextLabel = { { Name = "Name", Permits = W }, { Name = "Text", Permits = W } },
	UICorner = { { Name = "Name", Permits = W }, { Name = "CornerRadius", Permits = W } },
}
mock.declareEvents("TextButton", { "MouseButton1Click", "Activated" })
local gameShim = mock.gameShim(REFLECTED)
local q: any = Quad.New():UseProvider(QuadRoblox)
;(getfenv(installProperty) :: any).game = gameShim
;(getfenv(installProperty) :: any).TweenInfo = mock.tweenInfoShim
;(getfenv(installProperty) :: any).Enum = { EasingStyle = { Quad = "Quad" }, EasingDirection = { Out = "Out" } }
;(getfenv(installEvent) :: any).game = gameShim
;(getfenv(installShorthand) :: any).UDim = { new = function(s: number, o: number) return { Scale = s, Offset = o } end }
;(getfenv(q.Declaration.New) :: any).Instance = { new = mock.Instance.new }
q.Backend.isInst = mock.isMockInstance
local D = q.Declaration

local THIS = "probe.e8"
local rows = {}
local function L(): number return debug.info(2, "l") end
local function check(label: string, exp: number, fn: () -> ())
	local ok, err = pcall(fn)
	local s = tostring(err)
	local file, line = string.match(s, "^([^\n]-):(%d+): ")
	local id = string.match(s, "Quad%d%d%d%d") or "-"
	local verdict
	if ok then verdict = "NO-RAISE"
	elseif not file then verdict = "NO-PREFIX"
	elseif string.find(file, THIS, 1, true) and tonumber(line) == exp then verdict = "OK"
	elseif string.find(file, THIS, 1, true) then verdict = "USER-OTHER-LINE"
	else verdict = "LEAF" end
	local short = if file then (string.match(file, "[^/]+/[^/]+$") or file) .. ":" .. line else "-"
	print(string.format("%-7s | %-16s | exp %4d | got %-34s | %-15s | %s", id, label, exp, short, verdict, (string.gsub(string.sub(s, 1, 170), "\n", " "))))
end



-- ===== quad-base direct surface =====
check("AttrKey''", L(), function() q.AttrKey("") end)
check("StringAttr num", L(), function() q.StringAttr("x", 5) end)
check("Context.Provider", L(), function() q.Context.Provider(5) end)
check("Debounce(5)", L(), function() q.Debounce(5) end)
check("Debounce Time=-1", L(), function() q.Debounce({ Time = -1 }) end)
check("Mod:Apply(5)", L(), function() q.Modifier():Apply(5) end)
check("Mod.Overridden()", L(), function() q.Modifier.Overridden() end)
check("Modifier(5)", L(), function() q.Modifier(5) end)
check("Mod field Ref", L(), function() q.Modifier():Size(q.Ref()) end)
check("Effect(5)", L(), function() q.Effect(5) end)
check("Fallback(5)", L(), function() q.Fallback(5, function() end) end)
check("OnCreated(5)", L(), function() q.OnCreated(5) end)
check("Operator.Sum nil", L(), function() q.Operator.Sum(1, nil) end)
check("Ref:Callback(5)", L(), function() q.Ref():Callback(5) end)
check("Ref:Unwrap empty", L(), function() q.Ref():Unwrap() end)
check("Slot:List upd 5", L(), function() q.Slot():List({}, 5) end)
check("Slot:Get('x')", L(), function() q.Slot():Get("x") end)
check("Slot:Add idx oob", L(), function() q.Slot():Add(D.Frame {}, 5) end)
check("Slot add self", L(), function() local s = q.Slot(); s:Add(s) end)
check("Slot:Add(nil)", L(), function() q.Slot():Add(nil) end)
check("Slot:Add foreign", L(), function() q.Slot():Add(mock.Instance.foreign("Frame")) end)
check("Source:Set(Mod)", L(), function() q.Source(1):Set(q.Modifier()) end)
check("Compute(5)", L(), function() q.Source(1):Compute(5) end)
check("Store('')", L(), function() q.Store({ [""] = q.Source(1) }) end)
check("Tag('')", L(), function() q.Tag("") end)
check("RunInit(5)", L(), function() q:RunInit(5) end)
check("unbindLifetime nil", L(), function() q.Backend.unbindLifetime(nil) end)
check("Dispatch.process nil", L(), function() q.Dispatch.process(nil, "Size", 1, 1) end)
check("Dispatch.drive 5", L(), function() q.Dispatch.drive(D.Frame {}, 5) end)
check("dispose nil", L(), function() q.dispose(nil) end)
check("Relate:GetWeak nil", L(), function() q.Relate():GetWeak(nil, "k") end)
check("Bookkeeping pos 0", L(), function() q.Bookkeeping.getOffsetAt(D.Frame {}, 0) end)
check("Blocker Policy 5", L(), function() q.Blocker():Policy(5) end)

-- ===== quad-roblox =====
check("Animate(5)", L(), function() q.Animate(5) end)
check("OnChange('')", L(), function() q.OnChange("", function() end) end)
check("Out('Text',5)", L(), function() q.Out("Text", 5) end)
check("Tween Time='x'", L(), function() q.Tween({ Value = 1, Time = "x" }) end)
check("Tween no Value", L(), function() q.Tween({ Time = 1 }) end)
check("Tween:Mapped(5)", L(), function() q.Tween({ Value = 1 }):Mapped(5) end)
check("Event non-fn", L(), function() D.TextButton { Activated = 5 } end)
check("InstChild foreign", L(), function() D.Frame { mock.Instance.foreign("Frame") } end)
check("no handler match", L(), function() D.Frame { [{}] = 1 } end)
check("Ref as hash value", L(), function() D.Frame { Foo = q.Ref() } end)
check("Claim twice", L(), function() local f = D.Frame {}; q.Claim(f, D.Mapper.Frame(D.Mapper.Root)({})) end)
check("Claim bad 1st", L(), function() q.Claim(5, D.Mapper.Frame(D.Mapper.Root)({})) end)
check("Slot hash key", L(), function() D.Frame { X = q.Slot() } end)
check("Effect hash key", L(), function() D.Frame { X = q.Effect(function() end) } end)
check("Effect ret 5", L(), function() D.Frame { q.Effect(function() return 5 end) } end)
check("PreRef twice", L(), function() local r = q.PreRef(); D.Frame { r }; D.Frame { r } end)
check("already mounted", L(), function() local c = D.Frame {}; D.Frame { c }; D.Frame { c } end)

print("---- nested / callbacks ----")
local LC1 = 0
local function CompNoMatch(props: any): any
	LC1 = L(); return D.Frame { [{}] = 1 }
end
local cl = 0
check("comp nomatch", 0, function() cl = L(); CompNoMatch({}) end)
print("   component D.Frame line", LC1, "component caller line", cl)
local LC2 = 0
local function CompBadTween(props: any): any
	LC2 = L(); return D.Frame { Size = q.Tween({ Time = 1 }) }
end
check("comp bad Tween", 0, function() cl = L(); CompBadTween({}) end)
print("   inner line", LC2, "caller", cl)
-- child component inside outer D.Frame literal
local LC3 = 0
local function Child(): any LC3 = L(); return D.Frame { Foo = q.Ref() } end
check("child in parent literal", 0, function() D.Frame { Child() } end)
print("   child D.Frame line", LC3)

-- Compute callback
do
	local lf, lg = 0, 0
	local s = q.Source(1)
	local c = s:Compute(function(v) lf = L(); q.Ref():Callback(5); return v end)
	check("Compute nearest", 0, function() lg = L(); c:Get() end)
	print("   fn line", lf, "Get line", lg)
	local c2 = s:Compute(function(v) lf = L(); D.Frame { [{}] = 1 }; return v end)
	check("Compute outermost", 0, function() lg = L(); c2:Get() end)
	print("   fn line", lf, "Get line", lg)
	local a
	a = s:Compute(function() lf = L(); return a:Get() end)
	check("Compute cycle", 0, function() lg = L(); a:Get() end)
	print("   fn line", lf, "Get line", lg)
end
-- Observer
local okAll, errAll = xpcall(function()
do
	local lf, ls = 0, 0
	local s = q.Source(1)
	local armed = false
	local o = s:Observer(function() if not armed then return end lf = L(); q.Tag("") end)
	armed = true
	o:Subscribe()
	check("Observer nearest", 0, function() ls = L(); s:Set(2) end)
	print("   fn line", lf, "Set line", ls)
	o:Unsubscribe()
	local slot = q.Slot()
	armed = false
	local o2 = s:Observer(function() if not armed then return end lf = L(); slot:Add(nil) end)
	armed = true
	o2:Subscribe()
	check("Observer slot CRUD", 0, function() ls = L(); s:Set(3) end)
	print("   fn line", lf, "Set line", ls)
	o2:Unsubscribe()
	armed = false
	local o3 = s:Observer(function() if not armed then return end lf = L(); D.Frame { [{}] = 1 } end)
	armed = true
	o3:Subscribe()
	check("Observer outermost", 0, function() ls = L(); s:Set(4) end)
	print("   fn line", lf, "Set line", ls)
	o3:Unsubscribe()
	armed = false
	local o4 = s:Observer(function() if not armed then return end lf = L(); q.Claim(5, D.Mapper.Frame(D.Mapper.Root)({})) end)
	armed = true
	o4:Subscribe()
	check("Observer Claim bad", 0, function() ls = L(); s:Set(5) end)
	print("   fn line", lf, "Set line", ls)
	o4:Unsubscribe()
end
-- Effect
do
	local lf, lm = 0, 0
	check("Effect fn nearest", 0, function() lm = L(); D.Frame { q.Effect(function() lf = L(); q.Tag("") end) } end)
	print("   fn line", lf, "mount line", lm)
	local e
	local s0 = q.Source(1)
	e = q.Effect(function() if e == nil or s0:Get() == 1 then return end lf = L(); e:Subscribe() end, s0)
	D.Frame { e }
	check("Effect self-sub", 0, function() lm = L(); s0:Set(2) end)
	print("   fn line", lf, "mount line", lm)
	local s = q.Source(1)
	local e2 = q.Effect(function() lf = L(); if s:Get() == 2 then q.Tag("") end end, s)
	D.Frame { e2 }
	check("Effect rerun nearest", 0, function() lm = L(); s:Set(2) end)
	print("   fn line", lf, "Set line", lm)
end
-- Slot:List updateFn
do
	local lf, lm = 0, 0
	local data = q.Source({ 1, 2 })
	local slot = q.Slot()
	slot:List(data, function(item) lf = L(); return D.Frame { [{}] = 1 } end)
	check("List updateFn outer", 0, function() lm = L(); D.Frame { slot } end)
	print("   fn line", lf, "mount line", lm)
	local slot2 = q.Slot()
	slot2:List(data, function(item) lf = L(); return 5 end)
	check("List updateFn ret 5", 0, function() lm = L(); D.Frame { slot2 } end)
	print("   fn line", lf, "mount line", lm)
	local data3 = q.Source({ 1 })
	local slot3 = q.Slot()
	slot3:List(data3, function(item) return D.Frame {} end)
	D.Frame { slot3 }
	check("List data→dict", 0, function() lm = L(); data3:Set({ x = 1 }) end)
	print("   Set line", lm)
	local slot4 = q.Slot()
	slot4:List(data3, function(item) lf = L(); q.Tag(""); return D.Frame {} end)
	check("List updateFn nearest", 0, function() lm = L(); data3:Set({ 1 }); D.Frame { slot4 } end)
	print("   fn line", lf, "mount line", lm)
end
-- Event callback
do
	local lf = 0
	local b = D.TextButton { Activated = function() lf = L(); q.Tag("") end }
	check("Event cb", 0, function() (b :: any).Activated:Fire() end)
	print("   fn line", lf)
end
-- Operator / Debounce emit-depth
do
	local lm = 0
	local s = q.Source(nil)
	local o = q.Source(1):Apply(q.Operator.Sum(s))
	check("Operator nil State", 0, function() lm = L(); o:Get() end)
	print("   Get line", lm)
	check("Operator nil State mount", 0, function() lm = L(); D.Frame { BackgroundTransparency = o } end)
	print("   mount line", lm)
	local t = q.Source(0.1)
	local src = q.Source(1)
	local g = src:Apply(q.Debounce({ Time = t }))
	D.Frame { BackgroundTransparency = g }
	t:Set(-1)
	check("Debounce readTime", 0, function() lm = L(); src:Set(2) end)
	print("   Set line", lm)
	local s2 = q.Source(0.5)
	local an = s2:Apply(q.Animate({ Time = 0.1 }))
	D.Frame { BackgroundTransparency = an }
	check("Animate State Tween", 0, function() lm = L(); s2:Set(q.Tween({ Value = 1 })) end)
	print("   Set line", lm)
end
-- custom handler without retractor
do
	local lm = 0
	q.Dispatch.addHandler({ isHandlable = function(inst, k, v) return k == "Zz" end, process = function() end, priority = 5, keyType = "string" })
	check("no retractor", 0, function() lm = L(); D.Frame { Zz = 1 } end)
	print("   mount line", lm)
	local f = D.Frame {}
	check("InstChild cycle", 0, function() lm = L(); q.Dispatch.drive(f, { f }) end)
	print("   line", lm)
	check("getOffsetAt far", 0, function() lm = L(); q.Bookkeeping.getOffsetAt(f, 5) end)
	print("   line", lm)
end
-- C-frame caller known limit
check("pcall direct (C frame)", 0, function() assert(pcall(q.Debounce, 5)) end)
do
	local ok, err = pcall(q.Debounce, 5)
	print("   pcall(q.Debounce,5) raw:", err)
end
-- rethrow through Ref:Wait resume
do
	local lf = 0
	local r = q.Ref()
	local co = coroutine.create(function() r:Wait(); lf = L(); q.Tag("") end)
	coroutine.resume(co)
	local lm = 0
	check("Ref rethrow quad", 0, function() lm = L(); r:Set(D.Frame {}) end)
	print("   thread line", lf, "Set line", lm)
	local r2 = q.Ref()
	local co2 = coroutine.create(function() r2:Wait(); lf = L(); error("user boom") end)
	coroutine.resume(co2)
	local ok, err = pcall(function() r2:Set(D.Frame {}) end)
	print("   Ref rethrow user:", err, "thread line", lf)
end
end, function(e) return tostring(e) .. "\n" .. debug.traceback() end)
print("TAIL", okAll, errAll)

-- ===== (B) =====
do
local function P(label, f) local ok, e = pcall(f); print(label, ok, (string.gsub(string.sub(tostring(e), 1, 230), "^.*/quad/", ""))) end
local s = q.Source(1)
P("a obs subscribed→mount L" .. debug.info(1, "l"), function() local o = s:Observer(function() end); o:Subscribe(); D.Frame { o } end)
P("b effect subscribed→mount L" .. debug.info(1, "l"), function() local e = q.Effect(function() end); e:Subscribe(); D.Frame { e } end)
P("c obs twice mount L" .. debug.info(1, "l"), function() local o = s:Observer(function() end); D.Frame { o }; D.Frame { o } end)
P("d slot elem static L" .. debug.info(1, "l"), function() local c = D.Frame {}; local sl = q.Slot({ c }); D.Frame { sl }; D.Frame { c } end)
P("e static then slot L" .. debug.info(1, "l"), function() local c = D.Frame {}; D.Frame { c }; local sl = q.Slot({ c }); D.Frame { sl } end)
P("f static then slot:Add L" .. debug.info(1, "l"), function() local c = D.Frame {}; D.Frame { c }; q.Slot():Add(c) end)
P("g slot mounted twice L" .. debug.info(1, "l"), function() local sl = q.Slot(); D.Frame { sl }; D.Frame { sl } end)
local qb: any = Quad.New()
P("h base-only Slot:Add L" .. debug.info(1, "l"), function() qb.Slot():Add({}) end)
P("i base-only Tag bind L" .. debug.info(1, "l"), function() qb.Dispatch.drive({}, { qb.Tag("a") }) end)
local q2: any = Quad.New():UseProvider(QuadRoblox)
P("j cross-instance State L" .. debug.info(1, "l"), function() D.Frame { BackgroundTransparency = q2.Source(1) } end)
P("k cross-instance Slot L" .. debug.info(1, "l"), function() q.Slot():Add(q2.Slot()) end)
P("l cross-instance Slot mount L" .. debug.info(1, "l"), function() D.Frame { q2.Slot() } end)
P("m Store bad key L" .. debug.info(1, "l"), function() q.Store({ a = q.Source(1) }):Of("zz") end)
P("n Context:Get L" .. debug.info(1, "l"), function() local P1 = q.Context.Provider("x"); q.Context():Get(P1) end)
P("o Slot:Single upd L" .. debug.info(1, "l"), function() q.Slot():Single(q.Source(1), 5) end)
P("p Splice oob L" .. debug.info(1, "l"), function() q.Slot():Splice(1, 3) end)
P("q Modifier As bad L" .. debug.info(1, "l"), function() q.Modifier():As("NoSuchClass") end)
P("r Modifier Peek '' L" .. debug.info(1, "l"), function() q.Modifier():Peek("") end)
P("s State dep nil L" .. debug.info(1, "l"), function() q.Source(1):Depend(nil) end)
P("t Gate bad L" .. debug.info(1, "l"), function() q.Source(1):Gate(5) end)
P("u Attr dup L" .. debug.info(1, "l"), function() q.Attr({ a = 1 }, { a = 2 }) end)
P("v Attr fn value L" .. debug.info(1, "l"), function() q.Attr({ a = function() end }) end)
P("w Throttle MaxTime L" .. debug.info(1, "l"), function() q.Throttle({ Time = 1, MaxTime = 2 }) end)
P("x Tag Contains L" .. debug.info(1, "l"), function() q.Tag("a"):Contains(5) end)
P("y ModDefineSubtype cycle L" .. debug.info(1, "l"), function() q.Modifier.DefineSubtype("A1", "B1"); q.Modifier.DefineSubtype("B1", "A1") end)
P("z AddPlugin 5 L" .. debug.info(1, "l"), function() q:AddPlugin(5) end)
P("A UseProvider twice L" .. debug.info(1, "l"), function() q:UseProvider(QuadRoblox) end)
P("B Blocker Apply non-state L" .. debug.info(1, "l"), function() q.Blocker():__apply(5) end)
P("C List keyFn dup L" .. debug.info(1, "l"), function() local sl = q.Slot(); sl:List({ 1, 1 }, function() return D.Frame {} end, function(x) return x end); D.Frame { sl } end)
P("D List KeyGone bad L" .. debug.info(1, "l"), function() local d = q.Source({ 1 }); local sl = q.Slot(); sl:List(d, function(item, ud) if item == q.KeyGone then return 5 end return D.Frame {} end); D.Frame { sl }; d:Set({}) end)
P("E Traceback L" .. debug.info(1, "l"), function() local g = q.Traceback(function() q.Tag("") end, function(err, tb) print("   TB err:", (string.gsub(tostring(err), "^.*/quad/", ""))); print("   TB first:", (string.match(tb, "[^\n]*probe[^\n]*") )); print("   TB full head:", string.sub(tb, 1, 400)) end); g() end)
P("F Fallback L" .. debug.info(1, "l"), function() local g = q.Fallback(function() q.Tag("") end, function(err) print("   FB err:", (string.gsub(tostring(err), "^.*/quad/", ""))) end); g() end)
end
-- ===== (C)+(D) — originally a separate file with the same header =====
do
local function inObs(label, body)
	local s = q.Source(1); local armed = false; local lf = 0
	local o = s:Observer(function() if not armed then return end lf = debug.info(1, "l"); body() end)
	o:Subscribe(); armed = true
	local ls = debug.info(1, "l"); local ok, e = pcall(function() s:Set(2) end)
	print(label, "| blamed line", (string.match(tostring(e), ":(%d+): ")), "| Set closure line", ls + 0, "|", string.sub(tostring(e), 1, 120):gsub("^.*/", ""))
end
inObs("drive(nil)          L" .. debug.info(1, "l"), function() q.Dispatch.drive(nil, {}) end)
inObs("drive(f,5)          L" .. debug.info(1, "l"), function() q.Dispatch.drive(D.Frame {}, 5) end)
inObs("bindLifetime nil    L" .. debug.info(1, "l"), function() q.Backend.bindLifetime(D.Frame {}, nil) end)
inObs("getOffsetAt far     L" .. debug.info(1, "l"), function() q.Bookkeeping.getOffsetAt(D.Frame {}, 5) end)
inObs("Claim desc bad      L" .. debug.info(1, "l"), function() q.Claim(D.Frame {}, 5) end)
inObs("Tween bad (nearest) L" .. debug.info(1, "l"), function() q.Tween({}) end)
inObs("PreRef twice        L" .. debug.info(1, "l"), function() local r = q.PreRef(); D.Frame { r }; D.Frame { r } end)
inObs("D.Frame Ref hash    L" .. debug.info(1, "l"), function() D.Frame { X = q.Ref() } end)
end
do
local r = q.Ref()
local res
local co = coroutine.create(function()
	r:Wait(coroutine.running())
	res = table.pack(pcall(function() D.Frame { r } end))
end)
local ok, e = coroutine.resume(co)
print("resume", ok, e, "line of D.Frame =", 29)
print(res and res[1], res and res[2])
end
