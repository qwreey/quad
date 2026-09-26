--!nocheck
-- round13 E11 probe A — mock backend ops, nil/boundary/shape (not a spec)
local mock = require("./mock")
local QT = require("../luau_packages/quad_types")
local Instance = mock.Instance
local function try(label, f, ...)
	local r = table.pack(pcall(f, ...))
	local out = {}
	for i = 2, r.n do out[#out + 1] = tostring(r[i]) end
	print(string.format("%-58s %s %s", label, r[1] and "OK " or "ERR", table.concat(out, " | ")))
	return r[1], r[2]
end

local q = mock.newQuad()
local B = q.Backend
local nan = 0 / 0
local vals = { { "nil", nil }, { "5", 5 }, { "'s'", "s" }, { "NaN", nan }, { "{}", {} }, { "true", true }, { "fn", function() end } }

print("== 1. pure predicates, boundary args (contract: never throw, nil -> false) ==")
for _, op in { "isInst", "isClaimed", "isHeld" } do
	for _, p in vals do
		try(op .. "(" .. p[1] .. ")", B[op], p[2])
	end
end
local inst = Instance.new("Frame")
for _, p in vals do
	try("isHeldBy(" .. p[1] .. ", inst)", B.isHeldBy, p[2], inst)
	try("isHeldBy({}, " .. p[1] .. ")", B.isHeldBy, {}, p[2])
end
try("canExecute(NaN)", B.canExecute, nan)
try("canBound(5)", B.canBound, 5)

print("== 2. releaseLifetime boundary (contract: nil gate is base's) ==")
for _, p in vals do
	try("releaseLifetime(" .. p[1] .. ")", B.releaseLifetime, p[2])
end

print("== 3. onDestroying: Connection shape / colon Disconnect / destroyed inst ==")
do
	local a = Instance.new("Frame")
	local fired = 0
	local c = B.onDestroying(a, function() fired += 1 end)
	print("type", type(c), "Connected", c.Connected, "Disconnect is fn", type(c.Disconnect))
	try("c:Disconnect()", function() c:Disconnect() end)
	print("  after Disconnect Connected=", c.Connected)
	try("c:Disconnect() twice", function() c:Disconnect() end)
	try("c.Disconnect() dot-call", function() c.Disconnect() end)
	a:Destroy()
	print("  fired after Disconnect+Destroy =", fired)
	local b = Instance.new("Frame")
	local order = {}
	local c2 = B.onDestroying(b, function() order[#order + 1] = "fn(Parent=" .. tostring(b.Parent) .. ",Connected=" .. tostring(c2 and c2.Connected) .. ")" end)
	local p = Instance.new("Frame"); b.Parent = p
	b:Destroy()
	order[#order + 1] = "after Destroy returns"
	print("  sync order:", table.concat(order, " ; "), "| c2.Connected after =", c2.Connected)
	local d = Instance.new("Frame"); d:Destroy()
	local f3 = 0
	local c3 = B.onDestroying(d, function() f3 += 1 end)
	print("  onDestroying on already-destroyed: Connected=", c3.Connected, "fired=", f3)
	try("onDestroying(non-instance {})", B.onDestroying, {}, function() end)
	try("onDestroying(nil)", B.onDestroying, nil, function() end)
end

print("== 4. nativeFindChild: className / key domain / duplicates ==")
do
	local root = Instance.new("Frame")
	local k1 = Instance.new("ImageLabel"); k1.Name = "Kid"; k1.Parent = root
	local k2 = Instance.new("TextLabel"); k2.Name = "Kid"; k2.Parent = root
	try("find(root,'Kid',nil)", function() return B.nativeFindChild(root, "Kid", nil).ClassName end)
	try("find(root,'Kid','TextLabel') [2nd sibling has class]", B.nativeFindChild, root, "Kid", "TextLabel")
	try("find(root,'Kid','ImageLabel')", function() return B.nativeFindChild(root, "Kid", "ImageLabel").ClassName end)
	try("find(root,'Kid','GuiObject') [abstract]", B.nativeFindChild, root, "Kid", "GuiObject")
	try("find(root,'Kid','Instance') [root class]", B.nativeFindChild, root, "Kid", "Instance")
	try("find(root,123,nil)", B.nativeFindChild, root, 123, nil)
	try("find(root,nil,nil)", B.nativeFindChild, root, nil, nil)
	try("find({},'Kid')", B.nativeFindChild, {}, "Kid")
	-- mock IsA (used by quad-roblox's REAL nativeFindChild when quad-roblox specs run on mock)
	try("k2:IsA('GuiObject')", function() return k2:IsA("GuiObject") end)
	try("k2:IsA('Instance')", function() return k2:IsA("Instance") end)
end

print("== 5. native* no-op/offset, dispose domain ==")
do
	local t = Instance.new("Frame")
	local a, b = Instance.new("Frame"), Instance.new("Frame")
	try("nativeMove(any args)", B.nativeMove, nil, -1, {}, 99)
	try("nativeSwap(any args)", B.nativeSwap, nil, 0 / 0, nil, "x", nil)
	try("nativeInsert(t, 999, {a})", B.nativeInsert, t, 999, { a })
	print("  a.Parent==t", a.Parent == t)
	try("nativeRemove(t,0,{a},{b})", B.nativeRemove, t, 0, { a }, { b })
	print("  b.Parent==t", b.Parent == t, "a destroyed", mock.isDestroyed(a))
	try("nativeDispose(already destroyed a)", B.nativeDispose, a)
	try("nativeDispose({})", B.nativeDispose, {})
	try("nativeInsert(t,0,{ {} })", B.nativeInsert, t, 0, { {} })
end

print("== 6. hold ops: GC-evidence semantics ==")
do
	local v = {}
	local a = Instance.new("Frame")
	B.bindLifetime(a, v)
	print("  isHeld after bind", B.isHeld(v), "isHeldBy(v,a)", B.isHeldBy(v, a), "canExecute", B.canExecute(v))
	a:Destroy()
	print("  isHeld right after Destroy (no GC)", B.isHeld(v), "canBound", B.canBound(v))
	-- rebind the same value elsewhere after Destroy (evidence dead -> canBound true)
	local a2 = Instance.new("Frame")
	try("bindLifetime(a2, v) after a destroyed", B.bindLifetime, a2, v)
	print("  isHeldBy(v,a2)", B.isHeldBy(v, a2))
	-- foreign instance: engine = Quad0226, mock = lazy claim
	local f = Instance.foreign("Frame")
	print("  isClaimed(foreign) before", B.isClaimed(f))
	local ok = try("bindLifetime(foreign, {})", B.bindLifetime, f, {})
	print("  isClaimed(foreign) after bind", B.isClaimed(f))
	try("nativeClaim(foreign) after bind", B.nativeClaim, f)
	-- Instance.new that was destroyed before any hold: engine (pre-GC) hold succeeds with dead evidence
	local z = Instance.new("Frame"); z:Destroy()
	local w = {}
	try("bindLifetime(destroyed Instance.new, w)", B.bindLifetime, z, w)
	print("  isHeld(w)", B.isHeld(w), "canBound(w)", B.canBound(w))
	-- a destroyed foreign never claimed
	local zf = Instance.foreign("Frame"); zf:Destroy()
	try("bindLifetime(destroyed foreign, {})", B.bindLifetime, zf, {})
	try("holdLifetime({}, {}) non-instance", B.holdLifetime, {}, {})
	try("holdLifetime(a2, nil) direct", B.holdLifetime, Instance.new("Frame"), nil)
	-- primitive values as hold values
	for _, p in { { "5", 5 }, { "'s'", "s" }, { "true", true } } do
		local h = Instance.new("Frame")
		try("bindLifetime(h, " .. p[1] .. ")", B.bindLifetime, h, p[2])
		print("    isHeld(" .. p[1] .. ")", B.isHeld(p[2]))
	end
	try("bindLifetime(h, NaN)", B.bindLifetime, Instance.new("Frame"), nan)
end

print("== 7. isClaimed after Destroy / nativeClaim codes ==")
do
	local a = Instance.new("Frame")
	print("  isClaimed(new)", B.isClaimed(a))
	a:Destroy()
	print("  isClaimed(new, destroyed)", B.isClaimed(a))
	local ok, e = try("nativeClaim(new) (already)", B.nativeClaim, a)
	local f = Instance.foreign("Frame")
	B.nativeClaim(f)
	print("  isClaimed(foreign claimed)", B.isClaimed(f))
end

print("== 8. time ops ==")
do
	mock.resetTimers()
	local log = {}
	B.setTimeout(function() log[#log + 1] = "t0" end, 0)
	print("  fired synchronously?", #log)
	mock.advanceTime(0)
	print("  after advanceTime(0)", table.concat(log, ","))
	-- zero-delay self-rescheduling chain inside one advance
	mock.resetTimers()
	local n = 0
	local function tick()
		n += 1
		if n < 1000 then B.setTimeout(tick, 0) end
	end
	B.setTimeout(tick, 0)
	mock.advanceTime(0)
	print("  self-rescheduling setTimeout(0) chain: callbacks run in ONE advanceTime(0) =", n)
	-- clearTimeout of self inside own callback
	mock.resetTimers()
	local h
	h = B.setTimeout(function() try("clearTimeout(self) inside own callback", B.clearTimeout, h) end, 1)
	mock.advanceTime(1)
	-- clearTimeout of a sibling due at the same instant
	mock.resetTimers()
	local fired = {}
	local h2
	B.setTimeout(function() fired[#fired + 1] = "A"; B.clearTimeout(h2) end, 1)
	h2 = B.setTimeout(function() fired[#fired + 1] = "B" end, 1)
	mock.advanceTime(1)
	print("  same-instant sibling cancel: fired =", table.concat(fired, ","))
	try("setTimeout(fn, math.huge)", B.setTimeout, function() end, math.huge)
	try("setTimeout(fn, -0)", B.setTimeout, function() end, -0)
	try("setTimeout(fn, NaN)", B.setTimeout, function() end, nan)
	try("clearTimeout(forged {__quadTimeout=true})", B.clearTimeout, { __quadTimeout = true })
	try("clearTimeout(nil)", B.clearTimeout, nil)
	mock.resetTimers()
end

print("== 9. setAttr / addTag value domain (mock) ==")
do
	local a = Instance.new("Frame")
	for _, p in { { "table", {} }, { "fn", function() end }, { "instance", Instance.new("Part") }, { "NaN", nan } } do
		try("setAttr(a,'X'," .. p[1] .. ")", B.setAttr, a, "X", p[2])
	end
	for _, nm in { "", "RBXfoo", string.rep("x", 101), "has space", "a.b" } do
		try("setAttr(a," .. string.format("%q", nm:sub(1, 12)) .. ",1)", B.setAttr, a, nm, 1)
	end
	try("addTag(a,{''})", B.addTag, a, { "" })
	try("addTag(a,{string.rep('x',101)})", B.addTag, a, { string.rep("x", 101) })
	try("addTag(a,{5})", B.addTag, a, { 5 })
	-- through quad: raw AttrKey path and State path carrying a table
	local src = q.Source(1)
	try("drive {[AttrKey('T')] = {}} (raw key, table value)", q.Dispatch.drive, Instance.new("Frame"), { [q.AttrKey("T")] = {} })
	local inst2 = Instance.new("Frame")
	try("drive { Attr({ S = src }) }", q.Dispatch.drive, inst2, { q.Attr({ S = src }) })
	try("src:Set({}) -> setAttr(table) via State", function() src:Set({}) end)
	print("  inst2:GetAttribute('S') type =", type(inst2:GetAttribute("S")))
	try("drive {[AttrKey('RBXname')] = 1}", q.Dispatch.drive, Instance.new("Frame"), { [q.AttrKey("RBXname")] = 1 })
	try("Tag with '' name: drive { q.Tag('') }", function() q.Dispatch.drive(Instance.new("Frame"), { q.Tag("") }) end)
end

print("== 10. Brand (quad_types) ==")
do
	local Br = QT.Brand()
	for _, p in vals do try("Brand:Is(" .. p[1] .. ")", function() return Br:Is(p[2]) end) end
	try("Brand:Register(nil)", function() Br:Register(nil) end)
	try("Brand:Register(NaN)", function() Br:Register(nan) end)
	local x = {}
	Br:Register(x)
	try("Brand.Is(x) dot-call (x taken as self)", function() return Br.Is(x) end)
	try("Brand.Register(y) dot-call", function() Br.Register({}) end)
end

print("== 11. error-code prefix of mock messages vs engine ==")
do
	local _, e1 = pcall(B.setTimeout, 1, 1)
	local _, e2 = pcall(B.nativeClaim, Instance.new("Frame"))
	local _, e3 = pcall(B.holdLifetime, {}, {})
	print("  mock setTimeout msg:", e1)
	print("  mock nativeClaim msg:", e2)
	print("  mock holdLifetime msg:", e3)
end
