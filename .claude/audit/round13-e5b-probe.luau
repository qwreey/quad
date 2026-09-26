--!nocheck
-- round13 E5-2: state left behind after Fallback swallows a throw, per throw site x follow-up action.
-- Run: ./scripts/relink.sh, copy this file to quad-roblox/test/probe.e5b.luau, then (cd quad-roblox && luau test/probe.e5b.luau). Mock backend = quad-roblox provider over quad-base/test/mock.luau instances.
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
local D = q.Declaration
local BK = q.Bookkeeping

local function code(err)
	local s = tostring(err)
	return string.match(s, "Quad%d%d%d%d") or ("raw:" .. string.sub((string.gsub(s, "^.-:%d+: ", "")), 1, 70))
end
local function try(f)
	local ok, err = pcall(f)
	if ok then return "ok" end
	return code(err)
end
local function gc() collectgarbage("collect"); collectgarbage("collect") end
local function nsubs(s) local n = 0; for _ in s._subs do n += 1 end; return n end
local function blocking(inst)
	local ok, v = pcall(function() return BK.getBlocker(inst).Blocking end)
	return ok and tostring(v) or code(v)
end
local function rblocking(inst)
	local ok, v = pcall(function() return BK.getBookkeeping(inst).recomputeBlocker.Blocking end)
	return ok and tostring(v) or code(v)
end

-- env: things a parent passes into the component (all "made outside the boundary")
local function makeEnv(site)
	local env = { fail = true, src = q.Source(1) }
	env.child = D.Frame({ Name = env.src:Compute(function(s) return "A" .. s:Get() end) })
	env.slot1 = q.Slot({ D.Frame({ Name = "s1e1" }) })
	env.slot2 = q.Slot({ D.Frame({ Name = "s2e1" }) })
	if site == "S3" or site == "S3c" then
		env.data = q.Source({ 1, 2, 3, 4 })
		env.slot1 = q.Slot():List(env.data, function(ctx)
			if ctx.Item == q.KeyGone then return nil end
			if env.fail and ctx.Item == 3 then error("S3 updateFn") end
			return ctx.Prev or D.Frame({ Name = "L" .. ctx.Item })
		end, function(x) return x end)
	end
	return env
end

local function badCompute(env, tag)
	return env.src:Compute(function(s) if env.fail then error(tag) end return "N" .. s:Get() end)
end

-- component per site; captures the half-built instance through OnCreated (our instrument)
local function makeComp(site, env)
	return function()
		env.orphan = nil
		local cap = q.OnCreated(function(i) env.orphan = i end)
		if site == "S1" then -- string key (Property) throws after array part placed
			return D.Frame({ cap, env.child, env.slot1, env.slot2, Name = badCompute(env, "S1") })
		elseif site == "S2" then -- numeric-key static seat (State) throws
			return D.Frame({ cap, env.child, env.slot1, env.slot2, badCompute(env, "S2"), Size = 5 })
		elseif site == "S3" then -- :List updateFn throws during initial mount
			return D.Frame({ cap, env.child, env.slot2, env.slot1, Size = 5 })
		elseif site == "S4" then -- Modifier field throws
			return D.Frame({ cap, env.child, env.slot1, env.slot2, q.Modifier({ Name = badCompute(env, "S4") }) })
		elseif site == "S5" then -- Effect replay on install throws
			local e = q.Effect(function() local _ = env.src:Get(); if env.fail and env.armed then error("S5 effect") end end, env.src)
			env.armed = true
			env.src:Set(env.src:Get() + 1) -- withheld until install
			return D.Frame({ cap, env.child, env.slot1, env.slot2, e })
		elseif site == "S6a" then -- OnCreated throws
			return D.Frame({ cap, q.OnCreated(function() if env.fail then error("S6a") end end), env.child, env.slot1, env.slot2 })
		elseif site == "S6b" then -- OnRendered throws
			return D.Frame({ cap, env.child, env.slot1, env.slot2, q.OnRendered(function() if env.fail then error("S6b") end end) })
		elseif site == "S7" then -- throw in component body after building a sub-tree, before the outer D.Frame
			local inner = D.Frame({ cap, env.child, env.slot1, env.slot2 })
			if env.fail then error("S7 body") end
			return D.Frame({ inner })
		end
	end
end

local function snap(env)
	local o = env.orphan
	local t = {}
	if o then
		table.insert(t, ("orphan kids=%d gate=%s rgate=%s destroyed=%s"):format(#o:GetChildren(), blocking(o), rblocking(o), tostring(mock.isDestroyed(o))))
	else
		table.insert(t, "orphan=nil")
	end
	table.insert(t, ("child.Parent==orphan %s"):format(tostring(o ~= nil and env.child.Parent == o)))
	for _, n in { "slot1", "slot2" } do
		local s = env[n]
		table.insert(t, ("%s mat=%s gate=%s L=%s O=%s mounted=%s"):format(n, tostring(s._materializing), blocking(s), tostring(s.Length:Get()), tostring(s.Offset:Get()), tostring(s._mountedInst ~= nil)))
	end
	gc()
	table.insert(t, "src.subs=" .. nsubs(env.src))
	return table.concat(t, " | ")
end

local SITES = { "S1", "S2", "S3", "S4", "S5", "S6a", "S6b", "S7" }

local function setup(site)
	local env = makeEnv(site)
	local comp = makeComp(site, env)
	local err
	local safe = q.Fallback(comp, function(e) err = e; return "FB" end)
	local r = safe()
	env.firstErr = err and code(err) or ("no throw, r=" .. tostring(r))
	env.comp = comp
	return env
end

print("=== BASELINE snapshot after the swallowed throw ===")
for _, site in SITES do
	local env = setup(site)
	print(site, "err=" .. env.firstErr, "::", snap(env))
end

print("\n=== A: silent wrongness while gate stays on — grow slot1, read slot2.Offset ===")
for _, site in SITES do
	local env = setup(site)
	if env.orphan == nil then print(site, "no orphan"); continue end
	local before = env.slot2.Offset:Get()
	local r = try(function() env.slot1:Add(D.Frame({ Name = "grow" })) end)
	print(site, "slot1:Add ->", r, "slot2.Offset", before, "->", env.slot2.Offset:Get(), "slot1.L", env.slot1.Length:Get(), "orphan kids", #env.orphan:GetChildren())
end

local ACTIONS = {}
ACTIONS.A1_dispose = function(env)
	if not env.orphan then return "no orphan" end
	local r = try(function() q.dispose(env.orphan) end)
	return ("dispose=%s childDestroyed=%s slot1.destroyed=%s slot2.destroyed=%s"):format(r, tostring(mock.isDestroyed(env.child)), tostring(env.slot1._destroyed), tostring(env.slot2._destroyed))
end
ACTIONS.A2_rawDestroy = function(env)
	if not env.orphan then return "no orphan" end
	local r = try(function() env.orphan:Destroy() end)
	return ("Destroy=%s childDestroyed=%s slot1.destroyed=%s"):format(r, tostring(mock.isDestroyed(env.child)), tostring(env.slot1._destroyed))
end
ACTIONS.A3_retrySameProps = function(env)
	env.fail = false
	local r = try(function() return env.comp() end)
	return "retry=" .. r
end
ACTIONS.A3b_retrySameProps_afterDispose = function(env)
	if env.orphan then pcall(q.dispose, env.orphan) end
	env.fail = false
	local r = try(function() return env.comp() end)
	return "retry=" .. r
end
ACTIONS.A4_newTreeSameSource = function(env)
	env.fail = false
	gc(); local s0 = nsubs(env.src)
	local f = D.Frame({ Name = env.src:Compute(function(s) return "X" .. s:Get() end), D.Frame({ Name = env.src:Compute(function(s) return tostring(s:Get()) end) }) })
	gc(); local s1 = nsubs(env.src)
	env.src:Set(100)
	local ok = f.Name == "X100"
	return ("subs %d -> %d, newTree follows=%s, child follows=%s"):format(s0, s1, tostring(ok), tostring(env.child.Name))
end
ACTIONS.A5_reuseSlotNewTree = function(env)
	local r1 = try(function() D.Frame({ env.slot1 }) end)
	local r2 = try(function() D.Frame({ env.slot2 }) end)
	return ("slot1->new=%s slot2->new=%s"):format(r1, r2)
end
ACTIONS.A5b_reuseSlotAfterDispose = function(env)
	if env.orphan then pcall(q.dispose, env.orphan) end
	local r1 = try(function() D.Frame({ env.slot1 }) end)
	local r2 = try(function() env.slot2:Add(D.Frame({})) end)
	return ("slot1->new=%s slot2:Add=%s"):format(r1, r2)
end
ACTIONS.A5c_slotCRUD = function(env)
	local r1 = try(function() env.slot1:Add(D.Frame({})) end)
	local r2 = try(function() env.slot2:Add(D.Frame({})) end)
	local r3 = try(function() env.slot2:Clear() end)
	local r4 = try(function() q.dispose(env.slot2) end)
	return ("s1:Add=%s s2:Add=%s s2:Clear=%s dispose(s2)=%s"):format(r1, r2, r3, r4)
end
ACTIONS.A5d_childToNewTree = function(env)
	local r1 = try(function() D.Frame({ env.child }) end)
	local r2 = try(function() q.dispose(env.child) end)
	return ("child->new=%s dispose(child)=%s"):format(r1, r2)
end
ACTIONS.A6_listDataSet = function(env)
	if not env.data then return "n/a" end
	env.fail = false
	local r = try(function() env.data:Set({ 1, 2, 3, 4, 5 }) end)
	local ls = env.slot1
	return ("data:Set=%s L=%s kids=%s"):format(r, tostring(ls.Length:Get()), env.orphan and #env.orphan:GetChildren() or "-")
end
ACTIONS.A8_gc = function(env)
	local weak = setmetatable({}, { __mode = "k" })
	if env.orphan then weak[env.orphan] = "orphan" end
	weak[env.child] = "child"; weak[env.slot1] = "slot1"; weak[env.slot2] = "slot2"
	local src = env.src
	env.orphan, env.child, env.slot1, env.slot2, env.comp, env.data = nil, nil, nil, nil, nil, nil
	gc(); gc()
	local left = {}
	for k, v in weak do table.insert(left, v) end
	table.sort(left)
	return ("alive=[%s] src.subs=%d"):format(table.concat(left, ","), nsubs(src))
end
ACTIONS.A8b_disposeThenGc = function(env)
	if env.orphan then pcall(q.dispose, env.orphan) end
	local weak = setmetatable({}, { __mode = "k" })
	if env.orphan then weak[env.orphan] = "orphan" end
	weak[env.child] = "child"; weak[env.slot1] = "slot1"; weak[env.slot2] = "slot2"
	local src = env.src
	env.orphan, env.child, env.slot1, env.slot2, env.comp, env.data = nil, nil, nil, nil, nil, nil
	gc(); gc()
	local left = {}
	for k, v in weak do table.insert(left, v) end
	table.sort(left)
	return ("alive=[%s] src.subs=%d"):format(table.concat(left, ","), nsubs(src))
end

local ORDER = { "A1_dispose", "A2_rawDestroy", "A3_retrySameProps", "A3b_retrySameProps_afterDispose", "A4_newTreeSameSource", "A5_reuseSlotNewTree", "A5b_reuseSlotAfterDispose", "A5c_slotCRUD", "A5d_childToNewTree", "A6_listDataSet", "A8_gc", "A8b_disposeThenGc" }
for _, a in ORDER do
	print("\n=== " .. a .. " ===")
	for _, site in SITES do
		local env = setup(site)
		local ok, res = pcall(ACTIONS[a], env)
		print(site, ok and res or ("ACTION THREW " .. code(res)))
	end
end

print("\n=== EXTRA-1: S3 list slot after throw — which ops are refused, which silent ===")
do
	local env = setup("S3")
	print("err", env.firstErr, "slot1 elements", #env.slot1._elements, "orphan kids", #env.orphan:GetChildren())
	env.fail = false
	print("data:Set (fail off) ->", try(function() env.data:Set({ 1, 2, 3, 4, 5 }) end), "L", env.slot1.Length:Get(), "kids", #env.orphan:GetChildren(), "mat", env.slot1._materializing)
	print("slot2:Add ->", try(function() env.slot2:Add(D.Frame({})) end), "slot1.Offset", env.slot1.Offset:Get(), "(slot2 grew to", env.slot2.Length:Get(), ")")
	print("dispose(slot1) ->", try(function() q.dispose(env.slot1) end))
	print("dispose(orphan) ->", try(function() q.dispose(env.orphan) end))
	print("after dispose data:Set ->", try(function() env.data:Set({ 9 }) end))
end

print("\n=== EXTRA-2 (S3c): :List Slot whose updateFn throws, Added at runtime into a LIVE tree ===")
do
	local fail = true
	local data = q.Source({ 1, 2, 3 })
	local listSlot = q.Slot():List(data, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		if fail and ctx.Item == 2 then error("S3c") end
		return ctx.Prev or D.Frame({ Name = "L" .. ctx.Item })
	end, function(x) return x end)
	local outer = q.Slot({ D.Frame({ Name = "o1" }) })
	local after = q.Slot({ D.Frame({ Name = "after" }) })
	local live = D.Frame({ outer, after })
	local r = q.Fallback(function() outer:Add(listSlot) end, function(e) return code(e) end)()
	print("outer:Add(listSlot) swallowed ->", r)
	print("live gate", blocking(live), "outer mat", outer._materializing, "outer gate", blocking(outer), "listSlot mat", listSlot._materializing, "listSlot gate", blocking(listSlot))
	print("outer.L", outer.Length:Get(), "after.Offset", after.Offset:Get(), "live kids", #live:GetChildren())
	print("outer:Add(x) ->", try(function() outer:Add(D.Frame({})) end))
	print("outer:Remove(1) ->", try(function() outer:Remove(1) end))
	print("outer:Clear() ->", try(function() outer:Clear() end))
	print("after:Add(x) ->", try(function() after:Add(D.Frame({})) end), "after.L", after.Length:Get(), "after.Offset", after.Offset:Get())
	fail = false
	print("data:Set fail off ->", try(function() data:Set({ 1, 2, 3, 4 }) end), "listSlot.L", listSlot.Length:Get(), "outer.L", outer.Length:Get(), "after.Offset", after.Offset:Get())
	print("dispose(listSlot) ->", try(function() q.dispose(listSlot) end))
	print("dispose(outer) ->", try(function() q.dispose(outer) end))
	print("dispose(live) ->", try(function() q.dispose(live) end))
	local w = setmetatable({}, { __mode = "k" }); w[live] = 1; w[outer] = 1; w[listSlot] = 1
	live, outer, listSlot, after = nil, nil, nil, nil
	gc(); gc(); local n = 0; for _ in w do n += 1 end
	print("after dispose(live)+gc alive", n, "data.subs", nsubs(data))
end

print("\n=== EXTRA-3 (S3d): mounted :List, data:Set whose updateFn throws (inside Fallback) ===")
do
	local fail = false
	local data = q.Source({ 1, 2 })
	local ls = q.Slot():List(data, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		if fail and ctx.Item == 3 then error("S3d") end
		return ctx.Prev or D.Frame({ Name = "L" .. ctx.Item })
	end, function(x) return x end)
	local after = q.Slot({ D.Frame({ Name = "after" }) })
	local live = D.Frame({ ls, after })
	fail = true
	local r = q.Fallback(function() data:Set({ 1, 2, 3, 4 }) end, function(e) return code(e) end)()
	print("data:Set swallowed ->", r, "ls gate", blocking(ls), "ls mat", ls._materializing, "live gate", blocking(live))
	print("ls.L", ls.Length:Get(), "after.Offset", after.Offset:Get(), "live kids", #live:GetChildren())
	fail = false
	print("data:Set again ->", try(function() data:Set({ 1, 2, 3, 4 }) end), "ls.L", ls.Length:Get(), "after.Offset", after.Offset:Get(), "kids", #live:GetChildren())
	print("data:Set shrink ->", try(function() data:Set({ 1 }) end), "ls.L", ls.Length:Get(), "after.Offset", after.Offset:Get(), "kids", #live:GetChildren())
end

print("\n=== EXTRA-4: registry after dispose(orphan) + dropping the orphan reference + GC ===")
for _, site in { "S1", "S6b" } do
	local env = setup(site)
	q.dispose(env.orphan)
	local w = setmetatable({}, { __mode = "k" }); w[env.orphan] = 1
	env.orphan = nil
	gc(); gc()
	local alive = next(w) ~= nil
	print(site, "orphan alive after drop+gc", alive, "slot1._mountedInst set", env.slot1._mountedInst ~= nil,
		"slot1->new", try(function() D.Frame({ env.slot1 }) end), "slot2:Add", try(function() env.slot2:Add(D.Frame({})) end))
end

print("\n=== EXTRA-5: zombie slot Add after dispose(orphan) — where does the element go? ===")
do
	local env = setup("S1")
	local o = env.orphan
	q.dispose(o)
	local x = D.Frame({ Name = "zx" })
	print("slot2:Add ->", try(function() env.slot2:Add(x) end), "x.Parent==orphan", x.Parent == o, "orphan destroyed", mock.isDestroyed(o), "x destroyed", mock.isDestroyed(x), "slot2.L", env.slot2.Length:Get())
end

print("\n=== EXTRA-6: outer Ref/PreRef/PostRef after dispose(orphan) (Q83 (b) assumption check) ===")
do
	local fail = true
	local r, pre = q.Ref(nil), q.PreRef(nil)
	local orphan
	local comp = function() return D.Frame({ q.OnCreated(function(i) orphan = i end), r, pre, Name = q.Source(1):Compute(function() if fail then error("x") end return "n" end) }) end
	q.Fallback(comp, function() end)()
	print("r.Value==orphan", r.Value == orphan, "pre.Value==orphan", pre.Value == orphan)
	print("reuse before dispose: r", try(function() D.Frame({ r }) end), "pre", try(function() D.Frame({ pre }) end))
	q.dispose(orphan)
	print("reuse after dispose: r", try(function() D.Frame({ r }) end), "pre", try(function() D.Frame({ pre }) end))
end

print("\n=== EXTRA-7: orphan's own bookkeeping after dispose — getOffsetAt / getBlocker on the corpse ===")
do
	local env = setup("S1")
	local o = env.orphan
	print("before: getOffsetAt(o,4)", try(function() return BK.getOffsetAt(o, 4) end), BK.getOffsetAt(o, 4))
	q.dispose(o)
	print("after dispose: gate", blocking(o), "rgate", rblocking(o), "getOffsetAt", try(function() BK.getOffsetAt(o, 4) end))
end

print("\n=== EXTRA-8: Traceback trace — which line is the user's throw site ===")
local function frames(trace)
	local out = {}
	for line in string.gmatch(trace, "[^\n]+") do table.insert(out, line) end
	return out
end
local function firstProbe(fr)
	for i, l in fr do if string.find(l, "probe.e5b", 1, true) then return i, l end end
	return nil
end
local CASES = {
	{ "user error() in component body", function() error("plain") end },
	{ "quad surface misuse direct (q.Tag(\"\"))", function() q.Tag("") end },
	{ "user Compute throws at dispatch (string key)", function() return D.Frame({ Name = q.Source(1):Compute(function() error("cmp") end) }) end },
	{ "quad error at dispatch (unknown key)", function() return D.Frame({ NoSuchProp = 1 }) end },
	{ "quad error at dispatch (numeric bad value)", function() return D.Frame({ 42 }) end },
	{ "OnRendered throws", function() return D.Frame({ q.OnRendered(function() error("rendered") end) }) end },
	{ ":List updateFn throws on mount", function() return D.Frame({ q.Slot():List({ 1 }, function() error("upd") end) }) end },
}
for _, c in CASES do
	q.Traceback(c[2], function(err, trace)
		local fr = frames(trace)
		local i, l = firstProbe(fr)
		print(("%-46s err=%s | frames=%d first=%s | first probe frame #%s: %s"):format(c[1], code(err), #fr, (string.gsub(fr[1] or "", "^.*/quad/", "")), tostring(i), l and (string.gsub(l, "^.*test/", "")) or "-"))
	end)()
end
do
	q.Traceback(function() return D.Frame({ Name = q.Source(1):Compute(function() error("cmp") end) }) end, function(err, trace)
		print("FULL TRACE (user Compute at dispatch):\n" .. trace)
	end)()
	q.Traceback(function() q.Tag("") end, function(err, trace)
		print("FULL TRACE (quad surface misuse):\n" .. trace)
		print("err string:", err)
	end)()
end

print("\n=== EXTRA-9: more trace shapes — err-prefix line vs first user frame ===")
local CASES2 = {
	{ "nested D.Frame unknown key in updateFn", function() return D.Frame({ q.Slot():List({ 1 }, function() return D.Frame({ NoSuch = 1 }) end) }) end },
	{ "Slot ctor hole", function() return q.Slot({ nil, D.Frame({}) }) end },
	{ "dispose(nil)", function() q.dispose(nil) end },
	{ "Ref reuse Quad0233 at dispatch", function() local r = q.Ref(nil); D.Frame({ r }); return D.Frame({ r }) end },
	{ "Compute read after throw (same gen)", function() local c = q.Source(1):Compute(function() error("once") end); pcall(c.Get, c); return c:Get() end },
	{ "user error inside helper 2 deep", function() local function h2() error("deep") end local function h1() h2() end h1() end },
}
for _, c in CASES2 do
	q.Traceback(c[2], function(err, trace)
		local fr = frames(trace)
		local pl = {}
		for i, l in fr do if string.find(l, "probe.e5b", 1, true) then table.insert(pl, i .. "@" .. string.match(l, ":(%d+)")) end end
		local prefix = string.match(tostring(err), "probe%.e5b%.luau:(%d+):") or "-"
		print(("%-42s err=%s prefixLine=%s frames=%d probeFrames=%s f1=%s"):format(c[1], code(err), prefix, #fr, table.concat(pl, ","), (string.gsub(fr[1] or "", "^.*/", ""))))
	end)()
end

print("\n=== EXTRA-10: recovery through the outer Ref — dispose(r.Value) then reuse r ===")
do
	local fail = true
	local r, post = q.Ref(nil), q.PostRef(nil)
	local src = q.Source(1)
	local comp = function() return D.Frame({ r, Name = src:Compute(function(s) if fail then error("x") end return "n" .. s:Get() end) }) end
	q.Fallback(comp, function() end)()
	local corpse = r.Value
	print("r.Value is orphan", corpse ~= nil, "gate", blocking(corpse))
	q.dispose(r.Value)
	fail = false
	local f
	print("retry comp with same r ->", try(function() f = comp() end), "r.Value==new", r.Value == f, "new gate", f and blocking(f))
	local w = setmetatable({}, { __mode = "k" }); w[corpse] = 1; corpse = nil
	gc(); gc()
	print("corpse collected after rebinding r", next(w) == nil, "src.subs", nsubs(src))
	-- PostRef after dispose
	local failp = true
	local comp2 = function() return D.Frame({ post, Name = src:Compute(function() if failp then error("y") end return "m" end) }) end
	local orphan
	q.Fallback(function() return D.Frame({ q.OnCreated(function(i) orphan = i end), post, Name = src:Compute(function() error("y") end) }) end, function() end)()
	q.dispose(orphan)
	print("PostRef after dispose(orphan) reuse ->", try(function() D.Frame({ post }) end))
end
