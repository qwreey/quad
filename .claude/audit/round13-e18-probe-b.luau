--!nocheck
-- round13 E18 probe B (2026-09-27) — install order, provider lock, plugin dedup, debug toggles, merge. Run from repo root.
local Quad = require("../../quad-base/src")
local mock = require("../../quad-base/test/mock")
local Instance = mock.Instance
local function E(f)
	local ok, err = pcall(f)
	if ok then return "ok" end
	local s = tostring(err)
	return (s:match("Quad%d+[^\n]*") or s):sub(1, 160)
end
local function T(name, f) print(name .. " => " .. E(f)) end
local function nHandlers(q) return #q.Dispatch.listHandlers() end

print("== B1 provider nested UseProvider of a different provider ==")
do
	local m = Quad.New()
	local P2 = function(q) q.Backend.fromP2 = true; return { P2Field = 2 } end
	local P1 = function(q) q:UseProvider(P2); q.Backend.fromP1 = true; return { P1Field = 1 } end
	T("UseProvider(P1) which installs P2 inside", function() m:UseProvider(P1) end)
	print("   both merged:", m.P1Field, m.P2Field, "backend marks", m.Backend.fromP1, m.Backend.fromP2)
	T("  then UseProvider(P2) again (P2 is installed)", function() m:UseProvider(P2) end)
	T("  then UseProvider(P1) again", function() m:UseProvider(P1) end)
end

print("== B2 provider re-entering itself ==")
do
	local m = Quad.New()
	local depth = 0
	local P
	P = function(q) depth += 1; if depth < 5 then q:UseProvider(P) end; return {} end
	T("self-reentrant provider", function() m:UseProvider(P) end)
	print("   provider body ran", depth, "times")
end

print("== B3 yielding provider, two threads ==")
do
	local m = Quad.New()
	local runs = 0
	local waiting = {}
	local P = function(q)
		runs += 1
		q.Dispatch.addHandler({ name = "P-handler", isHandlable = function() return false end, process = function() return Quad.Void end, priority = 17 })
		table.insert(waiting, coroutine.running())
		coroutine.yield()
		return {}
	end
	local c1 = coroutine.create(function() m:UseProvider(P) end)
	local c2 = coroutine.create(function() m:UseProvider(P) end)
	coroutine.resume(c1); coroutine.resume(c2)
	for _, th in waiting do print("   resume", coroutine.resume(th)) end
	print("   provider body runs:", runs, "handlers named P-handler:", (function() local n = 0; for _, h in m.Dispatch.listHandlers() do if h.name == "P-handler" then n += 1 end end; return n end)())
end

print("== B4 yielding plugin, two threads (dedup mark after success) ==")
do
	local m = Quad.New()
	local runs = 0
	local waiting = {}
	local plug = function(q)
		runs += 1
		table.insert(waiting, coroutine.running())
		coroutine.yield()
		return { Plug = runs }
	end
	coroutine.resume(coroutine.create(function() m:AddPlugin(plug) end))
	coroutine.resume(coroutine.create(function() m:AddPlugin(plug) end))
	for _, th in waiting do coroutine.resume(th) end
	print("   plugin body runs:", runs)
end

print("== B5 throwing plugin that registered a handler, retried ==")
do
	local m = Quad.New()
	local fail = true
	local plug = function(q)
		q.Dispatch.addHandler({ name = "Plug-h", isHandlable = function() return false end, process = function() return Quad.Void end, priority = 23 })
		if fail then error("boom") end
		return {}
	end
	T("first", function() m:AddPlugin(plug) end)
	fail = false
	T("retry", function() m:AddPlugin(plug) end)
	local n = 0; for _, h in m.Dispatch.listHandlers() do if h.name == "Plug-h" then n += 1 end end
	print("   Plug-h registered", n, "times")
end

print("== B6 throwing provider after partial Backend mutation, then a different provider ==")
do
	local m = Quad.New()
	local Bad = function(q) q.Backend.nativeInsert = function() return "BAD" end; error("provider half-way") end
	T("Bad", function() m:UseProvider(Bad) end)
	T("mockProvider after Bad", function() mock.installLifetime(m) end)
	print("   (mock overwrote nativeInsert — residue only for keys the next provider does not set)")
end

print("== B7 extension merge order: plugin before provider, same key ==")
do
	local m = Quad.New()
	m.debug = true
	m:AddPlugin(function() return { Shared = "plugin" } end)
	m:UseProvider(function() return { Shared = "provider" } end)
	print("   Shared =", m.Shared, "(no print expected — UseProvider exempt)")
	m:AddPlugin(function() return { Shared = "plugin2" } end)
	print("   Shared =", m.Shared)
end

print("== B8 plugin overwrites structural fields ==")
do
	local m = Quad.New()
	mock.installLifetime(m)
	m.debug = true
	local old = m.moduleIdentity
	m:AddPlugin(function() return { moduleIdentity = {} } end)
	T("own Slot after moduleIdentity overwrite", function() m.Dispatch.drive(Instance.new("Frame"), { m.Slot() }) end)
	T("own Source string key", function() m.Dispatch.drive(Instance.new("Frame"), { Name = m.Source("x") }) end)
	local m2 = Quad.New()
	m2:AddPlugin(function() return { Backend = {} } end)
	T("after Backend replaced — Source:Observer", function() m2.Source(1):Observer(function() end) end)
	T("after Backend replaced — drive", function() m2.Dispatch.drive(Instance.new("Frame"), {}) end)
end

print("== B9 debug toggle & handler ties ==")
do
	local m = Quad.New()
	local hs = m.Dispatch.listHandlers()
	local seen = {}
	for _, h in hs do
		local key = tostring(h.priority) .. "/" .. tostring(h.keyType)
		seen[key] = seen[key] or {}
		table.insert(seen[key], tostring(h.name))
	end
	for k, list in seen do if #list > 1 then print("   base tie", k, table.concat(list, ",")) end end
	print("   base handlers:", #hs)
	-- tie added after debug on
	m.debug = true
	m.Dispatch.addHandler({ name = "TieProbe", isHandlable = function() return false end, process = function() return Quad.Void end, priority = hs[1].priority, keyType = hs[1].keyType })
	-- debug on AFTER registering a tie
	local m3 = Quad.New()
	m3.Dispatch.addHandler({ name = "X1", isHandlable = function() return false end, process = function() return Quad.Void end, priority = 7 })
	m3.Dispatch.addHandler({ name = "X2", isHandlable = function() return false end, process = function() return Quad.Void end, priority = 7 })
	m3.debug = true
	print("   (no tie line expected above for X1/X2 — debug was off at registration)")
end

print("== B10 AddPlugin debug flag read from which module ==")
do
	local a, b = Quad.New(), Quad.New()
	a.debug = false; b.debug = true
	a.AddPlugin(b, function() return { Source = 1 } end)
	print("   b.Source overwritten:", b.Source == 1, "(debug print above? b.debug=true but a's closure reads a.debug)")
	local c = Quad.New()
	b.UseProvider(c, function() return { Z = 1 } end)
	print("   provider slot on c via b.UseProvider:", c.Z)
	T("  c:UseProvider(other)", function() c:UseProvider(function() return {} end) end)
end

print("== B11 is<Brand> scan vs user helpers ==")
do
	local m = Quad.New()
	mock.installLifetime(m)
	m.isArray = function(t) return type(t) == "table" and #t > 0 end
	T("drive with array child after q.isArray helper", function() m.Dispatch.drive(Instance.new("Frame"), { m.Slot() }) end)
	T("drive with string props (no array) ", function() m.Dispatch.drive(Instance.new("Frame"), { }) end)
	local m2 = Quad.New()
	mock.installLifetime(m2)
	m2.isNonEmpty = function(t) return type(t) == "table" and next(t) ~= nil end
	T("drive {Name='x'} after q.isNonEmpty helper", function() m2.Dispatch.drive(Instance.new("Frame"), { Foo = 1 }) end)
	local m3 = Quad.New(); mock.installLifetime(m3)
	m3.isFrameLike = function(t) return typeof(t) == "Instance" end
	T("no-match message with harmless helper", function() m3.Dispatch.drive(Instance.new("Frame"), { Foo = {} }) end)
end

print("== B12 extension shapes ==")
do
	local m = Quad.New()
	T("frozen extension", function() m:AddPlugin(function() return table.freeze({ Fz = 1 }) end) end)
	print("   Fz", m.Fz)
	T("extension with __iter", function() m:AddPlugin(function() return setmetatable({ Real = 1 }, { __iter = function() return next, { Iter = 2 } end }) end) end)
	print("   Real", m.Real, "Iter", m.Iter)
	T("module frozen by user then AddPlugin", function() local m4 = Quad.New(); table.freeze(m4); m4:AddPlugin(function() return { K = 1 } end) end)
	T("frozen module New() still usable (Source)", function() local m5 = Quad.New(); table.freeze(m5); m5.Source(1):Set(2) end)
end

print("== B13 RunInit on two instances / throwing init ==")
do
	local n = 0
	local init = function() n += 1 end
	local a, b = Quad.New(), Quad.New()
	a:RunInit(init); a:RunInit(init); b:RunInit(init)
	print("   runs", n)
	T("a.RunInit(b, init) cross-call", function() a.RunInit(b, function() end) end)
end
