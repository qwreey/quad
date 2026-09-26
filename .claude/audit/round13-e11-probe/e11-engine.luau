--!nocheck
-- round13 E11 probe B — REAL quad-roblox EngineOps/LifetimeHandle over mock instances (not a spec).
-- Measures only the Luau logic of the real provider; engine behavior itself is NOT measured here.
local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installEngineOps = require("../src/EngineOps")
local mock = require("../../quad-base/test/mock")
local Instance = mock.Instance
;(getfenv(installEngineOps)).game = mock.gameShim({})
local fired = {}
;(getfenv(installEngineOps)).task = {
	delay = function(d, fn) local th = coroutine.create(fn); fired[#fired + 1] = { d = d, th = th }; return th end,
	cancel = function(th) if coroutine.status(th) ~= "dead" then coroutine.close(th) end end,
}
local function try(label, f, ...)
	local r = table.pack(pcall(f, ...))
	local out = {}
	for i = 2, r.n do out[#out + 1] = tostring(r[i]) end
	print(string.format("%-58s %s %s", label, r[1] and "OK " or "ERR", table.concat(out, " | ")))
	return r[1], r[2]
end
local q = Quad.New():UseProvider(QuadRoblox)
local B = q.Backend
local nan = 0 / 0
local vals = { { "nil", nil }, { "5", 5 }, { "'s'", "s" }, { "NaN", nan }, { "{}", {} }, { "true", true }, { "fn", function() end } }

print("== 1. real pure predicates, boundary args ==")
for _, op in { "isInst", "isClaimed", "isHeld" } do
	for _, p in vals do try(op .. "(" .. p[1] .. ")", B[op], p[2]) end
end
local mi = Instance.new("Frame")
try("isInst(mock instance) [real = typeof=='Instance']", B.isInst, mi)
for _, p in vals do
	try("isHeldBy(" .. p[1] .. ", mi)", B.isHeldBy, p[2], mi)
	try("isHeldBy({}, " .. p[1] .. ")", B.isHeldBy, {}, p[2])
end

print("== 2. real releaseLifetime boundary ==")
for _, p in vals do try("releaseLifetime(" .. p[1] .. ")", B.releaseLifetime, p[2]) end

print("== 3. real nativeClaim / isClaimed / holdLifetime ==")
local a = Instance.new("Frame")
print("  real isClaimed(mock Instance.new before nativeClaim)", B.isClaimed(a))
try("holdLifetime(unclaimed, {})", B.holdLifetime, a, {})
try("nativeClaim(a)", B.nativeClaim, a)
print("  isClaimed(a)", B.isClaimed(a))
try("nativeClaim(a) again", B.nativeClaim, a)
local v = {}
B.bindLifetime(a, v)
print("  isHeld(v)", B.isHeld(v))
a:Destroy()
print("  after Destroy: isHeld(v)", B.isHeld(v), "isClaimed(a)", B.isClaimed(a))
local w = {}
try("bindLifetime(destroyed claimed a, w) pre-GC", B.bindLifetime, a, w)
print("  isHeld(w)", B.isHeld(w))
-- GC: the gcconn closure anchors gchold; Destroy disconnected it
local a2 = Instance.new("Frame"); B.nativeClaim(a2); a2:Destroy()
collectgarbage("collect"); collectgarbage("collect")
try("bindLifetime(destroyed claimed a2, {}) post-GC", B.bindLifetime, a2, {})
try("nativeClaim(destroyed a2) post-GC (re-claim corpse)", B.nativeClaim, a2)
print("  isClaimed(re-claimed corpse)", B.isClaimed(a2))
local c = {}
local okc = try("bindLifetime(re-claimed corpse, c)", B.bindLifetime, a2, c)
print("  isHeld(c) on re-claimed corpse", B.isHeld(c))
try("holdLifetime(nil, {}) direct", B.holdLifetime, nil, {})
try("nativeClaim(nil)", B.nativeClaim, nil)
try("nativeClaim(5)", B.nativeClaim, 5)

print("== 4. real onDestroying ==")
try("onDestroying(nil, fn)", B.onDestroying, nil, function() end)
try("onDestroying({}, fn)", B.onDestroying, {}, function() end)

print("== 5. real nativeFindChild over mock (IsA == ClassName equality in mock) ==")
do
	local root = Instance.new("Frame")
	local k = Instance.new("TextLabel"); k.Name = "Kid"; k.Parent = root
	try("find(root,'Kid','TextLabel')", function() return B.nativeFindChild(root, "Kid", "TextLabel") ~= nil end)
	try("find(root,'Kid','GuiObject')", function() return B.nativeFindChild(root, "Kid", "GuiObject") ~= nil end)
	try("find(root, nil)", B.nativeFindChild, root, nil)
	try("find(root, 123)", B.nativeFindChild, root, 123)
end

print("== 6. real time ops ==")
try("setTimeout(fn, math.huge)", B.setTimeout, function() end, math.huge)
try("setTimeout(fn, 0)", function() local t = B.setTimeout(function() end, 0); return fired[#fired].d end)
local _, e = pcall(B.setTimeout, 1, 1); print("  msg:", e)
try("clearTimeout(forged {__quadTimeout=true})", B.clearTimeout, { __quadTimeout = true })

print("== 7. real setAttr/addTag pass-through (engine gate is Roblox's; mock SetAttribute accepts all) ==")
local t = Instance.new("Frame")
try("setAttr(t,'X',{})", B.setAttr, t, "X", {})
try("setAttr(t,'RBXx',1)", B.setAttr, t, "RBXx", 1)
try("addTag(t,{''})", B.addTag, t, { "" })
