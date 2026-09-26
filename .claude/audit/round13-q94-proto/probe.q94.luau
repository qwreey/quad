-- P-Q94 probe (scratch, 2026-09-27). Place at quad-roblox/test/probe.q94.luau of a variant dir; run `luau quad-roblox/test/probe.q94.luau`.
-- S1 needs a PROBE-ONLY line in the patched quad-roblox LifetimeHandle (not in the diff), right after `quad.Backend.isClaimed = isClaimed`:
--   quad.__q94probe = { anchor = GCCONN_ANCHOR, InstData = InstData }
-- Without it S1 prints "skipped". Variants: base / (b) reserved-anchor diff / (a) reject-primitive diff / both.
local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local mock = require("../../quad-base/test/mock")
local collectgarbage = (_G :: any).collectgarbage
local Instance = mock.Instance
local q: any = Quad.New():UseProvider(QuadRoblox)
q.Backend.isInst = mock.isMockInstance
local B = q.Backend
local function T(name, f)
	local ok, err = pcall(f)
	print(`--- {name}: {ok and "ok" or ("ERR " .. tostring(err))}`)
end
local function E(f, ...)
	local ok, err = pcall(f, ...)
	return ok and "ok" or tostring(err):match("Quad%w+[^\n]*") or tostring(err)
end
local function gc() for _ = 1, 5 do collectgarbage("collect") end end
-- engine-shaped fake (same as E9 R5): the engine pins the CALLBACK, the connection object lives only in Lua refs
local pinned = {}
local fnOf = setmetatable({}, { __mode = "kv" }) -- inst -> pinned callback (fn is pinned anyway)
local connOf = setmetatable({}, { __mode = "kv" }) -- inst -> conn, NOT pinning it (the whole point)
local function fakeInst()
	local inst = {}
	function inst.GetPropertyChangedSignal(self, _p)
		return { Connect = function(_s, fn)
			pinned[fn] = true
			local c = { Connected = true }
			function c.Disconnect(cc) cc.Connected = false; pinned[fn] = nil end
			fnOf[self] = fn
			connOf[self] = c
			return c
		end }
	end
	return inst
end
-- engine Destroy: unpin the callback, flip Connected on the conn if it still exists
local function fakeDestroy(inst)
	local fn = fnOf[inst]; if fn then pinned[fn] = nil end
	local c = connOf[inst]; if c then c.Connected = false end
end
local P = q.__q94probe
print("variant:", P and "anchor-sentinel" or "gchold[1]")

T("S1 sentinel is invisible to the four hold ops (b only)", function()
	if not P then print(" (no probe hook — skipped)"); return end
	local a = Instance.foreign("Frame"); B.nativeClaim(a)
	local gchold = P.InstData:GetWeak(a, "gchold")
	local gcconn = P.InstData:GetWeak(a, "gcconn")
	print(" gchold[anchor]==gcconn", gchold[P.anchor] == gcconn, "gchold[1]", gchold[1])
	print(" isHeld(anchor)", B.isHeld(P.anchor), "isHeldBy(anchor,a)", B.isHeldBy(P.anchor, a), "canBound(anchor)", B.canBound(P.anchor), "canExecute(anchor)", B.canExecute(P.anchor))
	print(" unbindLifetime(anchor):", E(B.unbindLifetime, P.anchor), "-> gchold[anchor] still gcconn", gchold[P.anchor] == gcconn, "isClaimed(a)", B.isClaimed(a))
	local v = {}
	B.bindLifetime(a, v)
	print(" after bind v: gchold[anchor] still gcconn", gchold[P.anchor] == gcconn, "isHeld(v)", B.isHeld(v), "isHeldBy(v,a)", B.isHeldBy(v, a))
	a:Destroy()
	print(" after Destroy: isHeld(v)", B.isHeld(v), "isClaimed(a)", B.isClaimed(a), "rebind:", E(B.bindLifetime, a, {}))
end)

T("S2 claim paths unchanged: New / Claim / double claim / foreign", function()
	local f = Instance.foreign("Frame")
	print(" foreign bind:", E(B.bindLifetime, f, {}), "isClaimed", B.isClaimed(f))
	B.nativeClaim(f)
	print(" claimed bind:", E(B.bindLifetime, f, {}), "double claim:", E(B.nativeClaim, f), "isClaimed", B.isClaimed(f))
	local d = Instance.foreign("Frame"); B.nativeClaim(d)
	local w = function() end
	B.bindLifetime(d, w)
	B.nativeDispose(d)
	print(" after nativeDispose: isHeld(w)", B.isHeld(w), "canBound(w)", B.canBound(w), "isClaimed", B.isClaimed(d))
end)

T("S3 R5 extended (engine-shaped fake): bind 1 / unbind 1 around a live value", function()
	for _, mode in { "bind1", "unbind1-only", "bind1+unbind1" } do
		local a = fakeInst(); B.nativeClaim(a)
		local v = {}
		B.bindLifetime(a, v)
		local r1, r2 = "-", "-"
		if mode ~= "unbind1-only" then r1 = E(B.bindLifetime, a, 1) end
		if mode ~= "bind1" then r2 = E(B.unbindLifetime, 1) end
		gc()
		print(string.format(" %-14s bind1=%s unbind1=%s | after GC isHeld(v)=%s isClaimed(a)=%s canBound(v)=%s", mode, r1, r2, tostring(B.isHeld(v)), tostring(B.isClaimed(a)), tostring(B.canBound(v))))
		if B.isHeld(1) then B.unbindLifetime(1) end -- keep value space clean for next mode
	end
end)

T("S4 primitive/other value kinds at the bind door", function()
	local a = Instance.foreign("Frame"); B.nativeClaim(a)
	local kinds = {
		{ "number 1", 1 }, { "number 0.5", 0.5 }, { "string", "label" }, { "true", true }, { "false", false },
		{ "vector", vector.create(1, 2, 3) }, { "buffer", buffer.create(1) }, { "thread", coroutine.create(function() end) },
		{ "table", {} }, { "function", function() end }, { "userdata(newproxy)", newproxy(false) }, { "mock Instance", Instance.foreign("Frame") },
	}
	for _, k in kinds do
		print(string.format(" %-20s type=%-9s -> %s", k[1], type(k[2]), E(B.bindLifetime, a, k[2])))
	end
end)

local weak5 = setmetatable({}, { __mode = "v" })
local function s5build()
	local a = fakeInst(); B.nativeClaim(a)
	local v = {}; local cap = {}; local fn = function() return cap end -- capturing: an upvalue-free closure is a cached constant and never collects
	B.bindLifetime(a, v); B.bindLifetime(a, fn)
	weak5.v = v; weak5.fn = fn; weak5.conn = connOf[a]; weak5.a = a
	return a
end
local function s5report(tag)
	local function st(x) return if x == nil then "collected" else "alive" end
	print(string.format(" %-26s a=%s v=%s fn=%s gcconn=%s", tag, st(weak5.a), st(weak5.v), st(weak5.fn), st(weak5.conn)))
end
T("S5 GC (engine-shaped fake): anchor keeps the island while alive, releases it after destroy", function()
	local holder = { s5build() } -- the only strong ref to a
	gc(); s5report("alive, after GC:")
	print(" isClaimed(a)", B.isClaimed(holder[1]), "isHeld(v)", B.isHeld(weak5.v))
	fakeDestroy(holder[1]); holder[1] = nil
	gc(); s5report("destroyed+dropped, GC:")
end)

T("S6 GC churn: 2000 claim/bind/destroy cycles (mock Instances) — memory returns", function()
	gc()
	local k0 = collectgarbage("count")
	local weak = setmetatable({}, { __mode = "v" })
	for i = 1, 2000 do
		local a = Instance.foreign("Frame"); B.nativeClaim(a)
		local v = {}
		B.bindLifetime(a, v)
		if i % 500 == 0 then weak[#weak + 1] = a; weak[#weak + 1] = v end
		a:Destroy()
	end
	gc()
	local n = 0
	for _ in weak do n += 1 end
	print(string.format(" KB before %.1f after %.1f (delta %.1f), sampled survivors %d/8", k0, collectgarbage("count"), collectgarbage("count") - k0, n))
end)
