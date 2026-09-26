-- round13 E9 probe (lifetime layer, quad-base). Run: copy to quad-base/test/probe.e9.luau, ./scripts/relink.sh, luau quad-base/test/probe.e9.luau
local Quad = require("../src")
local mock = require("./mock")
local collectgarbage = (_G :: any).collectgarbage
local Instance = mock.Instance
local q: any = mock.newQuad()
local B = q.Backend
local function T(name, f)
	local ok, err = pcall(f)
	print(`--- {name}: {ok and "ok" or ("ERR " .. tostring(err))}`)
end
local function E(f, ...)
	local ok, err = pcall(f, ...)
	return ok and "ok" or tostring(err):match("Quad%d+[^\n]*") or tostring(err)
end
local function gc() for _ = 1, 3 do collectgarbage("collect") end end

T("P1 same value two insts / same inst twice / isHeldBy", function()
	local a, b = Instance.new("Frame"), Instance.new("Frame")
	local v = function() end
	B.bindLifetime(a, v)
	print(" again same inst:", E(B.bindLifetime, a, v))
	print(" other inst:", E(B.bindLifetime, b, v))
	print(" isHeldBy a,b:", B.isHeldBy(v, a), B.isHeldBy(v, b))
	B.unbindLifetime(v)
	print(" after unbind canBound/canExecute:", B.canBound(v), B.canExecute(v), "isHeldBy a", B.isHeldBy(v, a))
	B.bindLifetime(b, v)
	print(" rebind b:", B.canExecute(v), B.isHeldBy(v, b))
	B.unbindLifetime(v); B.unbindLifetime(v)
	print(" double unbind ok; nil unbind:", E(B.unbindLifetime, nil))
end)

T("P2 primitive values collide across unrelated binds", function()
	local a, b = Instance.new("Frame"), Instance.new("Frame")
	B.bindLifetime(a, "label")
	print(" string on other inst:", E(B.bindLifetime, b, "label"))
	B.bindLifetime(a, 1)
	print(" number on other inst:", E(B.bindLifetime, b, 1))
	print(" bool:", E(B.bindLifetime, a, true), E(B.bindLifetime, b, true))
	a:Destroy()
	print(" after a destroyed, string rebinding b:", E(B.bindLifetime, b, "label"))
end)

T("P3 bind to destroyed inst (mock) — never bound before vs bound before", function()
	local a = Instance.new("Frame"); a:Destroy()
	local v = {}
	print(" fresh-destroyed:", E(B.bindLifetime, a, v), "canExecute", B.canExecute(v))
	local b = Instance.new("Frame"); B.bindLifetime(b, {}); b:Destroy()
	local w = {}
	print(" bound-then-destroyed:", E(B.bindLifetime, b, w), "canExecute", B.canExecute(w))
	local f = Instance.foreign("Frame")
	local x = {}
	print(" foreign:", E(B.bindLifetime, f, x), "isClaimed now", B.isClaimed(f))
end)

T("P4 bind during Destroying (never-bound inst vs bound inst)", function()
	for _, prebound in { false, true } do
		local a = Instance.new("Frame")
		if prebound then B.bindLifetime(a, {}) end
		local v = {}
		local during
		a.Destroying:Connect(function()
			during = E(B.bindLifetime, a, v) .. " canExecute=" .. tostring(B.canExecute(v)) .. " isClaimed=" .. tostring(B.isClaimed(a))
		end)
		a:Destroy()
		print(" prebound", prebound, "during:", during, "after canExecute", B.canExecute(v))
	end
end)

T("P5 Effect bound during host Destroying — cleanup?", function()
	for _, prebound in { false, true } do
		local a = Instance.new("Frame")
		if prebound then B.bindLifetime(a, {}) end
		local log = {}
		local eff = q.Effect(function()
			log[#log + 1] = "fn"
			return function(dying) log[#log + 1] = "cleanup dying=" .. tostring(dying) end
		end)
		a.Destroying:Connect(function()
			B.bindLifetime(a, eff)
		end)
		a:Destroy()
		print(" prebound", prebound, "log:", table.concat(log, ","), "cleanup pending:", eff._cleanup ~= nil, "canBound", B.canBound(eff))
		-- afterwards: rebinding elsewhere, then destroy there
		local b = Instance.new("Frame")
		print("  rebind b:", E(B.bindLifetime, b, eff)); b:Destroy()
		print("  after b destroyed log:", table.concat(log, ","))
	end
end)

T("P6 unbind during own host Destroying (user handler connected after the bind)", function()
	local a = Instance.new("Frame")
	local log = {}
	local eff = q.Effect(function() return function(d) log[#log + 1] = "c" .. tostring(d) end end)
	B.bindLifetime(a, eff)
	a.Destroying:Connect(function() B.unbindLifetime(eff); log[#log + 1] = "unbound" end)
	a:Destroy()
	print(" log:", table.concat(log, ","), "cleanup pending:", eff._cleanup ~= nil)
	local b = Instance.new("Frame")
	B.bindLifetime(b, eff)
	a = nil
	print(" rebound b log:", table.concat(log, ","))
	b:Destroy()
	print(" b destroyed log:", table.concat(log, ","))
end)

T("P7 rebind during Destroying to a new inst (unbind first)", function()
	local a, b = Instance.new("Frame"), Instance.new("Frame")
	local log = {}
	local s = q.Source(0)
	local eff = q.Effect(function() log[#log + 1] = "fn" .. s:Get(); return function(d) log[#log + 1] = "c" .. tostring(d) end end, s)
	B.bindLifetime(a, eff)
	a.Destroying:Connect(function()
		print("  in Destroying bind b w/o unbind:", E(B.bindLifetime, b, eff))
		B.unbindLifetime(eff); B.bindLifetime(b, eff)
	end)
	a:Destroy()
	s:Set(1)
	print(" log:", table.concat(log, ","), "canExecute", B.canExecute(eff), "_dying", eff._dying)
	b:Destroy()
	print(" after b destroyed:", table.concat(log, ","))
end)

T("P8 dying across Effect consume sites", function()
	local inst = Instance.new("Frame")
	local log = {}
	local s = q.Source(0)
	local eff = q.Effect(function() log[#log + 1] = "fn"; return function(d) log[#log + 1] = "c:" .. tostring(d) end end, s)
	-- 1) rerun
	B.bindLifetime(inst, eff); s:Set(1)
	-- 2) unbind then weak subscribe/ Unsubscribe
	B.unbindLifetime(eff); eff:Subscribe(); eff:Unsubscribe()
	-- 3) seat swap via State
	local st = q.Source(eff)
	local eff2 = q.Effect(function() return function(d) log[#log + 1] = "c2:" .. tostring(d) end end)
	q.Dispatch.drive(inst, { st })
	st:Set(eff2)
	-- 4) Destroying
	inst:Destroy()
	print(" log:", table.concat(log, ","))
	-- 5) Effect whose host dies while it's seated in a State position that is retracted by Destroy
end)

T("P9 dying: Destroy of ancestor while Effect seated via drive; OnDestroyed", function()
	local parent = Instance.new("Frame")
	local child = Instance.new("Frame"); child.Parent = parent
	local log = {}
	q.Dispatch.drive(child, { q.OnDestroyed(function() log[#log + 1] = "destroyed" end), q.Effect(function() return function(d) log[#log + 1] = "c:" .. tostring(d) end end) })
	parent:Destroy()
	print(" log:", table.concat(log, ","))
end)

T("P10 Observer bound: host destroyed, then rebind; and Observer subscribed then bind", function()
	local s = q.Source(0)
	local seen = {}
	local o = s:Observer(function(st) seen[#seen + 1] = st:Get() end)
	local a = Instance.new("Frame")
	B.bindLifetime(a, o)
	s:Set(1); a:Destroy(); s:Set(2)
	print(" seen after destroy:", table.concat(seen, ","), "canBound", B.canBound(o))
	local b = Instance.new("Frame"); B.bindLifetime(b, o)
	print(" seen after rebind (catch-up):", table.concat(seen, ","))
	B.unbindLifetime(b and o); o:Subscribe()
	print(" bind while subscribed:", E(B.bindLifetime, b, o), "unbind while subscribed:", E(B.unbindLifetime, o), "still subscribed", o.Subscribed)
end)

T("P11 GC: value bound to destroyed inst collects; unbound value collects; bind table remnants", function()
	local weak = setmetatable({}, { __mode = "v" })
	do
		local a = Instance.new("Frame")
		local v = {}
		weak.v = v
		B.bindLifetime(a, v)
		a:Destroy()
	end
	do
		local a2 = Instance.new("Frame")
		weak.a2 = a2
		local w = {}
		weak.w = w
		B.bindLifetime(a2, w)
		B.unbindLifetime(w)
		weak.keep = a2
		local _ = a2
	end
	do
		local d = Instance.new("Frame")
		local eff = q.Effect(function() return function() end end)
		weak.eff = eff
		B.bindLifetime(d, eff)
		B.nativeDispose(d)
	end
	gc()
	print(" v (destroyed host)", weak.v == nil and "collected" or "ALIVE", "| w (unbound, host alive)", weak.w == nil and "collected" or "ALIVE", "| eff after nativeDispose", weak.eff == nil and "collected" or "ALIVE")
	
end)

T("P12 GC: value bound to live inst stays; inst dropped w/o Destroy (engine rule)", function()
	local weak = setmetatable({}, { __mode = "v" })
	local a = Instance.new("Frame")
	do local v = {}; weak.v = v; B.bindLifetime(a, v) end
	gc()
	print(" held while inst alive:", weak.v ~= nil)
end)

T("P13 canBound == not canExecute over odd values", function()
	local vals = { {}, function() end, 0, "s", true, false, { Subscribed = true }, q.Source(0), q.Effect(function() end) }
	local bad = 0
	for i, v in vals do
		if B.canBound(v) == B.canExecute(v) then bad += 1; print("  mismatch", i) end
	end
	print(" mismatches:", bad, " canBound(nil),canExecute(nil):", B.canBound(nil), B.canExecute(nil))
	print(" bindLifetime(false):", E(B.bindLifetime, Instance.new("Frame"), false))
end)

T("P14 NotInstalled stubs on bare New() — every Backend op + public entry points", function()
	local fresh: any = Quad.New()
	local names = { "holdLifetime", "releaseLifetime", "isHeld", "isHeldBy", "onDestroying", "isInst", "nativeClaim", "isClaimed", "nativeFindChild", "nativeInsert", "nativeExtract", "nativeRemove", "nativeMove", "nativeSwap", "nativeDispose", "setTimeout", "clearTimeout", "addTag", "removeTag", "setAttr" }
	local n = 0
	for _, name in names do
		local r = E(fresh.Backend[name] or function() error("MISSING") end, {}, {})
		if not r:match("^Quad0108") then print("  NOT 0108:", name, r) else n += 1 end
	end
	print(" stubs Quad0108:", n, "/", #names)
	-- anything else function-valued on Backend not in the list?
	local set = {}
	for _, nm in names do set[nm] = true end
	for k, v in fresh.Backend do
		if type(v) == "function" and not set[k] then print("  other Backend fn:", k, E(v, {}, {})) end
	end
	-- public surface on a bare module
	local s = fresh.Source(0)
	print(" Observer:Subscribe:", E(function() s:Observer(function() end):Subscribe() end))
	print(" Observer:WeakSubscribe:", E(function() s:Observer(function() end):WeakSubscribe() end))
	print(" Effect ctor:", E(function() fresh.Effect(function() end) end))
	print(" Effect:Subscribe:", E(function() fresh.Effect(function() end):Subscribe() end))
	print(" Source:Set with weak observer:", E(function() s:Set(1) end))
	print(" Debounce:", E(function() local d = s:Apply(fresh.Debounce({ Time = 1 })); d:Observer(function() end):WeakSubscribe(); s:Set(2) end))
	print(" Slot:Add:", E(function() fresh.Slot():Add({}) end))
	print(" Slot ctor:", E(function() fresh.Slot() end))
	print(" Claim:", E(function() fresh.Claim({}, {}) end))
	print(" dispose:", E(function() fresh.dispose({}) end))
	print(" drive Effect:", E(function() fresh.Dispatch.drive({}, { fresh.Effect(function() end) }) end))
	print(" drive Tag:", E(function() fresh.Dispatch.drive({}, { fresh.Tag("x") }) end))
	print(" drive Ref:", E(function() fresh.Dispatch.drive({}, { fresh.Ref() }) end))
	print(" drive Attr:", E(function() fresh.Dispatch.drive({}, { fresh.Attr({ A = 1 }) }) end))
	print(" drive Slot:", E(function() fresh.Dispatch.drive({}, { fresh.Slot() }) end))
	print(" OnDestroyed drive:", E(function() fresh.Dispatch.drive({}, { fresh.OnDestroyed(function() end) }) end))
end)

T("P15 State<Effect> seat re-seated during host Destroy wave (sibling Destroying handler Sets it)", function()
	for _, order in { "handler-first", "handler-last" } do
		local inst = Instance.new("Frame")
		local log = {}
		local function mk(tag) return q.Effect(function() log[#log + 1] = tag .. ".fn"; return function(d) log[#log + 1] = tag .. ".c:" .. tostring(d) end end) end
		local A, Bf = mk("A"), mk("B")
		local st = q.Source(A)
		if order == "handler-first" then inst.Destroying:Connect(function() st:Set(Bf) end) end
		q.Dispatch.drive(inst, { st })
		if order == "handler-last" then inst.Destroying:Connect(function() st:Set(Bf) end) end
		inst:Destroy()
		print(" ", order, "log:", table.concat(log, ","), "| B cleanup pending:", Bf._cleanup ~= nil, "B canBound:", B.canBound(Bf))
	end
end)

T("P16 OnDestroyed seated via State swapped in during wave", function()
	local inst = Instance.new("Frame")
	local log = {}
	local st = q.Source(q.OnDestroyed(function() log[#log + 1] = "A" end))
	q.Dispatch.drive(inst, { st })
	inst.Destroying:Connect(function() st:Set(q.OnDestroyed(function() log[#log + 1] = "B" end)) end)
	inst:Destroy()
	print(" log:", table.concat(log, ","))
end)

T("P17 Slot mounted on destroyed host — remount elsewhere / canBound", function()
	local a = Instance.new("Frame")
	local s = q.Slot()
	q.Dispatch.drive(a, { s })
	a:Destroy()
	print(" canBound(slot)", B.canBound(s), "destroyed flag", s._destroyed)
	local b = Instance.new("Frame")
	print(" remount on b:", E(function() q.Dispatch.drive(b, { s }) end))
	gc()
	print(" remount on c after GC:", E(function() q.Dispatch.drive(Instance.new("Frame"), { s }) end))
end)

T("P18 State<Slot> seat swapped during host Destroy wave", function()
	local a = Instance.new("Frame")
	local s1, s2 = q.Slot(), q.Slot()
	local child = Instance.new("TextLabel")
	s2:Add(child)
	local st = q.Source(s1)
	q.Dispatch.drive(a, { st })
	a.Destroying:Connect(function() st:Set(s2) end)
	a:Destroy()
	print(" child destroyed?", mock.isDestroyed(child), "s2 destroyed flag", s2._destroyed, "canBound(s2)", B.canBound(s2))
	print(" remount s2 on b:", E(function() q.Dispatch.drive(Instance.new("Frame"), { s2 }) end))
end)

T("P19 unbindLifetime on never-bound values allocates BindData buckets", function()
	local keep = table.create(20000)
	for i = 1, 20000 do keep[i] = {} end
	gc()
	local before = collectgarbage("count")
	for i = 1, 20000 do B.unbindLifetime(keep[i]) end
	gc()
	print(string.format(" KB grown for 20000 no-op unbinds (values kept alive): %.1f", collectgarbage("count") - before))
	keep = nil
end)

T("P20 AddPlugin / UseProvider closure capturing the module — module collectable?", function()
	local weak = setmetatable({}, { __mode = "v" })
	do
		local m: any = Quad.New()
		m:AddPlugin(function() local _ = m; return {} end)
		weak.m = m
	end
	do
		local m2: any = Quad.New()
		weak.m2 = m2
	end
	gc()
	print(" module with capturing plugin:", weak.m == nil and "collected" or "ALIVE", "| control module:", weak.m2 == nil and "collected" or "ALIVE")
end)
