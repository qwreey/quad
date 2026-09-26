--!nocheck
-- P-gates Q108 probe (2026-09-27): UseProvider re-entry. Run from scratch root: luau probes/pgates.q108.luau
local Quad = require("../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../quad-roblox/src").QuadRoblox
local mock = require("../quad-base/test/mock")
local function E(f)
	local ok, err = pcall(f)
	if ok then return "ok" end
	local s = tostring(err)
	return s:gsub("^.-/probes/", "probes/"):sub(1, 260)
end
local function T(n, f) print(n .. " => " .. E(f)) end
local function slot(m) return m.__probeSlot end

print("== B1 provider body installs a different provider ==")
do
	local m = Quad.New()
	local P2 = function(q) q.Backend.fromP2 = true; return { P2Field = 2 } end
	local P1 = function(q) q:UseProvider(P2); q.Backend.fromP1 = true; return { P1Field = 1 } end
	T("UseProvider(P1)", function() m:UseProvider(P1) end)
	print("   merged P1/P2:", m.P1Field, m.P2Field, " backend marks:", m.Backend.fromP1, m.Backend.fromP2)
	T("  then UseProvider(P2) alone", function() m:UseProvider(P2) end)
	T("  then UseProvider(P1) (slot now P2)", function() m:UseProvider(P1) end)
end
print("== B2 provider re-enters itself ==")
do
	local m = Quad.New()
	local depth = 0
	local P
	P = function(q) depth += 1; if depth < 5 then q:UseProvider(P) end; return {} end
	T("self-reentrant provider", function() m:UseProvider(P) end)
	print("   body ran", depth, "times")
	depth = 10 -- no more recursion on retry
	T("  retry (body no longer recurses)", function() m:UseProvider(P) end)
end
print("== B2u unbounded self recursion ==")
do
	local m = Quad.New()
	local n = 0
	local P
	P = function(q) n += 1; q:UseProvider(P); return {} end
	T("unbounded", function() m:UseProvider(P) end)
	print("   body ran", n, "times")
end
print("== B3 yielding provider, two threads ==")
do
	local m = Quad.New()
	local runs, waiting = 0, {}
	local P = function(q)
		runs += 1
		table.insert(waiting, coroutine.running())
		coroutine.yield()
		return { Y = runs }
	end
	local c1 = coroutine.create(function() m:UseProvider(P) end)
	local c2 = coroutine.create(function() m:UseProvider(P) end)
	print("   c1", coroutine.resume(c1))
	local ok2, e2 = coroutine.resume(c2)
	print("   c2", ok2, (tostring(e2):gsub("^.-/probes/", "probes/")))
	for _, th in waiting do print("   resume", coroutine.resume(th)) end
	print("   body runs:", runs, " Y:", m.Y)
	T("  UseProvider(P) after", function() m:UseProvider(P) end)
end
print("== B6 throwing provider, then retry / then a different provider ==")
do
	local m = Quad.New()
	local fail = true
	local P = function(q) q.Backend.partial = true; if fail then error("boom") end; return { Ok = true } end
	T("throwing P", function() m:UseProvider(P) end)
	fail = false
	T("  retry P", function() m:UseProvider(P) end)
	print("   Ok:", m.Ok)
	local m2 = Quad.New()
	T("throwing P on m2", function() fail = true; m2:UseProvider(P) end)
	T("  different provider on m2", function() m2:UseProvider(function() return { Other = 1 } end) end)
	local m3 = Quad.New()
	T("provider throwing a table on m3", function() m3:UseProvider(function() error({ code = 7 }) end) end)
	local ok, v = pcall(function() m3:UseProvider(function() error({ code = 7 }) end) end)
	print("   table error identity kept:", type(v) == "table" and v.code)
end
print("== R Quad0228 retry path (quad-roblox) ==")
do
	local m = Quad.New()
	m.Version = "2.0.0"
	T("UseProvider(QuadRoblox) with Version 2.0.0", function() m:UseProvider(QuadRoblox) end)
	m.Version = "3.2.0"
	T("  retry after Version fix", function() m:UseProvider(QuadRoblox) end)
	print("   Declaration present:", m.Declaration ~= nil, " handlers:", #m.Dispatch.listHandlers())
end
print("== N normal paths ==")
do
	local m = Quad.New()
	local P = function(q)
		q:RunInit(function(qq) qq.initRan = true end)
		q:AddPlugin(function() return { FromPlugin = 1 } end)
		local other = Quad.New()
		other:UseProvider(function() return { InOther = 1 } end) -- a DIFFERENT module inside a provider
		q.otherOk = other.InOther
		return { P = 1 }
	end
	T("provider calling RunInit/AddPlugin/other-module UseProvider", function() m:UseProvider(P) end)
	print("   initRan/FromPlugin/otherOk/P:", m.initRan, m.FromPlugin, m.otherOk, m.P)
	local m2 = Quad.New()
	T("AddPlugin body calling UseProvider(QuadRoblox)", function() m2:AddPlugin(function(q) q:UseProvider(QuadRoblox); return {} end) end)
	print("   Declaration:", m2.Declaration ~= nil)
	local m3 = Quad.New()
	T("RunInit body calling UseProvider", function() m3:RunInit(function(q) q:UseProvider(function() return { R = 1 } end) end) end)
	print("   R:", m3.R)
	local m4 = Quad.New()
	local P2 = function() return { Inner = 1 } end
	T("provider that pcalls a nested UseProvider and continues", function()
		m4:UseProvider(function(q) local ok, e = pcall(function() q:UseProvider(P2) end); q.nestedErr = ok and "ok" or tostring(e):match("Quad%w+"); return { Outer = 1 } end)
	end)
	print("   Outer/Inner/nestedErr:", m4.Outer, m4.Inner, m4.nestedErr)
	T("mock.newQuad()", function() mock.newQuad() end)
	T("same provider twice (idempotent)", function() local q = Quad.New():UseProvider(QuadRoblox); q:UseProvider(QuadRoblox) end)
end
